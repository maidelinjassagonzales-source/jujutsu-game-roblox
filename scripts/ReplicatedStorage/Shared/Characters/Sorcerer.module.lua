-- Sorcerer: hechicero de rango (arquetipo "infinito": atrae, repele y borra).
local Accessories = require(script.Parent.Parent:WaitForChild("Accessories"))

local function hb(sx, sy, ox, oy)
	return { Size = Vector3.new(sx, sy, 6), Offset = Vector3.new(ox, oy, 0) }
end

return {
	Id = "Sorcerer",
	DisplayName = "Hechicero del Infinito",
	Color = Color3.fromRGB(110, 170, 255),
	Weight = 92,
	WalkSpeed = 22,
	JumpPower = 65,
	Appearance = {
		Head = Color3.fromRGB(245, 220, 200),
		Torso = Color3.fromRGB(20, 20, 30),
		Arms = Color3.fromRGB(20, 20, 30),
		Legs = Color3.fromRGB(20, 20, 30),
	},
	-- Pelo blanco alto + venda en los ojos + cuello alto
	Style = Accessories.Merge(Accessories.SpikyHair(Color3.fromRGB(240, 240, 248), 0.6), {
		{ Body = "Head", Size = Vector3.new(1.36, 0.28, 1.36), Offset = CFrame.new(0, 0.08, 0), Color = Color3.fromRGB(15, 15, 20) },
		{ Body = "Torso", Size = Vector3.new(1.5, 0.6, 1.1), Offset = CFrame.new(0, 1.15, 0), Color = Color3.fromRGB(15, 15, 25) },
	}),

	Moves = {
		Light_Neutral = { Damage = 3, BaseKnockback = 8, KnockbackGrowth = 30, Angle = 50, Startup = 0.06, Active = 0.08, Endlag = 0.12, Cooldown = 0, Hitbox = hb(5, 5, 3, 0) },
		Light_Side = { Damage = 6, BaseKnockback = 14, KnockbackGrowth = 70, Angle = 35, Startup = 0.08, Active = 0.08, Endlag = 0.2, Cooldown = 0, Hitbox = hb(6, 4, 3.5, 0) },
		Light_Up = { Damage = 6, BaseKnockback = 15, KnockbackGrowth = 85, Angle = 90, Startup = 0.07, Active = 0.1, Endlag = 0.2, Cooldown = 0, Hitbox = hb(6, 5, 1, 3) },
		Light_Down = { Damage = 5, BaseKnockback = 10, KnockbackGrowth = 55, Angle = 15, Startup = 0.06, Active = 0.08, Endlag = 0.18, Cooldown = 0, Hitbox = hb(7, 2.5, 3, -2) },
		AirLight_Down = { Damage = 8, BaseKnockback = 18, KnockbackGrowth = 80, Angle = -65, Startup = 0.14, Active = 0.12, Endlag = 0.25, Cooldown = 0, Hitbox = hb(5, 5, 0, -3) },

		Heavy_Neutral = { Damage = 15, BaseKnockback = 30, KnockbackGrowth = 95, Angle = 38, Startup = 0.35, Active = 0.1, Endlag = 0.4, Cooldown = 0.6, Hitbox = hb(7, 5, 4, 0) },
		Heavy_Up = { Damage = 14, BaseKnockback = 30, KnockbackGrowth = 95, Angle = 88, Startup = 0.3, Active = 0.12, Endlag = 0.4, Cooldown = 0.6, Hitbox = hb(7, 7, 1, 4) },
		Heavy_Down = { Damage = 12, BaseKnockback = 26, KnockbackGrowth = 90, Angle = 28, Startup = 0.3, Active = 0.1, Endlag = 0.4, Cooldown = 0.6, Hitbox = hb(14, 3, 0, -2) },

		Special_Neutral = { Name = "Azul: Atracción", Pose = "Palms", -- "Azul": proyectil que ATRAE (ángulo > 90 = hacia el lanzador)
			Damage = 5, BaseKnockback = 18, KnockbackGrowth = 30, Angle = 160,
			Startup = 0.2, Active = 0, Endlag = 0.3, Cooldown = 1.5,
			Projectile = { Speed = 70, Lifetime = 0.8, Size = Vector3.new(4, 4, 4), Color = Color3.fromRGB(60, 140, 255), Pierce = true },
		},
		Special_Side = { Name = "Rojo: Repulsión", Pose = "Palms", -- "Rojo": proyectil que REPELE
			Damage = 13, BaseKnockback = 35, KnockbackGrowth = 92, Angle = 35,
			Startup = 0.4, Active = 0, Endlag = 0.4, Cooldown = 4,
			Projectile = { Speed = 90, Lifetime = 1, Size = Vector3.new(5, 5, 5), Color = Color3.fromRGB(255, 60, 60), Pierce = false },
		},
		Special_Up = { Name = "Paso Infinito", Pose = "Rise", -- Recuperación sin hitbox
			Startup = 0.05, Active = 0, Endlag = 0.25, Cooldown = 0.5,
			SelfVelocity = Vector3.new(0, 100, 0), OncePerAir = true,
		},
		Special_Down = { Name = "Púrpura Hueco", Pose = "Beam", -- "Púrpura": lento, enorme, cooldown largo
			Damage = 22, BaseKnockback = 45, KnockbackGrowth = 95, Angle = 40,
			Startup = 0.9, Active = 0, Endlag = 0.6, Cooldown = 15,
			Projectile = { Speed = 45, Lifetime = 2.5, Size = Vector3.new(9, 9, 9), Color = Color3.fromRGB(170, 60, 255), Pierce = true },
		},
	},
}
