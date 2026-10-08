-- RouletteService: la Ruleta Maldita. El premio lo decide SIEMPRE el servidor (el cliente solo anima).
--   Spin("Free")  -> la tirada gratis del día
--   Spin("Coins") -> tirada pagando Monedas Malditas (máximo RouletteConfig.MaxPaidPerDay al día)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RouletteConfig = require(Shared:WaitForChild("RouletteConfig"))
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))

local RouletteService = {}
RouletteService.Handlers = {}

local services
local rng = Random.new()
local busy = {} -- [Player] = true mientras se procesa una tirada

local function result(ok: boolean, msg: string)
	return { ok = ok, msg = msg }
end

local function today(): number
	return math.floor(os.time() / 86400)
end

local function pick(): number
	local roll = rng:NextNumber() * RouletteConfig.TotalWeight()
	for i, prize in RouletteConfig.Prizes do
		roll -= prize.Weight
		if roll <= 0 then
			return i
		end
	end
	return 1
end

-- Estado de hoy (se reinicia solo al cambiar de día)
local function ensureDay(d)
	if d.Roulette.Day ~= today() then
		d.Roulette.Day = today()
		d.Roulette.FreeUsed = false
		d.Roulette.Paid = 0
	end
end

RouletteService.Handlers.Spin = function(player: Player, mode: any)
	if mode ~= "Free" and mode ~= "Coins" then
		return result(false, "Invalid request")
	end
	if busy[player] then
		return result(false, "")
	end
	local data = services.DataService.Get(player)
	if not data then
		return result(false, "Your data is still loading")
	end
	busy[player] = true
	local ok, response = pcall(function()
		services.DataService.Update(player, ensureDay)
		if mode == "Free" then
			if data.Roulette.FreeUsed then
				return result(false, "You already used today's free spin")
			end
			services.DataService.Update(player, function(d)
				d.Roulette.FreeUsed = true
			end)
		else
			if data.Roulette.Paid >= RouletteConfig.MaxPaidPerDay then
				return result(false, `Max {RouletteConfig.MaxPaidPerDay} spins per day. Come back tomorrow!`)
			end
			-- Evento "Fortuna Maldita": mitad de precio
			local cost = if services.EventService and services.EventService.Active() == "Fortune" then RouletteConfig.SpinCostCoins // 2 else RouletteConfig.SpinCostCoins
			if not services.EconomyService.SpendCurrency(player, "Coins", cost, "Roulette") then
				return result(false, "You don't have enough Cursed Coins")
			end
			services.DataService.Update(player, function(d)
				d.Roulette.Paid += 1
			end)
		end

		local index = pick()
		local prize = RouletteConfig.Prizes[index]
		local text = RouletteConfig.Describe(prize)
		local skinId = nil
		if prize.Kind == "Coins" or prize.Kind == "Gems" then
			services.EconomyService.AddCurrency(player, prize.Kind, prize.Amount, "Roulette")
		elseif prize.Kind == "XP" then
			services.EconomyService.AddXP(player, prize.Amount)
		elseif prize.Kind == "Boost" then
			services.DataService.Update(player, function(d)
				d.Boosts.CoinsUntil = math.max(d.Boosts.CoinsUntil, os.time()) + prize.Amount
			end)
			services.BoosterService.Refresh(player)
		elseif prize.Kind == "Skin" then
			local missing = {}
			for _, id in RouletteConfig.RareSkins do
				if not data.OwnedSkins[id] then
					table.insert(missing, id)
				end
			end
			if #missing > 0 then
				skinId = missing[rng:NextInteger(1, #missing)]
				local skin = CatalogConfig.Skins[skinId]
				-- Antes solo se daba la skin: si no tenías el personaje (p. ej. Sukuna) no podías usarla.
				-- Ahora, si no lo tienes, la ruleta te regala también el personaje.
				local unlockedCharacter = skin and skin.Character and not data.OwnedCharacters[skin.Character]
				services.DataService.Update(player, function(d)
					d.OwnedSkins[skinId] = true
					if unlockedCharacter then
						d.OwnedCharacters[skin.Character] = true
					end
					d.EquippedSkins[skin.Character] = skinId -- ya equipada para que se vea al momento
				end)
				local CharacterRegistry = require(ReplicatedStorage.Shared:WaitForChild("CharacterRegistry"))
				local charData = CharacterRegistry.Get(skin.Character)
				local charName = if charData then charData.DisplayName else skin.Character
				text = if unlockedCharacter then `{charName} UNLOCKED + {skin.Name} skin!` else `EXCLUSIVE SKIN: {skin.Name}`
				-- ¡Que se entere todo el servidor!
				for _, other in Players:GetPlayers() do
					services.EconomyFeedback:FireClient(other, "Reward", { Reason = `{player.DisplayName} won the {skin.Name} skin on the Cursed Roulette!` })
				end
			else
				services.EconomyService.AddCurrency(player, "Gems", RouletteConfig.DuplicateSkinGems, "Ruleta:SkinRepetida")
				text = `You already had every skin: +{RouletteConfig.DuplicateSkinGems} Gems`
			end
		end
		task.spawn(services.DataService.Save, player, false)
		services.QuestService.Add(player, "Roulette", 1)
		services.DataService.PushState(player)
		return { ok = true, msg = text, Index = index, Skin = skinId }
	end)
	busy[player] = nil
	if not ok then
		warn("[RouletteService]", response)
		return result(false, "Roulette error, try again")
	end
	return response
end

function RouletteService.Start(s)
	services = s
	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
end

return RouletteService
