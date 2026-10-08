-- BattlePassService: Pase de Batalla con ruta gratuita y premium (Fase 4).
-- El XP del pase sale del mismo XP de cuenta (jugar = progresar en ambos).
-- Replica "BPXP" y "BPPremium" como atributos del jugador; lo reclamado va en el estado (PushState).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BattlePassConfig = require(Shared:WaitForChild("BattlePassConfig"))
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local BattlePassService = {}
BattlePassService.Handlers = {}

local economyFeedback: RemoteEvent

local function result(ok: boolean, msg: string)
	return { ok = ok, msg = msg }
end

-- Si cambió la temporada, el progreso del pase se reinicia
local function ensureSeason(data)
	if data.BattlePass.Season ~= BattlePassConfig.Season.Id then
		data.BattlePass = {
			Season = BattlePassConfig.Season.Id,
			XP = 0,
			Premium = false,
			ClaimedFree = {},
			ClaimedPremium = {},
		}
	end
end

local function syncAttributes(player: Player, data)
	player:SetAttribute("BPXP", data.BattlePass.XP)
	player:SetAttribute("BPPremium", data.BattlePass.Premium)
end

local function onXPGained(player: Player, amount: number)
	if amount <= 0 or not BattlePassConfig.IsActive(os.time()) then
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	local beforeTier = BattlePassConfig.TierFromXP(data.BattlePass.XP)
	DataService.Update(player, function(d)
		ensureSeason(d)
		d.BattlePass.XP += amount
	end)
	syncAttributes(player, data)
	local afterTier = BattlePassConfig.TierFromXP(data.BattlePass.XP)
	if afterTier > beforeTier then
		economyFeedback:FireClient(player, "BPTier", afterTier)
		DataService.PushState(player)
	end
end

local function grantReward(player: Player, reward, label: string)
	if reward.Coins then
		EconomyService.AddCurrency(player, "Coins", reward.Coins, label)
		economyFeedback:FireClient(player, "Reward", { Coins = reward.Coins, Reason = "Pase" })
	end
	if reward.Gems then
		EconomyService.AddCurrency(player, "Gems", reward.Gems, label)
		economyFeedback:FireClient(player, "Reward", { Gems = reward.Gems, Reason = "Pase" })
	end
	if reward.Skin and CatalogConfig.Skins[reward.Skin] then
		DataService.Update(player, function(d)
			d.OwnedSkins[reward.Skin] = true
		end)
	end
end

BattlePassService.Handlers.ClaimTier = function(player: Player, tier: any, track: any)
	if type(tier) ~= "number" or tier % 1 ~= 0 or (track ~= "Free" and track ~= "Premium") then
		return result(false, "Petición inválida")
	end
	local tierInfo = BattlePassConfig.Tiers[tier]
	local data = DataService.Get(player)
	if not tierInfo or not data then
		return result(false, "Nivel inválido")
	end
	DataService.Update(player, ensureSeason)
	local bp = data.BattlePass
	if BattlePassConfig.TierFromXP(bp.XP) < tier then
		return result(false, "Aún no has llegado a ese nivel del pase")
	end
	if track == "Premium" and not bp.Premium then
		return result(false, "Necesitas el Pase Premium")
	end
	local claimed = if track == "Free" then bp.ClaimedFree else bp.ClaimedPremium
	local key = tostring(tier)
	if claimed[key] then
		return result(false, "Ya reclamado")
	end

	DataService.Update(player, function()
		claimed[key] = true
	end)
	grantReward(player, tierInfo[track], `Pase:{BattlePassConfig.Season.Id}:{track}:{tier}`)
	DataService.PushState(player)
	return result(true, `Recompensa del nivel {tier} reclamada`)
end

-- El Pase Premium se paga con ROBUX: el cliente abre la compra (PremiumProductId) y
-- EconomyService.ProcessReceipt llama a estas funciones al confirmarse el pago.
EconomyService.RegisterProduct(BattlePassConfig.PremiumProductId, function(_player, d)
	ensureSeason(d)
	d.BattlePass.Premium = true
end, function(d)
	d.BattlePass.Premium = false
end, function(player)
	local data = DataService.Get(player)
	if data then
		syncAttributes(player, data)
	end
	DataService.PushState(player)
end)

-- Saltar un nivel del pase pagando Gemas (atajo clásico de los pases de batalla)
BattlePassService.Handlers.SkipTier = function(player: Player)
	if not BattlePassConfig.IsActive(os.time()) then
		return result(false, "No hay ninguna temporada activa")
	end
	local data = DataService.Get(player)
	if not data then
		return result(false, "Tus datos aún se están cargando")
	end
	DataService.Update(player, ensureSeason)
	local tier = BattlePassConfig.TierFromXP(data.BattlePass.XP)
	if tier >= BattlePassConfig.MaxTier then
		return result(false, "Ya tienes el pase al máximo")
	end
	if not EconomyService.SpendCurrency(player, "Gems", CatalogConfig.TierSkipGems, "Pase:SaltarNivel") then
		return result(false, "No tienes suficientes Gemas")
	end
	DataService.Update(player, function(d)
		d.BattlePass.XP = (tier + 1) * BattlePassConfig.XPPerTier
	end)
	syncAttributes(player, data)
	DataService.PushState(player)
	return result(true, `¡Nivel {tier + 1} del pase!`)
end

function BattlePassService.Start(remotes: Folder)
	economyFeedback = remotes:WaitForChild("EconomyFeedback")
	EconomyService.OnXPGained(onXPGained)

	DataService.ProfileLoaded:Connect(function(player, data)
		DataService.Update(player, ensureSeason)
		syncAttributes(player, data)
		DataService.PushState(player)
	end)
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		if data then
			DataService.Update(player, ensureSeason)
			syncAttributes(player, data)
		end
	end
end

return BattlePassService
