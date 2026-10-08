-- StageConfig: datos de cada escenario (los modelos los construye Server/Builders/StageBuilder).
-- Todas las posiciones son RELATIVAS al centro de la arena (cada arena vive en su propio X).
local StageConfig = {}

local C = Color3.fromRGB

local function spawns(y)
	return { Vector3.new(-30, y, 0), Vector3.new(30, y, 0), Vector3.new(-10, y, 0), Vector3.new(10, y, 0) }
end

StageConfig.Stages = {
	Academy = {
		Name = "Escuela de Hechicería",
		HalfWidth = 55, -- mitad del suelo principal (la IA lo usa para no caerse)
		Bounds = { Left = -140, Right = 140, Top = 95, Bottom = -50 },
		Spawns = spawns(6),
		Respawn = Vector3.new(0, 34, 0),
		Lighting = {
			ClockTime = 17.3, Brightness = 2.2, Ambient = C(110, 95, 120), OutdoorAmbient = C(160, 130, 150),
			FogColor = C(255, 175, 150), FogStart = 250, FogEnd = 1100,
			AtmosphereColor = C(255, 190, 170), AtmosphereDecay = C(200, 120, 140), AtmosphereDensity = 0.3, Haze = 1.5,
			Clouds = { Cover = 0.6, Density = 0.45, Color = C(255, 210, 200) }, Stars = 0, Tint = C(255, 235, 228), Saturation = 0.15, Contrast = 0.1, SunRays = 0.1,
		},
	},
	Shibuya = {
		Name = "Shibuya Nocturno",
		HalfWidth = 50,
		Bounds = { Left = -130, Right = 130, Top = 95, Bottom = -50 },
		Spawns = spawns(6),
		Respawn = Vector3.new(0, 34, 0),
		Lighting = {
			ClockTime = 0.5, Brightness = 1, Ambient = C(80, 70, 120), OutdoorAmbient = C(70, 70, 130),
			FogColor = C(40, 30, 80), FogStart = 180, FogEnd = 900,
			AtmosphereColor = C(120, 80, 200), AtmosphereDecay = C(60, 30, 120), AtmosphereDensity = 0.35, Haze = 2,
			Clouds = { Cover = 0.7, Density = 0.5, Color = C(90, 70, 150) }, Stars = 1500, Tint = C(225, 215, 255), Saturation = 0.25, Contrast = 0.15, SunRays = 0,
		},
	},
	Infinity = {
		Name = "Dominio Infinito",
		HalfWidth = 45,
		Bounds = { Left = -125, Right = 125, Top = 100, Bottom = -50 },
		Spawns = spawns(5),
		Respawn = Vector3.new(0, 34, 0),
		Lighting = {
			ClockTime = 0, Brightness = 0.6, Ambient = C(100, 115, 180), OutdoorAmbient = C(80, 70, 160),
			FogColor = C(10, 10, 30), FogStart = 400, FogEnd = 1600,
			AtmosphereColor = C(80, 120, 255), AtmosphereDecay = C(40, 20, 100), AtmosphereDensity = 0.2, Haze = 0,
			Clouds = { Cover = 0.25, Density = 0.3, Color = C(120, 140, 255) }, Stars = 5000, Tint = C(215, 225, 255), Saturation = 0.3, Contrast = 0.18, SunRays = 0,
		},
	},
	Temple = {
		Name = "Santuario Maldito",
		HalfWidth = 52,
		Bounds = { Left = -135, Right = 135, Top = 95, Bottom = -50 },
		Spawns = spawns(5),
		Respawn = Vector3.new(0, 34, 0),
		Lighting = {
			ClockTime = 17.6, Brightness = 2.6, Ambient = C(170, 130, 130), OutdoorAmbient = C(185, 130, 120),
			FogColor = C(120, 35, 30), FogStart = 350, FogEnd = 1500,
			AtmosphereColor = C(230, 120, 100), AtmosphereDecay = C(120, 40, 40), AtmosphereDensity = 0.26, Haze = 1.2,
			Clouds = { Cover = 0.6, Density = 0.5, Color = C(200, 90, 70) }, Stars = 0,
			-- Cielo propio del Santuario de Sukuna (tools/gen_skybox.py)
			Skybox = { Side = 115392701796693, Up = 73566067549182, Down = 77060203635554 }, Tint = C(255, 238, 232), Saturation = 0.15, Contrast = 0.18, SunRays = 0.12,
		},
	},
}

-- Iluminación del Lobby 3D (anochecer en la Escuela, con cerezos)
StageConfig.LobbyLighting = {
	-- Anochecer: el sol acaba de ponerse, cielo violeta con estrellas
	ClockTime = 18.75, Brightness = 1.3, Ambient = C(95, 85, 130), OutdoorAmbient = C(110, 95, 150),
	FogColor = C(70, 55, 120), FogStart = 300, FogEnd = 1500,
	AtmosphereColor = C(190, 130, 210), AtmosphereDecay = C(70, 40, 120), AtmosphereDensity = 0.32, Haze = 1.8,
	Clouds = { Cover = 0.5, Density = 0.4, Color = C(170, 120, 190) }, Stars = 3500,
	-- "Shaders" (post-procesado) propios del Lobby
	Tint = C(238, 228, 255), Saturation = 0.2, Contrast = 0.14, SunRays = 0.15, Blur = true,
}

StageConfig.HubStage = "Academy"
StageConfig.MatchPool = { "Shibuya", "Infinity", "Temple", "Academy" }

-- Para las ventanas de elegir escenario (Dojo y votación antes de cada partida)
StageConfig.Cards = {
	Academy = { Kanji = "校", Description = "El patio de la Escuela al atardecer", Colors = { C(255, 150, 130), C(70, 40, 80) } },
	Shibuya = { Kanji = "渋", Description = "Calles de neón bajo el Velo", Colors = { C(130, 90, 230), C(20, 15, 50) } },
	Infinity = { Kanji = "無", Description = "Un vacío lleno de estrellas", Colors = { C(90, 140, 255), C(8, 10, 35) } },
	Temple = { Kanji = "寺", Description = "El santuario del Rey Maldito", Colors = { C(230, 90, 60), C(60, 12, 10) } },
}
StageConfig.VoteTime = 8 -- segundos para votar el escenario antes de un duelo / partida

return StageConfig
