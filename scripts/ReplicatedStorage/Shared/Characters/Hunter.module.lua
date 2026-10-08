-- Hunter · "Cazador sin Maldición": físico sobrehumano, cadena con espada. El más rápido en tierra.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part

return {
	Id = "Hunter", DisplayName = "Curseless Hunter", Color = C(70, 70, 75),
	Weight = 108, WalkSpeed = 27, JumpPower = 66,
	Appearance = { Head = C(225, 185, 150), Torso = C(20, 20, 22), Arms = C(225, 185, 150), Legs = C(170, 170, 175) },
	Style = A.Merge(A.SpikyHair(C(15, 15, 18), 0.25, { { -0.3, -0.2, -10 }, { 0.3, -0.2, 10 }, { 0, 0.2, 0 }, { -0.35, 0.3, -15 }, { 0.35, 0.3, 15 } }), {
		P("Head", V(0.05, 0.3, 0.04), CF(-0.2, -0.25, -0.63), C(170, 120, 110)),
		P("Right Arm", V(0.15, 0.3, 3.5), CF(0, -1.15, -1.9), C(80, 80, 90), nil, Enum.Material.Metal),
		P("Torso", V(2.06, 0.3, 1.06), CF(0, -0.85, 0), C(60, 60, 60)),
	}),
	Moves = MS.Build(MS.Standard({ Style = "Kicks", Power = 1.08, Speed = 0.85, KB = 1.05 }), {
		Special_Neutral = MS.Melee({ Name = "Infinite Chain", Pose = "Slash", Damage = 12, KB = 26, Growth = 86, Angle = 35, Startup = 0.2, Active = 0.1, Size = V(12, 3, 6), Offset = V(6.5, 0, 0), Cooldown = 2.2 }),
		Special_Side = MS.Melee({ Name = "Invisible Assault", Pose = "HighKick", Damage = 11, KB = 25, Growth = 80, Angle = 32, Startup = 0.08, Active = 0.28, Dash = V(115, 8, 0), Cooldown = 2.6 }),
		Special_Up = MS.Recovery({ Name = "Feline Leap", Velocity = V(12, 110, 0), Damage = 8 }),
		Special_Down = MS.Melee({ Name = "Hunter's Drop", Pose = "Slam", Damage = 15, KB = 32, Growth = 90, Angle = 75, Startup = 0.2, Active = 0.35, Dash = V(0, -120, 0), Size = V(10, 5, 6), Offset = V(0, -2, 0), Cooldown = 3 }),
	}),
}
