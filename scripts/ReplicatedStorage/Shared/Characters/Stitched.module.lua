-- Stitched · "Alma Cosida": remodela su cuerpo; brazos que se estiran y púas del alma.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part
local STITCH = C(30, 30, 30)

return {
	Id = "Stitched", DisplayName = "Alma Cosida", Color = C(140, 170, 200),
	Weight = 96, WalkSpeed = 24, JumpPower = 64,
	Appearance = { Head = C(220, 215, 215), Torso = C(25, 25, 35), Arms = C(220, 215, 215), Legs = C(30, 35, 50) },
	Style = {
		P("Head", V(1.32, 0.3, 1.32), CF(0, 0.55, 0.02), C(150, 170, 200)),
		P("Head", V(1.3, 2.2, 0.3), CF(0, -0.4, 0.62), C(150, 170, 200)),
		P("Head", V(0.6, 0.05, 0.04), CF(0, 0.05, -0.63), STITCH),
		P("Head", V(0.05, 0.5, 0.04), CF(0.25, -0.1, -0.63), STITCH),
		P("Left Arm", V(1.04, 0.06, 1.04), CF(0, 0.3, 0), STITCH),
		P("Right Arm", V(1.04, 0.06, 1.04), CF(0, -0.3, 0), STITCH),
		P("Torso", V(0.06, 1.6, 1.04), CF(-0.6, 0, 0), STITCH),
	},
	Moves = MS.Build(MS.Standard({ Style = "Fists", Reach = 1 }), {
		Special_Neutral = MS.Melee({ Name = "Transfiguración: Brazo Largo", Pose = "Jab", Damage = 11, KB = 24, Growth = 80, Angle = 35, Startup = 0.22, Active = 0.12, Size = V(14, 3, 6), Offset = V(7.5, 0, 0), Cooldown = 2 }),
		Special_Side = MS.Projectile({ Name = "Alma Disparada", Pose = "Palms", Damage = 8, KB = 18, Growth = 60, Angle = 30, Speed = 95, Lifetime = 0.8, Size = 3, Color = C(150, 170, 210), Cooldown = 1.6 }),
		Special_Up = MS.Recovery({ Name = "Alas Remodeladas", Velocity = V(10, 100, 0) }),
		Special_Down = MS.Melee({ Name = "Púas del Alma", Pose = "Spin", Damage = 12, KB = 28, Growth = 84, Angle = 80, Startup = 0.3, Active = 0.2, Size = V(12, 6, 6), Offset = V(0, 0, 0), Cooldown = 3.5 }),
	}),
}
