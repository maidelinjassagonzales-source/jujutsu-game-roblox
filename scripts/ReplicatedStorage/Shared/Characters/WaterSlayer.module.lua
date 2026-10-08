-- WaterSlayer · "Cazador del Agua" (Grieta Dimensional): respiración del agua, cortes fluidos con katana negra.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part

return {
	Id = "WaterSlayer", DisplayName = "Water Slayer", Color = C(60, 150, 220),
	Weight = 96, WalkSpeed = 24, JumpPower = 64,
	Appearance = { Head = C(240, 200, 170), Torso = C(40, 110, 70), Arms = C(40, 110, 70), Legs = C(30, 30, 35) },
	Style = A.Merge(A.SpikyHair(C(110, 30, 30), 0.3), A.Blade("Right Arm", 4, C(30, 30, 35), C(30, 30, 30)), {
		P("Head", V(0.1, 0.35, 0.3), CF(-0.66, -0.1, 0), C(240, 240, 240)),
		P("Head", V(0.1, 0.35, 0.3), CF(0.66, -0.1, 0), C(240, 240, 240)),
		P("Head", V(0.25, 0.2, 0.04), CF(-0.3, 0.3, -0.63), C(150, 50, 50)),
		P("Torso", V(2.06, 0.3, 1.06), CF(0, -0.6, 0), C(240, 240, 240)),
	}),
	Moves = MS.Build(MS.Standard({ Style = "Sword", Reach = 1.5 }), {
		Special_Neutral = MS.Melee({ Name = "Water Wheel", Pose = "Spin", Damage = 10, KB = 22, Growth = 74, Angle = 40, Startup = 0.15, Active = 0.25, Size = V(9, 6, 6), Offset = V(5, 0, 0), Cooldown = 1.8 }),
		Special_Side = MS.Melee({ Name = "Torrential Flow", Pose = "Slash", Damage = 9, KB = 20, Growth = 70, Angle = 30, Startup = 0.1, Active = 0.32, Dash = V(95, 4, 0), Cooldown = 2.2 }),
		Special_Up = MS.Recovery({ Name = "Rising Waterfall", Pose = "SlashUp", Velocity = V(12, 100, 0), Damage = 8 }),
		Special_Down = MS.Melee({ Name = "Fire God Dance", Pose = "SlashHeavy", Damage = 13, KB = 30, Growth = 88, Angle = 75, Startup = 0.3, Active = 0.3, Size = V(14, 5, 6), Offset = V(0, 0, 0), Cooldown = 3.5 }),
	}),
}
