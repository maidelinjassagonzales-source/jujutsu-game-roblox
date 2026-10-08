-- NailWitch · "Bruja de los Clavos": martillo y clavos. Su resonancia golpea DOS veces.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part

return {
	Id = "NailWitch", DisplayName = "Bruja de los Clavos", Color = C(200, 120, 60),
	Weight = 94, WalkSpeed = 23, JumpPower = 62,
	Appearance = { Head = C(240, 210, 185), Torso = C(30, 30, 55), Arms = C(30, 30, 55), Legs = C(30, 30, 55) },
	Style = {
		P("Head", V(1.36, 0.45, 1.36), CF(0, 0.48, 0.04), C(200, 110, 60)),
		P("Head", V(0.2, 0.8, 1.2), CF(-0.62, 0.05, 0.05), C(200, 110, 60)),
		P("Head", V(0.2, 0.8, 1.2), CF(0.62, 0.05, 0.05), C(200, 110, 60)),
		P("Head", V(1.3, 0.8, 0.2), CF(0, 0.1, 0.6), C(200, 110, 60)),
		P("Right Arm", V(0.2, 0.2, 2), CF(0, -1.15, -1), C(100, 70, 45), nil, Enum.Material.Wood),
		P("Right Arm", V(0.6, 0.5, 0.9), CF(0, -1.15, -2.1), C(90, 90, 100), nil, Enum.Material.Metal),
	},
	Moves = MS.Build(MS.Standard({ Style = "Fists", Power = 0.95, Reach = 0.8 }), {
		Special_Neutral = MS.Projectile({ Name = "Clavos", Pose = "Jab", Damage = 6, KB = 12, Growth = 45, Angle = 30, Speed = 110, Lifetime = 0.7, Size = 2, Color = C(200, 200, 210), Cooldown = 0.9, Startup = 0.12 }),
		Special_Side = MS.Melee({ Name = "Resonancia", Pose = "Haymaker", Damage = 9, KB = 18, Growth = 65, Angle = 40, Startup = 0.2, Active = 0.1, Cooldown = 2,
			FollowUp = { Delay = 0.4, Damage = 7, BaseKnockback = 28, KnockbackGrowth = 80, Angle = 45 } }),
		Special_Up = MS.Recovery({ Name = "Martillazo Ascendente" }),
		Special_Down = MS.Projectile({ Name = "Horquilla", Pose = "Slam", Damage = 12, KB = 26, Growth = 82, Angle = 50, Speed = 60, Lifetime = 1.2, Size = 5, Color = C(255, 150, 60), Startup = 0.5, Cooldown = 6 }),
	}),
}
