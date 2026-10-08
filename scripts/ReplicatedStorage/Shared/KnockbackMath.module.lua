-- KnockbackMath: fórmula de knockback inspirada en Super Smash Bros.
-- Cuanto mayor es el % de daño acumulado, más lejos sale volando el objetivo.
local Config = require(script.Parent:WaitForChild("CombatConfig"))

local KnockbackMath = {}

-- percentAfter: % del objetivo DESPUÉS de recibir el golpe
-- damage: daño del golpe
-- weight: peso del personaje (100 = medio; más alto = aguanta más)
-- baseKB: knockback base (lo que empuja incluso a 0%)
-- growth: crecimiento del knockback con el % (100 = normal)
function KnockbackMath.Compute(percentAfter: number, damage: number, weight: number, baseKB: number, growth: number): number
	local p, d = percentAfter, damage
	local raw = ((p / 10 + (p * d) / 20) * (200 / (weight + 100)) * 1.4) + 18
	return raw * (growth / 100) + baseKB
end

-- Convierte knockback + ángulo (grados, 0 = hacia delante, 90 = arriba) en velocidad.
-- Ángulos > 90 empujan hacia atrás (útil para técnicas que atraen).
function KnockbackMath.LaunchVelocity(kb: number, angleDeg: number, facing: number): Vector3
	local speed = kb * Config.LaunchSpeedMultiplier
	local a = math.rad(angleDeg)
	return Vector3.new(math.cos(a) * facing * speed, math.sin(a) * speed * (Config.VerticalScale or 1), 0)
end

function KnockbackMath.Hitstun(kb: number): number
	return math.max(Config.MinHitstun, kb * Config.HitstunFactor)
end

return KnockbackMath
