-- CurseMinion · enemigo del modo historia (no jugable): maldición menor de un solo ojo.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part

return {
	Id = "CurseMinion", DisplayName = "Maldición Menor", Color = C(120, 90, 150), Playable = false,
	Weight = 85, WalkSpeed = 17, JumpPower = 52,
	Appearance = { Head = C(120, 100, 140), Torso = C(80, 60, 100), Arms = C(100, 80, 120), Legs = C(60, 45, 80) },
	Style = {
		P("Head", V(0.85, 0.85, 0.85), CF(0, 0.05, -0.4), C(240, 240, 240), "Ball"),
		P("Head", V(0.35, 0.35, 0.35), CF(0, 0.05, -0.8), C(20, 10, 30), "Ball"),
		P("Torso", V(0.4, 0.9, 0.4), CF(-0.5, 0.6, 0.6) * CFrame.Angles(math.rad(30), 0, 0), C(60, 40, 80)),
		P("Torso", V(0.4, 0.9, 0.4), CF(0.5, 0.6, 0.6) * CFrame.Angles(math.rad(30), 0, 0), C(60, 40, 80)),
	},
	Moves = MS.Build(MS.Standard({ Style = "Fists", Power = 0.7, Speed = 1.3, KB = 0.9 }), {
		Special_Neutral = MS.Melee({ Name = "Mordisco", Pose = "Jab", Damage = 5, KB = 14, Growth = 50, Angle = 40, Startup = 0.3, Cooldown = 2 }),
		Special_Up = MS.Recovery({ Velocity = V(10, 90, 0) }),
	}),
}
