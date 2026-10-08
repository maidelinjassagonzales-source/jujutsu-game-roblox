-- GoldenWarrior · "Guerrero Dorado" (MÍTICO, llega por la Grieta Dimensional): artes marciales y ondas de energía.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part
local BLUE = C(40, 80, 180)

return {
	Id = "GoldenWarrior", DisplayName = "Guerrero Dorado", Color = C(255, 160, 40),
	Weight = 102, WalkSpeed = 25, JumpPower = 66,
	Appearance = { Head = C(240, 200, 165), Torso = C(255, 140, 30), Arms = C(240, 200, 165), Legs = C(255, 140, 30) },
	Style = A.Merge(A.SpikyHair(C(15, 15, 20), 0.75, {
		{ -0.5, -0.3, -45 }, { -0.2, -0.35, -15 }, { 0.2, -0.35, 15 }, { 0.5, -0.3, 45 },
		{ -0.55, 0.15, -60 }, { 0, 0.1, 0 }, { 0.55, 0.15, 60 }, { -0.3, 0.45, -30 }, { 0.3, 0.45, 30 },
	}), {
		P("Torso", V(1.2, 0.45, 1.06), CF(0, 0.82, 0), BLUE),
		P("Torso", V(2.06, 0.35, 1.06), CF(0, -0.6, 0), BLUE),
		P("Left Arm", V(1.06, 0.4, 1.06), CF(0, -0.6, 0), BLUE),
		P("Right Arm", V(1.06, 0.4, 1.06), CF(0, -0.6, 0), BLUE),
	}),
	Moves = MS.Build(MS.Standard({ Style = "Kicks", Power = 1.05, Speed = 0.95 }), {
		Special_Neutral = MS.Projectile({ Name = "Onda Celestial", Pose = "Beam", Damage = 14, KB = 30, Growth = 90, Angle = 35, Speed = 110, Lifetime = 1.1, Size = 6, Color = C(90, 200, 255), Startup = 0.6, Endlag = 0.4, Cooldown = 5, Pierce = true }),
		Special_Side = MS.Melee({ Name = "Embestida Dorada", Pose = "Haymaker", Damage = 10, KB = 22, Growth = 74, Angle = 35, Startup = 0.1, Active = 0.3, Dash = V(100, 5, 0), Cooldown = 2.2 }),
		Special_Up = MS.Recovery({ Name = "Teletransporte", NoHitbox = true, Velocity = V(0, 115, 0) }),
		Special_Down = MS.Melee({ Name = "Puño del Dragón", Pose = "DoubleUp", Damage = 13, KB = 30, Growth = 88, Angle = 80, Startup = 0.25, Active = 0.15, Size = V(7, 7, 6), Offset = V(2, 2, 0), Cooldown = 3 }),
	}),
}
