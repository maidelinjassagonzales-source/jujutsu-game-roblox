-- UltimateConfig: la ULTI de cada luchador y sus habilidades pasivas de firma.
-- La barra de ulti (0-100) se carga pegando (x1.6 del % que haces) y recibiendo (x0.8 del % que recibes).
-- Tipos:
--   Domain    = Expansión de Dominio: ataques que SIEMPRE aciertan a todos los rivales de la arena
--               Ticks golpes de TickDamage% cada TickEvery s; Final = golpe final; Freeze = paraliza (Gojo)
--   Transform = transformación temporal: Damage (multiplicador), Speed, KBResist (<1 = vuela menos), Aura
--   Burst     = técnica definitiva: un proyectil gigante que atraviesa el escenario
--   Gamble    = (Hakari) tirada: Jackpot = transformación; si no, Burst pequeño
local C = Color3.fromRGB

local UltimateConfig = {}

UltimateConfig.ChargeDealt = 1.6
UltimateConfig.ChargeTaken = 0.8
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
	}
end
local function transform(name, jp, color, o)
	return {
		Kind = "Transform", Name = name, Japanese = jp, Color = color, Duration = o.Duration or 12,
		Damage = o.Damage or 1.3, Speed = o.Speed or 1.15, KBResist = o.KBResist or 0.8, Jump = o.Jump or 1,
		HairSwap = o.HairSwap, BlackFlash = o.BlackFlash,
	}
end
local function burst(name, jp, color, o)
	o = o or {}
	return {
		Kind = "Burst", Name = name, Japanese = jp, Color = color,
		Damage = o.Damage or 24, KB = o.KB or 55, Size = o.Size or 14, Speed = o.Speed or 130, SureHit = o.SureHit,
	}
end

UltimateConfig.Characters = {
	-- Jujutsu Kaisen
	Brawler = transform("Destello Negro Divergente", "黒閃", C(200, 20, 40), { Duration = 10, Damage = 1.25, Speed = 1.15, BlackFlash = true }),
	Sorcerer = domain("Vacío Infinito", "無量空処", C(120, 190, 255), { Duration = 4.5, Ticks = 4, TickDamage = 3, Freeze = true, Final = { Damage = 10, KB = 55 } }),
	CursedKing = domain("Santuario Malévolo", "伏魔御厨子", C(220, 30, 30), { Duration = 5, Ticks = 10, TickDamage = 3, Final = { Damage = 9, KB = 65 } }),
	Swordsman = transform("Rika: Manifestación Completa", "完全顕現", C(170, 110, 255), { Duration = 10, Damage = 1.4, KBResist = 0.7 }),
	ShadowSummoner = domain("Jardín de Sombras Quimera", "嵌合暗翳庭", C(40, 30, 70), { Duration = 5, Ticks = 8, TickDamage = 3, Final = { Damage = 8, KB = 50 } }),
	WeaponMaster = transform("Restricción Celestial", "天与呪縛", C(90, 200, 120), { Duration = 10, Damage = 1.3, Speed = 1.35 }),
	YoungSorcerer = burst("Técnica Inversa: Púrpura Hueco", "虚式「茈」", C(170, 60, 255), { Damage = 26, KB = 62, Size = 18, Speed = 100 }),
	Hunter = transform("Asesino de Hechiceros", "術師殺し", C(80, 80, 90), { Duration = 10, Damage = 1.25, Speed = 1.4, KBResist = 0.85 }),
	Executor = transform("Horas Extra", "時間外労働", C(230, 200, 120), { Duration = 8, Damage = 1.55, Speed = 1.05 }),
	Stitched = domain("Autoencarnación de la Perfección", "自閉円頓裹", C(120, 160, 200), { Duration = 3, Ticks = 1, TickDamage = 4, Final = { Damage = 18, KB = 70 } }),
	BloodBrother = burst("Sangre Perforante", "穿血", C(200, 20, 50), { Damage = 22, KB = 58, Size = 8, Speed = 220 }),
	BoogieBrawler = transform("Boogie Woogie Supremo", "不義遊戯", C(200, 150, 90), { Duration = 10, Damage = 1.3, KBResist = 0.6 }),
	NailWitch = burst("Resonancia", "共鳴り", C(255, 140, 60), { Damage = 16, KB = 45, SureHit = true }),
	CurseMaster = burst("Uzumaki Máximo", "極ノ番「うずまき」", C(90, 70, 120), { Damage = 25, KB = 60, Size = 20, Speed = 90 }),
	VolcanoCurse = domain("Ataúd de la Montaña de Hierro", "蓋棺鉄囲山", C(255, 110, 20), { Duration = 5, Ticks = 8, TickDamage = 3.5, Burn = true, Final = { Damage = 8, KB = 55 } }),
	Gambler = { Kind = "Gamble", Name = "Juego de Muerte Ociosa", Japanese = "坐殺博徒", Color = C(80, 220, 140),
		Jackpot = transform("¡JACKPOT!", "大当たり", C(255, 220, 60), { Duration = 14, Damage = 1.35, Speed = 1.2, KBResist = 0.5 }),
		Miss = burst("Fallo...", "外れ", C(80, 220, 140), { Damage = 12, KB = 35, Size = 10 }) },
	-- Otros animes
	GoldenWarrior = transform("Super Saiyan", "超サイヤ人", C(255, 215, 60), { Duration = 15, Damage = 1.35, Speed = 1.2, KBResist = 0.75, HairSwap = true }),
	RubberPirate = transform("Gear Fifth", "ギア5", C(245, 245, 255), { Duration = 12, Damage = 1.3, Jump = 1.35, KBResist = 0.75 }),
	Viking = transform("Furia del Guerrero", "戦士の怒り", C(220, 180, 90), { Duration = 10, Damage = 1.3, Speed = 1.3 }),
	FoxNinja = transform("Modo Kurama", "九喇嘛モード", C(255, 150, 40), { Duration = 12, Damage = 1.3, Speed = 1.25 }),
	WaterSlayer = transform("Respiración del Sol", "ヒノカミ神楽", C(255, 90, 30), { Duration = 10, Damage = 1.4, Speed = 1.1 }),
	ThreeBlades = burst("Asura: Ichibugin", "阿修羅 一霧銀", C(80, 200, 110), { Damage = 25, KB = 60, Size = 16, Speed = 150 }),
	-- Enemigos (no usan ulti por defecto)
}

-- Pasivas de firma
UltimateConfig.Passives = {
	Brawler = { BlackFlashChance = 0.15 },       -- Destello Negro: x2.5 daño en golpes fuertes
	Sorcerer = { InfinityChance = 0.18 },        -- Infinito (Seis Ojos): anula golpes recibidos
	YoungSorcerer = { InfinityChance = 0.12 },
}

return UltimateConfig
