-- DataTemplate: estructura por defecto del perfil de cada jugador.
-- Añadir campos nuevos aquí es seguro: los perfiles antiguos se "reconcilian" al cargar.
return {
	Version = 2,

	Coins = 0, -- Monedas Malditas (F2P)
	Gems = 0, -- Gemas (premium)
	XP = 0,
	Level = 1,

	SelectedCharacter = "Brawler",
	OwnedCharacters = { Brawler = true }, -- el resto se desbloquea
	OwnedSkins = {}, -- [skinId] = true
	EquippedSkins = {}, -- [characterId] = skinId

	OwnedEffects = {}, -- [itemId] = true (efectos de KO)
	OwnedTitles = {}, -- [itemId] = true
	EquippedEffect = "",
	EquippedTitle = "",
	Boosts = { CoinsUntil = 0, XPUntil = 0 }, -- boosters temporales (timestamp unix)

	BattlePass = {
		Season = "",
		XP = 0,
		Premium = false,
		ClaimedFree = {}, -- ["nivel"] = true (claves string: DataStore no admite arrays con huecos)
		ClaimedPremium = {},
	},

	Story = {
		Unlocked = 1, -- último capítulo disponible
		Completed = {}, -- ["capítulo"] = true
	},

	Stats = {
		KOs = 0,
		DamageDealt = 0,
		PlaytimeSeconds = 0,
		Wins = 0,
		Matches = 0,
		BestStreak = 0,
		StoryClears = 0,
	},

	Daily = {
		Day = 0,
		CombatCoins = 0,
	},

	Login = { LastDay = 0, Streak = 0 }, -- recompensa diaria con racha
	RedeemedCodes = {}, -- [CÓDIGO] = true
	Tutorial = { Done = false },

	PurchaseHistory = {}, -- PurchaseIds de Developer Products ya entregados (evita duplicados)
	GemLedger = {}, -- últimas transacciones de gemas (auditoría / soporte)

	FirstJoin = 0,
	LastJoin = 0,
}
