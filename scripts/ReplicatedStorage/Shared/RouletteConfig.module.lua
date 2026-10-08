-- RouletteConfig: la RULETA MALDITA.
--   * 1 tirada GRATIS al día + tiradas extra con Monedas Malditas (no se usan Robux).
--   * Las probabilidades se muestran siempre en la ventana (obligatorio en Roblox para premios aleatorios).
--   * Premio gordo: una skin exclusiva que solo sale aquí. Si ya las tienes todas -> gemas de compensación.
local RouletteConfig = {}

RouletteConfig.SpinCostCoins = 1500
RouletteConfig.MaxPaidPerDay = 10
RouletteConfig.RareSkins = { "CursedKing_TrueForm", "Sorcerer_Honored" }
RouletteConfig.DuplicateSkinGems = 300 -- si ya tienes todas las skins de la ruleta

RouletteConfig.Rarities = {
	Common = { Name = "Common", Color = Color3.fromRGB(170, 170, 185) },
	Rare = { Name = "Rare", Color = Color3.fromRGB(80, 160, 255) },
	Epic = { Name = "Epic", Color = Color3.fromRGB(190, 90, 255) },
	Legendary = { Name = "Legendary", Color = Color3.fromRGB(255, 190, 40) },
	Mythic = { Name = "Mythic", Color = Color3.fromRGB(255, 50, 90) },
}

-- Weight = peso relativo (la probabilidad se calcula sola y se enseña en la ventana)
RouletteConfig.Prizes = {
	{ Id = "Coins150", Kind = "Coins", Amount = 150, Weight = 300, Rarity = "Common" },
	{ Id = "XP300", Kind = "XP", Amount = 300, Weight = 200, Rarity = "Common" },
	{ Id = "Coins400", Kind = "Coins", Amount = 400, Weight = 180, Rarity = "Common" },
	{ Id = "Gems10", Kind = "Gems", Amount = 10, Weight = 110, Rarity = "Rare" },
	{ Id = "Coins1000", Kind = "Coins", Amount = 1000, Weight = 90, Rarity = "Rare" },
	{ Id = "BoostCoins", Kind = "Boost", Amount = 1800, Weight = 60, Rarity = "Rare" }, -- x2 monedas 30 min
	{ Id = "Gems40", Kind = "Gems", Amount = 40, Weight = 35, Rarity = "Epic" },
	{ Id = "Coins3000", Kind = "Coins", Amount = 3000, Weight = 12, Rarity = "Epic" },
	{ Id = "Gems150", Kind = "Gems", Amount = 150, Weight = 7, Rarity = "Legendary" },
	{ Id = "RareSkin", Kind = "Skin", Amount = 1, Weight = 6, Rarity = "Mythic" },
}

function RouletteConfig.TotalWeight(): number
	local total = 0
	for _, p in RouletteConfig.Prizes do
		total += p.Weight
	end
	return total
end

function RouletteConfig.Chance(prize): number
	return prize.Weight / RouletteConfig.TotalWeight()
end

function RouletteConfig.Describe(prize): string
	if prize.Kind == "Coins" then
		return `{prize.Amount} Coins`
	elseif prize.Kind == "Gems" then
		return `{prize.Amount} Gems`
	elseif prize.Kind == "XP" then
		return `{prize.Amount} XP`
	elseif prize.Kind == "Boost" then
		return "x2 Coins 30 min"
	end
	return "EXCLUSIVE SKIN"
end

return RouletteConfig
