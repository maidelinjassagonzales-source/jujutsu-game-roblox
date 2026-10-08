-- YoungSorcerer · "Hechicero Prodigio" (EXCLUSIVO): la versión joven del más fuerte. Azul, Rojo y Púrpura.
-- Mismo poder que el resto: lo exclusivo es el personaje, no la ventaja.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part

return {
	Id = "YoungSorcerer", DisplayName = "Prodigy Sorcerer", Color = C(120, 200, 255),
	Weight = 100, WalkSpeed = 24, JumpPower = 66,
	Appearance = { Head = C(245, 225, 210), Torso = C(20, 20, 25), Arms = C(245, 225, 210), Legs = C(170, 170, 180) },
	Style = A.Merge(A.SpikyHair(C(245, 245, 250), 0.4), {
		P("Head", V(1.1, 0.22, 0.05), CF(0, 0.1, -0.63), C(10, 10, 10)),
		P("Torso", V(2.06, 0.3, 1.06), CF(0, -0.85, 0), C(30, 40, 70)),
	}),
	Moves = MS.Build(MS.Standard({ Style = "Kicks", Power = 1.02, Speed = 0.95 }), {
		Special_Neutral = MS.Projectile({ Name = "Blue: Attraction", Damage = 6, KB = 20, Growth = 35, Angle = 160, Speed = 75, Lifetime = 0.8, Size = 4, Color = C(60, 140, 255), Pierce = true, Cooldown = 1.4 }),
		Special_Side = MS.Projectile({ Name = "Red: Repulsion", Damage = 13, KB = 36, Growth = 92, Angle = 35, Speed = 95, Lifetime = 1, Size = 5, Color = C(255, 60, 60), Startup = 0.38, Cooldown = 4 }),
		Special_Up = MS.Recovery({ Name = "Infinite Step", NoHitbox = true, Velocity = V(0, 108, 0) }),
		Special_Down = MS.Projectile({ Name = "Hollow Purple", Damage = 22, KB = 45, Growth = 95, Angle = 40, Speed = 48, Lifetime = 2.4, Size = 9, Color = C(170, 60, 255), Pierce = true, Startup = 0.85, Endlag = 0.6, Cooldown = 15 }),
	}),
}
