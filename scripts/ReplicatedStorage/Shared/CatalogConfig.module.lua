-- CatalogConfig: personajes, rarezas, precios, Acceso Anticipado, skins, tienda y gamepasses.
-- Compartido: el servidor valida con estas reglas y el cliente las usa para mostrar la tienda.
--
-- PROGRESIÓN (diseñada para ser lenta y que el atajo de pago resulte tentador):
--   Común      -> gratis
--   Raro       ->  9.000 呪  ó  450 晶
--   Épico      -> 18.000 呪  ó  800 晶   (requiere Nivel 10 si pagas con 呪)
--   Legendario -> 35.000 呪  ó 1.400 晶  (requiere Nivel 20 si pagas con 呪)
--   Mítico     -> 60.000 呪  ó 2.400 晶  (requiere Nivel 35 si pagas con 呪)
--   Exclusivo  -> SOLO 晶 (no se puede conseguir con Monedas)
-- Con ~900 呪/h de juego: un Épico son ~20 h, un Mítico ~65 h.
local CatalogConfig = {}

local function utc(year, month, day, hour)
	return DateTime.fromUniversalTime(year, month, day, hour or 0).UnixTimestamp
end
CatalogConfig.utc = utc

-- Un personaje nuevo sale en Acceso Anticipado (solo Gemas) durante este tiempo;
-- después se puede comprar con Monedas Malditas.
CatalogConfig.EarlyAccessDuration = 14 * 86400

local C = Color3.fromRGB
CatalogConfig.Rarities = {
	Common = { Name = "Común", Color = C(180, 180, 190), Order = 1 },
	Rare = { Name = "Raro", Color = C(80, 160, 255), Order = 2, PriceCoins = 9000, PriceGems = 450 },
	Epic = { Name = "Épico", Color = C(190, 90, 255), Order = 3, PriceCoins = 18000, PriceGems = 800, Level = 10 },
	Legendary = { Name = "Legendario", Color = C(255, 190, 40), Order = 4, PriceCoins = 35000, PriceGems = 1400, Level = 20 },
	Mythic = { Name = "Mítico", Color = C(255, 60, 120), Order = 5, PriceCoins = 60000, PriceGems = 2400, Level = 35 },
	Exclusive = { Name = "Exclusivo", Color = C(0, 220, 255), Order = 6 },
}

-- Order = posición en la tienda. Los precios salen de la rareza salvo que se indiquen aquí.
CatalogConfig.Characters = {
	-- Jujutsu
	Brawler = { Order = 1, Rarity = "Common", Starter = true },
	ShadowSummoner = { Order = 2, Rarity = "Rare" },
	WeaponMaster = { Order = 3, Rarity = "Rare" },
	BloodBrother = { Order = 4, Rarity = "Rare" },
	BoogieBrawler = { Order = 5, Rarity = "Rare" },
	NailWitch = { Order = 6, Rarity = "Rare" },
	Sorcerer = { Order = 7, Rarity = "Epic" },
	Swordsman = { Order = 8, Rarity = "Epic" },
	Executor = { Order = 9, Rarity = "Epic" },
	Stitched = { Order = 10, Rarity = "Epic" },
	VolcanoCurse = { Order = 11, Rarity = "Epic" },
	Hunter = { Order = 12, Rarity = "Legendary" },
	CurseMaster = { Order = 13, Rarity = "Legendary" },
	CursedKing = { Order = 14, Rarity = "Legendary", Release = utc(2026, 10, 7, 12) },
	Gambler = { Order = 15, Rarity = "Mythic" },
	YoungSorcerer = { Order = 16, Rarity = "Exclusive", PriceGems = 2000 },
	-- Grieta Dimensional (otros animes)
	Viking = { Order = 17, Rarity = "Rare" },
	WaterSlayer = { Order = 18, Rarity = "Epic" },
	RubberPirate = { Order = 19, Rarity = "Legendary" },
	ThreeBlades = { Order = 20, Rarity = "Legendary" },
	GoldenWarrior = { Order = 21, Rarity = "Mythic", Release = utc(2026, 10, 21, 12) },
	FoxNinja = { Order = 22, Rarity = "Exclusive", PriceGems = 1800 },
}

-- Precio final de un personaje (rellena con los de su rareza)
function CatalogConfig.GetPrices(id: string): (number?, number?, number?)
	local entry = CatalogConfig.Characters[id]
	if not entry then
		return nil, nil, nil
	end
	local rarity = CatalogConfig.Rarities[entry.Rarity]
	local coins = entry.PriceCoins or rarity.PriceCoins
	local gems = entry.PriceGems or rarity.PriceGems
	local level = entry.Level or rarity.Level
	return coins, gems, level
end

-- Estado de compra de un personaje en un instante dado:
--   "Starter" | "Upcoming" (aún no ha salido) | "EarlyAccess" (solo 晶 hasta endsAt) | "Available"
function CatalogConfig.GetCharacterStatus(id: string, now: number): (string, number?)
	local entry = CatalogConfig.Characters[id]
	if not entry then
		return "Unknown", nil
	end
	if entry.Starter then
		return "Starter", nil
	end
	if entry.Release then
		if now < entry.Release then
			return "Upcoming", entry.Release
		end
		local endsAt = entry.Release + CatalogConfig.EarlyAccessDuration
		if now < endsAt then
			return "EarlyAccess", endsAt
		end
	end
	return "Available", nil
end

-- Skins: SOLO cosméticas. Premium = de pago -> booster +5% Monedas/XP.
-- Origen especial: BattlePassOnly / StoryOnly (no se venden).
CatalogConfig.Skins = {
	Brawler_Crimson = {
		Character = "Brawler", Name = "Puños Carmesí", PriceCoins = 4000,
		Colors = { Head = C(234, 184, 146), Torso = C(140, 20, 30), Arms = C(140, 20, 30), Legs = C(40, 15, 20) },
	},
	Brawler_Vessel = {
		Character = "Brawler", Name = "Recipiente Despertado", Premium = true, PriceGems = 400,
		Colors = { Head = C(234, 184, 146), Torso = C(15, 15, 15), Arms = C(234, 184, 146), Legs = C(15, 15, 15) },
		Aura = C(255, 40, 60),
	},
	Brawler_Awakened = {
		Character = "Brawler", Name = "Kaito Despertado", StoryOnly = true,
		Colors = { Head = C(234, 184, 146), Torso = C(60, 10, 20), Arms = C(234, 184, 146), Legs = C(20, 10, 15) },
		Aura = C(255, 20, 40),
	},
	Brawler_Climber = {
		Character = "Brawler", Name = "Estudiante de Grado 1", PriceCoins = 2500,
		Colors = { Head = C(234, 184, 146), Torso = C(30, 30, 80), Arms = C(30, 30, 80), Legs = C(200, 200, 210) },
	},
	Sorcerer_Blindfold = {
		Character = "Sorcerer", Name = "Venda Celestial", Premium = true, PriceGems = 450,
		Colors = { Head = C(245, 225, 205), Torso = C(235, 235, 245), Arms = C(235, 235, 245), Legs = C(30, 30, 45) },
		Aura = C(120, 200, 255),
	},
	Sorcerer_Hollow = {
		Character = "Sorcerer", Name = "Vacío Púrpura", Premium = true, BattlePassOnly = true,
		Colors = { Head = C(245, 225, 205), Torso = C(70, 20, 110), Arms = C(70, 20, 110), Legs = C(25, 10, 40) },
		Aura = C(170, 60, 255),
	},
	ShadowSummoner_Ash = {
		Character = "ShadowSummoner", Name = "Ceniza", BattlePassOnly = true,
		Colors = { Head = C(230, 190, 160), Torso = C(110, 110, 115), Arms = C(110, 110, 115), Legs = C(60, 60, 65) },
	},
	ShadowSummoner_Night = {
		Character = "ShadowSummoner", Name = "Noche Eterna", Premium = true, PriceGems = 350,
		Colors = { Head = C(230, 190, 160), Torso = C(10, 10, 25), Arms = C(10, 10, 25), Legs = C(10, 10, 25) },
		Aura = C(60, 60, 140),
	},
	CursedKing_Heian = {
		Character = "CursedKing", Name = "Era Heian", Premium = true, BattlePassOnly = true,
		Colors = { Head = C(225, 175, 145), Torso = C(240, 235, 225), Arms = C(225, 175, 145), Legs = C(120, 20, 20) },
		Aura = C(255, 80, 30),
	},
	Hunter_Shadow = {
		Character = "Hunter", Name = "Asesino a Sueldo", Premium = true, PriceGems = 500,
		Colors = { Head = C(225, 185, 150), Torso = C(10, 10, 12), Arms = C(10, 10, 12), Legs = C(10, 10, 12) },
		Aura = C(80, 80, 90),
	},
	Swordsman_Queen = {
		Character = "Swordsman", Name = "Pacto con la Reina", Premium = true, PriceGems = 550,
		Colors = { Head = C(240, 210, 185), Torso = C(25, 20, 35), Arms = C(25, 20, 35), Legs = C(25, 20, 35) },
		Aura = C(160, 60, 220),
	},
	GoldenWarrior_Blue = {
		Character = "GoldenWarrior", Name = "Poder Divino Azul", Premium = true, PriceGems = 650,
		Colors = { Head = C(240, 200, 165), Torso = C(40, 80, 200), Arms = C(240, 200, 165), Legs = C(40, 80, 200) },
		Aura = C(80, 200, 255),
	},
	-- Exclusivas de la RULETA MALDITA (solo salen ahí, muy raras)
	CursedKing_TrueForm = {
		Character = "CursedKing", Name = "Forma Verdadera del Rey", Premium = true, RouletteOnly = true,
		Colors = { Head = C(200, 150, 125), Torso = C(25, 5, 8), Arms = C(200, 150, 125), Legs = C(90, 10, 15) },
		Aura = C(255, 20, 40),
	},
	Sorcerer_Honored = {
		Character = "Sorcerer", Name = "El Honrado", Premium = true, RouletteOnly = true,
		Colors = { Head = C(245, 225, 205), Torso = C(250, 250, 255), Arms = C(250, 250, 255), Legs = C(220, 225, 240) },
		Aura = C(140, 220, 255),
	},
	RubberPirate_Gear = {
		Character = "RubberPirate", Name = "Quinta Marcha", Premium = true, PriceGems = 650,
		Colors = { Head = C(245, 235, 230), Torso = C(240, 240, 240), Arms = C(245, 235, 230), Legs = C(220, 220, 230) },
		Aura = C(255, 255, 255),
	},
}

-- Boosters (solo velocidad de progreso, nunca daño)
CatalogConfig.PremiumSkinBoost = 0.05 -- +5% Monedas y XP con una skin premium equipada

-- Gamepasses: crea el pase en Creator Hub (Monetization > Passes) y pega aquí su ID.
CatalogConfig.GamePasses = {
	VIP = { Id = 0, Name = "Pase VIP", Boost = 0.05, RobuxHint = 199, Description = "+5% 呪 y XP para siempre + título VIP" },
	CoinsX2 = { Id = 0, Name = "Monedas x2", CoinsBoost = 1.0, RobuxHint = 399, Description = "¡El doble de Monedas Malditas para siempre!" },
}

-- Tienda de Gemas: boosters temporales, efectos de KO y títulos
CatalogConfig.StoreItems = {
	Boost_Coins30 = { Kind = "Boost", Name = "x2 Monedas · 30 min", Gems = 60, Boost = "Coins", Duration = 1800, Order = 1 },
	Boost_XP30 = { Kind = "Boost", Name = "x2 XP · 30 min", Gems = 50, Boost = "XP", Duration = 1800, Order = 2 },
	Boost_Coins120 = { Kind = "Boost", Name = "x2 Monedas · 2 horas", Gems = 180, Boost = "Coins", Duration = 7200, Order = 3, Tag = "AHORRA 25%" },
	Effect_Sakura = { Kind = "Effect", Name = "KO: Lluvia de Sakura", Gems = 200, Color = C(255, 170, 210), Order = 10 },
	Effect_Gold = { Kind = "Effect", Name = "KO: Explosión Dorada", Gems = 300, Color = C(255, 210, 60), Order = 11 },
	Effect_Domain = { Kind = "Effect", Name = "KO: Expansión de Dominio", Gems = 350, Color = C(150, 60, 255), Order = 12 },
	Effect_BlackFlash = { Kind = "Effect", Name = "KO: Destello Negro", Gems = 450, Color = C(20, 0, 0), Accent = C(255, 30, 30), Order = 13 },
	Title_Grade1 = { Kind = "Title", Name = "Hechicero de Grado 1", Gems = 120, Color = C(120, 200, 255), Order = 20 },
	Title_Gambler = { Kind = "Title", Name = "Ludópata Afortunado", Gems = 150, Color = C(120, 255, 140), Order = 21 },
	Title_Special = { Kind = "Title", Name = "Grado Especial", Gems = 500, Color = C(255, 80, 120), Order = 22 },
	Title_Strongest = { Kind = "Title", Name = "El Más Fuerte", Gems = 900, Color = C(255, 220, 60), Order = 23 },
	Title_Vessel = { Kind = "Title", Name = "Recipiente del Rey", StoryOnly = true, Color = C(255, 40, 60), Order = 24 },
}

-- Pase de Batalla: saltar niveles
CatalogConfig.TierSkipGems = 100

return CatalogConfig
