-- Brawler: luchador cuerpo a cuerpo rápido (arquetipo "puños malditos").
-- Tiempos en segundos. Hitbox.Offset = (adelante, arriba, 0) relativo al personaje.
-- Angle: 0 = horizontal hacia delante, 90 = vertical, negativo = spike hacia abajo.
local Accessories = require(script.Parent.Parent:WaitForChild("Accessories"))

local function hb(sx, sy, ox, oy)
	return { Size = Vector3.new(sx, sy, 6), Offset = Vector3.new(ox, oy, 0) }
end

return {
	Id = "Brawler",
	DisplayName = "Brawler Maldito",
	Color = Color3.fromRGB(255, 110, 140),
	Weight = 100,
	WalkSpeed = 24,
	JumpPower = 62,
	-- Apariencia base (colores R6). Sustitúyelo por un modelo R6 propio cuando tengas el arte.
	Appearance = {
		Head = Color3.fromRGB(234, 184, 146),
		Torso = Color3.fromRGB(30, 30, 60),
		Arms = Color3.fromRGB(30, 30, 60),
		Legs = Color3.fromRGB(25, 25, 50),
	},
	-- Pelo de pinchos rosa + capucha/bufanda roja
	Style = Accessories.Merge(Accessories.SpikyHair(Color3.fromRGB(235, 150, 170), 0.45), {
		{ Body = "Torso", Size = Vector3.new(2.1, 0.55, 1.15), Offset = CFrame.new(0, 0.95, 0), Color = Color3.fromRGB(170, 30, 40) },
		{ Body = "Torso", Size = Vector3.new(1.6, 0.9, 0.35), Offset = CFrame.new(0, 0.7, 0.62), Color = Color3.fromRGB(150, 25, 35) },
	}),

	Moves = {
		-- Ataques ligeros (clic / J)
		Light_Neutral = { Damage = 3, BaseKnockback = 10, KnockbackGrowth = 30, Angle = 45, Startup = 0.05, Active = 0.08, Endlag = 0.12, Cooldown = 0, Hitbox = hb(5, 5, 3, 0) },
		Light_Side = { Damage = 7, BaseKnockback = 14, KnockbackGrowth = 75, Angle = 38, Startup = 0.08, Active = 0.08, Endlag = 0.2, Cooldown = 0, Hitbox = hb(6, 4, 3.5, 0) },
		Light_Up = { Damage = 6, BaseKnockback = 16, KnockbackGrowth = 90, Angle = 88, Startup = 0.07, Active = 0.1, Endlag = 0.2, Cooldown = 0, Hitbox = hb(6, 5, 1.5, 3) },
		Light_Down = { Damage = 5, BaseKnockback = 12, KnockbackGrowth = 60, Angle = 20, Startup = 0.06, Active = 0.08, Endlag = 0.18, Cooldown = 0, Hitbox = hb(7, 2.5, 3, -2) },
		AirLight_Down = { Damage = 10, BaseKnockback = 20, KnockbackGrowth = 85, Angle = -70, Startup = 0.15, Active = 0.12, Endlag = 0.25, Cooldown = 0, Hitbox = hb(5, 5, 0, -3) },

		-- Ataques fuertes / smash (clic derecho / K)
		Heavy_Neutral = { Damage = 16, BaseKnockback = 30, KnockbackGrowth = 98, Angle = 40, Startup = 0.35, Active = 0.1, Endlag = 0.4, Cooldown = 0.6, Hitbox = hb(7, 5, 4, 0) },
		Heavy_Up = { Damage = 15, BaseKnockback = 32, KnockbackGrowth = 95, Angle = 85, Startup = 0.3, Active = 0.12, Endlag = 0.4, Cooldown = 0.6, Hitbox = hb(7, 7, 1, 4) },
		Heavy_Down = { Damage = 13, BaseKnockback = 28, KnockbackGrowth = 92, Angle = 25, Startup = 0.3, Active = 0.1, Endlag = 0.4, Cooldown = 0.6, Hitbox = hb(14, 3, 0, -2) },

		-- Especiales (E / L)
		Special_Neutral = { Name = "Puño Divergente", Pose = "Haymaker", -- "Puño Divergente": golpe + impacto retardado
			Damage = 6, BaseKnockback = 5, KnockbackGrowth = 10, Angle = 50,
			Startup = 0.2, Active = 0.1, Endlag = 0.35, Cooldown = 2, Hitbox = hb(6, 5, 3.5, 0),
			FollowUp = { Delay = 0.25, Damage = 8, BaseKnockback = 30, KnockbackGrowth = 85, Angle = 40 },
		},
		Special_Side = { Name = "Embestida Maldita", Pose = "Haymaker", -- Embestida
			Damage = 9, BaseKnockback = 22, KnockbackGrowth = 70, Angle = 35,
			Startup = 0.1, Active = 0.3, Endlag = 0.3, Cooldown = 2.5, Hitbox = hb(6, 5, 3, 0),
			SelfVelocity = Vector3.new(85, 8, 0),
		},
		Special_Up = { Name = "Patada Ascendente", Pose = "HighKick", -- Recuperación: patada ascendente (1 vez por salto)
			Damage = 7, BaseKnockback = 20, KnockbackGrowth = 60, Angle = 80,
			Startup = 0.05, Active = 0.3, Endlag = 0.3, Cooldown = 0.5, Hitbox = hb(6, 6, 0, 2),
			SelfVelocity = Vector3.new(10, 95, 0), OncePerAir = true,
		},
		Special_Down = { Name = "Impacto Sísmico", Pose = "Slam", -- Impacto sísmico
			Damage = 11, BaseKnockback = 26, KnockbackGrowth = 80, Angle = 75,
			Startup = 0.12, Active = 0.35, Endlag = 0.35, Cooldown = 3, Hitbox = hb(10, 5, 0, -2),
			SelfVelocity = Vector3.new(0, -110, 0),
		},
	},
}
