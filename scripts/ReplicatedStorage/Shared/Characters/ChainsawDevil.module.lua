-- ChainsawDevil · "Diablo Motosierra" (Grieta Dimensional): sierras en la cabeza y en los brazos.
-- Lento pero brutal: golpes que pegan varias veces.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part
local STEEL, ORANGE = C(170, 170, 175), C(235, 110, 30)

return {
	Id = "ChainsawDevil", DisplayName = "Chainsaw Devil", Color = C(235, 110, 30),
	Weight = 110, WalkSpeed = 22, JumpPower = 60,
	Appearance = { Head = C(235, 190, 155), Torso = C(240, 240, 240), Arms = C(235, 190, 155), Legs = C(30, 30, 40) },
	Style = A.Merge(A.SpikyHair(C(240, 200, 90), 0.3), {
		-- sierra de la cabeza
		P("Head", V(1.2, 0.9, 0.9), CF(0, 0.1, -0.45), ORANGE),
		P("Head", V(0.2, 0.6, 2.2), CF(0, 0.15, -1.6), STEEL, nil, Enum.Material.Metal),
		-- sierras de los brazos
		P("Left Arm", V(1.05, 0.7, 1.05), CF(0, -0.7, 0), ORANGE),
		P("Left Arm", V(0.2, 0.5, 2.6), CF(0, -1.1, -1.5), STEEL, nil, Enum.Material.Metal),
		P("Right Arm", V(1.05, 0.7, 1.05), CF(0, -0.7, 0), ORANGE),
		P("Right Arm", V(0.2, 0.5, 2.6), CF(0, -1.1, -1.5), STEEL, nil, Enum.Material.Metal),
		P("Torso", V(1.2, 0.25, 1.08), CF(0, 0.75, 0), C(30, 30, 40)), -- corbata
	}),
	Moves = MS.Build(MS.Standard({ Style = "Heavy", Reach = 1.2, Power = 1.1, Speed = 1.05 }), {
		Special_Neutral = MS.Melee({ Name = "Spinning Saw", Pose = "Spin", Damage = 5, KB = 8, Growth = 20, Angle = 60, Startup = 0.15, Active = 0.2, Size = V(9, 6, 6), Offset = V(1.5, 0, 0), Cooldown = 2,
			FollowUp = { Delay = 0.25, Damage = 9, BaseKnockback = 26, KnockbackGrowth = 82, Angle = 40 } }),
		Special_Side = MS.Melee({ Name = "Jagged Rush", Pose = "Haymaker", Damage = 12, KB = 26, Growth = 80, Angle = 30, Startup = 0.18, Active = 0.3, Dash = V(90, 6, 0), Cooldown = 2.6 }),
		Special_Up = MS.Recovery({ Name = "Rising Chain", Pose = "Rise", Velocity = V(8, 96, 0), Damage = 7 }),
		Special_Down = MS.Melee({ Name = "Seismic Saw", Pose = "Slam", Damage = 15, KB = 32, Growth = 88, Angle = 80, Startup = 0.3, Active = 0.25, Dash = V(0, -105, 0), Size = V(12, 5, 6), Offset = V(0, -2, 0), Cooldown = 3.2 }),
	}),
}
