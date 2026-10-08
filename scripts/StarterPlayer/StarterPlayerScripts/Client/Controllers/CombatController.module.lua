-- CombatController: lee los inputs de combate y los envía al servidor.
-- Controles:
--   Clic izq / J / X(mando)   -> Golpe (ligero)
--   Clic der / K / Y(mando)   -> Fuerte (smash)
--   E / L / B(mando)          -> Especial
--   Q / L2 (mantener)         -> ESCUDO. Con escudo: ←/→ = rodar, ↓ = esquiva en el sitio.
--                                En el aire: esquiva aérea.
--   G / R2                    -> AGARRE (atraviesa escudos). Lanza hacia la dirección que mantengas.
--   Mantener A/D (lado), W (arriba), S (abajo) cambia la variante de cada ataque
--   T                         -> cambiar personaje (en el Hub)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local KnockbackSimulator = require(Shared:WaitForChild("KnockbackSimulator"))
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))

local MovementController = require(script.Parent:WaitForChild("MovementController"))
local CameraController = require(script.Parent:WaitForChild("CameraController"))

local player = Players.LocalPlayer

local CombatController = {}

local request: RemoteEvent
local animCache = setmetatable({}, { __mode = "k" }) -- [Animator] = { [animId] = AnimationTrack }
local shieldHeld = false
local lastDodgeX, lastDodgeDown = false, false

local function inFreeMode(): boolean
	local character = player.Character
	return character ~= nil and character:GetAttribute("MoveMode") == "Free"
end

local function getDirectionAndFacing(): (string, number)
	local mv = MovementController.GetMoveVector()
	local _, _, hrp = MovementController.GetCharacter()
	local facing = if hrp and hrp.CFrame.LookVector.X < 0 then -1 else 1

	local horizontal = math.abs(mv.X)
	local vertical = -mv.Z -- positivo = arriba
	if math.abs(vertical) > 0.5 and math.abs(vertical) >= horizontal then
		return (if vertical > 0 then "Up" else "Down"), facing
	elseif horizontal > 0.3 then
		return "Side", (if mv.X > 0 then 1 else -1)
	end
	return "Neutral", facing
end

-- kind = "Light" | "Heavy" | "Special". La variante sale de la dirección que se mantiene.
function CombatController.Attack(kind: string)
	if inFreeMode() then
		return
	end
	local dir, facing = getDirectionAndFacing()
	request:FireServer("Attack", kind, dir, facing)
end

function CombatController.Shield(on: boolean)
	if inFreeMode() then
		return
	end
	local _, humanoid = MovementController.GetCharacter()
	if on and humanoid and humanoid.FloorMaterial == Enum.Material.Air then
		request:FireServer("Dodge", "Air") -- escudo en el aire = esquiva aérea
		return
	end
	shieldHeld = on
	-- Si ya mantenías una dirección al levantar el escudo, hay que soltarla y volver a pulsarla para esquivar
	local mv = MovementController.GetMoveVector()
	lastDodgeX, lastDodgeDown = math.abs(mv.X) > 0.6, mv.Z > 0.6
	request:FireServer("Shield", on)
end

function CombatController.Grab()
	if inFreeMode() then
		return
	end
	local mv = MovementController.GetMoveVector()
	local _, _, hrp = MovementController.GetCharacter()
	local facing = if hrp and hrp.CFrame.LookVector.X < 0 then -1 else 1
	local dir = "Side"
	if -mv.Z > 0.5 then
		dir = "Up"
	elseif mv.Z > 0.5 then
		dir = "Down"
	elseif math.abs(mv.X) > 0.3 and math.sign(mv.X) ~= facing then
		dir = "Back" -- lanzar hacia atrás
	end
	request:FireServer("Grab", dir, facing)
end

local function onAction(actionName: string, inputState: Enum.UserInputState)
	if actionName == "Shield" then
		if inputState == Enum.UserInputState.Begin then
			CombatController.Shield(true)
		elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			if shieldHeld then
				CombatController.Shield(false)
			end
		end
		return Enum.ContextActionResult.Sink
	end
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if inFreeMode() and actionName ~= "SwapCharacter" then
		return Enum.ContextActionResult.Pass -- en el Lobby el clic derecho es para la cámara y E abre los puestos
	end
	if actionName == "Ultimate" then
		CombatController.Ultimate()
	elseif actionName == "SwapCharacter" then
		request:FireServer("SwapCharacter")
	elseif actionName == "Grab" then
		CombatController.Grab()
	else
		CombatController.Attack(actionName)
	end
	return Enum.ContextActionResult.Sink
end

local function playMoveAnimation(character: Model, moveKey: string)
	local data = CharacterRegistry.Get(character:GetAttribute("CharacterId"))
	local move = data and data.Moves[moveKey]
	local animId = move and move.AnimationId
	if not animId or animId == "" then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	local cache = animCache[animator] or {}
	animCache[animator] = cache
	local track = cache[animId]
	if not track then
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		track = animator:LoadAnimation(anim)
		track.Priority = Enum.AnimationPriority.Action
		cache[animId] = track
	end
	track:Play(0.05)
end

local function onFeedback(kind: string, a, b, c)
	local character = player.Character
	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?

	if kind == "Knockback" then
		-- a = velocidad, b = hitstun
		shieldHeld = false
		KnockbackSimulator.Apply(character, a, b)
		if a.Magnitude > 1 then
			CameraController.Shake(math.clamp(a.Magnitude / 60, 0.3, 2), 0.2)
		end
	elseif kind == "Push" and hrp then
		-- golpe sobre el escudo: pequeño retroceso
		hrp.AssemblyLinearVelocity = a
	elseif kind == "MoveStarted" and a == character then
		-- b = moveKey, c = velocidad propia (embestidas, rodar...)
		if c and hrp then
			hrp.AssemblyLinearVelocity = c
		end
		playMoveAnimation(character, b)
	elseif kind == "Respawned" then
		shieldHeld = false
		KnockbackSimulator.Cancel(character)
		MovementController.ResetAirJumps()
		if hrp then
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
	end
end

-- ULTI: solo si la barra está llena (el servidor lo vuelve a comprobar)
function CombatController.Ultimate()
	local character = player.Character
	if character and (character:GetAttribute("Ult") or 0) >= 100 then
		request:FireServer("Ultimate")
	end
end

function CombatController.Start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	request = remotes:WaitForChild("CombatRequest")
	remotes:WaitForChild("CombatFeedback").OnClientEvent:Connect(onFeedback)

	-- Los botones táctiles los crea MobileController (no dependen del PlayerModule)
	ContextActionService:BindAction("Light", onAction, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.J, Enum.KeyCode.ButtonX)
	ContextActionService:BindAction("Heavy", onAction, false, Enum.UserInputType.MouseButton2, Enum.KeyCode.K, Enum.KeyCode.ButtonY)
	ContextActionService:BindAction("Special", onAction, false, Enum.KeyCode.E, Enum.KeyCode.L, Enum.KeyCode.ButtonB)
	ContextActionService:BindAction("Shield", onAction, false, Enum.KeyCode.Q, Enum.KeyCode.ButtonL2, Enum.KeyCode.ButtonL1)
	ContextActionService:BindAction("Grab", onAction, false, Enum.KeyCode.G, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonR1)
	ContextActionService:BindAction("SwapCharacter", onAction, false, Enum.KeyCode.T, Enum.KeyCode.ButtonR3)
	ContextActionService:BindAction("Ultimate", onAction, false, Enum.KeyCode.R, Enum.KeyCode.DPadUp)

	-- Con el escudo puesto, un toque de dirección = esquiva (rodar o en el sitio)
	RunService.Heartbeat:Connect(function()
		if not shieldHeld then
			return
		end
		local mv = MovementController.GetMoveVector()
		local x = math.abs(mv.X) > 0.6
		local down = mv.Z > 0.6
		if x and not lastDodgeX then
			shieldHeld = false
			request:FireServer("Dodge", if mv.X > 0 then "Right" else "Left")
		elseif down and not lastDodgeDown then
			shieldHeld = false
			request:FireServer("Dodge", "Down")
		end
		lastDodgeX, lastDodgeDown = x, down
	end)
end

return CombatController
