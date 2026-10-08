-- SoulReaper · "Segador de Almas" (Grieta Dimensional): espadón negro enorme y ondas de energía.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part
local BLADE = C(25, 25, 30)

return {
	Id = "SoulReaper", DisplayName = "Soul Reaper", Color = C(255, 120, 40),
	Weight = 102, WalkSpeed = 24, JumpPower = 64,
	Appearance = { Head = C(235, 195, 160), Torso = C(20, 20, 25), Arms = C(20, 20, 25), Legs = C(20, 20, 25) },
	Style = A.Merge(A.SpikyHair(C(255, 130, 40), 0.45), A.Blade("Right Arm", 5, BLADE, C(230, 230, 235)), {
		P("Right Arm", V(0.16, 0.9, 5), CF(0, -1.15, -2.9), BLADE, nil, Enum.Material.Metal), -- hoja ancha (cuchilla)
		P("Torso", V(2.06, 0.3, 1.06), CF(0, -0.55, 0), C(240, 240, 240)), -- cinturón blanco
		P("Torso", V(0.35, 2.05, 1.08), CF(0.6, 0, 0) * CFrame.Angles(0, 0, math.rad(25)), C(140, 30, 30)), -- cinta de la vaina
	}),
	Moves = MS.Build(MS.Standard({ Style = "Sword", Reach = 2, Power = 1.05, Speed = 1.05 }), {
		Special_Neutral = MS.Projectile({ Name = "Lunar Fang", Pose = "SlashHeavy", Damage = 12, KB = 24, Growth = 78, Angle = 35, Speed = 110, Lifetime = 0.8, Size = 6, Color = C(120, 20, 30), Pierce = true, Startup = 0.3, Cooldown = 2.2 }),
		Special_Side = MS.Melee({ Name = "Flash Step", Pose = "Thrust", Damage = 10, KB = 22, Growth = 72, Angle = 35, Startup = 0.1, Active = 0.25, Dash = V(105, 4, 0), Cooldown = 2.2 }),
		Special_Up = MS.Recovery({ Name = "Celestial Cut", Pose = "SlashUp", Velocity = V(12, 100, 0), Damage = 8 }),
		Special_Down = MS.Melee({ Name = "Judgment Slash", Pose = "Slam", Damage = 14, KB = 30, Growth = 86, Angle = 75, Startup = 0.3, Active = 0.2, Dash = V(0, -100, 0), Size = V(10, 5, 6), Offset = V(1, -2, 0), Cooldown = 3 }),
	}),
}
