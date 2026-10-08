-- CombatService: servidor autoritativo del combate.
-- El cliente solo pide "quiero hacer un ataque Light/Heavy/Special en dirección X".
-- El servidor valida estado, cooldowns, calcula hitboxes, % de daño y knockback.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("CombatConfig"))
local KnockbackMath = require(Shared:WaitForChild("KnockbackMath"))
local KnockbackSimulator = require(Shared:WaitForChild("KnockbackSimulator"))
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))
local UltimateConfig = require(Shared:WaitForChild("UltimateConfig"))

local FighterService -- se resuelve en Start (evita require circular)

local CombatService = {}

local VALID_KINDS = { Light = true, Heavy = true, Special = true }
local VALID_DIRS = { Neutral = true, Side = true, Up = true, Down = true }

local feedback: RemoteEvent
local projectileFolder: Folder
local ArenaInfoFolder: Folder? = nil

local busyUntil = setmetatable({}, { __mode = "k" }) -- [model] = os.clock()
local stunUntil = setmetatable({}, { __mode = "k" })
local cooldowns = setmetatable({}, { __mode = "k" }) -- [model] = { [moveKey] = readyAt }
local airUsed = setmetatable({}, { __mode = "k" }) -- [model] = { [moveKey] = true }
local swapCooldown = setmetatable({}, { __mode = "k" })
local lastAttacker = setmetatable({}, { __mode = "k" }) -- [victim] = { Model, Time }
local hitListeners = {}

-- Defensa estilo Smash: escudo, esquivas (intangibilidad) y agarres
local Defense = Config.Defense
local shielding = setmetatable({}, { __mode = "k" }) -- [model] = true
local shieldHP = setmetatable({}, { __mode = "k" }) -- [model] = number
local intangibleUntil = setmetatable({}, { __mode = "k" })
local airDodgeUsed = setmetatable({}, { __mode = "k" })

-- Otros servicios (economía, misiones...) se suscriben a los golpes: fn(attacker, victim, damage)
function CombatService.OnHit(fn)
	table.insert(hitListeners, fn)
end

-- Avisos de "empieza un movimiento" (misiones: técnicas especiales usadas)
local moveListeners = {}
function CombatService.OnMoveStarted(fn)
	table.insert(moveListeners, fn)
end

-- Quién golpeó por última vez a la víctima (para dar el crédito del KO)
function CombatService.GetLastAttacker(victim: Model, window: number): Model?
	local entry = lastAttacker[victim]
	if entry and os.clock() - entry.Time <= window and entry.Model.Parent then
		return entry.Model
	end
	return nil
end

local function isStunned(model: Model): boolean
	return (stunUntil[model] or 0) > os.clock()
end

local function isGrounded(humanoid: Humanoid): boolean
	return humanoid.FloorMaterial ~= Enum.Material.Air
end

local function getFighterFromPart(part: BasePart): Model?
	local model = part:FindFirstAncestorWhichIsA("Model")
	while model and not CollectionService:HasTag(model, "Fighter") do
		model = model:FindFirstAncestorWhichIsA("Model")
	end
	return model
end

local function queryHitbox(attacker: Model, center: Vector3, size: Vector3): { [Model]: boolean }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { attacker, projectileFolder }

	local found = {}
	for _, part in workspace:GetPartBoundsInBox(CFrame.new(center), size, params) do
		local model = getFighterFromPart(part)
		if model and model ~= attacker then
			found[model] = true
		end
	end
	return found
end

-- Busca el movimiento más específico: AirLight_Down > Light_Down > AirLight_Neutral > Light_Neutral
local function resolveMove(data, kind: string, dir: string, airborne: boolean)
	local moves = data.Moves
	local candidates = {}
	if airborne then
		table.insert(candidates, `Air{kind}_{dir}`)
	end
	table.insert(candidates, `{kind}_{dir}`)
	if airborne then
		table.insert(candidates, `Air{kind}_Neutral`)
	end
	table.insert(candidates, `{kind}_Neutral`)

	for _, key in candidates do
		if moves[key] then
			return key, moves[key]
		end
	end
	return nil, nil
end

function CombatService.ApplyHit(attacker: Model, victim: Model, move, facing: number): boolean
	if victim == attacker or not victim.Parent then
		return false
	end
	if victim:GetAttribute("Invulnerable") or victim:GetAttribute("KOing") or victim:GetAttribute("Eliminated") then
		return false
	end
	if victim:GetAttribute("IsNPC") and attacker:GetAttribute("IsNPC") then
		return false -- los enemigos de la historia no se pegan entre ellos
	end
	if victim:GetAttribute("ArenaId") ~= attacker:GetAttribute("ArenaId") then
		return false
	end
	local humanoid = victim:FindFirstChildOfClass("Humanoid")
	local hrp = victim:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not hrp then
		return false
	end

	-- Esquivas: intangible = el golpe le atraviesa (los golpes de dominio aciertan siempre)
	if not move.SureHit and (intangibleUntil[victim] or 0) > os.clock() then
		return false
	end

	-- Pasiva Infinito (Gojo): a veces el golpe ni le toca
	local passive = UltimateConfig.Passives[victim:GetAttribute("CharacterId") or ""]
	if passive and passive.InfinityChance and not move.SureHit and not move.IgnoresShield and math.random() < passive.InfinityChance then
		feedback:FireAllClients("Infinity", victim, hrp.Position)
		return false
	end

	-- Escudo: absorbe el golpe (los agarres lo atraviesan, eso se gestiona en runGrab)
	if shielding[victim] and not move.IgnoresShield and not move.SureHit then
		local hp = (shieldHP[victim] or Defense.ShieldMax) - move.Damage * Defense.ShieldDamageMult
		shieldHP[victim] = hp
		victim:SetAttribute("ShieldHP", math.max(0, math.floor(hp)))
		feedback:FireAllClients("ShieldHit", victim, hrp.Position)
		if hp <= 0 then
			CombatService.BreakShield(victim)
		else
			-- pequeño retroceso sobre el escudo
			local push = Vector3.new(facing * math.min(10 + move.Damage * 2, 40), 0, 0)
			local player = Players:GetPlayerFromCharacter(victim)
			if player then
				feedback:FireClient(player, "Push", push)
			else
				hrp.AssemblyLinearVelocity = push
			end
		end
		return false
	end

	-- 0) Multiplicadores: transformaciones (ulti) y Destello Negro (Itadori)
	local damage = move.Damage * (attacker:GetAttribute("DamageMult") or 1)
	local kbMult = victim:GetAttribute("KBResist") or 1
	local attackerPassive = UltimateConfig.Passives[attacker:GetAttribute("CharacterId") or ""]
	local blackFlash = not move.SureHit and move.Damage >= 5 and (attacker:GetAttribute("BlackFlashMode")
		or (attackerPassive and attackerPassive.BlackFlashChance and move.Damage >= 7 and math.random() < attackerPassive.BlackFlashChance))
	if blackFlash then
		damage *= if attacker:GetAttribute("BlackFlashMode") then 1.6 else 2.5
		kbMult *= 1.4
		feedback:FireAllClients("BlackFlash", victim, hrp.Position)
	end
	damage = math.floor(damage * 10 + 0.5) / 10

	-- 1) Sumar % de daño
	local percent = math.min(Config.MaxPercent, (victim:GetAttribute("Percent") or 0) + damage)
	victim:SetAttribute("Percent", percent)

	-- 2) Knockback según % y peso
	local kb = KnockbackMath.Compute(percent, damage, victim:GetAttribute("Weight") or 100, move.BaseKnockback, move.KnockbackGrowth) * kbMult
	local angle = move.Angle
	if angle < 0 and isGrounded(humanoid) then
		angle = Config.GroundSpikeBounceAngle
	end
	local velocity = KnockbackMath.LaunchVelocity(kb, angle, facing)
	local hitstun = KnockbackMath.Hitstun(kb)

	-- 3) Hitstun: interrumpe lo que estuviera haciendo la víctima
	stunUntil[victim] = os.clock() + hitstun
	busyUntil[victim] = nil

	-- 4) Aplicar el lanzamiento donde viva su física
	local player = Players:GetPlayerFromCharacter(victim)
	if player then
		feedback:FireClient(player, "Knockback", velocity, hitstun)
	else
		KnockbackSimulator.Apply(victim, velocity, hitstun)
	end

	feedback:FireAllClients("Hit", victim, damage, kb, hrp.Position)

	-- Técnica de intercambio (aplauso): atacante y víctima cambian de sitio
	if move.Swap then
		local aHRP = attacker:FindFirstChild("HumanoidRootPart") :: BasePart?
		if aHRP then
			local aCF, vCF = attacker:GetPivot(), victim:GetPivot()
			attacker:PivotTo(vCF)
			victim:PivotTo(aCF)
			feedback:FireAllClients("Swap", attacker, victim)
		end
	end

	lastAttacker[victim] = { Model = attacker, Time = os.clock() }
	for _, fn in hitListeners do
		task.spawn(fn, attacker, victim, damage, move)
	end
	return true
end

local function runMelee(attacker: Model, move, facing: number)
	local hrp = attacker:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local hitbox = move.Hitbox
	local alreadyHit = {}
	local deadline = os.clock() + (move.Active or 0)

	repeat
		if not hrp.Parent or isStunned(attacker) then
			return
		end
		local center = hrp.Position + Vector3.new(hitbox.Offset.X * facing, hitbox.Offset.Y, 0)
		for victim in queryHitbox(attacker, center, hitbox.Size) do
			if not alreadyHit[victim] then
				alreadyHit[victim] = true
				if CombatService.ApplyHit(attacker, victim, move, facing) and move.FollowUp then
					task.delay(move.FollowUp.Delay or 0.2, CombatService.ApplyHit, attacker, victim, move.FollowUp, facing)
				end
			end
		end
		RunService.Heartbeat:Wait()
	until os.clock() >= deadline
end

-- Proyectiles: el servidor solo simula la posición y los golpes (autoridad).
-- Lo visual lo dibuja cada cliente (SpecialFX) con el estilo propio de cada técnica:
--   "ProjectileSpawn" (id, atacante, nombre de la técnica, color, tamaño, inicio, dirección, velocidad, vida)
--   "ProjectileHit"   (id, posición)        -> atraviesa a alguien
--   "ProjectileEnd"   (id, posición, choca) -> desaparece (choca = true si explota contra alguien)
local projectileCounter = 0

local function runProjectile(attacker: Model, move, facing: number)
	local hrp = attacker:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local spec = move.Projectile
	local d = math.max(spec.Size.X, spec.Size.Y)
	projectileCounter += 1
	local id = projectileCounter
	local start = hrp.Position + Vector3.new(facing * 3, 0.5, 0)
	local pos = start
	feedback:FireAllClients("ProjectileSpawn", id, attacker, move.Name or "", spec.Color, d, start, facing, spec.Speed, spec.Lifetime)

	local alreadyHit = {}
	local born = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - born
		if t > spec.Lifetime or not attacker.Parent then
			conn:Disconnect()
			feedback:FireAllClients("ProjectileEnd", id, pos, false)
			return
		end
		pos = start + Vector3.new(facing * spec.Speed * t, 0, 0)

		for victim in queryHitbox(attacker, pos, spec.Size) do
			if not alreadyHit[victim] then
				alreadyHit[victim] = true
				CombatService.ApplyHit(attacker, victim, move, facing)
				if not spec.Pierce then
					conn:Disconnect()
					feedback:FireAllClients("ProjectileEnd", id, pos, true)
					return
				end
				feedback:FireAllClients("ProjectileHit", id, pos)
			end
		end
	end)
end

-- Ataque de cualquier luchador (jugador o NPC). Devuelve true si el ataque empezó.
function CombatService.PerformAttack(model: Model, kind: string, dir: string, facingHint: number?): boolean
	if not VALID_KINDS[kind] or not VALID_DIRS[dir] then
		return false
	end
	if not CollectionService:HasTag(model, "Fighter") or model:GetAttribute("KOing") or model:GetAttribute("Eliminated") then
		return false
	end
	if model:GetAttribute("MoveMode") == "Free" then
		return false -- en la obby no se pelea
	end
	local arenaInfo = ArenaInfoFolder and ArenaInfoFolder:FindFirstChild(model:GetAttribute("ArenaId") or "")
	local matchState = arenaInfo and arenaInfo:GetAttribute("MatchState")
	if matchState == "Countdown" or matchState == "Finish" then
		return false
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not hrp or hrp.Anchored then
		return false
	end

	local now = os.clock()
	if (busyUntil[model] or 0) > now or isStunned(model) or shielding[model] then
		return false
	end

	local data = CharacterRegistry.Get(model:GetAttribute("CharacterId"))
	if not data then
		return false
	end

	local airborne = not isGrounded(humanoid)
	if not airborne then
		airUsed[model] = nil -- tocar suelo recarga la recuperación
	end

	local key, move = resolveMove(data, kind, dir, airborne)
	if not move then
		return false
	end

	local cds = cooldowns[model] or {}
	cooldowns[model] = cds
	if (cds[key] or 0) > now then
		return false
	end

	if move.OncePerAir then
		local used = airUsed[model] or {}
		airUsed[model] = used
		if used[key] then
			return false
		end
		used[key] = true
	end

	cds[key] = now + (move.Cooldown or 0)
	busyUntil[model] = now + (move.Startup or 0) + (move.Active or 0) + (move.Endlag or 0)

	-- La dirección hacia la que mira la decide el cliente (inofensivo); si es inválida, la deducimos.
	local facing = if facingHint == 1 or facingHint == -1
		then facingHint
		else (if hrp.CFrame.LookVector.X >= 0 then 1 else -1)

	local selfVelocity = if move.SelfVelocity
		then Vector3.new(move.SelfVelocity.X * facing, move.SelfVelocity.Y, 0)
		else nil
	feedback:FireAllClients("MoveStarted", model, key, selfVelocity, facing)
	for _, fn in moveListeners do
		task.spawn(fn, model, key)
	end
	-- Los NPC no tienen cliente: el impulso propio lo aplica el servidor
	if selfVelocity and not Players:GetPlayerFromCharacter(model) then
		hrp.AssemblyLinearVelocity = selfVelocity
	end

	task.spawn(CombatService.ExecuteMove, model, move, facing)
	return true
end

-- Ejecuta un movimiento ya validado (arranque -> golpe). También lo usa el probador de movesets.
function CombatService.ExecuteMove(model: Model, move, facing: number)
	if (move.Startup or 0) > 0 then
		task.wait(move.Startup)
	end
	if not model.Parent or isStunned(model) or model:GetAttribute("KOing") then
		return
	end
	if move.Projectile then
		runProjectile(model, move, facing)
	elseif move.Hitbox then
		runMelee(model, move, facing)
	end
end

-- Paraliza a un luchador (dominio de Gojo): no puede actuar ni moverse
function CombatService.Stun(model: Model, duration: number)
	stunUntil[model] = os.clock() + duration
	busyUntil[model] = nil
	local player = Players:GetPlayerFromCharacter(model)
	if player then
		feedback:FireClient(player, "Knockback", Vector3.zero, duration)
	else
		KnockbackSimulator.Apply(model, Vector3.zero, duration)
	end
	feedback:FireAllClients("Stunned", model, duration)
end

function CombatService.SetBusy(model: Model, duration: number)
	busyUntil[model] = math.max(busyUntil[model] or 0, os.clock() + duration)
end

function CombatService.IsStunned(model: Model): boolean
	return isStunned(model)
end

-- ================================================================ DEFENSA
local function canAct(model: Model): (Humanoid?, BasePart?)
	if not CollectionService:HasTag(model, "Fighter") or model:GetAttribute("KOing") or model:GetAttribute("Eliminated") then
		return nil, nil
	end
	if model:GetAttribute("MoveMode") == "Free" then
		return nil, nil
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not hrp or hrp.Anchored or isStunned(model) then
		return nil, nil
	end
	return humanoid, hrp
end

function CombatService.SetShield(model: Model, on: boolean)
	if not on then
		if shielding[model] then
			shielding[model] = nil
			model:SetAttribute("Shielding", false)
		end
		return
	end
	local humanoid = canAct(model)
	if not humanoid or (busyUntil[model] or 0) > os.clock() or not isGrounded(humanoid) then
		return
	end
	if (shieldHP[model] or Defense.ShieldMax) < Defense.ShieldMinToRaise then
		return
	end
	shielding[model] = true
	model:SetAttribute("Shielding", true)
	model:SetAttribute("ShieldHP", math.floor(shieldHP[model] or Defense.ShieldMax))
end

function CombatService.BreakShield(model: Model)
	shielding[model] = nil
	shieldHP[model] = Defense.ShieldMax * 0.4 -- vuelve a medio cargar tras el aturdimiento
	model:SetAttribute("Shielding", false)
	model:SetAttribute("ShieldHP", math.floor(shieldHP[model]))
	-- ¡Escudo roto! Sale disparado hacia arriba y queda aturdido
	stunUntil[model] = os.clock() + Defense.ShieldBreakStun
	busyUntil[model] = nil
	local launch = Vector3.new(0, 55, 0)
	local player = Players:GetPlayerFromCharacter(model)
	if player then
		feedback:FireClient(player, "Knockback", launch, Defense.ShieldBreakStun)
	else
		KnockbackSimulator.Apply(model, launch, Defense.ShieldBreakStun)
	end
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	feedback:FireAllClients("ShieldBreak", model, if hrp then hrp.Position else Vector3.zero)
end

-- dir = "Left" | "Right" (rodar) | "Down" (esquiva en el sitio) | "Air" (esquiva aérea)
function CombatService.Dodge(model: Model, dir: string)
	local humanoid, hrp = canAct(model)
	if not humanoid or not hrp or (busyUntil[model] or 0) > os.clock() then
		return false
	end
	local grounded = isGrounded(humanoid)
	if grounded then
		airDodgeUsed[model] = nil
	end

	local velocity, duration, lag
	if dir == "Air" then
		if grounded or airDodgeUsed[model] then
			return false
		end
		airDodgeUsed[model] = true
		local v = hrp.AssemblyLinearVelocity
		velocity = Vector3.new(v.X * 0.4, math.max(v.Y, 8), 0)
		duration, lag = Defense.AirDodgeTime, Defense.AirDodgeLag
	elseif dir == "Down" then
		if not shielding[model] then
			return false
		end
		velocity = Vector3.zero
		duration, lag = Defense.SpotDodgeTime, Defense.SpotDodgeLag
	elseif dir == "Left" or dir == "Right" then
		if not shielding[model] then
			return false
		end
		local sign = if dir == "Right" then 1 else -1
		velocity = Vector3.new(sign * Defense.RollSpeed, 0, 0)
		duration, lag = Defense.RollTime, Defense.RollLag
	else
		return false
	end

	CombatService.SetShield(model, false)
	local now = os.clock()
	intangibleUntil[model] = now + duration
	busyUntil[model] = now + duration + lag
	model:SetAttribute("Intangible", true)
	task.delay(duration, function()
		if model.Parent then
			model:SetAttribute("Intangible", false)
		end
	end)
	feedback:FireAllClients("MoveStarted", model, `Dodge_{dir}`, if velocity.Magnitude > 0 then velocity else nil, if velocity.X >= 0 then 1 else -1)
	if not Players:GetPlayerFromCharacter(model) and velocity.Magnitude > 0 then
		hrp.AssemblyLinearVelocity = velocity
	end
	return true
end

-- Agarre: atraviesa escudos. dir decide el lanzamiento (Side = delante/detrás según facing).
local THROWS = {
	Forward = { Damage = 8, BaseKnockback = 45, KnockbackGrowth = 55, Angle = 40, IgnoresShield = true },
	Back = { Damage = 10, BaseKnockback = 50, KnockbackGrowth = 62, Angle = 40, IgnoresShield = true },
	Up = { Damage = 7, BaseKnockback = 48, KnockbackGrowth = 58, Angle = 88, IgnoresShield = true },
	Down = { Damage = 6, BaseKnockback = 30, KnockbackGrowth = 35, Angle = 75, IgnoresShield = true },
}

function CombatService.Grab(model: Model, dir: string, facingHint: number?)
	local humanoid, hrp = canAct(model)
	if not humanoid or not hrp or (busyUntil[model] or 0) > os.clock() then
		return false
	end
	if not isGrounded(humanoid) then
		return false -- en Smash no se agarra en el aire
	end
	CombatService.SetShield(model, false)
	local facing = if facingHint == 1 or facingHint == -1 then facingHint else (if hrp.CFrame.LookVector.X >= 0 then 1 else -1)
	local now = os.clock()
	busyUntil[model] = now + Defense.GrabStartup + Defense.GrabActive + Defense.GrabWhiffLag
	feedback:FireAllClients("MoveStarted", model, "Grab", nil, facing)

	task.spawn(function()
		task.wait(Defense.GrabStartup)
		if not model.Parent or isStunned(model) then
			return
		end
		local deadline = os.clock() + Defense.GrabActive
		local victim: Model? = nil
		repeat
			local center = hrp.Position + Vector3.new(2.8 * facing, 0, 0)
			for candidate in queryHitbox(model, center, Vector3.new(4, 5, 6)) do
				if candidate:GetAttribute("ArenaId") == model:GetAttribute("ArenaId")
					and not candidate:GetAttribute("Invulnerable") and not candidate:GetAttribute("KOing")
					and (intangibleUntil[candidate] or 0) <= os.clock()
					and not (candidate:GetAttribute("IsNPC") and model:GetAttribute("IsNPC")) then
					victim = candidate
					break
				end
			end
			if victim then
				break
			end
			RunService.Heartbeat:Wait()
		until os.clock() >= deadline
		if not victim then
			return
		end

		-- ¡Agarrado! Ambos quietos un instante
		local vHRP = victim:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not vHRP then
			return
		end
		shielding[victim] = nil
		victim:SetAttribute("Shielding", false)
		stunUntil[victim] = os.clock() + Defense.GrabHold + 0.3
		busyUntil[model] = os.clock() + Defense.GrabHold + 0.25
		busyUntil[victim] = nil
		local vPlayer = Players:GetPlayerFromCharacter(victim)
		if vPlayer then
			feedback:FireClient(vPlayer, "Knockback", Vector3.zero, Defense.GrabHold + 0.1)
		else
			KnockbackSimulator.Apply(victim, Vector3.zero, Defense.GrabHold + 0.1)
		end
		feedback:FireAllClients("Grabbed", model, victim)

		local holdEnd = os.clock() + Defense.GrabHold
		while os.clock() < holdEnd and victim.Parent and model.Parent do
			local p = hrp.Position + Vector3.new(2.6 * facing, 0.5, 0)
			victim:PivotTo(CFrame.lookAt(p, p - Vector3.new(facing, 0, 0)))
			vHRP.AssemblyLinearVelocity = Vector3.zero
			RunService.Heartbeat:Wait()
		end
		if not victim.Parent or not model.Parent then
			return
		end

		-- Lanzamiento
		local throwName, throwFacing = "Forward", facing
		if dir == "Up" then
			throwName = "Up"
		elseif dir == "Down" then
			throwName = "Down"
		elseif dir == "Back" then
			throwName, throwFacing = "Back", -facing
		end
		feedback:FireAllClients("MoveStarted", model, `Throw_{throwName}`, nil, throwFacing)
		stunUntil[victim] = nil
		CombatService.ApplyHit(model, victim, THROWS[throwName], throwFacing)
	end)
	return true
end

function CombatService.IsBusy(model: Model): boolean
	return (busyUntil[model] or 0) > os.clock()
end

local function onAttack(player: Player, kind: any, dir: any, facingHint: any)
	if typeof(kind) ~= "string" or typeof(dir) ~= "string" then
		return
	end
	local model = player.Character
	if model then
		CombatService.PerformAttack(model, kind, dir, if facingHint == 1 or facingHint == -1 then facingHint else nil)
	end
end

local function onSwap(player: Player)
	local now = os.clock()
	if (swapCooldown[player] or 0) > now then
		return
	end
	swapCooldown[player] = now + 1
	if player:GetAttribute("Activity") ~= "Hub" then
		return -- solo se cambia de personaje en el Hub
	end
	FighterService.CycleCharacter(player)
end

function CombatService.ClearState(model: Model)
	busyUntil[model] = nil
	stunUntil[model] = nil
	airUsed[model] = nil
	lastAttacker[model] = nil
	shielding[model] = nil
	intangibleUntil[model] = nil
	airDodgeUsed[model] = nil
	model:SetAttribute("Shielding", false)
	model:SetAttribute("Intangible", false)
	KnockbackSimulator.Cancel(model)
end

function CombatService.Start(remotes: Folder)
	FighterService = require(script.Parent:WaitForChild("FighterService"))
	feedback = remotes:WaitForChild("CombatFeedback")

	ArenaInfoFolder = ReplicatedStorage:WaitForChild("ArenaInfo")
	projectileFolder = workspace:FindFirstChild("Projectiles") or Instance.new("Folder")
	projectileFolder.Name = "Projectiles"
	projectileFolder.Parent = workspace

	remotes:WaitForChild("CombatRequest").OnServerEvent:Connect(function(player, action, a, b, c)
		local model = player.Character
		if action == "Attack" then
			onAttack(player, a, b, c)
		elseif action == "SwapCharacter" then
			onSwap(player)
		elseif model and action == "Shield" then
			CombatService.SetShield(model, a == true)
		elseif model and action == "Dodge" and type(a) == "string" then
			CombatService.Dodge(model, a)
		elseif model and action == "Ultimate" and CombatService.UltimateHandler then
			CombatService.UltimateHandler(model)
		elseif model and action == "Grab" and type(a) == "string" then
			CombatService.Grab(model, a, if b == 1 or b == -1 then b else nil)
		end
	end)

	-- El escudo se gasta mientras se mantiene y se recarga solo cuando no
	local syncTimer = 0
	RunService.Heartbeat:Connect(function(dt)
		syncTimer += dt
		local sync = syncTimer >= 0.15
		if sync then
			syncTimer = 0
		end
		for _, model in CollectionService:GetTagged("Fighter") do
			local hp = shieldHP[model] or Defense.ShieldMax
			if shielding[model] then
				hp -= Defense.ShieldDrain * dt
				shieldHP[model] = hp
				if hp <= 0 then
					CombatService.BreakShield(model)
				elseif sync then
					model:SetAttribute("ShieldHP", math.floor(hp))
				end
			elseif hp < Defense.ShieldMax then
				shieldHP[model] = math.min(Defense.ShieldMax, hp + Defense.ShieldRegen * dt)
				if sync then
					model:SetAttribute("ShieldHP", math.floor(shieldHP[model]))
				end
			end
		end
	end)
end

return CombatService
