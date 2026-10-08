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
		economyFeedback:FireClient(player, "Reward", { Coins = reward.Coins, Reason = "Pass" })
	end
	if reward.Gems then
		EconomyService.AddCurrency(player, "Gems", reward.Gems, label)
		economyFeedback:FireClient(player, "Reward", { Gems = reward.Gems, Reason = "Pass" })
	end
	if reward.Skin and CatalogConfig.Skins[reward.Skin] then
		DataService.Update(player, function(d)
			d.OwnedSkins[reward.Skin] = true
		end)
	end
end

BattlePassService.Handlers.ClaimTier = function(player: Player, tier: any, track: any)
	if type(tier) ~= "number" or tier % 1 ~= 0 or (track ~= "Free" and track ~= "Premium") then
		return result(false, "Invalid request")
	end
	local tierInfo = BattlePassConfig.Tiers[tier]
	local data = DataService.Get(player)
	if not tierInfo or not data then
		return result(false, "Invalid tier")
	end
	DataService.Update(player, ensureSeason)
	local bp = data.BattlePass
	if BattlePassConfig.TierFromXP(bp.XP) < tier then
		return result(false, "You haven't reached that pass tier yet")
	end
	if track == "Premium" and not bp.Premium then
		return result(false, "You need the Premium Pass")
	end
	local claimed = if track == "Free" then bp.ClaimedFree else bp.ClaimedPremium
	local key = tostring(tier)
	if claimed[key] then
		return result(false, "Already claimed")
	end

	DataService.Update(player, function()
		claimed[key] = true
	end)
	grantReward(player, tierInfo[track], `Pase:{BattlePassConfig.Season.Id}:{track}:{tier}`)
	DataService.PushState(player)
	return result(true, `Tier {tier} reward claimed`)
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
		return result(false, "There is no active season")
	end
	local data = DataService.Get(player)
	if not data then
		return result(false, "Your data is still loading")
	end
	DataService.Update(player, ensureSeason)
	local tier = BattlePassConfig.TierFromXP(data.BattlePass.XP)
	if tier >= BattlePassConfig.MaxTier then
		return result(false, "Your pass is already maxed out")
	end
	if not EconomyService.SpendCurrency(player, "Gems", CatalogConfig.TierSkipGems, "Pase:SaltarNivel") then
		return result(false, "You don't have enough Gems")
	end
	DataService.Update(player, function(d)
		d.BattlePass.XP = (tier + 1) * BattlePassConfig.XPPerTier
	end)
	syncAttributes(player, data)
	DataService.PushState(player)
	return result(true, `Pass tier {tier + 1}!`)
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
