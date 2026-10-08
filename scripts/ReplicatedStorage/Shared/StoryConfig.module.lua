-- StoryConfig: "Crónicas del Sello Maldito" · Temporada 1 (8 capítulos).
-- Cada capítulo: escenario, diálogo de entrada, oleadas de enemigos, diálogo final y recompensas.
-- Enemigos: { Character, Name, Level (1-5 = dificultad de la IA), Stocks }
local C = Color3.fromRGB

local StoryConfig = {}

StoryConfig.PlayerStocks = 3
StoryConfig.ReplayRewardMultiplier = 0.25 -- repetir un capítulo ya superado da el 25%
StoryConfig.ReviveGems = 25 -- revivir tras perder (continuar con 3 stocks)

-- Character = luchador cuyo retrato 3D se ve en el cuadro de diálogo
StoryConfig.Speakers = {
	Narrador = { Name = "Narrador", Color = C(200, 200, 210), Icon = "語" },
	Kaito = { Name = "Kaito Hayami", Color = C(255, 110, 140), Icon = "", Character = "Brawler" },
	Shiro = { Name = "Shiro Tenma", Color = C(110, 170, 255), Icon = "", Character = "Sorcerer" },
	Ryo = { Name = "Ryo Kurogane", Color = C(90, 90, 170), Icon = "", Character = "ShadowSummoner" },
	Mika = { Name = "Mika Zenra", Color = C(90, 200, 120), Icon = "", Character = "WeaponMaster" },
	Yuto = { Name = "Yuto Arashi", Color = C(230, 230, 240), Icon = "", Character = "Swordsman" },
	Tsugi = { Name = "Tsugi, el Alma Cosida", Color = C(140, 170, 200), Icon = "", Character = "Stitched" },
	Kessen = { Name = "Kessen", Color = C(170, 60, 90), Icon = "", Character = "BloodBrother" },
	Gen = { Name = "Gen, el Cazador", Color = C(80, 80, 80), Icon = "", Character = "Hunter" },
	Ozen = { Name = "Ozen, el Rey Maldito", Color = C(220, 40, 60), Icon = "", Character = "CursedKing" },
	Voz = { Name = "???", Color = C(220, 40, 60), Icon = "", Character = "CursedKing" },
	Raiko = { Name = "Raiko", Color = C(255, 160, 40), Icon = "", Character = "GoldenWarrior" },
	Kubo = { Name = "Kubo", Color = C(230, 50, 50), Icon = "", Character = "RubberPirate" },
	Eirik = { Name = "Eirik", Color = C(200, 170, 90), Icon = "", Character = "Viking" },
}

local function L(speaker: string, text: string)
	return { Speaker = speaker, Text = text }
end

local MINION = { Character = "CurseMinion", Name = "Maldición Menor", Level = 1, Stocks = 1 }
local GRADE2 = { Character = "CurseGrade2", Name = "Maldición de Grado 2", Level = 2, Stocks = 1 }

StoryConfig.Chapters = {
	{
		Id = 1, Title = "El Dedo Maldito", Stage = "Academy",
		Reward = { Coins = 300, XP = 150 },
		Intro = {
			L("Narrador", "Tokio, 23:47. Un objeto maldito de grado especial ha desaparecido del almacén de la Escuela de Hechicería."),
			L("Kaito", "¿Qué es este dedo tan raro que he encontrado en el patio...? Está caliente."),
			L("Narrador", "Las maldiciones huelen su poder. Decenas de ojos se abren en la oscuridad."),
			L("Kaito", "¡¿Qué demonios son esas cosas?!"),
			L("Voz", "Je... Por fin alguien con agallas. Trágatelo, chaval, y te prestaré mi fuerza."),
			L("Kaito", "No pienso hacer caso a voces raras... ¡pero tampoco pienso huir!"),
			L("Narrador", "TUTORIAL · Golpe: clic/J · Fuerte: clic der/K · Especial: E. Acumula % y ¡échalas del escenario!"),
		},
		Waves = { { MINION, MINION }, { MINION, MINION, MINION } },
		Outro = {
			L("Kaito", "Uf... ¿He sido yo?"),
			L("Shiro", "Impresionante para alguien sin entrenamiento. Soy Shiro Tenma, profesor de la Escuela."),
			L("Shiro", "Ese dedo pertenece a Ozen, el Rey Maldito. Y me temo que ahora... vive dentro de ti."),
			L("Kaito", "¡¿QUÉ?!"),
		},
	},
	{
		Id = 2, Title = "La Escuela de Hechicería", Stage = "Academy",
		Reward = { Coins = 400, XP = 200 },
		Intro = {
			L("Shiro", "Los altos mandos quieren ejecutarte. Les he convencido de esperar... si demuestras que puedes controlarlo."),
			L("Ryo", "Ryo Kurogane. Si de verdad eres útil, demuéstralo contra mis sombras."),
			L("Kaito", "¿Un combate el primer día? ¡Me encanta!"),
			L("Shiro", "Recuerda: cuanto más % acumule tu rival, más lejos saldrá volando."),
		},
		Waves = { { { Character = "ShadowSummoner", Name = "Ryo Kurogane", Level = 2, Stocks = 1 } } },
		Outro = {
			L("Ryo", "...No está mal. Para ser un recipiente."),
			L("Mika", "¡Ja! Ryo perdiendo contra el novato. Soy Mika Zenra, encantada."),
			L("Shiro", "Bien. Mañana tenéis vuestra primera misión: Shibuya."),
		},
	},
	{
		Id = 3, Title = "Noche en Shibuya", Stage = "Shibuya",
		Reward = { Coins = 500, XP = 260 },
		Intro = {
			L("Narrador", "Shibuya, 20:00. Una cortina negra cae sobre el barrio: nadie puede entrar ni salir."),
			L("Mika", "Es una barrera. Alguien la ha levantado a propósito."),
			L("Ryo", "Las maldiciones están cazando a los civiles. Hay que despejar las azoteas."),
			L("Kaito", "Pues tejado por tejado. ¡Yo voy delante!"),
		},
		Waves = { { MINION, MINION, MINION }, { GRADE2, MINION }, { GRADE2, GRADE2 } },
		Outro = {
			L("Kaito", "Esto no se acaba nunca..."),
			L("Tsugi", "Qué alma tan interesante tienes, chico. Me encantaría... remodelarla."),
			L("Ryo", "¡Kaito, cuidado! Esa presencia no es normal."),
		},
	},
	{
		Id = 4, Title = "El Alma Cosida", Stage = "Shibuya",
		Reward = { Coins = 600, XP = 320, Gems = 30 },
		Intro = {
			L("Tsugi", "Me llamo Tsugi. El alma es solo arcilla, ¿sabes? Y yo soy un artista."),
			L("Kaito", "Has convertido a esa gente en... ¡Te voy a hacer pedazos!"),
			L("Tsugi", "¡Eso es! ¡Odia! El odio hace que el alma sea más fácil de moldear."),
			L("Voz", "Je je... Déjame salir un rato y le enseño lo que es moldear de verdad."),
			L("Kaito", "¡Cállate, Ozen! Esto lo hago yo."),
		},
		Waves = { { { Character = "Stitched", Name = "Tsugi, el Alma Cosida", Level = 3, Stocks = 2 } } },
		Outro = {
			L("Tsugi", "Ah... así que tu alma está protegida por ÉL. Qué injusto."),
			L("Narrador", "Tsugi se deshace en hilos negros y desaparece en la noche."),
			L("Kaito", "Se ha escapado... La próxima vez no."),
		},
	},
	{
		Id = 5, Title = "Sangre y Hermandad", Stage = "Temple",
		Reward = { Coins = 650, XP = 380 },
		Intro = {
			L("Shiro", "Hemos localizado otro dedo en un templo abandonado de Kioto."),
			L("Mika", "Huele a sangre. Mucha sangre."),
			L("Kessen", "Así que tú eres el recipiente que mató a mis hermanos menores... No, espera. Algo no cuadra."),
			L("Kessen", "Da igual. Un hermano mayor siempre protege a los suyos. ¡Prepárate!"),
		},
		Waves = { { MINION, GRADE2 }, { { Character = "BloodBrother", Name = "Kessen", Level = 3, Stocks = 2 } } },
		Outro = {
			L("Kessen", "Mientras luchábamos... he visto recuerdos que no existen. Tú y yo... ¿somos hermanos?"),
			L("Kaito", "¡¿Hermanos?! ¡Si soy hijo único!"),
			L("Kessen", "Entonces lo averiguaremos juntos. Te debo una, hermanito."),
			L("Narrador", "Kessen se une a la Escuela como un aliado inesperado."),
		},
	},
	{
		Id = 6, Title = "El Cazador sin Maldición", Stage = "Temple",
		Reward = { Coins = 750, XP = 450 },
		Intro = {
			L("Narrador", "Alguien ha puesto precio a la cabeza de Kaito: cien millones de yenes."),
			L("Gen", "Nada personal, chaval. No tengo energía maldita... pero tampoco la necesito."),
			L("Yuto", "¡Kaito! Te cubro. Soy Yuto Arashi, de segundo curso. Shiro me ha enviado."),
			L("Gen", "Dos críos más. El precio no cambia."),
		},
		Waves = { { { Character = "Hunter", Name = "Gen, el Cazador", Level = 4, Stocks = 2 } } },
		Outro = {
			L("Gen", "Je... Me pagaron por un monstruo y me encuentro a un crío que no se rinde."),
			L("Gen", "Busca a quien me contrató: lleva una cicatriz de puntos en la frente."),
			L("Yuto", "¿Puntos en la frente...? Shiro tiene que saber esto."),
		},
	},
	{
		Id = 7, Title = "La Grieta Dimensional", Stage = "Infinity",
		Reward = { Coins = 900, XP = 550, Gems = 50 },
		Intro = {
			L("Narrador", "Un dedo maldito reacciona con el cielo y abre una grieta entre mundos."),
			L("Shiro", "Esto es malo. La grieta está arrastrando guerreros de otras dimensiones."),
			L("Eirik", "¿Dónde está mi barco? ...Tú. Tienes pinta de enemigo."),
			L("Kubo", "¡Shishi! ¡Qué sitio más raro! ¿Aquí hay carne?"),
			L("Raiko", "¡Hola! Noto mucha energía en ti. ¿Peleamos? ¡Me muero de ganas!"),
			L("Kaito", "¿Por qué todo el mundo quiere pelear conmigo?"),
		},
		Waves = {
			{ { Character = "Viking", Name = "Eirik", Level = 3, Stocks = 1 } },
			{ { Character = "RubberPirate", Name = "Kubo", Level = 3, Stocks = 1 } },
			{ { Character = "GoldenWarrior", Name = "Raiko", Level = 4, Stocks = 2 } },
		},
		Outro = {
			L("Raiko", "¡Ha sido genial! Eres muy fuerte, ¿sabes?"),
			L("Kubo", "¡La grieta se cierra! ¡Nos vemos, amigo raro!"),
			L("Eirik", "Un verdadero guerrero no necesita enemigos... Lo recordaré."),
			L("Narrador", "Los guerreros vuelven a sus mundos. Pero la grieta ha despertado algo dentro de Kaito."),
		},
	},
	{
		Id = 8, Title = "El Rey Despierta", Stage = "Infinity",
		Reward = { Coins = 1500, XP = 900, Gems = 100, Skin = "Brawler_Awakened", Title = "Title_Vessel" },
		Intro = {
			L("Tsugi", "¡Por fin! Con el último dedo, Ozen despertará por completo."),
			L("Shiro", "¡Kaito, no dejes que te controle!"),
			L("Ozen", "Je je je... Gracias por guardarme el cuerpo, mocoso. Ahora es MÍO."),
			L("Narrador", "Kaito pierde el control. El Rey Maldito camina de nuevo por el mundo."),
			L("Kaito", "...No... ¡Este cuerpo es mío! ¡Te sacaré a golpes!"),
			L("Narrador", "COMBATE FINAL: derrota a Tsugi y enfréntate a Ozen dentro de tu propio dominio."),
		},
		Waves = {
			{ { Character = "Stitched", Name = "Tsugi, el Alma Cosida", Level = 4, Stocks = 1 } },
			{ { Character = "CursedKing", Name = "Ozen, el Rey Maldito", Level = 5, Stocks = 3 } },
		},
		Outro = {
			L("Ozen", "Imposible... ¿Un simple humano me ha... encerrado otra vez?"),
			L("Kaito", "No soy un simple humano. Soy un hechicero."),
			L("Shiro", "Bienvenido oficialmente a la Escuela, Kaito."),
			L("Kessen", "Ese es mi hermanito."),
			L("Narrador", "FIN DE LA TEMPORADA 1. Has conseguido la skin exclusiva «Kaito Despertado»."),
		},
	},
}

function StoryConfig.Get(id: number)
	return StoryConfig.Chapters[id]
end

return StoryConfig
