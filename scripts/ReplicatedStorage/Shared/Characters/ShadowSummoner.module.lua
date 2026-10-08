-- ShadowSummoner: invocador que controla el espacio con sombras (arquetipo "shikigami").
local Accessories = require(script.Parent.Parent:WaitForChild("Accessories"))

local function hb(sx, sy, ox, oy)
	return { Size = Vector3.new(sx, sy, 6), Offset = Vector3.new(ox, oy, 0) }
end

return {
	Id = "ShadowSummoner",
	DisplayName = "Shadow Summoner",
	Color = Color3.fromRGB(90, 90, 170),
	Weight = 98,
	WalkSpeed = 23,
	JumpPower = 63,
	Appearance = {
		Head = Color3.fromRGB(230, 190, 160),
		Torso = Color3.fromRGB(25, 25, 45),
		Arms = Color3.fromRGB(25, 25, 45),
		Legs = Color3.fromRGB(20, 20, 35),
	},
	-- Pelo negro muy puntiagudo + cuello alto del uniforme
	Style = Accessories.Merge(Accessories.SpikyHair(Color3.fromRGB(20, 20, 30), 0.55, {
		{ -0.45, -0.3, -30 }, { 0, -0.35, 0 }, { 0.45, -0.3, 30 }, { -0.45, 0.1, -35 },
		{ 0.45, 0.1, 35 }, { -0.2, 0.4, -20 }, { 0.2, 0.4, 20 }, { 0, 0.1, 0 },
	}), {
		{ Body = "Torso", Size = Vector3.new(1.5, 0.5, 1.1), Offset = CFrame.new(0, 1.1, 0), Color = Color3.fromRGB(20, 20, 40) },
	}),

	Moves = {
		Light_Neutral = { Damage = 3, BaseKnockback = 9, KnockbackGrowth = 30, Angle = 45, Startup = 0.05, Active = 0.08, Endlag = 0.12, Cooldown = 0, Hitbox = hb(5, 5, 3, 0) },
		Light_Side = { Damage = 6, BaseKnockback = 13, KnockbackGrowth = 72, Angle = 36, Startup = 0.08, Active = 0.08, Endlag = 0.2, Cooldown = 0, Hitbox = hb(6, 4, 3.5, 0) },
		Light_Up = { Damage = 6, BaseKnockback = 15, KnockbackGrowth = 88, Angle = 88, Startup = 0.07, Active = 0.1, Endlag = 0.2, Cooldown = 0, Hitbox = hb(6, 5, 1.5, 3) },
		Light_Down = { Damage = 5, BaseKnockback = 11, KnockbackGrowth = 58, Angle = 18, Startup = 0.06, Active = 0.08, Endlag = 0.18, Cooldown = 0, Hitbox = hb(7, 2.5, 3, -2) },
		AirLight_Down = { Damage = 9, BaseKnockback = 19, KnockbackGrowth = 82, Angle = -68, Startup = 0.15, Active = 0.12, Endlag = 0.25, Cooldown = 0, Hitbox = hb(5, 5, 0, -3) },

		Heavy_Neutral = { Damage = 15, BaseKnockback = 30, KnockbackGrowth = 96, Angle = 40, Startup = 0.35, Active = 0.1, Endlag = 0.4, Cooldown = 0.6, Hitbox = hb(7, 5, 4, 0) },
		Heavy_Up = { Damage = 14, BaseKnockback = 31, KnockbackGrowth = 94, Angle = 86, Startup = 0.3, Active = 0.12, Endlag = 0.4, Cooldown = 0.6, Hitbox = hb(7, 7, 1, 4) },
		Heavy_Down = { Damage = 13, BaseKnockback = 27, KnockbackGrowth = 92, Angle = 25, Startup = 0.3, Active = 0.1, Endlag = 0.4, Cooldown = 0.6, Hitbox = hb(14, 3, 0, -2) },

		Special_Neutral = { Name = "Divine Dogs", Pose = "Palms", -- "Perros Divinos": proyectil que embiste
			Damage = 9, BaseKnockback = 20, KnockbackGrowth = 60, Angle = 40,
			Startup = 0.25, Active = 0, Endlag = 0.3, Cooldown = 2,
			Projectile = { Speed = 60, Lifetime = 1, Size = Vector3.new(4, 4, 4), Color = Color3.fromRGB(30, 30, 50), Pierce = false },
		},
		Special_Side = { Name = "Nue: Dive", Pose = "Thrust", -- "Nue": picado en diagonal
			Damage = 10, BaseKnockback = 22, KnockbackGrowth = 70, Angle = 55,
			Startup = 0.12, Active = 0.3, Endlag = 0.3, Cooldown = 2.5, Hitbox = hb(6, 5, 3, 0),
			SelfVelocity = Vector3.new(70, 30, 0),
		},
		Special_Up = { Name = "Nue: Ascent", Pose = "Rise", -- Recuperación: alzarse con Nue
			Damage = 6, BaseKnockback = 18, KnockbackGrowth = 55, Angle = 82,
			Startup = 0.05, Active = 0.25, Endlag = 0.3, Cooldown = 0.5, Hitbox = hb(6, 6, 0, 2),
			SelfVelocity = Vector3.new(15, 95, 0), OncePerAir = true,
		},
		Special_Down = { Name = "Sea of Shadows", Pose = "Slam", -- "Mar de Sombras": barrido amplio que levanta
			Damage = 8, BaseKnockback = 24, KnockbackGrowth = 65, Angle = 80,
			Startup = 0.25, Active = 0.2, Endlag = 0.35, Cooldown = 3, Hitbox = hb(16, 3, 0, -2),
		},
	},
}
