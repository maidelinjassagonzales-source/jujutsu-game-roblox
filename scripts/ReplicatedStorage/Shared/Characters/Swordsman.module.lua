-- Swordsman · "Espadachín Maldito": katana + espíritu maldito que le protege. Alcance largo.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new

return {
	Id = "Swordsman", DisplayName = "Espadachín Maldito", Color = C(230, 230, 240),
	Weight = 98, WalkSpeed = 23, JumpPower = 63,
	Appearance = { Head = C(240, 210, 185), Torso = C(235, 235, 240), Arms = C(235, 235, 240), Legs = C(30, 30, 35) },
	Style = A.Merge(A.SpikyHair(C(25, 25, 30), 0.35), A.Blade("Right Arm", 4, C(220, 225, 235), C(150, 30, 40))),
	Moves = MS.Build(MS.Standard({ Style = "Sword", Reach = 1.5 }), {
		Special_Neutral = MS.Projectile({ Name = "Tajo Maldito", Pose = "Slash", Damage = 7, KB = 14, Growth = 45, Angle = 30, Speed = 120, Lifetime = 0.6, Size = 3, Color = C(240, 240, 255), Pierce = true, Cooldown = 1.2, Startup = 0.15 }),
		Special_Side = MS.Melee({ Name = "Estocada Relámpago", Pose = "Thrust", Damage = 10, KB = 22, Growth = 72, Angle = 35, Startup = 0.12, Active = 0.3, Dash = V(90, 6, 0), Cooldown = 2.5 }),
		Special_Up = MS.Recovery({ Name = "Corte Ascendente", Pose = "SlashUp", Velocity = V(15, 96, 0) }),
		Special_Down = MS.Projectile({ Name = "¡Ven, Reina Maldita!", Pose = "Palms", Damage = 18, KB = 40, Growth = 92, Angle = 45, Speed = 40, Lifetime = 2.2, Size = 8, Color = C(140, 60, 200), Pierce = true, Startup = 0.8, Endlag = 0.5, Cooldown = 14 }),
	}),
}
