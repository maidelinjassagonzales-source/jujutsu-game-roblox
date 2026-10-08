-- FlameAlchemist · "Alquimista de Fuego" (Grieta Dimensional): chasquea los dedos y todo arde.
-- Personaje de distancia: proyectiles de fuego y control de zona.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part
local BLUE, WHITE = C(35, 55, 120), C(245, 245, 245)

return {
	Id = "FlameAlchemist", DisplayName = "Flame Alchemist", Color = C(255, 120, 30),
	Weight = 96, WalkSpeed = 23, JumpPower = 63,
	Appearance = { Head = C(240, 205, 175), Torso = BLUE, Arms = BLUE, Legs = BLUE },
	Style = A.Merge(A.SpikyHair(C(25, 25, 30), 0.2), {
		-- guantes blancos con el círculo de transmutación
		P("Left Arm", V(1.06, 0.7, 1.06), CF(0, -0.68, 0), WHITE),
		P("Right Arm", V(1.06, 0.7, 1.06), CF(0, -0.68, 0), WHITE),
		P("Right Arm", V(0.05, 0.5, 0.5), CF(-0.54, -0.68, 0), C(220, 40, 40)),
		-- chaqueta militar: hombreras doradas y cinturón
		P("Torso", V(0.6, 0.15, 1.1), CF(-0.75, 0.98, 0), C(230, 190, 60)),
		P("Torso", V(0.6, 0.15, 1.1), CF(0.75, 0.98, 0), C(230, 190, 60)),
		P("Torso", V(2.06, 0.25, 1.06), CF(0, -0.7, 0), C(30, 30, 35)),
	}),
	Moves = MS.Build(MS.Standard({ Style = "Fists", Power = 0.95, Speed = 0.95 }), {
		Special_Neutral = MS.Projectile({ Name = "Fire Snap", Pose = "Palms", Damage = 8, KB = 16, Growth = 55, Angle = 40, Speed = 95, Lifetime = 0.9, Size = 4, Color = C(255, 120, 30), Startup = 0.18, Cooldown = 1.2 }),
		Special_Side = MS.Projectile({ Name = "Blaze", Pose = "Beam", Damage = 13, KB = 28, Growth = 85, Angle = 35, Speed = 70, Lifetime = 1.2, Size = 7, Color = C(255, 70, 20), Pierce = true, Startup = 0.4, Endlag = 0.4, Cooldown = 3.5 }),
		Special_Up = MS.Recovery({ Name = "Rising Explosion", Pose = "Rise", Velocity = V(10, 100, 0), Damage = 8 }),
		Special_Down = MS.Melee({ Name = "Fire Pillar", Pose = "Palms", Damage = 12, KB = 28, Growth = 84, Angle = 88, Startup = 0.3, Active = 0.3, Size = V(6, 12, 6), Offset = V(4, 3, 0), Cooldown = 3 }),
	}),
}
