-- MobileController: controles táctiles propios (no dependen del PlayerModule de Roblox).
--   * Joystick dinámico en la mitad izquierda (aparece donde pones el dedo)
--   * Botones a la derecha: Golpe, Fuerte, Especial y Saltar
-- La dirección del joystick también elige la variante del ataque (arriba/abajo/lado).
local UserInputService = game:GetService("UserInputService")

local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local MovementController = require(script.Parent:WaitForChild("MovementController"))
local CombatController = require(script.Parent:WaitForChild("CombatController"))

local MobileController = {}

local JOYSTICK_RADIUS = 60

local function actionButton(parent: Instance, text: string, color: Color3, size: number, position: UDim2, onPress: () -> ())
	local b = UI.make("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = position, Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = color, BackgroundTransparency = 0.15, Text = string.upper(text), TextSize = if size >= 70 then 16 else 12,
		Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = false,
		TextStrokeTransparency = 0.3, TextStrokeColor3 = UI.darker(color, 0.7),
	}, parent)
	UI.corner(b, size // 2)
	UI.gradient(b, Color3.new(1, 1, 1), Color3.fromRGB(120, 120, 130))
	UI.stroke(b, color:Lerp(Color3.new(1, 1, 1), 0.55), 2.5).Transparency = 0.15
	-- Anillo exterior suave
	local ring = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 10, 1, 10), BackgroundTransparency = 1,
	}, b)
	UI.corner(ring, size)
	UI.make("UIStroke", { Color = color, Thickness = 3, Transparency = 0.7 }, ring)
	local scale = UI.make("UIScale", {}, b)
	b.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			scale.Scale = 0.88
			game:GetService("TweenService"):Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			onPress()
		end
	end)
	return b
end

function MobileController.Start()
	if not UserInputService.TouchEnabled then
		return
	end
	-- Fuera los controles táctiles de Roblox (joystick y botón de salto): se superponían con los nuestros
	pcall(function()
		game:GetService("GuiService").TouchControlsEnabled = false
	end)
	task.spawn(function()
		local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
		local function hide(child: Instance)
			if child.Name == "TouchGui" and child:IsA("ScreenGui") then
				child.Enabled = false
				child:GetPropertyChangedSignal("Enabled"):Connect(function()
					child.Enabled = false
				end)
			end
		end
		for _, child in playerGui:GetChildren() do
			hide(child)
		end
		playerGui.ChildAdded:Connect(hide)
	end)

	local gui = UI.screenGui("MobileControls", 6)


	local gui = UI.screenGui("MobileControls", 6, true)

	-- Joystick dinámico
	local zone = UI.make("Frame", {
		Position = UDim2.fromScale(0, 0.45), Size = UDim2.fromScale(0.45, 0.55), BackgroundTransparency = 1, Active = true,
	}, gui)
	local base = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2),
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.6, Visible = false,
	}, gui)
	UI.corner(base, JOYSTICK_RADIUS)
	UI.stroke(base, Color3.new(1, 1, 1), 2).Transparency = 0.6
	local knob = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(50, 50),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.3,
	}, base)
	UI.corner(knob, 25)

	local activeTouch: InputObject? = nil
	local origin = Vector2.zero

	local function update(position: Vector2)
		local delta = position - origin
		if delta.Magnitude > JOYSTICK_RADIUS then
			delta = delta.Unit * JOYSTICK_RADIUS
		end
		knob.Position = UDim2.new(0.5, delta.X, 0.5, delta.Y)
		local v = delta / JOYSTICK_RADIUS
		-- X = lado, Z = +abajo / -arriba (mismo formato que el teclado)
		MovementController.SetExternalMoveVector(Vector3.new(v.X, 0, v.Y))
	end

	local stateConn: RBXScriptConnection? = nil
	local function release()
		activeTouch = nil
		base.Visible = false
		MovementController.SetExternalMoveVector(Vector3.zero)
		if stateConn then
			stateConn:Disconnect()
			stateConn = nil
		end
	end

	zone.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch or activeTouch then
			return
		end
		activeTouch = input
		origin = Vector2.new(input.Position.X, input.Position.Y)
		base.Position = UDim2.fromOffset(origin.X, origin.Y)
		base.Visible = true
		update(origin)
		-- Fiable en todos los dispositivos: el propio InputObject avisa cuando el dedo se levanta
		stateConn = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
			if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
				release()
			end
		end)
	end)
	UserInputService.TouchMoved:Connect(function(input)
		if input == activeTouch then
			update(Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
	UserInputService.TouchEnded:Connect(function(input)
		if input == activeTouch then
			release()
		end
	end)

	-- Botones de acción (abajo a la derecha)
	local pad = UI.make("Frame", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(250, 200),
		BackgroundTransparency = 1,
	}, gui)
	UI.autoScale(pad, 480) -- botones grandes: cómodos para el pulgar incluso en móviles pequeños
	actionButton(pad, "Attack", Color3.fromRGB(220, 60, 70), 84, UDim2.fromOffset(160, 150), function()
		CombatController.Attack("Light")
	end)
	actionButton(pad, "Heavy", Color3.fromRGB(230, 130, 30), 64, UDim2.fromOffset(70, 160), function()
		CombatController.Attack("Heavy")
	end)
	actionButton(pad, "Special", Color3.fromRGB(150, 70, 220), 64, UDim2.fromOffset(110, 80), function()
		CombatController.Attack("Special")
	end)
	actionButton(pad, "Jump", Color3.fromRGB(40, 150, 230), 64, UDim2.fromOffset(196, 60), function()
		MovementController.TryJump()
	end)
	actionButton(pad, "Grab", Color3.fromRGB(60, 160, 90), 54, UDim2.fromOffset(40, 90), function()
		CombatController.Grab()
	end)
	local ult = actionButton(pad, "ULT", Color3.fromRGB(255, 190, 40), 58, UDim2.fromOffset(230, 0), function()
		CombatController.Ultimate()
	end)
	task.spawn(function()
		local player = game:GetService("Players").LocalPlayer
		while ult.Parent do
			local c = player.Character
			local ready = c ~= nil and (c:GetAttribute("Ult") or 0) >= 100
			ult.BackgroundTransparency = if ready then 0 else 0.7
			ult.Text = if ready then "ULT" else `{math.floor(c and c:GetAttribute("Ult") or 0)}%`
			task.wait(0.2)
		end
	end)
	-- Escudo: se mantiene pulsado. Con él puesto, el joystick hace esquivas.
	local shield = actionButton(pad, "Shield", Color3.fromRGB(80, 120, 200), 54, UDim2.fromOffset(0, 150), function()
		CombatController.Shield(true)
	end)
	shield.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			CombatController.Shield(false)
		end
	end)
end

return MobileController
