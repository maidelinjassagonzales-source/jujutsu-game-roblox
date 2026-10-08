-- CombatController: lee los inputs de combate y los envía al servidor.
-- Controles:
--   Clic izq / J / X(mando)   -> Golpe (ligero)
--   Clic der / K / Y(mando)   -> Fuerte (smash). En el suelo, MANTENER para cargarlo (hasta +40% de daño)
--   E / L / B(mando)          -> Especial
--   Q / L2 (mantener)         -> ESCUDO. Con escudo: ←/→ = rodar, ↓ = esquiva en el sitio.
--                                En el aire: esquiva aérea.
--   G / R2                    -> AGARRE (atraviesa escudos). Lanza hacia la dirección que mantengas.
--   Mantener A/D (lado), W (arriba), S (abajo) cambia la variante de cada ataque
--   T                         -> cambiar personaje (en el Hub; en el Dojo puedes probar cualquiera)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local KnockbackSimulator = require(Shared:WaitForChild("KnockbackSimulator"))
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))
local Config = require(Shared:WaitForChild("CombatConfig"))

local MovementController = require(script.Parent:WaitForChild("MovementController"))
local CameraController = require(script.Parent:WaitForChild("CameraController"))

local player = Players.LocalPlayer

local CombatController = {}

local request: RemoteEvent
local animCache = setmetatable({}, { __mode = "k" }) -- [Animator] = { [animId] = AnimationTrack }
local shieldHeld = false
local shieldKeyDown = false -- la tecla de escudo sigue pulsada (para volver a levantarlo tras rodar)
local lastShieldTry = 0
local lastDodgeX, lastDodgeDown = false, false

-- Carga del ataque fuerte (smash)
local charge: { Start: number, Dir: string, Facing: number }? = nil

-- Agarre: la dirección del lanzamiento se puede elegir mientras tienes al rival agarrado
local grabUntil = 0
local grabFacing = 1
local lastThrowDir = "Side"

local function inFreeMode(): boolean
	local character = player.Character
	return character ~= nil and character:GetAttribute("MoveMode") == "Free"
end

local function isGrounded(): boolean
	local _, humanoid = MovementController.GetCharacter()
	return humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
end

local function getDirectionAndFacing(): (string, number)
	local mv = MovementController.GetMoveVector()
	local facing = MovementController.GetFacing()

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

-- Smash cargable: al pulsar empieza la carga (quieto, brillando); al soltar o al llegar al máximo, golpea.
-- La dirección y el lado se fijan al pulsar, como en Smash. El servidor mide la carga él mismo.
local function startCharge()
	local dir, facing = getDirectionAndFacing()
	charge = { Start = os.clock(), Dir = dir, Facing = facing }
	MovementController.LockFor(Config.SmashChargeTime + 0.5)
	request:FireServer("Charge", true)
end

local function releaseCharge()
	local c = charge
	if not c then
		return
	end
	charge = nil
	MovementController.LockFor(0)
	request:FireServer("Attack", "Heavy", c.Dir, c.Facing)
end

local function cancelCharge()
	if charge then
		charge = nil
		MovementController.LockFor(0)
		request:FireServer("Charge", false)
	end
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
	if on then
		lastShieldTry = os.clock()
	end
	shieldHeld = on
	-- Si ya mantenías una dirección al levantar el escudo, hay que soltarla y volver a pulsarla para esquivar
	local mv = MovementController.GetMoveVector()
	lastDodgeX, lastDodgeDown = math.abs(mv.X) > 0.6, mv.Z > 0.6
	request:FireServer("Shield", on)
end

-- Dirección del lanzamiento respecto al lado hacia el que se agarró
local function throwDirection(facing: number): string
	local mv = MovementController.GetMoveVector()
	if -mv.Z > 0.5 then
		return "Up"
	elseif mv.Z > 0.5 then
		return "Down"
	elseif math.abs(mv.X) > 0.3 and math.sign(mv.X) ~= facing then
		return "Back" -- lanzar hacia atrás
	end
	return "Side"
end

function CombatController.Grab()
	if inFreeMode() then
		return
	end
	grabFacing = MovementController.GetFacing()
	lastThrowDir = throwDirection(grabFacing)
	if isGrounded() then
		-- Quieto y sin girarse mientras agarra: así A/D eligen lanzar delante/detrás
		grabUntil = os.clock() + Config.Defense.GrabStartup + Config.Defense.GrabActive + 0.1
		MovementController.LockFor(grabUntil - os.clock())
	end
	request:FireServer("Grab", lastThrowDir, grabFacing)
end

local function onAction(actionName: string, inputState: Enum.UserInputState)
	if actionName == "Shield" then
		if inputState == Enum.UserInputState.Begin then
			shieldKeyDown = true
			if not charge then
				CombatController.Shield(true)
			end
		elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			shieldKeyDown = false
			local character = player.Character
			if shieldHeld or (character and character:GetAttribute("Shielding")) then
				CombatController.Shield(false)
			end
		end
		return Enum.ContextActionResult.Sink
	end
	if actionName == "Heavy" then
		if inputState == Enum.UserInputState.Begin then
			if inFreeMode() then
				return Enum.ContextActionResult.Pass -- en el Lobby el clic derecho es para la cámara
			end
			if not charge then
				if isGrounded() and not shieldHeld and not KnockbackSimulator.IsActive(player.Character) then
					startCharge()
				else
					CombatController.Attack("Heavy") -- en el aire no se carga
				end
			end
		elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			releaseCharge()
		end
		return Enum.ContextActionResult.Sink
	end
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if inFreeMode() and actionName ~= "SwapCharacter" then
		return Enum.ContextActionResult.Pass -- en el Lobby el clic derecho es para la cámara y E abre los puestos
	end
	if charge and actionName ~= "SwapCharacter" then
		return Enum.ContextActionResult.Sink -- cargando un smash no se hace otra cosa
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
		charge = nil -- un golpe corta la carga (el servidor también la cancela)
		grabUntil = 0
		MovementController.LockFor(0)
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
	elseif kind == "Grabbed" and a == character then
		-- Tienes a alguien agarrado: hasta el lanzamiento puedes elegir dirección (sin girarte)
		grabUntil = os.clock() + Config.Defense.GrabHold
		MovementController.LockFor(Config.Defense.GrabHold + 0.1)
	elseif kind == "Respawned" then
		shieldHeld = false
		charge = nil
		grabUntil = 0
		MovementController.LockFor(0)
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

	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local character = player.Character

		-- Smash cargado al máximo: se suelta solo
		if charge and now - charge.Start >= Config.SmashChargeTime then
			releaseCharge()
		end

		-- Agarrando: actualizar la dirección del lanzamiento si cambia
		if now < grabUntil then
			local dir = throwDirection(grabFacing)
			if dir ~= lastThrowDir then
				lastThrowDir = dir
				request:FireServer("ThrowDir", dir)
			end
		end

		-- Escudo mantenido: si se cayó (tras rodar, esquivar o recibir un golpe) se vuelve a levantar
		-- en cuanto se pueda, sin tener que soltar y volver a pulsar la tecla
		if shieldKeyDown and not charge and character and not character:GetAttribute("Shielding")
			and not inFreeMode() and isGrounded() and not KnockbackSimulator.IsActive(character)
			and now - lastShieldTry > 0.2 then
			CombatController.Shield(true)
		end

		-- Con el escudo puesto, un toque de dirección = esquiva (rodar o en el sitio)
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
