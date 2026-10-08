-- BaldHero · "Héroe Calvo" (Grieta Dimensional): solo puñetazos... pero qué puñetazos.
-- Pocos trucos, muchísimo knockback.
local Shared = script.Parent.Parent
local MS = require(Shared:WaitForChild("MoveSets"))
local A = require(Shared:WaitForChild("Accessories"))
local C, V, CF = Color3.fromRGB, Vector3.new, CFrame.new
local P = A.Part
local RED, YELLOW, WHITE = C(200, 30, 35), C(250, 210, 40), C(245, 245, 245)

return {
	Id = "BaldHero", DisplayName = "Bald Hero", Color = C(250, 210, 40),
	Weight = 104, WalkSpeed = 24, JumpPower = 64,
	Appearance = { Head = C(245, 205, 170), Torso = YELLOW, Arms = YELLOW, Legs = YELLOW },
	Style = {
		-- guantes y botas rojos
		P("Left Arm", V(1.06, 0.8, 1.06), CF(0, -0.62, 0), RED),
		P("Right Arm", V(1.06, 0.8, 1.06), CF(0, -0.62, 0), RED),
		P("Left Leg", V(1.06, 0.7, 1.06), CF(0, -0.68, 0), RED),
		P("Right Leg", V(1.06, 0.7, 1.06), CF(0, -0.68, 0), RED),
		-- cinturón negro y capa blanca
		P("Torso", V(2.06, 0.25, 1.06), CF(0, -0.75, 0), C(30, 30, 30)),
		P("Torso", V(2, 2.8, 0.1), CF(0, -0.45, 0.58), WHITE),
		P("Torso", V(1.6, 0.3, 1.1), CF(0, 0.95, 0.05), WHITE), -- cuello de la capa
	},
	Moves = MS.Build(MS.Standard({ Style = "Fists", Power = 1.1, KB = 1.12 }), {
		Special_Neutral = MS.Melee({ Name = "Normal Punch", Pose = "Haymaker", Damage = 14, KB = 34, Growth = 95, Angle = 38, Startup = 0.45, Active = 0.1, Endlag = 0.45, Size = V(7, 5, 6), Offset = V(4, 0, 0), Cooldown = 3 }),
		Special_Side = MS.Melee({ Name = "Consecutive Normal Punches", Pose = "Jab", Damage = 4, KB = 6, Growth = 15, Angle = 40, Startup = 0.12, Active = 0.3, Size = V(7, 5, 6), Offset = V(4, 0, 0), Cooldown = 2.2,
			FollowUp = { Delay = 0.3, Damage = 8, BaseKnockback = 24, KnockbackGrowth = 80, Angle = 38 } }),
		Special_Up = MS.Recovery({ Name = "Normal Jump", Pose = "Rise", Velocity = V(10, 110, 0), Damage = 9, KB = 24 }),
		Special_Down = MS.Melee({ Name = "Normal Stomp", Pose = "Stomp", Damage = 13, KB = 30, Growth = 86, Angle = 80, Startup = 0.25, Active = 0.2, Dash = V(0, -110, 0), Size = V(11, 5, 6), Offset = V(0, -2, 0), Cooldown = 3 }),
	}),
}
