-- FoxNinja · "Ninja del Zorro" (EXCLUSIVO, Grieta Dimensional): kunais, clones y la esfera espiral.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part
local INK = C(20, 20, 20)

return {
	Id = "FoxNinja", DisplayName = "Ninja del Zorro", Color = C(255, 150, 40),
	Weight = 98, WalkSpeed = 26, JumpPower = 67,
	Appearance = { Head = C(240, 200, 165), Torso = C(255, 140, 40), Arms = C(255, 140, 40), Legs = C(255, 140, 40) },
	Style = A.Merge(A.SpikyHair(C(255, 215, 60), 0.45), {
		P("Head", V(1.34, 0.22, 1.34), CF(0, 0.32, 0), C(30, 40, 90)),
		P("Head", V(0.5, 0.2, 0.05), CF(0, 0.32, -0.68), C(190, 190, 200), nil, Enum.Material.Metal),
		P("Head", V(0.3, 0.03, 0.03), CF(-0.32, -0.12, -0.63), INK),
		P("Head", V(0.3, 0.03, 0.03), CF(0.32, -0.12, -0.63), INK),
		P("Torso", V(2.1, 0.45, 1.12), CF(0, 0.9, 0), INK),
	}),
	Moves = MS.Build(MS.Standard({ Style = "Kicks", Power = 0.98, Speed = 0.9 }), {
		Special_Neutral = MS.Projectile({ Name = "Esfera Espiral", Pose = "Palms", Damage = 12, KB = 28, Growth = 88, Angle = 35, Speed = 70, Lifetime = 0.7, Size = 5, Color = C(120, 200, 255), Startup = 0.45, Cooldown = 4 }),
		Special_Side = MS.Projectile({ Name = "Kunai", Pose = "Jab", Damage = 6, KB = 12, Growth = 45, Angle = 30, Speed = 130, Lifetime = 0.6, Size = 2, Color = C(80, 80, 90), Cooldown = 0.9, Startup = 0.1 }),
		Special_Up = MS.Recovery({ Name = "Salto Ninja", Velocity = V(15, 108, 0) }),
		Special_Down = MS.Melee({ Name = "Lluvia de Clones", Pose = "Spin", Damage = 11, KB = 24, Growth = 80, Angle = 60, Startup = 0.2, Active = 0.3, Size = V(14, 5, 6), Offset = V(0, 0, 0), Cooldown = 3 }),
	}),
}
