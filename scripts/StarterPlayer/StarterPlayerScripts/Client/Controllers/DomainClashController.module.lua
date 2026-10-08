-- DomainClashController: CHOQUE DE DOMINIOS (dos hechiceros expanden su dominio a la vez).
--   * Pantalla partida: a la izquierda el jugador 1 con su dominio, a la derecha el jugador 2
--   * Cada lado tiene la misma secuencia de teclas; los dos participantes pulsan las de SU lado
--   * Fallo o tardar demasiado = pierdes. El primero en completarla impone su dominio.
-- El servidor (UltimateService) decide todo; aquí solo se dibuja y se envían las pulsaciones.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local Sfx = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Sfx"))

local player = Players.LocalPlayer

local DomainClashController = {}

-- El servidor manda símbolos neutros; cada dispositivo tiene sus teclas y sus etiquetas
local KEYCODES = {
	-- Teclado
	[Enum.KeyCode.W] = "Up", [Enum.KeyCode.S] = "Down", [Enum.KeyCode.A] = "Left", [Enum.KeyCode.D] = "Right",
	[Enum.KeyCode.J] = "A", [Enum.KeyCode.K] = "B",
	[Enum.KeyCode.Up] = "Up", [Enum.KeyCode.Down] = "Down", [Enum.KeyCode.Left] = "Left", [Enum.KeyCode.Right] = "Right",
	-- Mando
	[Enum.KeyCode.DPadUp] = "Up", [Enum.KeyCode.DPadDown] = "Down", [Enum.KeyCode.DPadLeft] = "Left", [Enum.KeyCode.DPadRight] = "Right",
	[Enum.KeyCode.ButtonA] = "A", [Enum.KeyCode.ButtonB] = "B",
}
local LABELS = {
	Keyboard = { Up = "W", Down = "S", Left = "A", Right = "D", A = "J", B = "K" },
	Gamepad = { Up = "↑", Down = "↓", Left = "←", Right = "→", A = "Ⓐ", B = "Ⓑ" },
	Touch = { Up = "▲", Down = "▼", Left = "◀", Right = "▶", A = "●", B = "■" },
}

local function device(): string
	-- Para probar la versión móvil en Studio: player:SetAttribute("ForceTouchUI", true) desde la barra de comandos
	if player:GetAttribute("ForceTouchUI") then
		return "Touch"
	end
	local last = UserInputService:GetLastInputType()
	if last.Name:find("Gamepad") then
		return "Gamepad"
	end
	if last == Enum.UserInputType.Touch or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) then
		return "Touch"
	end
	return "Keyboard"
end

local function labelFor(symbol: string): string
	return (LABELS[device()] or LABELS.Keyboard)[symbol] or symbol
end

local gui: ScreenGui
local request: RemoteEvent
local current = nil -- { Id, MySide, Sides = { { Boxes, Status, Half } } }

local function clearGui()
	for _, c in gui:GetChildren() do
		c:Destroy()
	end
end

-- Retrato 3D del hechicero (clon de su personaje) dentro de un ViewportFrame
local function portrait(parent: GuiObject, model: Model?, mirror: boolean)
	local vp = UI.make("ViewportFrame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.12, 0), Size = UDim2.fromScale(0.9, 0.6),
		BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 190, 210), LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-0.3, -1, -0.6), ZIndex = 3,
	}, parent)
	if not model then
		return vp
	end
	-- Mejor el retrato "limpio" del personaje (el modelo vivo está a mitad de una animación y sale deformado)
	local portraits = ReplicatedStorage:FindFirstChild("Portraits")
	local template = portraits and portraits:FindFirstChild(model:GetAttribute("CharacterId") or "")
	local ok, clone = pcall(function()
		if template then
			return template:Clone()
		end
		model.Archivable = true
		return model:Clone()
	end)
	if not ok or not clone then
		return vp
	end
	for _, tag in CollectionService:GetTags(clone) do
		CollectionService:RemoveTag(clone, tag)
	end
	for _, d in clone:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("Highlight") or d:IsA("BillboardGui") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	local world = UI.make("WorldModel", {}, vp)
	clone:PivotTo(CFrame.new())
	clone.Parent = world
	local camera = UI.make("Camera", { FieldOfView = 32 }, vp)
	vp.CurrentCamera = camera
	local side = if mirror then -1 else 1
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not vp.Parent then
			conn:Disconnect()
			return
		end
		-- acercamiento lento y dramático
		local k = math.min(1, (os.clock() - t0) / 3)
		local dist = 11 - k * 3
		camera.CFrame = CFrame.lookAt(Vector3.new(2.2 * side, 1.4, -dist), Vector3.new(0, 1, 0))
	end)
	return vp
end

local function buildHalf(index: number, data, model: Model?, name: string, domainName: string, japanese: string?, color: Color3, seq)
	local left = index == 1
	local half = UI.make("Frame", {
		Position = UDim2.fromScale(if left then 0 else 0.5, 0), Size = UDim2.fromScale(0.5, 1),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 1,
	}, gui)
	UI.make("UIGradient", {
		Rotation = if left then 20 else 160,
		Color = ColorSequence.new(color:Lerp(Color3.new(0, 0, 0), 0.2), Color3.fromRGB(8, 6, 14)),
	}, half)
	-- kanji gigante de fondo
	UI.label(half, {
		Size = UDim2.fromScale(1, 0.8), Position = UDim2.fromScale(0, 0.05), Text = japanese or "領域展開", TextScaled = true,
		Font = Enum.Font.GothamBlack, TextTransparency = 0.8, TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.5),
		TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 2,
	})
	portrait(half, model, not left)
	UI.label(half, {
		Position = UDim2.fromScale(0, 0.03), Size = UDim2.new(1, 0, 0.06, 0), Text = `JUGADOR {index} · {name}`, TextScaled = true,
		Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3, ZIndex = 4,
	})
	local title = UI.label(half, {
		Position = UDim2.fromScale(0.05, 0.66), Size = UDim2.new(0.9, 0, 0.08, 0), Text = domainName, TextScaled = true,
		Font = UI.TitleFont, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.45),
		TextStrokeTransparency = 0.2, ZIndex = 4,
	})
	UI.make("UITextSizeConstraint", { MaxTextSize = 48 }, title)

	-- Fila de teclas
	local row = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.78), Size = UDim2.new(0.92, 0, 0.1, 0),
		BackgroundTransparency = 1, ZIndex = 4,
	}, half)
	UI.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0.012, 0), SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	local boxes = {}
	for i, key in seq do
		local box = UI.make("TextLabel", {
			Size = UDim2.fromScale(0.105, 1), BackgroundColor3 = Color3.fromRGB(25, 20, 35), Text = labelFor(key), TextScaled = true,
			Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1), LayoutOrder = i, ZIndex = 5,
		}, row)
		UI.make("UIAspectRatioConstraint", { AspectRatio = 1 }, box)
		UI.corner(box, 8)
		local stroke = UI.stroke(box, Color3.fromRGB(90, 80, 120), 2)
		boxes[i] = { Label = box, Stroke = stroke }
	end
	local status = UI.label(half, {
		Position = UDim2.fromScale(0, 0.9), Size = UDim2.new(1, 0, 0.06, 0), Text = "", TextScaled = true,
		Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4, TextStrokeTransparency = 0.3,
	})
	return { Half = half, Boxes = boxes, Status = status, Index = 0, Color = color }
end

local function highlight(side, index: number, failed: boolean)
	side.Index = index
	for i, b in side.Boxes do
		if i <= index then
			b.Label.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
			b.Stroke.Color = Color3.fromRGB(150, 255, 180)
		elseif i == index + 1 and not failed then
			b.Label.BackgroundColor3 = side.Color:Lerp(Color3.new(0, 0, 0), 0.3)
			b.Stroke.Color = UI.Colors.Gold
			b.Stroke.Thickness = 4
		else
			b.Stroke.Thickness = 2
		end
	end
	if failed then
		local b = side.Boxes[index + 1]
		if b then
			b.Label.BackgroundColor3 = Color3.fromRGB(200, 30, 40)
			b.Label.Text = "✕"
		end
		side.Status.Text = "MISS!"
		side.Status.TextColor3 = UI.Colors.Red
	end
end

local function startClash(data)
	clearGui()
	gui.Enabled = true
	local myModel = player.Character
	local mySide = if data.A == myModel then 1 elseif data.B == myModel then 2 else nil
	current = { Id = data.Id, MySide = mySide, Sides = {}, Started = false }
	current.Sides[1] = buildHalf(1, data, data.A, data.PlayerA or "?", data.NameA or "", data.JapaneseA, data.ColorA or Color3.new(1, 1, 1), data.Seq)
	current.Sides[2] = buildHalf(2, data, data.B, data.PlayerB or "?", data.NameB or "", data.JapaneseB, data.ColorB or Color3.new(1, 1, 1), data.Seq)

	-- Separador diagonal + VS
	local divider = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 10, 1.3, 0),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Rotation = 6, ZIndex = 6,
	}, gui)
	UI.make("UIGradient", { Color = ColorSequence.new(data.ColorA or Color3.new(1, 1, 1), data.ColorB or Color3.new(1, 1, 1)) }, divider)
	local banner = UI.label(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.5, 0.14),
		Text = "VS", TextScaled = true, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0, ZIndex = 8,
	})
	local top = UI.label(gui, {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.1), Size = UDim2.fromScale(0.7, 0.07),
		Text = "DOMAIN CLASH!", TextScaled = true, Font = UI.TitleFont, TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = UI.Colors.Gold, TextStrokeTransparency = 0, ZIndex = 8,
	})
	local hint = UI.label(gui, {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.99), Size = UDim2.fromScale(0.8, 0.035),
		Text = if not mySide then "Two domains collide... which one will prevail?"
			elseif device() == "Touch" then "Tap the buttons in YOUR side's order as fast as you can! One miss and you lose"
			elseif device() == "Gamepad" then "Press the D-pad and Ⓐ/Ⓑ in YOUR side's order! One miss and you lose"
			else `Press the keys on YOUR side ({if mySide == 1 then "left" else "right"}) as fast as you can. One miss and you lose!`,
		TextScaled = true, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.2, ZIndex = 8,
	})
	if mySide then
		UI.stroke(current.Sides[mySide].Half, UI.Colors.Gold, 5)
		-- Móvil: botonera grande en tu mitad (cruz de direcciones + dos botones de acción)
		if device() == "Touch" then
			local half = current.Sides[mySide].Half
			local pad = UI.make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromScale(0.9, 0.3),
				BackgroundTransparency = 1, ZIndex = 9,
			}, half)
			local LAYOUT = {
				Up = { 0.17, 0 }, Left = { 0.02, 0.5 }, Right = { 0.32, 0.5 }, Down = { 0.17, 1 },
				A = { 0.62, 0.55 }, B = { 0.8, 0.2 },
			}
			for symbol, at in LAYOUT do
				local b = UI.make("TextButton", {
					AnchorPoint = Vector2.new(0, if at[2] >= 1 then 1 elseif at[2] > 0 then 0.5 else 0),
					Position = UDim2.fromScale(at[1], at[2]), Size = UDim2.fromScale(0.16, 0.42),
					BackgroundColor3 = if symbol == "A" or symbol == "B" then current.Sides[mySide].Color else Color3.fromRGB(40, 34, 60),
					BackgroundTransparency = 0.1, Text = LABELS.Touch[symbol], TextScaled = true, Font = Enum.Font.GothamBlack,
					TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = true, ZIndex = 10,
				}, pad)
				UI.make("UIAspectRatioConstraint", { AspectRatio = 1 }, b)
				UI.corner(b, if symbol == "A" or symbol == "B" then 999 else 12)
				UI.stroke(b, Color3.new(1, 1, 1), 2)
				b.Activated:Connect(function()
					if current and current.Started then
						request:FireServer("ClashKey", symbol)
					end
				end)
			end
		end
	end

	-- Entrada con efecto: las dos mitades llegan desde los lados
	current.Sides[1].Half.Position = UDim2.fromScale(-0.5, 0)
	current.Sides[2].Half.Position = UDim2.fromScale(1, 0)
	TweenService:Create(current.Sides[1].Half, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Position = UDim2.fromScale(0, 0) }):Play()
	TweenService:Create(current.Sides[2].Half, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Position = UDim2.fromScale(0.5, 0) }):Play()
	Sfx.Play("Domain", nil, 1)

	-- Cuenta atrás hasta el ¡YA!
	local id = data.Id
	task.spawn(function()
		local intro = data.Intro or 2.4
		task.wait(math.max(0, intro - 1.5))
		for _, txt in { "3", "2", "1" } do
			if not current or current.Id ~= id then
				return
			end
			banner.Text = txt
			task.wait(0.5)
		end
		if current and current.Id == id then
			banner.Text = "GO!"
			current.Started = true
			highlight(current.Sides[1], 0, false)
			highlight(current.Sides[2], 0, false)
			Sfx.Play("Special", nil, 1)
			task.wait(0.4)
			if current and current.Id == id then
				banner.Text = ""
				top.Text = "DOMAIN CLASH!"
			end
		end
	end)
end

local function endClash(id: number, winnerSide: number, winnerName: string, domainName: string)
	if not current or current.Id ~= id then
		return
	end
	local winner = current.Sides[winnerSide]
	local loser = current.Sides[3 - winnerSide]
	winner.Status.Text = "WINS!"
	winner.Status.TextColor3 = UI.Colors.Gold
	if loser.Status.Text == "" then
		loser.Status.Text = "DOMAIN SHATTERED"
		loser.Status.TextColor3 = UI.Colors.Red
	end
	-- La mitad ganadora se come la pantalla
	TweenService:Create(winner.Half, TweenInfo.new(0.6, Enum.EasingStyle.Quart), {
		Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(1, 1),
	}):Play()
	TweenService:Create(loser.Half, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	local msg = UI.label(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.8, 0.12),
		Text = `{winnerName} imposes {domainName}!`, TextScaled = true, Font = UI.TitleFont,
		TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = UI.Colors.Gold, TextStrokeTransparency = 0, ZIndex = 10,
	})
	Sfx.Play("KO", nil, 1)
	local myId = id
	task.delay(1.9, function()
		if current and current.Id == myId then
			current = nil
			gui.Enabled = false
			clearGui()
		end
		msg:Destroy()
	end)
end

function DomainClashController.Start()
	gui = UI.screenGui("DomainClash", 60, true)
	gui.IgnoreGuiInset = true
	gui.Enabled = false
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	request = remotes:WaitForChild("CombatRequest")

	remotes:WaitForChild("CombatFeedback").OnClientEvent:Connect(function(kind, a, b, c, d)
		if kind == "DomainClash" and type(a) == "table" then
			local character = player.Character
			if character and character:GetAttribute("ArenaId") == a.Arena then
				startClash(a)
			end
		elseif kind == "ClashProgress" and current and current.Id == a then
			local side = current.Sides[b]
			if side then
				highlight(side, c, d == true)
				if side == current.Sides[current.MySide or 0] and not d then
					Sfx.Play("Click", nil, 0.6, 1.3)
				end
			end
		elseif kind == "ClashEnd" then
			endClash(a, b, c, d)
		end
	end)

	-- Pulsaciones (también si otra acción ya ha "usado" la tecla: en el choque todo vale)
	UserInputService.InputBegan:Connect(function(input)
		if not current or not current.MySide or not current.Started then
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		local key = KEYCODES[input.KeyCode]
		if key then
			request:FireServer("ClashKey", key)
		end
	end)
end

return DomainClashController
