-- PoseController: reproductor de las animaciones hechas en Blender (Modules/AnimationData, generado por
-- tools/blender_anims.py + tools/anims_to_lua.py). Mueve las articulaciones Motor6D del rig R6.
--   * Capa base (locomoción): Idle / Walk / Run / Jump / Fall / Shield (en el Lobby: versión relajada)
--   * Capa de acción: golpes, especiales, esquivas, agarres, daño, aterrizaje, doble salto
--     Cada golpe se re-temporiza para que su IMPACTO coincida con el arranque real del movimiento.
--   * Todo se mezcla suavemente (sin saltos entre poses). Se ejecuta en TODOS los clientes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))
local RAW = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("AnimationData"))

local PoseController = {}

local JOINTS = { -- orden de los datos
	{ Part = "Torso", Name = "Right Shoulder" },
	{ Part = "Torso", Name = "Left Shoulder" },
	{ Part = "Torso", Name = "Right Hip" },
	{ Part = "Torso", Name = "Left Hip" },
	{ Part = "Torso", Name = "Neck" },
	{ Part = "HumanoidRootPart", Name = "RootJoint" },
}

local MOVE_ANIM = {
	Light_Neutral = "Jab", Light_Side = "Jab", Light_Up = "Uppercut", Light_Down = "LowKick",
	AirLight_Down = "Stomp",
	Heavy_Neutral = "Haymaker", Heavy_Side = "Haymaker", Heavy_Up = "DoubleUp", Heavy_Down = "Sweep",
	Special_Neutral = "Palms", Special_Side = "Palms", Special_Up = "Rise", Special_Down = "Slam",
}
local GENERIC = {
	Dodge_Left = { Pose = "Roll", Startup = 0.02, Active = 0.26, Endlag = 0.12 },
	Dodge_Right = { Pose = "Roll", Startup = 0.02, Active = 0.26, Endlag = 0.12 },
	Dodge_Down = { Pose = "Dodge", Startup = 0.02, Active = 0.26, Endlag = 0.1 },
	Dodge_Air = { Pose = "Dodge", Startup = 0.02, Active = 0.26, Endlag = 0.1 },
	Grab = { Pose = "Grab", Startup = 0.08, Active = 0.5, Endlag = 0.2 },
	Throw_Forward = { Pose = "ThrowForward", Startup = 0.08, Active = 0.12, Endlag = 0.22 },
	Throw_Back = { Pose = "ThrowBack", Startup = 0.1, Active = 0.12, Endlag = 0.22 },
	Throw_Up = { Pose = "ThrowUp", Startup = 0.08, Active = 0.12, Endlag = 0.22 },
	Throw_Down = { Pose = "ThrowDown", Startup = 0.08, Active = 0.12, Endlag = 0.22 },
	Ultimate = { Pose = "Beam", Startup = 0.5, Active = 0.4, Endlag = 0.4 },
}

local CULL_DISTANCE = 230
local BLEND_SPEED = 22 -- cuanto más alto, más rápido llega a la pose objetivo

-- ===== Datos: cuaterniones -> CFrames (una sola vez al cargar)
local ANIMS = {}
for name, a in RAW do
	local frames = table.create(#a.Frames)
	for i, f in a.Frames do
		local pose = table.create(7)
		for j = 0, 5 do
			local k = j * 4
			pose[j + 1] = CFrame.new(0, 0, 0, f[k + 1], f[k + 2], f[k + 3], f[k + 4])
		end
		pose[7] = Vector3.new(f[25], f[26], f[27])
		frames[i] = pose
	end
	ANIMS[name] = { Length = a.Length, Loop = a.Loop, Hit = a.Hit, Recover = a.Recover, Fps = a.Fps, Frames = frames }
end

local function sample(anim, t: number)
	local frames = anim.Frames
	local n = #frames
	local x = t * anim.Fps
	local i0, alpha
	if anim.Loop then
		x %= n
		i0 = math.floor(x)
		alpha = x - i0
		local a, b = frames[i0 + 1], frames[(i0 + 1) % n + 1]
		local out = table.create(7)
		for j = 1, 6 do
			out[j] = a[j]:Lerp(b[j], alpha)
		end
		out[7] = a[7]:Lerp(b[7], alpha)
		return out
	end
	x = math.clamp(x, 0, n - 1)
	i0 = math.floor(x)
	alpha = x - i0
	local a, b = frames[i0 + 1], frames[math.min(i0 + 2, n)]
	local out = table.create(7)
	for j = 1, 6 do
		out[j] = a[j]:Lerp(b[j], alpha)
	end
	out[7] = a[7]:Lerp(b[7], alpha)
	return out
end

-- ===== Estado por luchador
local states = setmetatable({}, { __mode = "k" })

local function getState(model: Model)
	local s = states[model]
	if s then
		return s
	end
	local motors, bases = {}, {}
	for i, info in JOINTS do
		local part = model:FindFirstChild(info.Part)
		local m = part and part:FindFirstChild(info.Name)
		if not (m and m:IsA("Motor6D")) then
			return nil
		end
		motors[i] = m
		bases[i] = m.C0
	end
	s = {
		Motors = motors, Bases = bases, Current = nil,
		BaseTime = 0, BaseName = "Idle", Action = nil,
		WasAir = false, LastVY = 0,
	}
	states[model] = s
	return s
end

local function playAction(model: Model, animName: string, duration: number, timeMap)
	local s = getState(model)
	local anim = ANIMS[animName]
	if not s or not anim then
		return
	end
	s.Action = { Anim = anim, Start = os.clock(), Duration = duration, Map = timeMap }
end

function PoseController.Reset(model: Model)
	local s = states[model]
	if s then
		s.Action = nil
	end
end

-- Golpe: el impacto de la animación cae justo al acabar el arranque (Startup) del movimiento
function PoseController.Play(model: Model, moveKey: string, move)
	local animName = move.Pose or MOVE_ANIM[moveKey] or (if moveKey:find("Special") then "Palms" else "Jab")
	local anim = ANIMS[animName] or ANIMS.Jab
	local startup = math.max(move.Startup or 0.05, 0.03)
	local active = math.max(move.Active or 0, 0.08)
	local endlag = math.clamp(move.Endlag or 0.2, 0.15, 0.5)
	local L = anim.Length
	local hit = anim.Hit or L * 0.3
	local rec = math.max(anim.Recover or hit + 0.1, hit)
	playAction(model, animName, startup + active + endlag, function(g)
		if g < startup then
			return hit * g / startup
		elseif g < startup + active then
			return hit + (rec - hit) * (g - startup) / active
		end
		return rec + (L - rec) * math.min(1, (g - startup - active) / endlag)
	end)
end

-- Acción con su duración natural (aterrizar, recibir daño, doble salto...)
local function playNatural(model: Model, animName: string, speed: number?)
	local anim = ANIMS[animName]
	if anim then
		local k = speed or 1
		playAction(model, animName, anim.Length / k, function(g)
			return g * k
		end)
	end
end

-- ===== Bucle
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

local function baseAnim(model: Model, s, hrp: BasePart, dt: number)
	local v = hrp.AssemblyLinearVelocity
	rayParams.FilterDescendantsInstances = { model }
	local grounded = workspace:Raycast(hrp.Position, Vector3.new(0, -3.6, 0), rayParams) ~= nil
	local relaxed = model:GetAttribute("MoveMode") == "Free"

	-- Eventos: aterrizaje y doble salto (se detectan por la física, sirven para todos los jugadores)
	if grounded and s.WasAir and s.LastVY < -25 and not s.Action then
		playNatural(model, "Land", 1.2)
	elseif not grounded and v.Y - s.LastVY > 30 and s.LastVY < 15 and not s.Action and not relaxed then
		playNatural(model, "DoubleJump")
	end
	s.WasAir = not grounded
	s.LastVY = v.Y

	local speed = Vector2.new(v.X, v.Z).Magnitude
	local name, rate = "Idle", 1
	if model:GetAttribute("Shielding") then
		name = "Shield"
	elseif not grounded then
		name = if v.Y > 4 then "Jump" else "Fall"
	elseif speed < 1.5 then
		name = if relaxed then "IdleRelaxed" else "Idle"
	elseif speed < 19 then
		name = if relaxed then "WalkRelaxed" else "Walk"
		rate = math.clamp(speed / (if relaxed then 13 else 15), 0.6, 1.4)
	else
		name = "Run"
		rate = math.clamp(speed / 24, 0.8, 1.4)
	end
	if name ~= s.BaseName then
		s.BaseName = name
		s.BaseTime = 0
	end
	s.BaseTime += dt * rate
	return sample(ANIMS[name], s.BaseTime)
end

local function step(dt: number)
	local camera = workspace.CurrentCamera
	local camPos = camera and camera.CFrame.Position or Vector3.zero
	local alpha = 1 - math.exp(-BLEND_SPEED * dt)
	local now = os.clock()
	for _, model in CollectionService:GetTagged("Fighter") do
		local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp or not model:IsDescendantOf(workspace) or (hrp.Position - camPos).Magnitude > CULL_DISTANCE then
			continue
		end
		local s = getState(model)
		if not s then
			continue
		end
		local target
		local action = s.Action
		if action then
			local g = now - action.Start
			if g >= action.Duration then
				s.Action = nil
			else
				target = sample(action.Anim, action.Map(g))
			end
		end
		local base = baseAnim(model, s, hrp, dt)
		target = target or base

		local cur = s.Current
		if not cur then
			cur = target
		else
			local a = if action then math.min(1, alpha * 1.6) else alpha -- los golpes llegan más rápido
			local mixed = table.create(7)
			for j = 1, 6 do
				mixed[j] = cur[j]:Lerp(target[j], a)
			end
			mixed[7] = cur[7]:Lerp(target[7], a)
			cur = mixed
		end
		s.Current = cur

		for j = 1, 6 do
			local motor = s.Motors[j]
			if motor.Parent then
				local b = s.Bases[j]
				local offset = if j == 6 then cur[7] else Vector3.zero
				motor.C0 = CFrame.new(b.Position + offset) * cur[j] * b.Rotation
			end
		end
	end
end

function PoseController.Start()
	RunService.RenderStepped:Connect(step)
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CombatFeedback").OnClientEvent:Connect(function(kind, a, b, c)
		if typeof(a) ~= "Instance" or not a:IsA("Model") then
			return
		end
		if kind == "MoveStarted" then
			local move = GENERIC[b]
			if not move then
				local data = CharacterRegistry.Get(a:GetAttribute("CharacterId"))
				move = data and data.Moves[b]
			end
			if move then
				PoseController.Play(a, b, move)
			end
		elseif kind == "Hit" then
			-- c = fuerza del golpe: los fuertes mandan a volar dando vueltas
			if (c or 0) > 70 then
				playNatural(a, "Tumble", 0.9)
			else
				playNatural(a, "Hurt", 1.1)
			end
		end
	end)
end

return PoseController
