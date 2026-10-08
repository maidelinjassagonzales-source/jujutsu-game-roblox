-- Gambler · "Apostador Afortunado" (MÍTICO): todo es una apuesta. Su Jackpot es devastador... cada mucho tiempo.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part

return {
	Id = "Gambler", DisplayName = "Apostador Afortunado", Color = C(80, 200, 120),
	Weight = 104, WalkSpeed = 24, JumpPower = 63,
	Appearance = { Head = C(235, 200, 170), Torso = C(40, 60, 50), Arms = C(40, 60, 50), Legs = C(30, 30, 35) },
	Style = A.Merge(A.SpikyHair(C(200, 200, 205), 0.3, { { -0.4, 0.3, -20 }, { 0, 0.4, 0 }, { 0.4, 0.3, 20 }, { -0.2, 0.55, -10 }, { 0.2, 0.55, 10 } }), {
		P("Torso", V(2.1, 0.5, 1.15), CF(0, 0.95, 0), C(225, 225, 225)),
		P("Head", V(0.15, 0.15, 0.15), CF(-0.66, -0.1, 0), C(230, 200, 60), "Ball", Enum.Material.Metal),
	}),
	Moves = MS.Build(MS.Standard({ Style = "Fists", Power = 1.05, Speed = 0.95 }), {
		Special_Neutral = MS.Melee({ Name = "Doble o Nada", Pose = "Jab", Damage = 10, KB = 24, Growth = 78, Angle = 38, Startup = 0.18, Active = 0.12, Size = V(7, 5, 6), Offset = V(4, 0, 0), Cooldown = 1.8,
			FollowUp = { Delay = 0.3, Damage = 5, BaseKnockback = 20, KnockbackGrowth = 60, Angle = 45 } }),
		Special_Side = MS.Projectile({ Name = "Puertas Corredizas", Damage = 7, KB = 16, Growth = 55, Angle = 30, Speed = 90, Lifetime = 0.9, Size = 3, Color = C(120, 255, 140), Cooldown = 1.4 }),
		Special_Up = MS.Recovery({ Name = "Racha Ganadora" }),
		Special_Down = MS.Melee({ Name = "¡JACKPOT!", Pose = "DoubleUp", Damage = 18, KB = 38, Growth = 94, Angle = 60, Startup = 0.5, Active = 0.2, Size = V(16, 6, 6), Offset = V(0, 0, 0), Cooldown = 10 }),
	}),
}
