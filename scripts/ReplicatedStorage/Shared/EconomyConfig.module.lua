-- EconomyConfig: valores de la economía dual (compartido: el cliente lo usa para mostrar la UI).
--   Monedas Malditas (Coins) -> F2P, se ganan jugando.
--   Gemas (Gems)              -> premium, se compran con Robux (y un goteo pequeño F2P por subir de nivel).
local EconomyConfig = {}

EconomyConfig.Currencies = {
	Coins = { DisplayName = "Cursed Coins", Icon = "呪", Color = Color3.fromRGB(190, 120, 255) },
	Gems = { DisplayName = "Gems", Icon = "晶", Color = Color3.fromRGB(90, 220, 255) },
}

-- Recompensas de combate (solo contra jugadores reales; los muñecos no dan nada en servidores públicos)
EconomyConfig.Rewards = {
	KO = { Coins = 20, XP = 40 },
	CoinsPer10Damage = 1, -- 1 moneda por cada 10% de daño infligido
	XPPerDamage = 1, -- 1 XP por cada 1% de daño
	Playtime = { Interval = 300, Coins = 15, XP = 25 }, -- cada 5 min si has peleado
	Win = { Coins = 60, XP = 120 }, -- ganar una partida (no cuenta para el tope diario)
	Participation = { Coins = 25, XP = 50 }, -- terminar una partida
	DailyCombatCoinCap = 3000, -- tope diario de monedas de combate (anti-farmeo)
	LevelUpCoins = 50,
	GemsEveryNLevels = { Every = 10, Gems = 5 }, -- goteo F2P de gemas
}

-- Estimación para mostrar "~X h de juego" en los objetivos (ajústala con datos reales de analítica)
EconomyConfig.EstimatedCoinsPerHour = 900

-- En Studio los muñecos sí dan recompensas para poder probar la economía tú solo.
EconomyConfig.RewardDummiesInStudio = true

function EconomyConfig.XPForLevel(level: number): number
	return 100 + (level - 1) * 50
end

-- Developer Products de gemas. Crea cada producto en el Creator Hub
-- (Monetization > Developer Products) y pega aquí su ID. Con Id = 0 el botón avisa de que falta.
EconomyConfig.GemPacks = {
	{ Id = 3717315328, Gems = 100, Name = "Handful of Gems", RobuxHint = 80 },
	{ Id = 3717315416, Gems = 550, Name = "Bag of Gems", RobuxHint = 400, Tag = "+10%" },
	{ Id = 3717315495, Gems = 1200, Name = "Chest of Gems", RobuxHint = 800, Tag = "+20%" },
	{ Id = 3717315580, Gems = 2700, Name = "Ark of Gems", RobuxHint = 1700, Tag = "+35%" },
	{ Id = 3717315845, Gems = 7500, Name = "Cursed Treasure", RobuxHint = 4500, Tag = "BEST VALUE" },
}

return EconomyConfig
