-- TitleController: pantalla de título al entrar (logo + botones metálicos en ángulo).
-- La cámara gira despacio sobre la Escuela mientras tanto. Al pulsar cualquier opción se cierra,
-- se marca el atributo local "TitleDone" (la intro, la diaria y el tutorial esperan a él) y se
-- abre lo elegido.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local CameraController = require(script.Parent:WaitForChild("CameraController"))
local PlayMenuController = require(script.Parent:WaitForChild("PlayMenuController"))
local CharacterShopController = require(script.Parent:WaitForChild("CharacterShopController"))
local StoreController = require(script.Parent:WaitForChild("StoreController"))

local player = Players.LocalPlayer

local TitleController = {}

local gui: ScreenGui
local hiddenGuis = {}
local closing = false

-- Las otras interfaces se esconden mientras está el título
local function hideOthers(pg: PlayerGui)
	for _, other in pg:GetChildren() do
		if other:IsA("ScreenGui") and other ~= gui and other.Enabled and other.Name ~= "Cinematic" then
			other.Enabled = false
			table.insert(hiddenGuis, other)
		end
	end
end

local function close(after: (() -> ())?)
	if closing then
		return
	end
	closing = true
	local root = gui:FindFirstChild("Root") :: Frame
	TweenService:Create(root, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromScale(-0.6, 0) }):Play()
	local fade = gui:FindFirstChild("Fade") :: Frame
	TweenService:Create(fade, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
	task.wait(0.4)
	CameraController.SetOverride(nil)
	for _, other in hiddenGuis do
		other.Enabled = true
	end
	gui:Destroy()
	GuiService.SelectedObject = nil
	if after then
		after()
	end
	player:SetAttribute("TitleDone", true)
end

function TitleController.WaitDone(timeout: number?)
	local deadline = os.clock() + (timeout or 120)
	while not player:GetAttribute("TitleDone") and os.clock() < deadline do
		task.wait(0.2)
	end
end

local function build()
	local pg = player:WaitForChild("PlayerGui")
	gui = UI.screenGui("Title", 60, true)

	local fade = UI.make("Frame", {
		Name = "Fade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(8, 4, 16), BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
	}, gui)
	UI.make("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.45, 0.35), NumberSequenceKeypoint.new(1, 1) }),
	}, fade)

	local root = UI.make("Frame", { Name = "Root", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, gui)
	local column = UI.make("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 60, 0.5, 30), Size = UDim2.fromOffset(460, 620),
		BackgroundTransparency = 1,
	}, root)
	UI.autoScale(column, 760)

	local logo = UI.icon(column, "Logo", { Size = UDim2.fromOffset(440, 237) })
	local logoScale = UI.make("UIScale", { Scale = 0.6 }, logo)
	TweenService:Create(logoScale, TweenInfo.new(0.6, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	-- "Respira" suavemente
	task.spawn(function()
		while logo.Parent do
			TweenService:Create(logo, TweenInfo.new(1.6, Enum.EasingStyle.Sine), { Rotation = 1.2 }):Play()
			task.wait(1.6)
			TweenService:Create(logo, TweenInfo.new(1.6, Enum.EasingStyle.Sine), { Rotation = -1.2 }):Play()
			task.wait(1.6)
		end
	end)

	local entries = {
		{ "Start", "Play", Color3.fromRGB(230, 50, 60), function()
			player:SetAttribute("TitleStart", true)
		end },
		{ "Game modes", "Duel", Color3.fromRGB(255, 170, 40), PlayMenuController.Toggle },
		{ "Characters", "Characters", Color3.fromRGB(150, 90, 255), CharacterShopController.Toggle },
		{ "Rewards and codes", "Codes", Color3.fromRGB(80, 220, 120), function()
			local ok, rewards = pcall(require, script.Parent:WaitForChild("RewardsController"))
			if ok then
				rewards.Open()
			end
		end },
		{ "Shop", "Store", Color3.fromRGB(90, 200, 255), StoreController.Toggle },
	}
	local first
	for i, e in entries do
		local b = UI.metalButton(column, e[1], e[3], e[2], {
			Position = UDim2.fromOffset(-500, 260 + (i - 1) * 64), Size = UDim2.fromOffset(if i == 1 then 380 else 340, if i == 1 then 60 else 54),
		})
		b.Selectable = true
		first = first or b
		TweenService:Create(b, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.15 + i * 0.07), {
			Position = UDim2.fromOffset(i * 6, 260 + (i - 1) * 64),
		}):Play()
		b.Activated:Connect(function()
			task.spawn(close, e[4])
		end)
	end

	-- Jugador (arriba a la derecha)
	local card = UI.make("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 70), Size = UDim2.fromOffset(260, 64),
		BackgroundColor3 = Color3.fromRGB(20, 16, 30), BackgroundTransparency = 0.25,
	}, root)
	UI.corner(card, 10)
	UI.stroke(card, Color3.fromRGB(200, 200, 215), 2)
	UI.autoScale(card)
	UI.avatar(card, player.UserId, { Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(52, 52) })
	UI.label(card, { Position = UDim2.fromOffset(66, 8), Size = UDim2.new(1, -72, 0, 26), Text = player.DisplayName, TextSize = 20, Font = Enum.Font.GothamBlack, TextTruncate = Enum.TextTruncate.AtEnd })
	UI.label(card, { Position = UDim2.fromOffset(66, 34), Size = UDim2.new(1, -72, 0, 20), Text = `@{player.Name}`, TextSize = 13, TextColor3 = UI.Colors.Muted })

	local hint = UI.label(root, {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.fromOffset(600, 26),
		Text = if UserInputService.GamepadEnabled then "Press Ⓐ to choose" else "Choose an option to start",
		TextSize = 18, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4,
	})
	task.spawn(function()
		while hint.Parent do
			TweenService:Create(hint, TweenInfo.new(0.9), { TextTransparency = 0.6 }):Play()
			task.wait(0.9)
			TweenService:Create(hint, TweenInfo.new(0.9), { TextTransparency = 0 }):Play()
			task.wait(0.9)
		end
	end)

	if UserInputService.GamepadEnabled then
		task.delay(0.8, function()
			pcall(function()
				GuiService.SelectedObject = first
			end)
		end)
	end

	-- Cámara: vuelta lenta alrededor de la Escuela
	local lobby = workspace:WaitForChild("Lobby", 20)
	local origin = if lobby then lobby:GetPivot().Position else Vector3.new(-3000, 0, 0)
	local t = 0
	CameraController.SetOverride(function(dt)
		t += dt
		local a = t * 0.06 + 0.6
		local center = origin + Vector3.new(0, 18, -90)
		return CFrame.lookAt(center + Vector3.new(math.sin(a) * 130, 46, math.cos(a) * 130), center)
	end)

	hideOthers(pg)
	-- Las que se creen mientras tanto también se esconden
	local conn
	conn = pg.ChildAdded:Connect(function(child)
		if not gui.Parent then
			conn:Disconnect()
			return
		end
		task.defer(function()
			if gui.Parent and child:IsA("ScreenGui") and child.Enabled and child.Name ~= "Cinematic" then
				child.Enabled = false
				table.insert(hiddenGuis, child)
			end
		end)
	end)
end

function TitleController.Start()
	task.spawn(function()
		-- Solo al entrar, cuando el personaje ya está en el Lobby
		local deadline = os.clock() + 30
		while os.clock() < deadline do
			local character = player.Character
			if character and character:GetAttribute("ArenaId") == "Lobby" and workspace:FindFirstChild("Lobby") then
				build()
				return
			end
			task.wait(0.3)
		end
		player:SetAttribute("TitleDone", true)
	end)
end

return TitleController
