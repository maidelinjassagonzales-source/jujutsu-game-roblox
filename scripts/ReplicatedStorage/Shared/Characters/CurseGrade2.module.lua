-- CurseGrade2 · enemigo del modo historia (no jugable): maldición de grado 2 con cuernos que escupe energía.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part
local BONE = C(230, 220, 200)

return {
	Id = "CurseGrade2", DisplayName = "Maldición de Grado 2", Color = C(60, 120, 70), Playable = false,
	Weight = 95, WalkSpeed = 19, JumpPower = 56,
	Appearance = { Head = C(70, 110, 70), Torso = C(40, 80, 50), Arms = C(60, 100, 60), Legs = C(30, 60, 40) },
	Style = {
		P("Head", V(0.25, 0.8, 0.25), CF(-0.42, 0.85, 0) * CFrame.Angles(0, 0, math.rad(20)), BONE),
		P("Head", V(0.25, 0.8, 0.25), CF(0.42, 0.85, 0) * CFrame.Angles(0, 0, math.rad(-20)), BONE),
		P("Head", V(0.8, 0.15, 0.05), CF(0, -0.25, -0.63), C(150, 20, 20), nil, Enum.Material.Neon),
		P("Head", V(0.2, 0.12, 0.05), CF(-0.25, 0.12, -0.63), C(255, 40, 40), nil, Enum.Material.Neon),
		P("Head", V(0.2, 0.12, 0.05), CF(0.25, 0.12, -0.63), C(255, 40, 40), nil, Enum.Material.Neon),
	},
	Moves = MS.Build(MS.Standard({ Style = "Heavy", Power = 0.9, Speed = 1.1 }), {
		Special_Neutral = MS.Projectile({ Name = "Escupitajo Maldito", Damage = 7, KB = 16, Growth = 55, Angle = 35, Speed = 70, Lifetime = 1, Size = 3, Color = C(120, 255, 120), Cooldown = 2.5 }),
		Special_Side = MS.Melee({ Name = "Embestida", Damage = 9, KB = 20, Growth = 70, Angle = 35, Startup = 0.2, Active = 0.25, Dash = V(70, 6, 0), Cooldown = 3 }),
		Special_Up = MS.Recovery({}),
	}),
}
