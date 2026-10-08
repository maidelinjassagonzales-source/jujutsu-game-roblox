-- BloodBrother · "Hermano de Sangre": manipulación de sangre. Zoner: disparos rapidísimos.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part

return {
	Id = "BloodBrother", DisplayName = "Hermano de Sangre", Color = C(170, 60, 90),
	Weight = 100, WalkSpeed = 22, JumpPower = 62,
	Appearance = { Head = C(240, 220, 210), Torso = C(230, 230, 230), Arms = C(230, 230, 230), Legs = C(230, 230, 230) },
	Style = {
		P("Head", V(1.32, 0.3, 1.32), CF(0, 0.55, 0.02), C(60, 40, 35)),
		P("Head", V(0.65, 0.65, 0.65), CF(-0.45, 0.85, 0), C(60, 40, 35), "Ball"),
		P("Head", V(0.65, 0.65, 0.65), CF(0.45, 0.85, 0), C(60, 40, 35), "Ball"),
		P("Head", V(0.7, 0.12, 0.04), CF(0, 0.05, -0.63), C(20, 20, 20)),
		P("Torso", V(2.1, 0.6, 1.15), CF(0, 0.95, 0), C(100, 60, 120)),
		P("Torso", V(2.06, 0.4, 1.06), CF(0, -0.6, 0), C(100, 60, 120)),
	},
	Moves = MS.Build(MS.Standard({ Style = "Fists", Power = 0.97 }), {
		Special_Neutral = MS.Projectile({ Name = "Perforación de Sangre", Pose = "Palms", Damage = 8, KB = 12, Growth = 50, Angle = 25, Speed = 160, Lifetime = 0.6, Size = 2, Color = C(200, 20, 40), Pierce = true, Startup = 0.28, Cooldown = 1.4 }),
		Special_Side = MS.Projectile({ Name = "Bala de Sangre", Pose = "Jab", Damage = 5, KB = 14, Growth = 40, Angle = 35, Speed = 90, Lifetime = 0.8, Size = 3, Color = C(180, 20, 40), Cooldown = 1, Startup = 0.12 }),
		Special_Up = MS.Recovery({ Name = "Impulso Carmesí" }),
		Special_Down = MS.Melee({ Name = "Meteoro de Sangre", Pose = "Slam", Damage = 11, KB = 26, Growth = 82, Angle = 75, Startup = 0.25, Active = 0.2, Size = V(14, 4, 6), Offset = V(0, -1, 0), Cooldown = 3 }),
	}),
}
