-- VolcanoCurse · "Maldición Volcánica": una maldición de desastre con cabeza de volcán. Fuego por todas partes.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part

return {
	Id = "VolcanoCurse", DisplayName = "Maldición Volcánica", Color = C(255, 120, 40),
	Weight = 98, WalkSpeed = 22, JumpPower = 60,
	Appearance = { Head = C(230, 220, 200), Torso = C(30, 25, 25), Arms = C(30, 25, 25), Legs = C(30, 25, 25) },
	Style = {
		P("Head", V(1.15, 0.5, 1.15), CF(0, 0.75, 0), C(70, 50, 45), nil, Enum.Material.Rock),
		P("Head", V(0.8, 0.35, 0.8), CF(0, 1.15, 0), C(70, 50, 45), nil, Enum.Material.Rock),
		P("Head", V(0.55, 0.12, 0.55), CF(0, 1.36, 0), C(255, 100, 20), nil, Enum.Material.Neon),
		P("Head", V(0.25, 0.25, 0.05), CF(0, 0.1, -0.63), C(30, 30, 30), "Ball"),
		P("Torso", V(2.06, 0.35, 1.06), CF(0, -0.6, 0), C(200, 90, 30)),
	},
	Moves = MS.Build(MS.Standard({ Style = "Fists" }), {
		Special_Neutral = MS.Projectile({ Name = "Bola de Magma", Damage = 8, KB = 18, Growth = 60, Angle = 40, Speed = 85, Lifetime = 1, Size = 4, Color = C(255, 110, 30), Cooldown = 1.5 }),
		Special_Side = MS.Projectile({ Name = "Insectos de Fuego", Damage = 7, KB = 16, Growth = 50, Angle = 25, Speed = 100, Lifetime = 0.7, Size = 3, Color = C(255, 180, 60), Pierce = true, Cooldown = 1.2, Startup = 0.15 }),
		Special_Up = MS.Recovery({ Name = "Géiser", Velocity = V(10, 102, 0), Damage = 8 }),
		Special_Down = MS.Melee({ Name = "Erupción", Pose = "Slam", Damage = 14, KB = 30, Growth = 88, Angle = 85, Startup = 0.3, Active = 0.25, Size = V(14, 8, 6), Offset = V(0, 0, 0), Cooldown = 4 }),
	}),
}
