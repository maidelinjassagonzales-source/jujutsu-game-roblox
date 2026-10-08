-- RubberPirate · "Pirata Elástico" (Grieta Dimensional): brazos de goma que llegan a la otra punta del escenario.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part
local up = CFrame.Angles(0, 0, math.rad(90)) -- cilindro en vertical
local STRAW = C(230, 200, 110)

return {
	Id = "RubberPirate", DisplayName = "Rubber Pirate", Color = C(230, 50, 50),
	Weight = 95, WalkSpeed = 24, JumpPower = 66,
	Appearance = { Head = C(240, 200, 165), Torso = C(210, 40, 40), Arms = C(240, 200, 165), Legs = C(50, 90, 180) },
	Style = A.Merge(A.SpikyHair(C(15, 15, 20), 0.25), {
		P("Head", V(0.15, 2.7, 2.7), CF(0, 0.7, 0) * up, STRAW, "Cylinder"),
		P("Head", V(0.8, 1.45, 1.45), CF(0, 1.05, 0) * up, STRAW, "Cylinder"),
		P("Head", V(0.25, 1.5, 1.5), CF(0, 0.82, 0) * up, C(200, 30, 30), "Cylinder"),
		P("Head", V(0.25, 0.05, 0.04), CF(-0.3, -0.12, -0.63), C(120, 40, 40)),
		P("Torso", V(0.6, 2, 0.05), CF(0, 0, -0.53), C(240, 200, 165)),
		P("Torso", V(2.06, 0.35, 1.06), CF(0, -0.7, 0), C(240, 200, 40)),
	}),
	Moves = MS.Build(MS.Standard({ Style = "Fists", Reach = 1.5, Power = 0.98 }), {
		Special_Neutral = MS.Melee({ Name = "Rubber Pistol", Pose = "Jab", Damage = 9, KB = 20, Growth = 70, Angle = 32, Startup = 0.2, Active = 0.12, Size = V(16, 3, 6), Offset = V(9, 0, 0), Cooldown = 1.6 }),
		Special_Side = MS.Melee({ Name = "Rubber Bazooka", Pose = "Palms", Damage = 13, KB = 30, Growth = 88, Angle = 35, Startup = 0.35, Active = 0.12, Size = V(10, 5, 6), Offset = V(6, 0, 0), Cooldown = 3 }),
		Special_Up = MS.Recovery({ Name = "Rubber Rocket", Velocity = V(10, 112, 0) }),
		Special_Down = MS.Melee({ Name = "Rubber Hammer", Pose = "Slam", Damage = 12, KB = 28, Growth = 84, Angle = 75, Startup = 0.25, Active = 0.25, Dash = V(0, -100, 0), Size = V(9, 5, 6), Offset = V(0, -2, 0), Cooldown = 3 }),
	}),
}
