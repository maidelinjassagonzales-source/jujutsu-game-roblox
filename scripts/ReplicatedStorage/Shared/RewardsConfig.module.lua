-- RewardsConfig: recompensa diaria con racha y códigos canjeables.
--   * Calendario de 7 días: si faltas un día la racha vuelve al día 1 (motiva entrar cada día)
--   * VIP cobra +50% de Monedas en la diaria (otro motivo para comprarlo)
--   * Códigos: publícalos en Discord/YouTube/TikTok para atraer jugadores. Para retirar uno, bórralo.
local RewardsConfig = {}

RewardsConfig.Daily = {
	{ Coins = 150 },
	{ Coins = 250 },
	{ Coins = 350, XP = 150 },
	{ Coins = 450 },
	{ Coins = 600, Gems = 5 },
	{ Coins = 800, XP = 300 },
	{ Coins = 1200, Gems = 25 }, -- día 7: gran premio
}
RewardsConfig.VIPDailyBonus = 0.5

-- Códigos (en MAYÚSCULAS). Expires = fecha UTC opcional (os.time) a partir de la cual deja de valer.
RewardsConfig.Codes = {
	LANZAMIENTO = { Coins = 1500, Gems = 20 },
	CURSEDCLASH = { Coins = 1000 },
	DOMINIO = { Gems = 10 },
	ESCUELA = { Coins = 500, XP = 500 },
}

function RewardsConfig.Today(now: number): number
	return math.floor(now / 86400)
end

return RewardsConfig
