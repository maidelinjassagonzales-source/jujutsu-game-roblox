-- MovementController: movimiento 2D estilo Smash.
--   * Solo eje X (W/S se reutilizan como "arriba/abajo" para direcciones de ataque)
--   * Salto doble
--   * Caída rápida (S / abajo en el aire)
--   * Bloqueo al plano Z
-- Funciona en PC, mando y móvil porque lee el vector del PlayerModule.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("CombatConfig"))
local Sfx = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Sfx"))
local KnockbackSimulator = require(Shared:WaitForChild("KnockbackSimulator"))

local player = Players.LocalPlayer

local MovementController = {}

local controls
local character: Model?
local humanoid: Humanoid?
local hrp: BasePart?
local airJumpsUsed = 0
local lastJumpTime = 0
local externalMove = Vector3.zero
local dropUntil = 0

local FREE_WALK_SPEED, FREE_RUN_SPEED = 14, 26 -- Lobby: caminar / correr

local function isFreeMode(): boolean
	return character ~= nil and character:GetAttribute("MoveMode") == "Free"
end

function MovementController.SetExternalMoveVector(v: Vector3)
	externalMove = v
end

local KEYS = {
	Left = { Enum.KeyCode.A, Enum.KeyCode.Left },
	Right = { Enum.KeyCode.D, Enum.KeyCode.Right },
	Up = { Enum.KeyCode.W, Enum.KeyCode.Up },
	Down = { Enum.KeyCode.S, Enum.KeyCode.Down },
}
local THUMBSTICK_DEADZONE = 0.25

local function anyKeyDown(list): boolean
	if UserInputService:GetFocusedTextBox() then
		return false -- escribiendo en el chat
	end
	for _, key in list do
		if UserInputService:IsKeyDown(key) then
			return true
		end
	end
	return false
end

-- X = izquierda/derecha, Z = -1 arriba (W) / +1 abajo (S)
-- Lee teclado y mando directamente; el PlayerModule (si existe) aporta el joystick táctil.
function MovementController.GetMoveVector(): Vector3
	local x, z = 0, 0
	if anyKeyDown(KEYS.Left) then x -= 1 end
	if anyKeyDown(KEYS.Right) then x += 1 end
	if anyKeyDown(KEYS.Up) then z -= 1 end
	if anyKeyDown(KEYS.Down) then z += 1 end

	for _, input in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
		if input.KeyCode == Enum.KeyCode.Thumbstick1 and input.Position.Magnitude > THUMBSTICK_DEADZONE then
			x += input.Position.X
			z -= input.Position.Y
		end
	end

	local v = Vector3.new(math.clamp(x, -1, 1), 0, math.clamp(z, -1, 1))
	if externalMove.Magnitude > v.Magnitude then
		v = externalMove -- joystick táctil propio (MobileController)
	end
	if controls then
		local cv = controls:GetMoveVector()
		if cv.Magnitude > v.Magnitude then
			v = cv
		end
	end
	return v
end

function MovementController.GetCharacter()
	return character, humanoid, hrp
end

function MovementController.ResetAirJumps()
	airJumpsUsed = 0
end

local function onCharacterAdded(char: Model)
	character = char
	humanoid = nil
	hrp = nil
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	local root = char:WaitForChild("HumanoidRootPart") :: BasePart
	if character ~= char then
		return
	end
	humanoid, hrp = hum, root
	airJumpsUsed = 0

	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			airJumpsUsed = 0
		end
	end)
end

-- Teclado/mando y el botón táctil pueden llamar a la vez: el debounce compartido evita dobles saltos.
local function tryJump()
	MovementController.TryJump()
end

function MovementController.TryJump()
	if not humanoid or not hrp or KnockbackSimulator.IsActive(character) then
		return
	end
	local now = os.clock()
	if now - lastJumpTime < 0.22 then
		return
	end
	if humanoid.FloorMaterial ~= Enum.Material.Air then
		lastJumpTime = now
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		Sfx.Play("Jump", hrp, 0.6)
		return
	end
	if isFreeMode() or airJumpsUsed >= Config.MaxAirJumps then -- en el Lobby no hay salto doble
		return
	end
	airJumpsUsed += 1
	lastJumpTime = now
	Sfx.Play("Jump", hrp, 0.7, 1.25)
	local v = hrp.AssemblyLinearVelocity
	hrp.AssemblyLinearVelocity = Vector3.new(v.X, Config.DoubleJumpVelocity, 0)
end

function MovementController.Start()
	-- PlayerModule es opcional (solo aporta los controles táctiles); no bloqueamos si no existe.
	task.spawn(function()
		local module = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 10)
		if module then
			controls = require(module):GetControls()
		end
	end)

	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end

	-- Se ejecuta justo después del ControlModule para sobrescribir su Move()
	RunService:BindToRenderStep("SmashMovement", Enum.RenderPriority.Input.Value + 1, function()
		if not humanoid or not hrp or not hrp.Parent then
			return
		end
		if KnockbackSimulator.IsActive(character) then
			humanoid:Move(Vector3.zero, false)
			return
		end

		local mv = MovementController.GetMoveVector()

		-- Modo libre (Lobby): movimiento 3D relativo a la cámara
		if isFreeMode() then
			local camCF = workspace.CurrentCamera.CFrame
			local forward = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
			local right = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
			local dir = Vector3.zero
			if forward.Magnitude > 0.01 then
				dir = right.Unit * mv.X + forward.Unit * -mv.Z
			end
			humanoid:Move(if dir.Magnitude > 1 then dir.Unit else dir, false)
			-- Caminar / correr: Shift (o L3, o el joystick táctil a tope) para correr
			local sprint = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
				or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonL3)
				or (UserInputService.TouchEnabled and mv.Magnitude > 0.92)
			humanoid.WalkSpeed = if sprint then FREE_RUN_SPEED else FREE_WALK_SPEED
			return
		end

		-- Con el escudo puesto no se camina (las direcciones sirven para esquivar)
		if character:GetAttribute("Shielding") then
			humanoid:Move(Vector3.zero, false)
			return
		end
		humanoid:Move(Vector3.new(mv.X, 0, 0), false)

		-- Caída rápida
		local v = hrp.AssemblyLinearVelocity
		if mv.Z > 0.6 and humanoid.FloorMaterial == Enum.Material.Air and v.Y < 10 and v.Y > -Config.FastFallSpeed then
			hrp.AssemblyLinearVelocity = Vector3.new(v.X, -Config.FastFallSpeed, 0)
		end
		-- Bajar de una plataforma atravesable: abajo estando en el suelo
		if mv.Z > 0.7 and humanoid.FloorMaterial ~= Enum.Material.Air then
			dropUntil = os.clock() + 0.3
		end
	end)

	-- Plataformas atravesables (solo afectan a TU física; el servidor las ve sólidas para los NPC)
	RunService.Stepped:Connect(function()
		if not hrp or not hrp.Parent then
			return
		end
		local feet = hrp.Position.Y - 3
		local dropping = os.clock() < dropUntil
		for _, platform in CollectionService:GetTagged("SoftPlatform") do
			if platform:IsA("BasePart") then
				local top = platform.Position.Y + platform.Size.Y / 2
				platform.CanCollide = not dropping and feet >= top - 0.7
			end
		end
	end)

	-- Bloqueo al plano 2D
	RunService.Heartbeat:Connect(function()
		if not hrp or not hrp.Parent or hrp.Anchored or isFreeMode() then
			return
		end
		local pos = hrp.Position
		if math.abs(pos.Z - Config.PlaneZ) > 0.05 then
			hrp.CFrame += Vector3.new(0, 0, Config.PlaneZ - pos.Z)
		end
		local v = hrp.AssemblyLinearVelocity
		if v.Z ~= 0 then
			hrp.AssemblyLinearVelocity = Vector3.new(v.X, v.Y, 0)
		end
	end)

	-- ContextActionService (igual que los ataques): InputBegan marca Espacio como "gameProcessed".
	ContextActionService:BindActionAtPriority("SmashJump", function(_, state)
		if state == Enum.UserInputState.Begin then
			tryJump()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
	UserInputService.JumpRequest:Connect(tryJump) -- botón de salto táctil
end

return MovementController
