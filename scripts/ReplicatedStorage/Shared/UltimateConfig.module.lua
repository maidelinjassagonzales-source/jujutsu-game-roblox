-- UltimateConfig: la ULTI de cada luchador y sus habilidades pasivas de firma.
-- La barra de ulti (0-100) se carga pegando (x0.7 del % que haces) y recibiendo (x0.35 del % que recibes).
-- Tipos:
--   Domain    = Expansión de Dominio: ataques que SIEMPRE aciertan a todos los rivales de la arena
--               Ticks golpes de TickDamage% cada TickEvery s; Final = golpe final; Freeze = paraliza (Gojo)
--   Transform = transformación temporal: Damage (multiplicador), Speed, KBResist (<1 = vuela menos), Aura
--   Burst     = técnica definitiva: un proyectil gigante que atraviesa el escenario
--   Domain con Jackpot (Hakari): al terminar el dominio, tirada -> JACKPOT = transformación
local C = Color3.fromRGB

local UltimateConfig = {}

-- Más difícil de cargar (antes 1.6 / 0.8): hace falta ~140% de daño hecho (o mucho recibido) para llenarla
UltimateConfig.ChargeDealt = 0.7
UltimateConfig.ChargeTaken = 0.35
UltimateConfig.Windup = 1.3 -- cinemática (el lanzador es invulnerable mientras)
-- Las Expansiones de Dominio tienen cinemática larga: el tiempo se para para TODOS los de la arena
UltimateConfig.DomainWindup = 3.2
UltimateConfig.TransformWindup = 1.8

function UltimateConfig.WindupFor(kind: string): number
	if kind == "Domain" then
		return UltimateConfig.DomainWindup
	elseif kind == "Transform" then
		return UltimateConfig.TransformWindup
	end
	return UltimateConfig.Windup
end

local function domain(name, jp, color, o)
	o = o or {}
	return {
		Kind = "Domain", Name = name, Japanese = jp, Color = color, Duration = o.Duration or 5,
		Ticks = o.Ticks or 8, TickDamage = o.TickDamage or 3, Final = o.Final, Freeze = o.Freeze, Burn = o.Burn,
		Theme = o.Theme, Canon = o.Canon ~= false, Jackpot = o.Jackpot, JackpotChance = o.JackpotChance,
	}
end
local function transform(name, jp, color, o)
	return {
		Kind = "Transform", Name = name, Japanese = jp, Color = color, Duration = o.Duration or 12,
		Damage = o.Damage or 1.3, Speed = o.Speed or 1.15, KBResist = o.KBResist or 0.8, Jump = o.Jump or 1,
		HairSwap = o.HairSwap, BlackFlash = o.BlackFlash, Theme = o.Theme,
	}
end
local function burst(name, jp, color, o)
	o = o or {}
	return {
		Kind = "Burst", Name = name, Japanese = jp, Color = color,
		Damage = o.Damage or 24, KB = o.KB or 55, Size = o.Size or 14, Speed = o.Speed or 130, SureHit = o.SureHit,
		Theme = o.Theme,
	}
end

-- Theme = estilo visual propio de cada dominio / transformación (UltimateController lo dibuja)
-- Canon = false -> dominio inventado para personajes que no tienen uno en la serie
UltimateConfig.Characters = {
	-- ===== Jujutsu Kaisen: Expansiones de Dominio
	Sorcerer = domain("Vacío Infinito", "無量空処", C(120, 190, 255), { Duration = 4.5, Ticks = 4, TickDamage = 3, Freeze = true, Final = { Damage = 10, KB = 55 }, Theme = "Void" }),
	CursedKing = domain("Santuario Malévolo", "伏魔御厨子", C(220, 30, 30), { Duration = 5, Ticks = 10, TickDamage = 3, Final = { Damage = 9, KB = 65 }, Theme = "Shrine" }),
	ShadowSummoner = domain("Jardín de Sombras Quimera", "嵌合暗翳庭", C(70, 50, 120), { Duration = 5, Ticks = 8, TickDamage = 3, Final = { Damage = 8, KB = 50 }, Theme = "Shadow" }),
	Stitched = domain("Autoencarnación de la Perfección", "自閉円頓裹", C(120, 160, 200), { Duration = 3, Ticks = 1, TickDamage = 4, Final = { Damage = 18, KB = 70 }, Theme = "Hands" }),
	VolcanoCurse = domain("Ataúd de la Montaña de Hierro", "蓋棺鉄囲山", C(255, 110, 20), { Duration = 5, Ticks = 8, TickDamage = 3.5, Burn = true, Final = { Damage = 8, KB = 55 }, Theme = "Volcano" }),
	Swordsman = domain("Amor Mutuo Auténtico", "真贋相愛", C(170, 110, 255), { Duration = 4.5, Ticks = 6, TickDamage = 3.5, Final = { Damage = 10, KB = 60 }, Theme = "Swords" }),
	CurseMaster = domain("Útero Profuso", "胎蔵遍野", C(150, 90, 70), { Duration = 5, Ticks = 7, TickDamage = 3.5, Final = { Damage = 9, KB = 58 }, Theme = "Womb" }),
	-- Hakari: su dominio es una máquina de pachinko; si sale JACKPOT, transformación inmortal
	Gambler = domain("Juego de Muerte Ociosa", "坐殺博徒", C(80, 220, 140), { Duration = 4, Ticks = 4, TickDamage = 2, Final = { Damage = 6, KB = 40 }, Theme = "Pachinko",
		JackpotChance = 1 / 3, Jackpot = transform("¡JACKPOT!", "大当たり", C(255, 220, 60), { Duration = 14, Damage = 1.35, Speed = 1.2, KBResist = 0.5, Theme = "Jackpot" }) }),
	-- Dominios inventados (en la serie no tienen) con el estilo de cada uno
	Brawler = domain("Dominio del Destello Negro", "黒閃領域", C(200, 20, 40), { Duration = 4, Ticks = 5, TickDamage = 3.5, Final = { Damage = 10, KB = 62 }, Theme = "BlackFlash", Canon = false }),
	Executor = domain("Horas Extra: Proporción 7:3", "十劃呪法", C(230, 200, 120), { Duration = 4, Ticks = 5, TickDamage = 3.5, Final = { Damage = 11, KB = 60 }, Theme = "Ratio", Canon = false }),
	BloodBrother = domain("Río Carmesí", "血河", C(200, 20, 50), { Duration = 4.5, Ticks = 7, TickDamage = 3, Final = { Damage = 9, KB = 58 }, Theme = "Blood", Canon = false }),
	BoogieBrawler = domain("Escenario del Mejor Amigo", "不義遊戯", C(200, 150, 90), { Duration = 4, Ticks = 6, TickDamage = 3, Final = { Damage = 10, KB = 60 }, Theme = "Clap", Canon = false }),
	NailWitch = domain("Bosque de Clavos", "共鳴り", C(255, 140, 60), { Duration = 4, Ticks = 6, TickDamage = 3, Final = { Damage = 10, KB = 55 }, Theme = "Nails", Canon = false }),
	-- Sin energía maldita (Restricción Celestial): en la serie no pueden expandir dominio
	WeaponMaster = transform("Restricción Celestial", "天与呪縛", C(90, 200, 120), { Duration = 10, Damage = 1.3, Speed = 1.35, Theme = "Celestial" }),
	Hunter = transform("Asesino de Hechiceros", "術師殺し", C(80, 80, 90), { Duration = 10, Damage = 1.25, Speed = 1.4, KBResist = 0.85, Theme = "Celestial" }),
	YoungSorcerer = burst("Técnica Inversa: Púrpura Hueco", "虚式「茈」", C(170, 60, 255), { Damage = 26, KB = 62, Size = 18, Speed = 100, Theme = "Purple" }),
	-- ===== Otros animes: su ulti icónica
	GoldenWarrior = transform("Super Saiyan", "超サイヤ人", C(255, 215, 60), { Duration = 15, Damage = 1.35, Speed = 1.2, KBResist = 0.75, HairSwap = true, Theme = "Saiyan" }),
	RubberPirate = transform("Gear Fifth", "ギア5", C(245, 245, 255), { Duration = 12, Damage = 1.3, Jump = 1.35, KBResist = 0.75, Theme = "Gear5" }),
	Viking = transform("Furia del Guerrero", "戦士の怒り", C(220, 60, 40), { Duration = 10, Damage = 1.3, Speed = 1.3, Theme = "Berserk" }),
	FoxNinja = transform("Modo Kurama", "九喇嘛モード", C(255, 150, 40), { Duration = 12, Damage = 1.3, Speed = 1.25, Theme = "Kurama" }),
	WaterSlayer = transform("Respiración del Sol", "ヒノカミ神楽", C(255, 90, 30), { Duration = 10, Damage = 1.4, Speed = 1.1, Theme = "SunBreath" }),
	ThreeBlades = burst("Asura: Ichibugin", "阿修羅 一霧銀", C(80, 200, 110), { Damage = 25, KB = 60, Size = 16, Speed = 150, Theme = "Asura" }),
	-- Enemigos (no usan ulti por defecto)
}

-- Pasivas de firma
UltimateConfig.Passives = {
	Brawler = { BlackFlashChance = 0.15 },       -- Destello Negro: x2.5 daño en golpes fuertes
	Sorcerer = { InfinityChance = 0.18 },        -- Infinito (Seis Ojos): anula golpes recibidos
	YoungSorcerer = { InfinityChance = 0.12 },
}

return UltimateConfig
