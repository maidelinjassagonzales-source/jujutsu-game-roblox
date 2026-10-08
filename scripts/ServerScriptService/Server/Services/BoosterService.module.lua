-- BoosterService: multiplicadores de progreso. NUNCA afectan al combate.
--   * Skin premium equipada        -> +5% Monedas y XP
--   * Gamepass VIP                 -> +5% Monedas y XP
--   * Gamepass Monedas x2          -> +100% Monedas (permanente)
--   * Booster temporal (tienda)    -> +100% Monedas o XP durante X minutos
-- Publica "BoostCoins" y "BoostXP" (en %) como atributos del jugador para la UI.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local CatalogConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CatalogConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local BoosterService = {}

local owned = setmetatable({}, { __mode = "k" }) -- [Player] = { VIP = true, CoinsX2 = true }
local PASSES = CatalogConfig.GamePasses

local function bonusFor(player: Player, kind: string): number
	local bonus = 0
	local passes = owned[player] or {}
	if passes.VIP then
		bonus += PASSES.VIP.Boost
	end
	if kind == "Coins" and passes.CoinsX2 then
		bonus += PASSES.CoinsX2.CoinsBoost
	end
	local model = player.Character
	local skinId = model and model:GetAttribute("SkinId")
	local skin = skinId and CatalogConfig.Skins[skinId]
	if skin and skin.Premium then
		bonus += CatalogConfig.PremiumSkinBoost
	end
	local data = DataService.Get(player)
	if data then
		local untilTime = if kind == "Coins" then data.Boosts.CoinsUntil else data.Boosts.XPUntil
		if untilTime > os.time() then
			bonus += 1
		end
	end
	return bonus
end

function BoosterService.Refresh(player: Player)
	player:SetAttribute("BoostCoins", math.floor(bonusFor(player, "Coins") * 100 + 0.5))
	player:SetAttribute("BoostXP", math.floor(bonusFor(player, "XP") * 100 + 0.5))
	local passes = owned[player] or {}
	player:SetAttribute("VIP", passes.VIP == true)
	player:SetAttribute("CoinsX2", passes.CoinsX2 == true)
	local data = DataService.Get(player)
	if data then
		player:SetAttribute("BoostCoinsUntil", data.Boosts.CoinsUntil)
		player:SetAttribute("BoostXPUntil", data.Boosts.XPUntil)
	end
end

local function checkPasses(player: Player)
	local passes = owned[player] or {}
	owned[player] = passes
	for key, pass in PASSES do
		if pass.Id ~= 0 then
			local ok, has = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			if ok and has then
				passes[key] = true
			end
		end
	end
	BoosterService.Refresh(player)
end

function BoosterService.HasPass(player: Player, key: string): boolean
	return (owned[player] or {})[key] == true
end

local function onPlayerAdded(player: Player)
	task.spawn(checkPasses, player)
	player.CharacterAdded:Connect(function()
		task.wait(0.1) -- el atributo SkinId se pone al construir el modelo
		BoosterService.Refresh(player)
	end)
end

function BoosterService.Start(economyService)
	economyService.RegisterMultiplier(function(player, kind)
		return 1 + bonusFor(player, kind)
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for key, pass in PASSES do
			if pass.Id == passId then
				owned[player] = owned[player] or {}
				owned[player][key] = true
			end
		end
		BoosterService.Refresh(player)
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	-- Los boosters temporales caducan: refresco periódico
	task.spawn(function()
		while true do
			task.wait(5)
			for _, player in Players:GetPlayers() do
				BoosterService.Refresh(player)
			end
		end
	end)
end

return BoosterService
