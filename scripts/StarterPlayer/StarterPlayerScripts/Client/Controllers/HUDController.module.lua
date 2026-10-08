-- HUDController: tarjetas de % de daño y stocks estilo Smash.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))
local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local Portrait = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Portrait"))

local player = Players.LocalPlayer

local HUDController = {}

local cards = {} -- [model] = { frame, connections }
local cardRefreshers = setmetatable({}, { __mode = "k" }) -- [model] = refresh()
local container: Frame

-- Blanco -> amarillo -> rojo -> rojo oscuro según el %
local COLOR_STOPS = {
	{ 0, Color3.fromRGB(255, 255, 255) },
	{ 50, Color3.fromRGB(255, 220, 80) },
	{ 100, Color3.fromRGB(255, 70, 40) },
	{ 160, Color3.fromRGB(140, 0, 0) },
}

local function percentColor(p: number): Color3
	for i = 2, #COLOR_STOPS do
		local a, b = COLOR_STOPS[i - 1], COLOR_STOPS[i]
		if p <= b[1] then
			return a[2]:Lerp(b[2], (p - a[1]) / (b[1] - a[1]))
		end
	end
	return COLOR_STOPS[#COLOR_STOPS][2]
end

local function label(parent: Instance, props): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Font = Enum.Font.GothamBold
	l.TextScaled = false
	for k, v in props do
		(l :: any)[k] = v
	end
	l.Parent = parent
	return l
end

local function removeCard(model: Model)
	local card = cards[model]
	if not card then
		return
	end
	for _, c in card.connections do
		c:Disconnect()
	end
	card.frame:Destroy()
	cards[model] = nil
end

-- Colores de jugador (como en Smash): tú siempre rojo, luego azul, amarillo, verde; los enemigos, morado
local SLOT_COLORS = { Color3.fromRGB(225, 45, 50), Color3.fromRGB(45, 110, 235), Color3.fromRGB(240, 185, 30), Color3.fromRGB(50, 175, 85) }
local ENEMY_COLOR = Color3.fromRGB(120, 60, 170)
local nextSlot = 1

local function addCard(model: Model)
	if cards[model] or not model:IsA("Model") then
		return
	end
	local isMe = model == player.Character
	local owner = Players:GetPlayerFromCharacter(model)
	local slotColor
	if model:GetAttribute("IsNPC") or model:GetAttribute("IsDummy") then
		slotColor = ENEMY_COLOR
	elseif isMe then
		slotColor = SLOT_COLORS[1]
	else
		nextSlot = nextSlot % (#SLOT_COLORS - 1) + 1
		slotColor = SLOT_COLORS[nextSlot + 1]
	end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(250, 118)
	frame.BackgroundTransparency = 1
	frame.LayoutOrder = if isMe then 0 else 1
	UI.autoScale(frame)

	-- Retrato en un cuadro inclinado del color del jugador
	local tile = Instance.new("Frame")
	tile.Position = UDim2.fromOffset(4, 6)
	tile.Size = UDim2.fromOffset(86, 86)
	tile.Rotation = -6
	tile.BackgroundColor3 = slotColor
	tile.Parent = frame
	UI.make("UIGradient", { Rotation = 45, Color = ColorSequence.new(slotColor:Lerp(Color3.new(1, 1, 1), 0.25), slotColor:Lerp(Color3.new(0, 0, 0), 0.35)) }, tile)
	UI.stroke(tile, Color3.new(1, 1, 1), 3)
	local portrait = Portrait.Create(tile, model:GetAttribute("CharacterId") or "Brawler", "Bust", { Size = UDim2.fromScale(1, 1) })
	if owner and not model:GetAttribute("IsNPC") then
		UI.avatar(frame, owner.UserId, { Position = UDim2.fromOffset(66, 0), Size = UDim2.fromOffset(28, 28), ZIndex = 6 })
	end

	-- % enorme, con contorno grueso y degradado según el daño
	local percentLabel = label(frame, {
		Position = UDim2.fromOffset(92, 6), Size = UDim2.fromOffset(150, 64), Text = "0", TextSize = 60,
		Font = Enum.Font.LuckiestGuy, TextXAlignment = Enum.TextXAlignment.Right, Rotation = -4, ZIndex = 3,
	})
	UI.make("UIStroke", { Thickness = 3, Color = Color3.fromRGB(20, 10, 10) }, percentLabel)
	local gradient = UI.make("UIGradient", { Rotation = 90 }, percentLabel)
	local scale = Instance.new("UIScale", percentLabel)
	local sign = label(frame, {
		Position = UDim2.fromOffset(240, 34), Size = UDim2.fromOffset(28, 30), Text = "%", TextSize = 28,
		Font = Enum.Font.LuckiestGuy, TextXAlignment = Enum.TextXAlignment.Left, Rotation = -4, ZIndex = 3,
	})
	UI.make("UIStroke", { Thickness = 2.5, Color = Color3.fromRGB(20, 10, 10) }, sign)

	-- Banda con el nombre
	local banner = Instance.new("Frame")
	banner.Position = UDim2.fromOffset(70, 72)
	banner.Size = UDim2.fromOffset(186, 22)
	banner.BackgroundColor3 = slotColor
	banner.BorderSizePixel = 0
	banner.Parent = frame
	UI.make("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.25, 0), NumberSequenceKeypoint.new(1, 0.15) }) }, banner)
	local nameLabel = label(banner, {
		Position = UDim2.fromOffset(26, 0), Size = UDim2.new(1, -30, 1, 0), TextSize = 15, Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, TextStrokeTransparency = 0.4,
	})
	local titleLabel = label(frame, {
		Position = UDim2.fromOffset(96, 96), Size = UDim2.fromOffset(150, 12), TextSize = 10, Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	-- Vidas (corazones) y barra de ulti
	local stocksLabel = label(frame, {
		Position = UDim2.fromOffset(6, 96), Size = UDim2.fromOffset(90, 18), TextSize = 16, Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.fromRGB(255, 70, 80), TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.3,
	})
	local ultBack = UI.make("Frame", { Position = UDim2.fromOffset(96, 109), Size = UDim2.fromOffset(150, 6), BackgroundColor3 = Color3.fromRGB(30, 26, 40) }, frame)
	UI.corner(ultBack, 3)
	local ultFill = UI.make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(255, 200, 50) }, ultBack)
	UI.corner(ultFill, 3)
	local ultText = label(frame, {
		Position = UDim2.fromOffset(150, 96), Size = UDim2.fromOffset(96, 12), TextSize = 10, Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(255, 215, 90), Text = "",
	})

	local lastPercent = model:GetAttribute("Percent") or 0
	local lastCharacter = model:GetAttribute("CharacterId")

	local function refresh()
		local data = CharacterRegistry.Get(model:GetAttribute("CharacterId"))
		if model:GetAttribute("CharacterId") ~= lastCharacter then
			lastCharacter = model:GetAttribute("CharacterId")
			portrait:Destroy()
			portrait = Portrait.Create(tile, lastCharacter or "Brawler", "Bust", { Size = UDim2.fromScale(1, 1) })
		end
		local shown = if model:GetAttribute("IsNPC") then (model:GetAttribute("DisplayName") or model.Name)
			elseif data then data.DisplayName else model.Name
		nameLabel.Text = string.upper(shown)

		local title = CatalogConfig.StoreItems[model:GetAttribute("Title") or ""]
		if title then
			titleLabel.Text = `{title.Name}`
			titleLabel.TextColor3 = title.Color
		elseif owner and owner:GetAttribute("VIP") then
			titleLabel.Text = "VIP"
			titleLabel.TextColor3 = Color3.fromRGB(255, 210, 60)
		else
			titleLabel.Text = if owner then owner.DisplayName else ""
			titleLabel.TextColor3 = Color3.fromRGB(200, 195, 215)
		end

		local myCharacter = player.Character
		local myArena = myCharacter and myCharacter:GetAttribute("ArenaId")
		frame.Visible = myArena ~= "Lobby" and (myCharacter == nil or model:GetAttribute("ArenaId") == myArena)

		local p = math.floor(model:GetAttribute("Percent") or 0)
		percentLabel.Text = tostring(p)
		local c = percentColor(p)
		gradient.Color = ColorSequence.new(c:Lerp(Color3.new(1, 1, 1), 0.35), c)
		sign.TextColor3 = c
		if p > lastPercent then
			scale.Scale = 1.4
			TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			tile.Position = UDim2.fromOffset(4 + math.random(-4, 4), 6 + math.random(-3, 3))
			TweenService:Create(tile, TweenInfo.new(0.15), { Position = UDim2.fromOffset(4, 6) }):Play()
		end
		lastPercent = p

		local eliminated = model:GetAttribute("Eliminated") == true
		stocksLabel.Text = if eliminated then "K.O." else string.rep("♥", model:GetAttribute("Stocks") or 0)
		local dim = model:GetAttribute("KOing") or eliminated
		tile.BackgroundTransparency = if dim then 0.6 else 0
		percentLabel.TextTransparency = if dim then 0.5 else 0

		local ult = model:GetAttribute("Ult") or 0
		ultFill.Size = UDim2.fromScale(ult / 100, 1)
		local ready = ult >= 100
		ultFill.BackgroundColor3 = if ready then Color3.fromRGB(255, 240, 120) else Color3.fromRGB(255, 190, 40)
		ultText.Text = if model:GetAttribute("Transformed") then string.upper(model:GetAttribute("Transformed"))
			elseif ready then (if isMe then "ULT READY! (R)" else "ULT READY!") else ""
	end

	local connections = {}
	for _, attr in { "Percent", "Stocks", "CharacterId", "DisplayName", "KOing", "Eliminated", "ArenaId", "Title", "Ult", "Transformed" } do
		table.insert(connections, model:GetAttributeChangedSignal(attr):Connect(refresh))
	end
	cardRefreshers[model] = refresh
	table.insert(connections, model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) then
			removeCard(model)
		end
	end))

	frame.Parent = container
	cards[model] = { frame = frame, connections = connections }
	refresh()
end

function HUDController.Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "SmashHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- nada debajo de la barra de Roblox
	end)
	gui.Parent = player:WaitForChild("PlayerGui")

	container = Instance.new("Frame")
	container.AnchorPoint = Vector2.new(0.5, 1)
	container.Position = UDim2.new(0.5, 0, 1, -16)
	container.Size = UDim2.new(1, -32, 0, 118)
	container.BackgroundTransparency = 1
	container.Parent = gui
	local layout = Instance.new("UIListLayout", container)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 26)

	-- Teclas en cajas a la izquierda (como en los juegos de lucha) y rombo de habilidades abajo a la derecha.
	-- En móvil no se muestran: ahí están el joystick y los botones táctiles.
	local keys = Instance.new("Frame")
	keys.Position = UDim2.fromOffset(16, 152)
	keys.Size = UDim2.fromOffset(220, 320)
	keys.BackgroundTransparency = 1
	keys.Parent = gui
	UI.autoScale(keys)
	local keysLayout = Instance.new("UIListLayout", keys)
	keysLayout.Padding = UDim.new(0, 4)
	keysLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local KEYBOARD_ROWS = {
		{ { "A", "D" }, "Move" }, { { "SPACE" }, "Jump ×2" }, { { "J" }, "Attack" }, { { "K" }, "Heavy" },
		{ { "E" }, "Special" }, { { "Q" }, "Shield / dodge" }, { { "G" }, "Grab" }, { { "R" }, "Ult" },
		{ { "SHIFT" }, "Run" }, { { "W", "S" }, "+ attack: variants" }, { { "T" }, "Switch character" },
	}
	local GAMEPAD_ROWS = {
		{ { "A" }, "Jump ×2" }, { { "X" }, "Attack" }, { { "Y" }, "Heavy" }, { { "B" }, "Special" },
		{ { "↑" }, "Ult (D-pad)" }, { { "L1" }, "Shield / dodge" }, { { "R1" }, "Grab" }, { { "R3" }, "Switch character" },
	}
	local function buildKeys(rows)
		for _, child in keys:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		for i, row in rows do
			local line = Instance.new("Frame")
			line.Size = UDim2.new(1, 0, 0, 24)
			line.BackgroundTransparency = 1
			line.LayoutOrder = i
			line.Parent = keys
			local x = 0
			for _, key in row[1] do
				local w = math.max(24, 10 + #key * 9)
				local box = label(line, {
					Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(w, 24), Text = key, TextSize = 13,
					Font = Enum.Font.GothamBlack, BackgroundTransparency = 0.15, BackgroundColor3 = Color3.fromRGB(18, 16, 26),
				})
				UI.corner(box, 5)
				UI.stroke(box, Color3.fromRGB(220, 220, 235), 1.5)
				x += w + 4
			end
			label(line, {
				Position = UDim2.fromOffset(x + 4, 0), Size = UDim2.new(1, -x - 4, 1, 0), Text = row[2], TextSize = 13,
				Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.3,
				TextColor3 = if row[2]:find("Ult") then Color3.fromRGB(255, 215, 90) else Color3.new(1, 1, 1),
			})
		end
	end

	-- Rombo: arriba ULTI, izquierda golpe, derecha especial, abajo fuerte
	local diamond = Instance.new("Frame")
	diamond.AnchorPoint = Vector2.new(1, 1)
	diamond.Position = UDim2.new(1, -24, 1, -24)
	diamond.Size = UDim2.fromOffset(190, 190)
	diamond.BackgroundTransparency = 1
	diamond.Parent = gui
	UI.autoScale(diamond)
	local tiles = {}
	local function tile(name: string, keyText: string, center: Vector2, side: number, color: Color3)
		local sq = Instance.new("Frame")
		sq.AnchorPoint = Vector2.new(0.5, 0.5)
		sq.Position = UDim2.fromOffset(center.X, center.Y)
		sq.Size = UDim2.fromOffset(side, side)
		sq.Rotation = 45
		sq.BackgroundColor3 = Color3.fromRGB(22, 18, 32)
		sq.BackgroundTransparency = 0.1
		sq.ClipsDescendants = true
		sq.Parent = diamond
		local stroke = UI.make("UIStroke", { Color = color, Thickness = 2.5 }, sq)
		UI.make("UIGradient", { Rotation = -45, Color = ColorSequence.new(color:Lerp(Color3.new(0, 0, 0), 0.35), Color3.fromRGB(16, 12, 24)) }, sq)
		local text = label(diamond, {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(center.X, center.Y - 6), Size = UDim2.fromOffset(side, 22),
			Text = string.upper(name), TextSize = if side > 60 then 15 else 11, Font = Enum.Font.GothamBlack, TextStrokeTransparency = 0.3, ZIndex = 3,
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		local key = label(diamond, {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(center.X, center.Y + 12), Size = UDim2.fromOffset(side, 16),
			Text = keyText, TextSize = 12, Font = Enum.Font.GothamBlack, TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.5), ZIndex = 3,
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		local scale = Instance.new("UIScale", sq)
		tiles[name] = { Square = sq, Stroke = stroke, Scale = scale, Key = key, Text = text, Color = color }
		return tiles[name]
	end
	local ult = tile("Ult", "R", Vector2.new(120, 62), 64, Color3.fromRGB(255, 200, 50))
	tile("Attack", "J", Vector2.new(62, 120), 52, Color3.fromRGB(230, 70, 80))
	tile("Special", "E", Vector2.new(166, 140), 52, Color3.fromRGB(120, 140, 255))
	tile("Heavy", "K", Vector2.new(110, 170), 46, Color3.fromRGB(255, 140, 50))
	-- Relleno de la ulti (sube desde abajo; va girado al revés para quedar horizontal dentro del rombo).
	-- ClipsDescendants NO recorta en marcos girados (por eso se veía un cuadrado saliéndose del rombo):
	-- un CanvasGroup sí recorta a sus hijos aunque esté girado, así el líquido queda DENTRO del rombo.
	-- Sin recortes (en algunos dispositivos no funcionan con marcos girados): el relleno es un rombo
	-- EXACTO encima del de la ulti, y un degradado de transparencia hace de "nivel de líquido".
	-- Va girado como su padre, así que el degradado a 45° queda vertical en pantalla
	-- (0 = punta de arriba, 1 = punta de abajo).
	local ultFill = Instance.new("Frame")
	ultFill.Name = "UltFill"
	ultFill.Size = UDim2.fromScale(1, 1)
	ultFill.BackgroundColor3 = Color3.new(1, 1, 1)
	ultFill.BorderSizePixel = 0
	ultFill.ZIndex = 2
	ultFill.Parent = ult.Square
	local ultLevel = UI.make("UIGradient", {
		Rotation = 45, Color = ColorSequence.new(Color3.fromRGB(255, 235, 140), Color3.fromRGB(255, 140, 20)),
		Transparency = NumberSequence.new(1),
	}, ultFill)
	local ultPercent = label(diamond, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(120, 16), Size = UDim2.fromOffset(80, 18),
		Text = "", TextSize = 14, Font = Enum.Font.LuckiestGuy, TextColor3 = Color3.fromRGB(255, 215, 90), ZIndex = 3,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	UI.make("UIStroke", { Thickness = 2, Color = Color3.fromRGB(20, 10, 10) }, ultPercent)

	local function pulse(name: string)
		local t = tiles[name]
		if t then
			t.Scale.Scale = 1.2
			TweenService:Create(t.Scale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
	end
	local KEY_TILES = {
		[Enum.KeyCode.J] = "Attack", [Enum.KeyCode.K] = "Heavy", [Enum.KeyCode.E] = "Special", [Enum.KeyCode.L] = "Special",
		[Enum.KeyCode.R] = "Ult", [Enum.KeyCode.ButtonX] = "Attack", [Enum.KeyCode.ButtonY] = "Heavy", [Enum.KeyCode.ButtonB] = "Special",
		[Enum.KeyCode.DPadUp] = "Ult",
	}
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			pulse("Attack")
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			pulse("Heavy")
		elseif KEY_TILES[input.KeyCode] then
			pulse(KEY_TILES[input.KeyCode])
		end
	end)

	local function refreshHelp()
		local gamepad = UserInputService:GetLastInputType().Name:find("Gamepad") ~= nil
		-- Tablets con teclado también tienen TouchEnabled: manda lo último que se usó
		local lastTouch = UserInputService:GetLastInputType() == Enum.UserInputType.Touch
		local touchOnly = UserInputService.TouchEnabled and (lastTouch or not UserInputService.KeyboardEnabled) and not gamepad
		buildKeys(if gamepad then GAMEPAD_ROWS else KEYBOARD_ROWS)
		local labels = if gamepad then { Attack = "X", Heavy = "Y", Special = "B", Ult = "↑" } else { Attack = "J", Heavy = "K", Special = "E", Ult = "R" }
		for name, t in tiles do
			t.Key.Text = labels[name]
		end
		keys:SetAttribute("Allowed", not touchOnly)
		diamond:SetAttribute("Allowed", not touchOnly)
	end
	UserInputService.LastInputTypeChanged:Connect(refreshHelp)
	refreshHelp()

	-- Visibilidad (solo en arena) y estado de la ulti
	game:GetService("RunService").Heartbeat:Connect(function()
		local character = player.Character
		local arena = character and character:GetAttribute("ArenaId")
		local inArena = arena ~= nil and arena ~= "Lobby"
		keys.Visible = keys:GetAttribute("Allowed") == true and inArena
		diamond.Visible = diamond:GetAttribute("Allowed") == true and inArena
		if not diamond.Visible or not character then
			return
		end
		local value = character:GetAttribute("Ult") or 0
		local ready = value >= 100
		-- El cuadrado va girado 45°: el relleno (horizontal en pantalla) crece desde la esquina de abajo
		-- (la esquina local (1,1)). Roblox gira sobre el centro, así que se coloca el centro a mano.
		-- Nivel del líquido: por debajo de "cut" opaco, por encima transparente (con un borde suave)
		local level = math.clamp(value / 100, 0, 1)
		if level <= 0.001 then
			ultLevel.Transparency = NumberSequence.new(1)
		elseif level >= 0.999 then
			ultLevel.Transparency = NumberSequence.new(0.05)
		else
			local cut = 1 - level
			ultLevel.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(math.max(0.002, cut - 0.015), 1),
				NumberSequenceKeypoint.new(math.min(0.998, cut + 0.015), 0.15),
				NumberSequenceKeypoint.new(1, 0.15),
			})
		end
		ultPercent.Text = if ready then "READY!" else `{math.floor(value)}%`
		local glow = 0.5 + 0.5 * math.sin(os.clock() * 8)
		ult.Stroke.Color = if ready then Color3.fromRGB(255, 240, 150):Lerp(Color3.new(1, 1, 1), glow) else ult.Color
		ult.Stroke.Thickness = if ready then 3 + glow * 2 else 2.5
	end)

	-- Al cambiar TÚ de arena hay que recalcular qué tarjetas se ven
	task.spawn(function()
		local lastArena = nil
		while true do
			task.wait(0.4)
			local myArena = player.Character and player.Character:GetAttribute("ArenaId")
			if myArena ~= lastArena then
				lastArena = myArena
				for _, refresh in cardRefreshers do
					refresh()
				end
			end
		end
	end)

	CollectionService:GetInstanceAddedSignal("Fighter"):Connect(addCard)
	CollectionService:GetInstanceRemovedSignal("Fighter"):Connect(removeCard)
	for _, model in CollectionService:GetTagged("Fighter") do
		addCard(model)
	end
end

return HUDController
