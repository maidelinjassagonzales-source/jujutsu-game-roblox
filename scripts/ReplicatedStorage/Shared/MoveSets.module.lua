-- MoveSets: plantillas para crear personajes con movesets propios.
--
-- Standard(opts) genera los golpes normales según el ESTILO de pelea del personaje:
--   Style = "Fists" (puños) | "Sword" (cortes) | "Staff" (estocadas largas) | "Kicks" (patadas)
--         | "Daggers" (combos rapidísimos) | "Heavy" (golpes lentos y brutales)
--   Power = daño · Reach = alcance extra · Speed = arranque (<1 más rápido) · KB = knockback
-- Cada movimiento puede llevar Name (se muestra en la tienda) y Pose (animación procedural).
local MoveSets = {}

local STYLE = {
	Fists = { Side = "Jab", Up = "Uppercut", Down = "LowKick", Heavy = "Haymaker" },
	Sword = { Side = "Slash", Up = "SlashUp", Down = "SlashLow", Heavy = "SlashHeavy" },
	Staff = { Side = "Thrust", Up = "SlashUp", Down = "Sweep", Heavy = "Thrust" },
	Kicks = { Side = "HighKick", Up = "HighKick", Down = "Sweep", Heavy = "HighKick" },
	Daggers = { Side = "Slash", Up = "SlashUp", Down = "Spin", Heavy = "Spin" },
	Heavy = { Side = "Haymaker", Up = "DoubleUp", Down = "Slam", Heavy = "Haymaker" },
}

local function hitbox(sx, sy, ox, oy, reach)
	return { Size = Vector3.new(sx + reach * 0.6, sy, 6), Offset = Vector3.new(ox + reach * 0.5, oy, 0) }
end

function MoveSets.Standard(o)
	o = o or {}
	local p, r, s, k = o.Power or 1, o.Reach or 0, o.Speed or 1, o.KB or 1
	local poses = STYLE[o.Style or "Fists"] or STYLE.Fists
	local function d(x)
		return math.max(1, math.floor(x * p + 0.5))
	end
	local function hb(sx, sy, ox, oy)
		return hitbox(sx, sy, ox, oy, r)
	end
	local moves = {
		Light_Neutral = { Damage = d(3), BaseKnockback = 9 * k, KnockbackGrowth = 30, Angle = 45, Startup = 0.05 * s, Active = 0.08, Endlag = 0.12, Cooldown = 0, Hitbox = hb(5, 5, 3, 0), Pose = poses.Side },
		Light_Side = { Damage = d(7), BaseKnockback = 13 * k, KnockbackGrowth = 72, Angle = 37, Startup = 0.08 * s, Active = 0.08, Endlag = 0.2, Cooldown = 0, Hitbox = hb(6, 4, 3.5, 0), Pose = poses.Side },
		Light_Up = { Damage = d(6), BaseKnockback = 15 * k, KnockbackGrowth = 88, Angle = 88, Startup = 0.07 * s, Active = 0.1, Endlag = 0.2, Cooldown = 0, Hitbox = hb(6, 5, 1.5, 3), Pose = poses.Up },
		Light_Down = { Damage = d(5), BaseKnockback = 11 * k, KnockbackGrowth = 58, Angle = 20, Startup = 0.06 * s, Active = 0.08, Endlag = 0.18, Cooldown = 0, Hitbox = hb(7, 2.5, 3, -2), Pose = poses.Down },
		AirLight_Down = { Damage = d(9), BaseKnockback = 19 * k, KnockbackGrowth = 84, Angle = -70, Startup = 0.15 * s, Active = 0.12, Endlag = 0.25, Cooldown = 0, Hitbox = hb(5, 5, 0, -3), Pose = "Stomp" },
		Heavy_Neutral = { Damage = d(15), BaseKnockback = 30 * k, KnockbackGrowth = 96, Angle = 40, Startup = 0.35 * s, Active = 0.1, Endlag = 0.4, Cooldown = 0.6, Hitbox = hb(7, 5, 4, 0), Pose = poses.Heavy },
		Heavy_Up = { Damage = d(14), BaseKnockback = 31 * k, KnockbackGrowth = 95, Angle = 86, Startup = 0.3 * s, Active = 0.12, Endlag = 0.4, Cooldown = 0.6, Hitbox = hb(7, 7, 1, 4), Pose = if poses.Up == "Uppercut" then "DoubleUp" else poses.Up },
		Heavy_Down = { Damage = d(13), BaseKnockback = 27 * k, KnockbackGrowth = 92, Angle = 25, Startup = 0.3 * s, Active = 0.1, Endlag = 0.4, Cooldown = 0.6, Hitbox = hb(14, 3, 0, -2), Pose = if poses.Down == "LowKick" then "Sweep" else poses.Down },
	}
	-- Estilos con identidad propia
	if o.Style == "Daggers" then
		moves.Light_Side.Damage = d(4)
		moves.Light_Side.FollowUp = { Delay = 0.12, Damage = d(4), BaseKnockback = 14 * k, KnockbackGrowth = 70, Angle = 38 }
	elseif o.Style == "Heavy" then
		moves.Heavy_Neutral.Damage = d(18)
		moves.Heavy_Neutral.Startup = 0.45 * s
	elseif o.Style == "Kicks" then
		moves.Light_Side.Hitbox = hb(7, 4, 4, 1)
		moves.Light_Side.Angle = 45
	end
	return moves
end

-- Proyectil
function MoveSets.Projectile(o)
	return {
		Name = o.Name, Pose = o.Pose or "Palms",
		Damage = o.Damage, BaseKnockback = o.KB or 18, KnockbackGrowth = o.Growth or 60, Angle = o.Angle or 40,
		Startup = o.Startup or 0.2, Active = 0, Endlag = o.Endlag or 0.3, Cooldown = o.Cooldown or 2,
		Projectile = {
			Speed = o.Speed or 80, Lifetime = o.Lifetime or 1, Size = Vector3.one * (o.Size or 4),
			Color = o.Color, Pierce = o.Pierce == true,
		},
	}
end

-- Golpe cuerpo a cuerpo con hitbox propia (y opcionalmente impulso y segundo impacto)
function MoveSets.Melee(o)
	return {
		Name = o.Name, Pose = o.Pose or "Haymaker",
		Damage = o.Damage, BaseKnockback = o.KB or 22, KnockbackGrowth = o.Growth or 75, Angle = o.Angle or 38,
		Startup = o.Startup or 0.15, Active = o.Active or 0.12, Endlag = o.Endlag or 0.35, Cooldown = o.Cooldown or 2,
		Hitbox = { Size = o.Size or Vector3.new(6, 5, 6), Offset = o.Offset or Vector3.new(3.5, 0, 0) },
		SelfVelocity = o.Dash, FollowUp = o.FollowUp,
	}
end

-- Recuperación (especial arriba): sube y golpea, una vez por salto
function MoveSets.Recovery(o)
	o = o or {}
	return {
		Name = o.Name or "Recuperación", Pose = o.Pose or "Rise",
		Damage = o.Damage or 7, BaseKnockback = o.KB or 19, KnockbackGrowth = o.Growth or 60, Angle = o.Angle or 80,
		Startup = 0.05, Active = o.Active or 0.28, Endlag = 0.3, Cooldown = 0.5,
		Hitbox = if o.NoHitbox then nil else { Size = Vector3.new(6, 6, 6), Offset = Vector3.new(0, 2, 0) },
		SelfVelocity = o.Velocity or Vector3.new(10, 96, 0), OncePerAir = true,
	}
end

function MoveSets.Build(base, specials)
	local moves = table.clone(base)
	for key, move in specials do
		moves[key] = move
	end
	return moves
end

return MoveSets
