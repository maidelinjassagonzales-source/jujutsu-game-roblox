-- BoogieBrawler · "Puño del Aplauso": un mastodonte que, con una palmada, INTERCAMBIA su posición con el rival.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part

local clap = MS.Melee({ Name = "Clap: Swap", Pose = "Clap", Damage = 4, KB = 8, Growth = 15, Angle = 70, Startup = 0.15, Active = 0.1, Size = V(24, 8, 6), Offset = V(12, 0, 0), Cooldown = 3 })
clap.Swap = true -- CombatService intercambia las posiciones al impactar

return {
	Id = "BoogieBrawler", DisplayName = "Clap Fist", Color = C(150, 110, 80),
	Weight = 112, WalkSpeed = 21, JumpPower = 58,
	Appearance = { Head = C(200, 150, 110), Torso = C(205, 155, 115), Arms = C(205, 155, 115), Legs = C(40, 45, 60) },
	Style = {
		P("Head", V(1.32, 0.25, 1.32), CF(0, 0.55, 0.02), C(25, 20, 20)),
		P("Head", V(0.55, 0.55, 0.55), CF(0, 0.95, 0.15), C(25, 20, 20), "Ball"),
		P("Head", V(0.05, 0.6, 0.04), CF(0.25, 0, -0.63), C(150, 90, 80)),
		P("Torso", V(0.5, 2, 1.08), CF(-0.78, 0, 0), C(40, 45, 60)),
		P("Torso", V(0.5, 2, 1.08), CF(0.78, 0, 0), C(40, 45, 60)),
	},
	Moves = MS.Build(MS.Standard({ Style = "Heavy", Power = 1.1, Speed = 1.1, KB = 1.05 }), {
		Special_Neutral = clap,
		Special_Side = MS.Melee({ Name = "Freight Train", Pose = "Haymaker", Damage = 12, KB = 26, Growth = 84, Angle = 38, Startup = 0.15, Active = 0.25, Dash = V(80, 6, 0), Cooldown = 2.4 }),
		Special_Up = MS.Recovery({ Name = "Bestseller", Velocity = V(10, 92, 0), Damage = 9 }),
		Special_Down = MS.Melee({ Name = "Black Flash Fist", Pose = "Slam", Damage = 16, KB = 33, Growth = 90, Angle = 70, Startup = 0.35, Active = 0.15, Size = V(12, 4, 6), Offset = V(0, -2, 0), Cooldown = 3 }),
	}),
}
