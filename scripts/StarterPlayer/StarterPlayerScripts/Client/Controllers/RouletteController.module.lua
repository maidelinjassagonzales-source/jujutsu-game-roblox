-- RouletteController: ventana de la RULETA MALDITA.
--   Una tira de premios pasa a toda velocidad bajo la flecha dorada y va frenando hasta pararse en
--   el premio que ha decidido el servidor. Abajo: probabilidades de cada premio (siempre visibles).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RouletteConfig = require(Shared:WaitForChild("RouletteConfig"))
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))
local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local Sfx = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Sfx"))
local Portrait = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Portrait"))
local StateController = require(script.Parent:WaitForChild("StateController"))
local CurrencyController = require(script.Parent:WaitForChild("CurrencyController"))

local player = Players.LocalPlayer

local RouletteController = {}

local CARD_W, GAP = 120, 10
local STEP = CARD_W + GAP
local STRIP_CARDS = 60
local WIN_SLOT = 52

local frame: Frame
local strip: Frame
local track: Frame
local resultLabel: TextLabel
local freeButton: TextButton
local paidButton: TextButton
local infoLabel: TextLabel
local spinning = false

-- Tarjeta de premio (también se usa en la tabla de probabilidades)
local cardSkinOverride: string? = nil -- skin real que ha tocado (para la tarjeta ganadora)

local function prizeCard(parent: Instance, prize, props)
	local rarity = RouletteConfig.Rarities[prize.Rarity]
	local card = UI.make("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromOffset(CARD_W, 140) }, parent)
	for k, v in props or {} do
		(card :: any)[k] = v
	end
	UI.corner(card, 12)
	UI.gradient(card, rarity.Color:Lerp(Color3.fromRGB(20, 18, 30), 0.35), Color3.fromRGB(16, 14, 24))
	UI.stroke(card, rarity.Color, 2)
	local iconBox = UI.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(70, 70), BackgroundTransparency = 1 }, card)
	if prize.Kind == "Skin" then
		local holder = UI.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rarity.Color, BackgroundTransparency = 0.4 }, iconBox)
		UI.corner(holder, 999)
		UI.stroke(holder, Color3.new(1, 1, 1), 2)
		-- La tarjeta ganadora enseña el personaje de la skin que ha tocado de verdad
		local skin = CatalogConfig.Skins[cardSkinOverride or RouletteConfig.RareSkins[1]] or CatalogConfig.Skins[RouletteConfig.RareSkins[1]]
		local vp = Portrait.Create(holder, skin.Character, "Bust", { Size = UDim2.fromScale(1, 1) })
		UI.corner(vp, 999)
	else
		local icon = if prize.Kind == "Coins" then (if prize.Amount >= 1000 then "CoinPile" else "Coins")
			elseif prize.Kind == "Gems" then (if prize.Amount >= 40 then "GemBig" else "Gems")
			elseif prize.Kind == "Boost" then "Boost" else "Rewards"
		UI.icon(iconBox, icon, { Size = UDim2.fromScale(1, 1) })
	end
	UI.label(card, {
		Position = UDim2.fromOffset(4, 84), Size = UDim2.new(1, -8, 0, 30), Text = RouletteConfig.Describe(prize), TextWrapped = true,
		TextScaled = true, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4,
	})
	local tag = UI.label(card, {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -16, 0, 16), BackgroundTransparency = 0,
		BackgroundColor3 = rarity.Color, Text = string.upper(rarity.Name), TextSize = 11, Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	UI.corner(tag, 999)
	return card
end

-- Premio "de relleno" para la tira (mismas probabilidades que la ruleta real)
local function randomPrize()
	local roll = math.random() * RouletteConfig.TotalWeight()
	for _, p in RouletteConfig.Prizes do
		roll -= p.Weight
		if roll <= 0 then
			return p
		end
	end
	return RouletteConfig.Prizes[1]
end

local function buildStrip(winIndex: number?, winSkin: string?)
	for _, c in track:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for i = 1, STRIP_CARDS do
		cardSkinOverride = if i == WIN_SLOT then winSkin else nil
		local prize = if i == WIN_SLOT and winIndex then RouletteConfig.Prizes[winIndex] else randomPrize()
		-- que se vea pasar la skin de vez en cuando (y casi tocar justo al lado del premio)
		if not winIndex and i % 17 == 0 then
			prize = RouletteConfig.Prizes[#RouletteConfig.Prizes]
		elseif winIndex and (i == WIN_SLOT + 1 or i == WIN_SLOT - 2) and RouletteConfig.Prizes[winIndex].Kind ~= "Skin" then
			prize = RouletteConfig.Prizes[#RouletteConfig.Prizes]
		end
		prizeCard(track, prize, { Position = UDim2.fromOffset((i - 1) * STEP, 5), Name = `Card{i}` })
	end
end

local function refreshButtons()
	local st = StateController.Get()
	local r = st and st.Roulette
	local todayDay = math.floor(StateController.Now() / 86400)
	local freeLeft = not r or r.Day ~= todayDay or not r.FreeUsed
	local paid = if r and r.Day == todayDay then r.Paid else 0
	freeButton.Visible = freeLeft
	paidButton.Visible = not freeLeft
	infoLabel.Text = if freeLeft then "You have 1 FREE spin today!" else `Extra spins today: {paid}/{RouletteConfig.MaxPaidPerDay}  ·  free spin returns tomorrow`
	freeButton.Active = not spinning
	paidButton.Active = not spinning
end

local function spin(mode: string)
	if spinning then
		return
	end
	spinning = true
	refreshButtons()
	resultLabel.Text = ""
	local response = StateController.Request("Spin", mode) :: any
	if not response.ok or not response.Index then
		spinning = false
		refreshButtons()
		if response.msg and response.msg ~= "" then
			CurrencyController.Toast(response.msg, UI.Colors.Red)
		end
		return
	end
	buildStrip(response.Index, response.Skin)
	cardSkinOverride = nil
	-- Animación: desde el principio hasta el premio (con un pequeño desvío aleatorio dentro de la tarjeta)
	local center = strip.AbsoluteSize.X / 2
	local jitter = math.random(-CARD_W // 2 + 12, CARD_W // 2 - 12)
	local targetX = center - ((WIN_SLOT - 1) * STEP + CARD_W / 2) + jitter
	track.Position = UDim2.fromOffset(center - CARD_W / 2, 0)
	local tween = TweenService:Create(track, TweenInfo.new(5.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(targetX, 0) })
	-- "tic" cada vez que una tarjeta pasa por la flecha
	local lastSlot = -1
	local conn = RunService.RenderStepped:Connect(function()
		local slot = math.floor((center - track.Position.X.Offset) / STEP)
		if slot ~= lastSlot then
			lastSlot = slot
			Sfx.Play("Click", nil, 0.35, 1.2)
		end
	end)
	tween:Play()
	tween.Completed:Wait()
	conn:Disconnect()

	local prize = RouletteConfig.Prizes[response.Index]
	local rarity = RouletteConfig.Rarities[prize.Rarity]
	local winner = track:FindFirstChild(`Card{WIN_SLOT}`) :: Frame?
	if winner then
		local s = UI.make("UIScale", {}, winner)
		TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1.12 }):Play()
		UI.animatedStroke(winner, rarity.Color, 4)
	end
	resultLabel.Text = `{response.msg}!`
	resultLabel.TextColor3 = rarity.Color
	if prize.Kind == "Skin" or prize.Rarity == "Legendary" then
		Sfx.Play("LevelUp", nil, 1)
		local flash = UI.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rarity.Color, BackgroundTransparency = 0.2, ZIndex = 50 }, frame)
		UI.corner(flash, 18)
		TweenService:Create(flash, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
		task.delay(0.85, function()
			flash:Destroy()
		end)
		if prize.Kind == "Skin" then
			CurrencyController.Toast(`{response.msg}!! It's already equipped`, rarity.Color)
		end
	else
		Sfx.Play("Buy", nil, 0.8)
	end
	spinning = false
	refreshButtons()
end

function RouletteController.Open()
	UI.show(frame)
	if not spinning then
		buildStrip(nil)
		track.Position = UDim2.fromOffset(0, 0)
	end
	refreshButtons()
end

function RouletteController.Toggle()
	if frame.Visible then
		frame.Visible = false
	else
		RouletteController.Open()
	end
end

function RouletteController.Start()
	local gui = UI.screenGui("Roulette", 10)
	local content
	frame, content = UI.modal(gui, "🎰 Cursed Roulette", UDim2.fromOffset(780, 560), Color3.fromRGB(255, 50, 90))

	-- Tira de premios con flecha dorada en el centro
	strip = UI.make("Frame", {
		Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 152), BackgroundColor3 = Color3.fromRGB(10, 8, 16), ClipsDescendants = true,
	}, content)
	UI.corner(strip, 12)
	UI.stroke(strip, Color3.fromRGB(255, 210, 90), 2)
	track = UI.make("Frame", { Size = UDim2.fromOffset(STRIP_CARDS * STEP, 150), BackgroundTransparency = 1 }, strip)
	-- Sombra en los bordes (la tira "entra" y "sale")
	for _, side in { 0, 1 } do
		local shade = UI.make("Frame", {
			AnchorPoint = Vector2.new(side, 0), Position = UDim2.fromScale(side, 0), Size = UDim2.new(0, 110, 1, 0),
			BackgroundColor3 = Color3.fromRGB(10, 8, 16), BorderSizePixel = 0, ZIndex = 5,
		}, strip)
		UI.make("UIGradient", { Transparency = NumberSequence.new(if side == 0 then 0 else 1, if side == 0 then 1 else 0) }, shade)
	end
	local pointerLine = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 210, 90), BorderSizePixel = 0, ZIndex = 6,
	}, strip)
	UI.make("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 0) }) }, pointerLine)
	for _, info in { { 0, "▼" }, { 1, "▲" } } do
		UI.label(content, {
			AnchorPoint = Vector2.new(0.5, info[1]), Position = UDim2.new(0.5, 0, 0, if info[1] == 0 then -8 else 178), Size = UDim2.fromOffset(40, 26),
			Text = info[2], TextSize = 28, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(255, 210, 90),
			TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0, ZIndex = 7,
		})
	end

	resultLabel = UI.label(content, {
		Position = UDim2.fromOffset(0, 168), Size = UDim2.new(1, 0, 0, 34), Text = "", TextSize = 26, Font = UI.TitleFont,
		TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3,
	})

	-- Botones
	freeButton = UI.button(content, "FREE SPIN", UI.Colors.Green, {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 206), Size = UDim2.fromOffset(260, 48), TextSize = 20,
	})
	UI.shine(freeButton, 1.2)
	freeButton.Activated:Connect(function()
		task.spawn(spin, "Free")
	end)
	paidButton = UI.priceButton(content, "Coins", RouletteConfig.SpinCostCoins, Color3.fromRGB(150, 80, 230), {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 206), Size = UDim2.fromOffset(260, 48), TextSize = 20,
	})
	UI.shine(paidButton, 2)
	paidButton.Activated:Connect(function()
		task.spawn(spin, "Coins")
	end)
	infoLabel = UI.label(content, {
		Position = UDim2.fromOffset(0, 258), Size = UDim2.new(1, 0, 0, 18), TextSize = 13, TextColor3 = UI.Colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	-- Probabilidades (siempre visibles)
	UI.sectionHeader(content, "Rewards", "Prizes and odds", Color3.fromRGB(255, 50, 90)).Position = UDim2.fromOffset(0, 282)
	local odds = UI.make("Frame", { Position = UDim2.fromOffset(0, 328), Size = UDim2.new(1, 0, 1, -328), BackgroundTransparency = 1 }, content)
	UI.make("UIGridLayout", { CellSize = UDim2.new(0.2, -8, 0.5, -6), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, odds)
	for i, prize in RouletteConfig.Prizes do
		local rarity = RouletteConfig.Rarities[prize.Rarity]
		local cell = UI.make("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), LayoutOrder = i }, odds)
		UI.corner(cell, 8)
		UI.gradient(cell, rarity.Color:Lerp(Color3.fromRGB(20, 18, 30), 0.55), Color3.fromRGB(18, 16, 26))
		UI.stroke(cell, rarity.Color, 1.2)
		UI.label(cell, {
			Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -12, 0.55, -4), Text = RouletteConfig.Describe(prize), TextScaled = true,
			TextWrapped = true, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center,
		})
		local pct = RouletteConfig.Chance(prize) * 100
		UI.label(cell, {
			Position = UDim2.new(0, 6, 0.55, 0), Size = UDim2.new(1, -12, 0.45, -4), Text = string.format(if pct < 1 then "%.1f%%" else "%.0f%%", pct),
			TextScaled = true, Font = Enum.Font.GothamBlack, TextColor3 = rarity.Color, TextXAlignment = Enum.TextXAlignment.Center,
		})
	end

	StateController.Changed:Connect(function()
		if frame.Visible then
			refreshButtons()
		end
	end)
end

return RouletteController
