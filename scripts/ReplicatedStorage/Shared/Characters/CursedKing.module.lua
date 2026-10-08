-- CursedKing: rey de las maldiciones (arquetipo "cortes invisibles"). Personaje de Acceso Anticipado.
-- Balanceado igual que el resto: el Acceso Anticipado vende ANTES, no MÁS FUERTE.
local Accessories = require(script.Parent.Parent:WaitForChild("Accessories"))

local function hb(sx, sy, ox, oy)
	return { Size = Vector3.new(sx, sy, 6), Offset = Vector3.new(ox, oy, 0) }
end

return {
	Id = "CursedKing",
	DisplayName = "Cursed King",
	Color = Color3.fromRGB(220, 40, 60),
	Weight = 100,
	WalkSpeed = 24,
	JumpPower = 63,
	Appearance = {
		Head = Color3.fromRGB(225, 175, 145),
		Torso = Color3.fromRGB(235, 230, 225),
		Arms = Color3.fromRGB(225, 175, 145),
		Legs = Color3.fromRGB(30, 25, 30),
	},
	-- Pelo rosa peinado hacia atrás + marcas negras en cara y brazos + fajín
	Style = Accessories.Merge(Accessories.SpikyHair(Color3.fromRGB(225, 130, 150), 0.35, {
		{ -0.4, 0.2, -10 }, { 0, 0.3, 0 }, { 0.4, 0.2, 10 }, { -0.2, 0.5, -5 }, { 0.2, 0.5, 5 },
	}), {
		{ Body = "Head", Size = Vector3.new(0.34, 0.06, 0.04), Offset = CFrame.new(-0.28, -0.04, -0.63), Color = Color3.fromRGB(10, 10, 10) },
		{ Body = "Head", Size = Vector3.new(0.34, 0.06, 0.04), Offset = CFrame.new(0.28, -0.04, -0.63), Color = Color3.fromRGB(10, 10, 10) },
		{ Body = "Head", Size = Vector3.new(0.3, 0.06, 0.04), Offset = CFrame.new(0, 0.3, -0.63), Color = Color3.fromRGB(10, 10, 10) },
		{ Body = "Left Arm", Size = Vector3.new(1.04, 0.12, 1.04), Offset = CFrame.new(0, 0.2, 0), Color = Color3.fromRGB(10, 10, 10) },
		{ Body = "Right Arm", Size = Vector3.new(1.04, 0.12, 1.04), Offset = CFrame.new(0, 0.2, 0), Color = Color3.fromRGB(10, 10, 10) },
		{ Body = "Torso", Size = Vector3.new(2.06, 0.35, 1.06), Offset = CFrame.new(0, -0.65, 0), Color = Color3.fromRGB(110, 15, 20) },
	}),

	Moves = {
		Light_Neutral = { Damage = 3, BaseKnockback = 9, KnockbackGrowth = 30, Angle = 45, Startup = 0.05, Active = 0.08, Endlag = 0.12, Cooldown = 0, Hitbox = hb(5, 5, 3, 0) },
		Light_Side = { Damage = 7, BaseKnockback = 13, KnockbackGrowth = 72, Angle = 37, Startup = 0.09, Active = 0.08, Endlag = 0.22, Cooldown = 0, Hitbox = hb(6, 4, 3.5, 0) },
		Light_Up = { Damage = 6, BaseKnockback = 15, KnockbackGrowth = 88, Angle = 88, Startup = 0.07, Active = 0.1, Endlag = 0.2, Cooldown = 0, Hitbox = hb(6, 5, 1.5, 3) },
		Light_Down = { Damage = 5, BaseKnockback = 11, KnockbackGrowth = 58, Angle = 20, Startup = 0.06, Active = 0.08, Endlag = 0.18, Cooldown = 0, Hitbox = hb(7, 2.5, 3, -2) },
		AirLight_Down = { Damage = 9, BaseKnockback = 19, KnockbackGrowth = 84, Angle = -70, Startup = 0.15, Active = 0.12, Endlag = 0.25, Cooldown = 0, Hitbox = hb(5, 5, 0, -3) },

		Heavy_Neutral = { Damage = 15, BaseKnockback = 30, KnockbackGrowth = 96, Angle = 40, Startup = 0.35, Active = 0.1, Endlag = 0.4, Cooldown = 0.6, Hitbox = hb(7, 5, 4, 0) },
		Heavy_Up = { Damage = 14, BaseKnockback = 31, KnockbackGrowth = 95, Angle = 86, Startup = 0.3, Active = 0.12, Endlag = 0.4, Cooldown = 0.6, Hitbox = hb(7, 7, 1, 4) },
		Heavy_Down = { Damage = 13, BaseKnockback = 27, KnockbackGrowth = 92, Angle = 25, Startup = 0.3, Active = 0.1, Endlag = 0.4, Cooldown = 0.6, Hitbox = hb(14, 3, 0, -2) },

		Special_Neutral = { Name = "Dismantle", Pose = "Slash", -- "Desmantelar": corte a distancia rápido y débil
			Damage = 6, BaseKnockback = 10, KnockbackGrowth = 35, Angle = 30,
			Startup = 0.15, Active = 0, Endlag = 0.25, Cooldown = 1,
			Projectile = { Speed = 130, Lifetime = 0.6, Size = Vector3.new(3, 3, 3), Color = Color3.fromRGB(255, 230, 230), Pierce = true },
		},
		Special_Side = { Name = "Cleave", Pose = "SlashHeavy", -- "Partir": corte pesado a corta distancia
			Damage = 14, BaseKnockback = 32, KnockbackGrowth = 90, Angle = 38,
			Startup = 0.28, Active = 0.1, Endlag = 0.4, Cooldown = 3, Hitbox = hb(7, 5, 3.5, 0),
		},
		Special_Up = { Name = "King's Ascent", Pose = "Rise", -- Recuperación
			Damage = 7, BaseKnockback = 19, KnockbackGrowth = 60, Angle = 80,
			Startup = 0.05, Active = 0.3, Endlag = 0.3, Cooldown = 0.5, Hitbox = hb(6, 6, 0, 2),
			SelfVelocity = Vector3.new(10, 98, 0), OncePerAir = true,
		},
		Special_Down = { Name = "Fire Arrow", Pose = "Beam", -- "Flecha de Fuego": lenta, enorme castigo
			Damage = 20, BaseKnockback = 42, KnockbackGrowth = 94, Angle = 40,
			Startup = 1, Active = 0, Endlag = 0.6, Cooldown = 18,
			Projectile = { Speed = 80, Lifetime = 1.6, Size = Vector3.new(6, 6, 6), Color = Color3.fromRGB(255, 120, 30), Pierce = true },
		},
	},
}
