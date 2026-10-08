-- CameraController:
--   * Modo arena (2D): cámara lateral estilo Smash que encuadra a los luchadores de TU arena.
--   * Modo libre (obby): cámara 3D en tercera persona (clic derecho / arrastrar para girar, rueda = zoom).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("CombatConfig"))
local ArenaInfo = require(Shared:WaitForChild("ArenaInfo"))

local player = Players.LocalPlayer

local CameraController = {}

local shakeIntensity = 0
local shakeUntil = 0

-- Cámara libre
local yaw, pitch, zoom = 0, math.rad(18), 22
local dragging = false
local wasFree = false
local rightStick = Vector2.zero -- stick derecho del mando (cámara del Lobby)

-- Modo cine: si hay override, manda él (CinematicController). fn(dt) -> CFrame?
local override: ((number) -> CFrame?)? = nil

function CameraController.SetOverride(fn: ((number) -> CFrame?)?)
	override = fn
end

function CameraController.Shake(intensity: number, duration: number)
	shakeIntensity = math.max(shakeIntensity, intensity)
	shakeUntil = math.max(shakeUntil, os.clock() + duration)
end

local function applyShake(cf: CFrame): CFrame
	if os.clock() < shakeUntil then
		local s = shakeIntensity
		return cf * CFrame.new((math.random() - 0.5) * s, (math.random() - 0.5) * s, 0)
	end
	shakeIntensity = 0
	return cf
end

local function freeMode(): boolean
	local character = player.Character
	return character ~= nil and character:GetAttribute("MoveMode") == "Free"
end

function CameraController.Start()
	local camConfig = Config.Camera
	local current: CFrame? = nil

	-- Controles de la cámara libre
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseButton2 and freeMode() and not processed then
			dragging = true
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			dragging = false
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end)
	UserInputService.InputChanged:Connect(function(input, processed)
		if not freeMode() then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
			yaw -= input.Delta.X * 0.006
			pitch = math.clamp(pitch + input.Delta.Y * 0.006, math.rad(-20), math.rad(70))
		elseif input.UserInputType == Enum.UserInputType.MouseWheel and not processed then
			zoom = math.clamp(zoom - input.Position.Z * 2.5, 8, 45)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Thumbstick2 then
			local v = Vector2.new(input.Position.X, input.Position.Y)
			rightStick = if v.Magnitude > 0.15 then v else Vector2.zero
		end
	end)
	UserInputService.TouchMoved:Connect(function(touch, processed)
		if freeMode() and not processed and touch.Position.X > workspace.CurrentCamera.ViewportSize.X * 0.45 then
			yaw -= touch.Delta.X * 0.008
			pitch = math.clamp(pitch + touch.Delta.Y * 0.008, math.rad(-20), math.rad(70))
		end
	end)

	RunService:BindToRenderStep("SmashCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Scriptable
		if override then
			local cf = override(dt)
			if cf then
				camera.CFrame = applyShake(cf)
				current = cf -- al terminar, la cámara lateral vuelve con suavidad desde aquí
				return
			end
		end
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?

		-- ===== Cámara libre (Lobby 3D)
		local free = freeMode()
		if free and not wasFree then
			yaw, pitch = 0, math.rad(18) -- al llegar al Lobby: mirando a la Escuela
		end
		wasFree = free
		if free and rightStick.Magnitude > 0 then
			yaw -= rightStick.X * dt * 2.6
			pitch = math.clamp(pitch - rightStick.Y * dt * 1.8, math.rad(-20), math.rad(70))
		end
		if free and hrp then
			local target = hrp.Position + Vector3.new(0, 2.5, 0)
			local rot = CFrame.Angles(0, yaw, 0) * CFrame.Angles(-pitch, 0, 0)
			local desired = target + rot:VectorToWorldSpace(Vector3.new(0, 0, zoom))
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { character }
			local hit = workspace:Raycast(target, desired - target, params)
			local pos = if hit then hit.Position + hit.Normal * 0.6 else desired
			camera.CFrame = applyShake(CFrame.lookAt(pos, target))
			current = nil
			return
		end

		-- ===== Cámara lateral (arenas)
		local arenaId = if character then character:GetAttribute("ArenaId") else "Hub"
		local left, right, bottom, top = ArenaInfo.Bounds(arenaId)
		local info = ArenaInfo.Get(arenaId)
		local centerX = if info then info:GetAttribute("CenterX") or 0 else 0
		left, right, bottom, top = left or (centerX - 140), right or (centerX + 140), bottom or -50, top or 95

		local minX, maxX, minY, maxY
		for _, model in CollectionService:GetTagged("Fighter") do
			local fhrp = model:FindFirstChild("HumanoidRootPart")
			if fhrp and model:GetAttribute("ArenaId") == arenaId and not model:GetAttribute("KOing") and not model:GetAttribute("Eliminated") then
				local p = fhrp.Position
				local x = math.clamp(p.X, left + 20, right - 20)
				local y = math.clamp(p.Y, bottom + 15, top - 15)
				minX = if minX then math.min(minX, x) else x
				maxX = if maxX then math.max(maxX, x) else x
				minY = if minY then math.min(minY, y) else y
				maxY = if maxY then math.max(maxY, y) else y
			end
		end

		local center, spread
		if minX then
			center = Vector3.new((minX + maxX) / 2, (minY + maxY) / 2, Config.PlaneZ)
			spread = math.max(maxX - minX, (maxY - minY) * 1.7)
		else
			center = Vector3.new(centerX, 10, Config.PlaneZ)
			spread = 0
		end

		local distance = math.clamp(camConfig.MinDistance + spread * camConfig.SpreadFactor, camConfig.MinDistance, camConfig.MaxDistance)
		local target = CFrame.lookAt(center + Vector3.new(0, camConfig.Height, distance), center)

		-- Al cambiar de arena (saltos de 1000 studs) no se interpola: corte directo
		if current and (current.Position - target.Position).Magnitude > 300 then
			current = nil
		end
		local alpha = 1 - math.exp(-camConfig.Smoothness * dt)
		current = if current then current:Lerp(target, alpha) else target
		camera.CFrame = applyShake(current :: CFrame)
	end)
end

return CameraController
