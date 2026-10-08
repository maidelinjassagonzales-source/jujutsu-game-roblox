-- Viking · "Vikingo de Dagas" (Grieta Dimensional): dos dagas, combos rapidísimos, poco daño por golpe.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part
local STEEL = C(210, 210, 215)

return {
	Id = "Viking", DisplayName = "Dagger Viking", Color = C(200, 170, 90),
	Weight = 90, WalkSpeed = 27, JumpPower = 67,
	Appearance = { Head = C(235, 200, 170), Torso = C(150, 120, 80), Arms = C(50, 45, 40), Legs = C(70, 60, 50) },
	Style = A.Merge(A.SpikyHair(C(230, 200, 110), 0.35), {
		P("Torso", V(2.06, 0.3, 1.06), CF(0, -0.5, 0), C(40, 30, 25)),
		P("Right Arm", V(0.12, 0.3, 1.8), CF(0, -1.15, -1), STEEL, nil, Enum.Material.Metal),
		P("Left Arm", V(0.12, 0.3, 1.8), CF(0, -1.15, -1), STEEL, nil, Enum.Material.Metal),
	}),
	Moves = MS.Build(MS.Standard({ Style = "Daggers", Power = 0.85, Speed = 0.75 }), {
		Special_Neutral = MS.Projectile({ Name = "Throwing Dagger", Pose = "Jab", Damage = 6, KB = 12, Growth = 45, Angle = 30, Speed = 120, Lifetime = 0.6, Size = 2, Color = STEEL, Cooldown = 1, Startup = 0.1 }),
		Special_Side = MS.Melee({ Name = "Viking Thrust", Pose = "Thrust", Damage = 8, KB = 18, Growth = 66, Angle = 35, Startup = 0.06, Active = 0.25, Dash = V(105, 8, 0), Cooldown = 1.8 }),
		Special_Up = MS.Recovery({ Name = "Flip", Velocity = V(18, 104, 0) }),
		Special_Down = MS.Melee({ Name = "Dagger Whirlwind", Pose = "Spin", Damage = 9, KB = 20, Growth = 72, Angle = 70, Startup = 0.12, Active = 0.3, Size = V(9, 6, 6), Offset = V(0, 0, 0), Cooldown = 2.2 }),
	}),
}
