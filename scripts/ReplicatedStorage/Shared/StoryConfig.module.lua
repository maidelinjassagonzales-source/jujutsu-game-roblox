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
	Narrador = { Name = "Narrator", Color = C(200, 200, 210), Icon = "語" },
	Kaito = { Name = "Kaito Hayami", Color = C(255, 110, 140), Icon = "", Character = "Brawler" },
	Shiro = { Name = "Shiro Tenma", Color = C(110, 170, 255), Icon = "", Character = "Sorcerer" },
	Ryo = { Name = "Ryo Kurogane", Color = C(90, 90, 170), Icon = "", Character = "ShadowSummoner" },
	Mika = { Name = "Mika Zenra", Color = C(90, 200, 120), Icon = "", Character = "WeaponMaster" },
	Yuto = { Name = "Yuto Arashi", Color = C(230, 230, 240), Icon = "", Character = "Swordsman" },
	Tsugi = { Name = "Tsugi, the Stitched Soul", Color = C(140, 170, 200), Icon = "", Character = "Stitched" },
	Kessen = { Name = "Kessen", Color = C(170, 60, 90), Icon = "", Character = "BloodBrother" },
	Gen = { Name = "Gen, the Hunter", Color = C(80, 80, 80), Icon = "", Character = "Hunter" },
	Ozen = { Name = "Ozen, the Cursed King", Color = C(220, 40, 60), Icon = "", Character = "CursedKing" },
	Voz = { Name = "???", Color = C(220, 40, 60), Icon = "", Character = "CursedKing" },
	Raiko = { Name = "Raiko", Color = C(255, 160, 40), Icon = "", Character = "GoldenWarrior" },
	Kubo = { Name = "Kubo", Color = C(230, 50, 50), Icon = "", Character = "RubberPirate" },
	Eirik = { Name = "Eirik", Color = C(200, 170, 90), Icon = "", Character = "Viking" },
}

local function L(speaker: string, text: string)
	return { Speaker = speaker, Text = text }
end

local MINION = { Character = "CurseMinion", Name = "Lesser Curse", Level = 1, Stocks = 1 }
local GRADE2 = { Character = "CurseGrade2", Name = "Grade 2 Curse", Level = 2, Stocks = 1 }

StoryConfig.Chapters = {
	{
		Id = 1, Title = "The Cursed Finger", Stage = "Academy",
		Reward = { Coins = 300, XP = 150 },
		Intro = {
			L("Narrador", "Tokyo, 11:47 PM. A special-grade cursed object has vanished from the Sorcery School's vault."),
			L("Kaito", "What's this weird finger I found in the courtyard...? It's warm."),
			L("Narrador", "The curses can smell its power. Dozens of eyes open in the dark."),
			L("Kaito", "What the heck are those things?!"),
			L("Voz", "Heh... Finally someone with guts. Swallow it, kid, and I'll lend you my strength."),
			L("Kaito", "I'm not listening to weird voices... but I'm not running away either!"),
			L("Narrador", "TUTORIAL · Attack: click/J · Heavy: right click/K · Special: E. Rack up % and knock them off the stage!"),
		},
		Waves = { { MINION, MINION }, { MINION, MINION, MINION } },
		Outro = {
			L("Kaito", "Phew... Was that me?"),
			L("Shiro", "Impressive for someone with no training. I'm Shiro Tenma, a teacher at the School."),
			L("Shiro", "That finger belongs to Ozen, the Cursed King. And I'm afraid that now... he lives inside you."),
			L("Kaito", "WHAT?!"),
		},
	},
	{
		Id = 2, Title = "The Sorcery School", Stage = "Academy",
		Reward = { Coins = 400, XP = 200 },
		Intro = {
			L("Shiro", "The higher-ups want you executed. I convinced them to wait... if you prove you can control him."),
			L("Ryo", "Ryo Kurogane. If you're really useful, prove it against my shadows."),
			L("Kaito", "A fight on my first day? I love it!"),
			L("Shiro", "Remember: the more % your opponent has, the farther they'll fly."),
		},
		Waves = { { { Character = "ShadowSummoner", Name = "Ryo Kurogane", Level = 2, Stocks = 1 } } },
		Outro = {
			L("Ryo", "...Not bad. For a vessel."),
			L("Mika", "Ha! Ryo losing to the new kid. I'm Mika Zenra, nice to meet you."),
			L("Shiro", "Good. Tomorrow is your first mission: Shibuya."),
		},
	},
	{
		Id = 3, Title = "Night in Shibuya", Stage = "Shibuya",
		Reward = { Coins = 500, XP = 260 },
		Intro = {
			L("Narrador", "Shibuya, 8:00 PM. A black curtain falls over the district: no one can get in or out."),
			L("Mika", "It's a barrier. Someone put it up on purpose."),
			L("Ryo", "The curses are hunting civilians. We have to clear the rooftops."),
			L("Kaito", "Roof by roof, then. I'll go first!"),
		},
		Waves = { { MINION, MINION, MINION }, { GRADE2, MINION }, { GRADE2, GRADE2 } },
		Outro = {
			L("Kaito", "This never ends..."),
			L("Tsugi", "What an interesting soul you have, boy. I'd love to... remodel it."),
			L("Ryo", "Kaito, careful! That presence isn't normal."),
		},
	},
	{
		Id = 4, Title = "The Stitched Soul", Stage = "Shibuya",
		Reward = { Coins = 600, XP = 320, Gems = 30 },
		Intro = {
			L("Tsugi", "My name is Tsugi. The soul is just clay, you know? And I'm an artist."),
			L("Kaito", "You turned those people into... I'm going to tear you apart!"),
			L("Tsugi", "That's it! Hate! Hatred makes the soul easier to mold."),
			L("Voz", "Heh heh... Let me out for a bit and I'll show him what real molding is."),
			L("Kaito", "Shut up, Ozen! I'm doing this myself."),
		},
		Waves = { { { Character = "Stitched", Name = "Tsugi, the Stitched Soul", Level = 3, Stocks = 2 } } },
		Outro = {
			L("Tsugi", "Ah... so your soul is protected by HIM. How unfair."),
			L("Narrador", "Tsugi unravels into black threads and vanishes into the night."),
			L("Kaito", "He got away... Next time he won't."),
		},
	},
	{
		Id = 5, Title = "Blood and Brotherhood", Stage = "Temple",
		Reward = { Coins = 650, XP = 380 },
		Intro = {
			L("Shiro", "We've located another finger in an abandoned temple in Kyoto."),
			L("Mika", "It smells like blood. A lot of blood."),
			L("Kessen", "So you're the vessel who killed my little brothers... No, wait. Something doesn't add up."),
			L("Kessen", "Doesn't matter. A big brother always protects his own. Get ready!"),
		},
		Waves = { { MINION, GRADE2 }, { { Character = "BloodBrother", Name = "Kessen", Level = 3, Stocks = 2 } } },
		Outro = {
			L("Kessen", "While we fought... I saw memories that don't exist. You and I... are we brothers?"),
			L("Kaito", "Brothers?! I'm an only child!"),
			L("Kessen", "Then we'll figure it out together. I owe you one, little brother."),
			L("Narrador", "Kessen joins the School as an unexpected ally."),
		},
	},
	{
		Id = 6, Title = "The Curseless Hunter", Stage = "Temple",
		Reward = { Coins = 750, XP = 450 },
		Intro = {
			L("Narrador", "Someone has put a price on Kaito's head: one hundred million yen."),
			L("Gen", "Nothing personal, kid. I have no cursed energy... but I don't need it either."),
			L("Yuto", "Kaito! I've got your back. I'm Yuto Arashi, second year. Shiro sent me."),
			L("Gen", "Two more kids. The price doesn't change."),
		},
		Waves = { { { Character = "Hunter", Name = "Gen, the Hunter", Level = 4, Stocks = 2 } } },
		Outro = {
			L("Gen", "Heh... They paid me for a monster and I find a kid who won't give up."),
			L("Gen", "Look for the one who hired me: he has a stitched scar across his forehead."),
			L("Yuto", "Stitches on his forehead...? Shiro needs to know about this."),
		},
	},
	{
		Id = 7, Title = "The Dimensional Rift", Stage = "Infinity",
		Reward = { Coins = 900, XP = 550, Gems = 50 },
		Intro = {
			L("Narrador", "A cursed finger reacts with the sky and opens a rift between worlds."),
			L("Shiro", "This is bad. The rift is pulling in warriors from other dimensions."),
			L("Eirik", "Where's my ship? ...You. You look like an enemy."),
			L("Kubo", "Shishi! What a weird place! Is there any meat here?"),
			L("Raiko", "Hi! I sense a lot of energy in you. Wanna fight? I can't wait!"),
			L("Kaito", "Why does everyone want to fight me?"),
		},
		Waves = {
			{ { Character = "Viking", Name = "Eirik", Level = 3, Stocks = 1 } },
			{ { Character = "RubberPirate", Name = "Kubo", Level = 3, Stocks = 1 } },
			{ { Character = "GoldenWarrior", Name = "Raiko", Level = 4, Stocks = 2 } },
		},
		Outro = {
			L("Raiko", "That was awesome! You're really strong, you know?"),
			L("Kubo", "The rift is closing! See you, weird friend!"),
			L("Eirik", "A true warrior needs no enemies... I'll remember that."),
			L("Narrador", "The warriors return to their worlds. But the rift has awakened something inside Kaito."),
		},
	},
	{
		Id = 8, Title = "The King Awakens", Stage = "Infinity",
		Reward = { Coins = 1500, XP = 900, Gems = 100, Skin = "Brawler_Awakened", Title = "Title_Vessel" },
		Intro = {
			L("Tsugi", "At last! With the final finger, Ozen will fully awaken."),
			L("Shiro", "Kaito, don't let him control you!"),
			L("Ozen", "Heh heh heh... Thanks for keeping my body warm, brat. Now it's MINE."),
			L("Narrador", "Kaito loses control. The Cursed King walks the world once more."),
			L("Kaito", "...No... This body is mine! I'll beat you out of it!"),
			L("Narrador", "FINAL BATTLE: defeat Tsugi and face Ozen inside your own domain."),
		},
		Waves = {
			{ { Character = "Stitched", Name = "Tsugi, the Stitched Soul", Level = 4, Stocks = 1 } },
			{ { Character = "CursedKing", Name = "Ozen, the Cursed King", Level = 5, Stocks = 3 } },
		},
		Outro = {
			L("Ozen", "Impossible... A mere human has... sealed me away again?"),
			L("Kaito", "I'm not a mere human. I'm a sorcerer."),
			L("Shiro", "Officially, welcome to the School, Kaito."),
			L("Kessen", "That's my little brother."),
			L("Narrador", "END OF SEASON 1. You earned the exclusive skin «Awakened Kaito»."),
		},
	},
}

function StoryConfig.Get(id: number)
	return StoryConfig.Chapters[id]
end

return StoryConfig
