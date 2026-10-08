-- CurseMaster · "Maestro de Maldiciones": invoca maldiciones absorbidas. Zoner con el ataque más grande del juego.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part

return {
	Id = "CurseMaster", DisplayName = "Curse Master", Color = C(120, 90, 60),
	Weight = 102, WalkSpeed = 22, JumpPower = 62,
	Appearance = { Head = C(235, 205, 175), Torso = C(45, 40, 35), Arms = C(45, 40, 35), Legs = C(45, 40, 35) },
	Style = {
		P("Head", V(1.32, 0.3, 1.32), CF(0, 0.55, 0.02), C(15, 15, 20)),
		P("Head", V(0.6, 0.6, 0.6), CF(0, 0.75, 0.45), C(15, 15, 20), "Ball"),
		P("Head", V(0.15, 0.8, 0.15), CF(-0.5, 0.1, -0.6), C(15, 15, 20)),
		P("Head", V(0.7, 0.05, 0.04), CF(0, 0.42, -0.63), C(30, 30, 30)),
		P("Torso", V(0.4, 2.3, 1.08), CF(0.3, 0, 0) * CFrame.Angles(0, 0, math.rad(30)), C(200, 140, 60)),
	},
	Moves = MS.Build(MS.Standard({ Style = "Kicks" }), {
		Special_Neutral = MS.Projectile({ Name = "Summoned Curse", Damage = 9, KB = 20, Growth = 65, Angle = 35, Speed = 70, Lifetime = 1.2, Size = 5, Color = C(90, 60, 120), Cooldown = 1.8 }),
		Special_Side = MS.Projectile({ Name = "Cursed Swarm", Damage = 6, KB = 14, Growth = 45, Angle = 30, Speed = 120, Lifetime = 0.8, Size = 3, Color = C(60, 60, 80), Pierce = true, Cooldown = 1.3, Startup = 0.15 }),
		Special_Up = MS.Recovery({ Name = "Cursed Mount", Velocity = V(10, 100, 0) }),
		Special_Down = MS.Projectile({ Name = "Cursed Vortex", Damage = 20, KB = 44, Growth = 94, Angle = 45, Speed = 35, Lifetime = 3, Size = 10, Color = C(40, 20, 60), Pierce = true, Startup = 1, Endlag = 0.6, Cooldown = 16 }),
	}),
}
