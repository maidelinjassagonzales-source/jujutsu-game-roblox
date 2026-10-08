-- Executor · "Ejecutor 7:3": golpes medidos al milímetro. Lento pero cada impacto pesa muchísimo.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part

return {
	Id = "Executor", DisplayName = "Ejecutor 7:3", Color = C(220, 200, 140),
	Weight = 104, WalkSpeed = 22, JumpPower = 60,
	Appearance = { Head = C(240, 210, 180), Torso = C(215, 200, 165), Arms = C(215, 200, 165), Legs = C(215, 200, 165) },
	Style = {
		P("Head", V(1.32, 0.3, 1.32), CF(0, 0.55, 0.02), C(235, 210, 120)),
		P("Head", V(1.32, 0.55, 0.25), CF(0, 0.3, 0.55), C(235, 210, 120)),
		P("Head", V(0.6, 0.4, 1.2), CF(-0.4, 0.45, 0), C(235, 210, 120)),
		P("Head", V(1.2, 0.25, 0.05), CF(0, 0.12, -0.63), C(20, 60, 40)),
		P("Torso", V(0.35, 1.4, 0.05), CF(0, 0.2, -0.53), C(230, 200, 60)),
		P("Torso", V(0.9, 0.5, 0.05), CF(0, 0.75, -0.53), C(40, 70, 120)),
		P("Right Arm", V(0.2, 0.6, 2.8), CF(0, -1.15, -1.5), C(230, 230, 230)),
	},
	Moves = MS.Build(MS.Standard({ Style = "Heavy", Power = 1.05, Speed = 1.05 }), {
		Special_Neutral = MS.Melee({ Name = "Ratio 7:3", Pose = "Slash", Damage = 16, KB = 34, Growth = 94, Angle = 38, Startup = 0.32, Active = 0.1, Size = V(6, 5, 6), Offset = V(4, 0, 0), Cooldown = 2.5 }),
		Special_Side = MS.Melee({ Name = "Horas Extra", Pose = "Haymaker", Damage = 10, KB = 22, Growth = 74, Angle = 36, Startup = 0.12, Active = 0.25, Dash = V(80, 6, 0), Cooldown = 2.4 }),
		Special_Up = MS.Recovery({ Name = "Salto Profesional" }),
		Special_Down = MS.Melee({ Name = "Colapso", Pose = "Slam", Damage = 12, KB = 28, Growth = 86, Angle = 60, Startup = 0.4, Active = 0.15, Size = V(18, 4, 6), Offset = V(0, -1, 0), Cooldown = 4 }),
	}),
}
