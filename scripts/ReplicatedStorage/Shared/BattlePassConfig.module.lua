-- BattlePassConfig: temporada actual, XP por nivel y recompensas de las dos rutas.
--   Free    -> todos los jugadores
--   Premium -> se compra con ROBUX (Developer Product); incluye 500 晶 repartidas por la ruta
local CatalogConfig = require(script.Parent:WaitForChild("CatalogConfig"))
local utc = CatalogConfig.utc

local BattlePassConfig = {}

BattlePassConfig.Season = {
	Id = "S1",
	Name = "Season 1 · Cursed Awakening",
	Start = utc(2026, 10, 1),
	End = utc(2026, 12, 15),
}

BattlePassConfig.XPPerTier = 1500 -- ~3 partidas por nivel del pase
BattlePassConfig.MaxTier = 30
-- Pase Premium = Developer Product de Robux (uno por temporada, porque se reinicia cada temporada).
-- Créalo en Creator Hub > Monetization > Developer Products y pega aquí su ID (0 = botón avisa que falta).
BattlePassConfig.PremiumProductId = 3717315969
BattlePassConfig.PremiumRobuxHint = 499

local tiers = {}
for tier = 1, BattlePassConfig.MaxTier do
	local free = { Coins = 100 + tier * 10 }
	local premium = { Coins = 250 + tier * 20 }
	if tier % 5 == 0 then
		premium = { Gems = 100 }
	end
	if tier % 10 == 0 then
		free = { Gems = 10 }
	end
	tiers[tier] = { Free = free, Premium = premium }
end
-- Hitos con skins exclusivas
tiers[12].Premium = { Skin = "Sorcerer_Hollow" }
tiers[20].Free = { Skin = "ShadowSummoner_Ash" }
tiers[30].Premium = { Skin = "CursedKing_Heian" }
BattlePassConfig.Tiers = tiers

function BattlePassConfig.IsActive(now: number): boolean
	local s = BattlePassConfig.Season
	return now >= s.Start and now < s.End
end

function BattlePassConfig.TierFromXP(xp: number): number
	return math.min(BattlePassConfig.MaxTier, math.floor(xp / BattlePassConfig.XPPerTier))
end

return BattlePassConfig
