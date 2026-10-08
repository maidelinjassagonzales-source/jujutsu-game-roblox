-- ThreeBlades · "Espadachín de Tres Hojas" (Grieta Dimensional): una espada en cada mano y otra en la boca.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part
local STEEL = C(220, 225, 235)

return {
	Id = "ThreeBlades", DisplayName = "Three-Blade Swordsman", Color = C(60, 160, 90),
	Weight = 106, WalkSpeed = 23, JumpPower = 62,
	Appearance = { Head = C(220, 180, 145), Torso = C(230, 230, 230), Arms = C(220, 180, 145), Legs = C(35, 35, 40) },
	Style = A.Merge(A.SpikyHair(C(60, 170, 90), 0.2), A.Blade("Right Arm", 4, STEEL, C(30, 30, 30)), A.Blade("Left Arm", 4, STEEL, C(200, 30, 30)), {
		P("Head", V(4, 0.15, 0.3), CF(0, -0.25, -0.75), STEEL, nil, Enum.Material.Metal),
		P("Torso", V(2.06, 0.5, 1.06), CF(0, -0.6, 0), C(40, 120, 60)),
		P("Head", V(0.1, 0.4, 0.1), CF(-0.66, -0.15, 0), C(230, 200, 60), nil, Enum.Material.Metal),
	}),
	Moves = MS.Build(MS.Standard({ Style = "Sword", Reach = 1.8, Power = 1.05, Speed = 1.05 }), {
		Special_Neutral = MS.Projectile({ Name = "Flying Slash", Pose = "SlashHeavy", Damage = 11, KB = 24, Growth = 80, Angle = 35, Speed = 95, Lifetime = 0.8, Size = 5, Color = C(140, 255, 170), Pierce = true, Startup = 0.35, Cooldown = 2.5 }),
		Special_Side = MS.Melee({ Name = "Ogre Cutter", Pose = "Slash", Damage = 12, KB = 26, Growth = 82, Angle = 35, Startup = 0.15, Active = 0.25, Dash = V(95, 4, 0), Cooldown = 2.5 }),
		Special_Up = MS.Recovery({ Name = "Dragon Cut", Pose = "SlashUp", Velocity = V(10, 96, 0), Damage = 8 }),
		Special_Down = MS.Melee({ Name = "Three-Sword Tornado", Pose = "Spin", Damage = 14, KB = 32, Growth = 88, Angle = 85, Startup = 0.3, Active = 0.3, Size = V(10, 8, 6), Offset = V(0, 1, 0), Cooldown = 3.5 }),
	}),
}
