-- WeaponMaster · "Maestra de Armas": sin energía maldita, pura técnica con su bastón. Rapidísima y de alcance largo.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part

return {
	Id = "WeaponMaster", DisplayName = "Maestra de Armas", Color = C(90, 200, 120),
	Weight = 92, WalkSpeed = 26, JumpPower = 66,
	Appearance = { Head = C(235, 195, 165), Torso = C(30, 40, 35), Arms = C(30, 40, 35), Legs = C(30, 40, 35) },
	Style = {
		P("Head", V(1.32, 0.3, 1.32), CF(0, 0.55, 0.02), C(40, 90, 60)),
		P("Head", V(1.32, 0.6, 0.25), CF(0, 0.3, 0.55), C(40, 90, 60)),
		P("Head", V(0.4, 1.4, 0.4), CF(0, 0.1, 0.8), C(40, 90, 60)),
		P("Head", V(1.1, 0.25, 0.05), CF(0, 0.1, -0.63), C(20, 20, 20)),
		P("Right Arm", V(0.25, 8, 0.25), CF(0, -1, -0.6), C(120, 80, 50), nil, Enum.Material.Wood),
		P("Right Arm", V(0.1, 1, 0.5), CF(0, 3.4, -0.6), C(210, 210, 220), nil, Enum.Material.Metal),
	},
	Moves = MS.Build(MS.Standard({ Style = "Staff", Reach = 2.5, Power = 0.95, Speed = 0.9 }), {
		Special_Neutral = MS.Melee({ Name = "Lanza Maldita", Pose = "Thrust", Damage = 9, KB = 20, Growth = 70, Angle = 30, Startup = 0.18, Active = 0.1, Size = V(11, 3, 6), Offset = V(6, 0, 0), Cooldown = 1.6 }),
		Special_Side = MS.Melee({ Name = "Carga Imparable", Pose = "Thrust", Damage = 8, KB = 20, Growth = 68, Angle = 40, Startup = 0.08, Active = 0.3, Dash = V(95, 10, 0), Cooldown = 2.2 }),
		Special_Up = MS.Recovery({ Name = "Salto con Pértiga", Pose = "Rise", Velocity = V(20, 105, 0), Damage = 6 }),
		Special_Down = MS.Melee({ Name = "Barrido Giratorio", Pose = "Spin", Damage = 10, KB = 24, Growth = 78, Angle = 70, Startup = 0.22, Active = 0.15, Size = V(16, 3, 6), Offset = V(0, -2, 0), Cooldown = 2.8 }),
	}),
}
