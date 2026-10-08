-- UI: utilidades compartidas para construir interfaces por código con un estilo coherente.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UI = {}

local Sfx = require(script.Parent:WaitForChild("Sfx"))

UI.Colors = {
	Panel = Color3.fromRGB(18, 16, 28),
	Card = Color3.fromRGB(32, 28, 48),
	CardHover = Color3.fromRGB(44, 38, 66),
	Accent = Color3.fromRGB(150, 70, 220),
	Green = Color3.fromRGB(0, 170, 90),
	Gems = Color3.fromRGB(40, 150, 230),
	Gold = Color3.fromRGB(255, 205, 60),
	Red = Color3.fromRGB(220, 60, 70),
	Muted = Color3.fromRGB(150, 145, 170),
	Disabled = Color3.fromRGB(70, 65, 85),
	Text = Color3.new(1, 1, 1),
}

-- Iconos propios estilo Jujutsu (kanji a pincel en un ensō): tools/gen_icons.py
UI.Icons = {
	Play = 87959425781807, Characters = 101439620472940, Pass = 104225770281982, Store = 92771352121451,
	Rewards = 114750908741473, Coins = 123724251722771, Gems = 109852530494436, Story = 127554595423553,
	Dojo = 82292812682485, Lobby = 76836951195575, FFA = 74512218038662, Duel = 116615453893100,
	Boost = 110193071185059, Codes = 136460972654856,
	-- Arte de la interfaz (tools/gen_ui.py)
	Logo = 108235176735726, MetalButton = 127273806000361, CoinPile = 91638132091436, GemBig = 96762974045852,
	Chest = 74789042502370,
	-- Segunda tanda (tools/gen_ui2.py): piezas 9-slice para teñir + iconos cartoon
	Panel = 97604856229295, Ribbon = 137839799702952, Glossy = 140526732497287, Card = 108242889971167,
	Corner = 114488982693276, DiamondBack = 104754858924108, DiamondFill = 117880785752004, DiamondRing = 82532512531696,
	Lock = 76625601767310, Check = 119843750033451, Star = 130023898272492, Crown = 121351891262153, X2 = 115689614042772,
	Clock = 121979246064434, Skin = 116097598724590, Title = 116910914701946, KO = 85530704947126, Swords = 117182317496374,
	PlayArrow = 70660727636840, Close = 138112506964523, Rays = 112044518614084, PortalSwirl = 124014435863502,
}
-- Emoji -> icono (para quitar los emojis de los títulos)
local EMOJI_ICONS = {
	["⚔️"] = "Play", ["🥋"] = "Characters", ["🎫"] = "Pass", ["🛒"] = "Store", ["🎁"] = "Rewards", ["📖"] = "Story",
	["💎"] = "Gems", ["🔮"] = "Coins", ["🏯"] = "Lobby", ["🗡️"] = "Duel", ["⚡"] = "Boost", ["🎟️"] = "Codes", ["🎰"] = "Chest", ["📜"] = "Codes",
}

function UI.icon(parent: Instance, name: string, props): ImageLabel
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Image = `rbxassetid://{UI.Icons[name] or 0}`
	image.ScaleType = Enum.ScaleType.Fit
	for k, v in props or {} do
		(image :: any)[k] = v
	end
	image.Parent = parent
	return image
end

-- Quita el emoji del principio de un texto y devuelve el icono que le corresponde (si hay)
function UI.splitEmoji(text: string): (string, string?)
	for emoji, icon in EMOJI_ICONS do
		if text:sub(1, #emoji) == emoji then
			return (text:sub(#emoji + 1):gsub("^%s+", "")), icon
		end
	end
	return text, nil
end

-- Tipografía de pincel (estilo del logo de Jujutsu) para títulos y textos grandes
UI.TitleFont = Enum.Font.FredokaOne
UI.DisplayFont = Enum.Font.LuckiestGuy

function UI.make(className: string, props, parent: Instance?)
	local inst = Instance.new(className)
	for k, v in props do
		(inst :: any)[k] = v
	end
	if (className == "TextLabel" or className == "TextButton") and (inst :: any).Font == Enum.Font.GothamBlack
		and ((inst :: any).TextScaled or (inst :: any).TextSize >= 17) then
		(inst :: any).Font = UI.TitleFont
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function UI.corner(parent: Instance, radius: number?)
	return UI.make("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, parent)
end

function UI.stroke(parent: Instance, color: Color3, thickness: number?)
	return UI.make("UIStroke", { Color = color, Thickness = thickness or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
end

function UI.label(parent: Instance, props)
	local defaults = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = UI.Colors.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	}
	for k, v in props do
		defaults[k] = v
	end
	return UI.make("TextLabel", defaults, parent)
end

-- Degradado (multiplica el color del objeto)
function UI.gradient(parent: Instance, top: Color3, bottom: Color3, rotation: number?)
	return UI.make("UIGradient", { Color = ColorSequence.new(top, bottom), Rotation = rotation or 90 }, parent)
end

local function darker(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(0, 0, 0), amount)
end
UI.darker = darker

-- Hover y pulsación con "rebote" (para cualquier botón)
function UI.bounce(button: GuiButton, hoverScale: number?)
	local scale = button:FindFirstChildOfClass("UIScale") or UI.make("UIScale", {}, button)
	local function to(value)
		TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = value }):Play()
	end
	button.MouseEnter:Connect(function() to(hoverScale or 1.05) end)
	button.MouseLeave:Connect(function() to(1) end)
	button.MouseButton1Down:Connect(function() to(0.94) end)
	button.MouseButton1Up:Connect(function() to(hoverScale or 1.05) end)
	return scale
end

-- Brillo que cruza el objeto cada pocos segundos (botones de compra, premium...)
function UI.shine(obj: GuiObject, period: number?)
	local old = obj:FindFirstChildOfClass("UIGradient") -- solo puede haber un degradado por objeto
	if old then
		old:Destroy()
	end
	local g = UI.make("UIGradient", {
		Rotation = 25,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(205, 205, 205)),
			ColorSequenceKeypoint.new(0.42, Color3.fromRGB(205, 205, 205)),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.58, Color3.fromRGB(205, 205, 205)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 170, 170)),
		}),
		Offset = Vector2.new(-1, 0),
	}, obj)
	task.spawn(function()
		while g.Parent do
			g.Offset = Vector2.new(-1, 0)
			local t = TweenService:Create(g, TweenInfo.new(0.7, Enum.EasingStyle.Sine), { Offset = Vector2.new(1, 0) })
			t:Play()
			t.Completed:Wait()
			task.wait(period or 2.4)
		end
	end)
	return g
end

local spinning = setmetatable({}, { __mode = "k" })

-- Borde con degradado que gira lentamente (aspecto "premium")
function UI.animatedStroke(parent: GuiObject, color: Color3, thickness: number?)
	local stroke = UI.stroke(parent, color, thickness or 2)
	local g = UI.make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color),
			ColorSequenceKeypoint.new(0.5, color:Lerp(Color3.new(1, 1, 1), 0.75)),
			ColorSequenceKeypoint.new(1, color),
		}),
	}, stroke)
	spinning[g] = true
	return stroke
end

-- Un único bucle gira todos los bordes animados (los destruidos se sueltan solos)
task.spawn(function()
	local RunService = game:GetService("RunService")
	RunService.Heartbeat:Connect(function()
		local rot = (os.clock() * 70) % 360
		for g in spinning do
			if g.Parent then
				g.Rotation = rot
			else
				spinning[g] = nil
			end
		end
	end)
end)

-- Halo suave alrededor de un panel (varios bordes transparentes por fuera)
function UI.glow(parent: GuiObject, color: Color3, radius: number?)
	for i, t in { 0.72, 0.85, 0.93 } do
		local pad = i * 4
		local ring = UI.make("Frame", {
			Name = "Glow", BackgroundTransparency = 1, Position = UDim2.fromOffset(-pad, -pad),
			Size = UDim2.new(1, pad * 2, 1, pad * 2), ZIndex = parent.ZIndex,
		}, parent)
		UI.corner(ring, (radius or 16) + pad)
		UI.make("UIStroke", { Color = color, Thickness = 4, Transparency = t }, ring)
	end
end

function UI.button(parent: Instance, text: string, color: Color3, props)
	local defaults = {
		BackgroundColor3 = color,
		Text = text,
		Font = Enum.Font.FredokaOne,
		TextSize = 15,
		TextColor3 = UI.Colors.Text,
		AutoButtonColor = false,
	}
	for k, v in props or {} do
		defaults[k] = v
	end
	local b = UI.make("TextButton", defaults, parent)
	-- El fondo lo pinta una imagen con brillo; el texto va en una etiqueta hija (si no, la imagen lo taparía)
	local skin = UI.make("ImageLabel", {
		Name = "Skin", BackgroundTransparency = 1, Image = `rbxassetid://{UI.Icons.Glossy}`, ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(18, 18, 110, 44), SliceScale = 0.6, Size = UDim2.fromScale(1, 1), ZIndex = 0,
		ImageColor3 = b.BackgroundColor3, ImageTransparency = b.BackgroundTransparency,
	}, b)
	local label = UI.make("TextLabel", {
		Name = "Label", BackgroundTransparency = 1, Size = UDim2.new(1, -8, 1, -4), Position = UDim2.fromOffset(4, 0),
		Text = b.Text, Font = b.Font, TextSize = b.TextSize, TextColor3 = b.TextColor3, TextScaled = b.TextScaled,
		TextWrapped = true, RichText = b.RichText, ZIndex = 1,
	}, b)
	local outline = UI.make("UIStroke", { Thickness = 1.6, Transparency = 0.15 }, label)
	b.TextTransparency = 1
	b.BackgroundTransparency = 1
	local function syncColor()
		local c = b.BackgroundColor3
		skin.ImageColor3 = c
		outline.Color = c:Lerp(Color3.new(0, 0, 0), 0.65)
	end
	syncColor()
	b:GetPropertyChangedSignal("BackgroundColor3"):Connect(syncColor)
	b:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
		if b.BackgroundTransparency < 1 then
			skin.ImageTransparency = b.BackgroundTransparency
			b.BackgroundTransparency = 1
		end
	end)
	for _, prop in { "Text", "TextColor3", "TextSize", "Font", "TextScaled" } do
		b:GetPropertyChangedSignal(prop):Connect(function()
			(label :: any)[prop] = (b :: any)[prop]
		end)
	end
	b:GetPropertyChangedSignal("TextTransparency"):Connect(function()
		if b.TextTransparency < 1 then
			label.TextTransparency = b.TextTransparency
			b.TextTransparency = 1
		end
	end)
	local scale = UI.make("UIScale", {}, b)
	b.MouseEnter:Connect(function()
		skin.ImageColor3 = b.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.18)
		TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1.04 }):Play()
	end)
	b.MouseLeave:Connect(function()
		syncColor()
		TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1 }):Play()
	end)
	b.MouseButton1Down:Connect(function()
		scale.Scale = 0.94
	end)
	b.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end)
	b.Activated:Connect(function()
		Sfx.Play("Click")
	end)
	return b
end

-- Tarjeta con degradado y brillo, teñida del color que se pase (rareza, sección...)
function UI.card(parent: Instance, color: Color3, props)
	local c = UI.make("ImageLabel", {
		BackgroundTransparency = 1, Image = `rbxassetid://{UI.Icons.Card}`, ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(20, 20, 108, 108), SliceScale = 0.6, ImageColor3 = color,
	}, parent)
	for k, v in props or {} do
		(c :: any)[k] = v
	end
	return c
end

-- Rayos de luz que giran detrás de un premio
function UI.rays(parent: Instance, color: Color3, props)
	local r = UI.make("ImageLabel", {
		BackgroundTransparency = 1, Image = `rbxassetid://{UI.Icons.Rays}`, ImageColor3 = color, ImageTransparency = 0.2,
		AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 0,
	}, parent)
	for k, v in props or {} do
		(r :: any)[k] = v
	end
	task.spawn(function()
		while r.Parent do
			r.Rotation = (r.Rotation + 0.4) % 360
			task.wait(1 / 30)
		end
	end)
	return r
end

-- Etiqueta inclinada tipo "¡OFERTA!"
function UI.badge(parent: Instance, text: string, color: Color3, props)
	local b = UI.label(parent, {
		Text = text, TextSize = 12, Font = Enum.Font.FredokaOne, BackgroundTransparency = 0, BackgroundColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Center, Rotation = -8, ZIndex = 6, AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
	})
	for k, v in props or {} do
		(b :: any)[k] = v
	end
	UI.corner(b, 6)
	UI.make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, b)
	UI.make("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	return b
end

-- Texto grande de dibujos (con contorno grueso)
function UI.display(parent: Instance, props)
	local l = UI.label(parent, { Font = Enum.Font.LuckiestGuy, TextSize = 24 })
	for k, v in props or {} do
		(l :: any)[k] = v
	end
	UI.make("UIStroke", { Thickness = 2.5, Color = Color3.fromRGB(14, 8, 22) }, l)
	return l
end

-- Iconos de moneda reales (imagen) en lugar del kanji de texto
local CURRENCY_ICON = { Coins = "Coins", Gems = "Gems" }
local ROBUX = utf8.char(0xE002) -- glifo oficial de Robux en las fuentes de Roblox

-- Botón de precio: [icono] 1.400   (currency = "Coins" | "Gems" | "Robux")
function UI.priceButton(parent: Instance, currency: string, amount: number, color: Color3, props)
	local b = UI.button(parent, "", color, props)
	local row = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0, 0.8),
		AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = b.ZIndex + 1,
	}, b)
	UI.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	local h = b.Size.Y.Offset
	local text = UI.formatNumber(amount)
	if currency == "Robux" then
		text = `{ROBUX} {text}`
	else
		UI.icon(row, CURRENCY_ICON[currency] or "Coins", { Size = UDim2.fromOffset(h * 0.72, h * 0.72), LayoutOrder = 1, ZIndex = b.ZIndex + 1 })
	end
	local label = UI.label(row, {
		Text = text, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), LayoutOrder = 2,
		Font = Enum.Font.GothamBlack, TextSize = (props and props.TextSize) or 15, ZIndex = b.ZIndex + 1,
		TextStrokeTransparency = 0.6,
	})
	-- Para que UI.confirmButton pueda cambiar el texto: el botón refleja su Text en la etiqueta
	b:GetPropertyChangedSignal("Text"):Connect(function()
		if b.Text == "" then
			row.Visible = true
		else
			row.Visible = false
		end
	end)
	return b, label
end

-- Cantidad con icono de moneda (no clicable)
function UI.currencyChip(parent: Instance, currency: string, amount: number, props)
	local chip = UI.make("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 22) }, parent)
	for k, v in props or {} do
		(chip :: any)[k] = v
	end
	UI.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = (props and props.HorizontalAlignment) or Enum.HorizontalAlignment.Left,
	}, chip)
	local h = chip.Size.Y.Offset
	UI.icon(chip, CURRENCY_ICON[currency] or "Coins", { Size = UDim2.fromOffset(h, h), LayoutOrder = 1, ZIndex = chip.ZIndex })
	UI.label(chip, {
		Text = UI.formatNumber(amount), AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), LayoutOrder = 2,
		Font = Enum.Font.GothamBlack, TextSize = math.floor(h * 0.75), ZIndex = chip.ZIndex, TextStrokeTransparency = 0.6,
	})
	return chip
end

-- Cinta diagonal en la esquina superior derecha ("MÁS VENDIDO", "+20%"...)
function UI.ribbon(parent: GuiObject, text: string, color: Color3)
	local tag = UI.make("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 6, 0, -8), Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = color, Text = string.upper(text), TextSize = 11,
		Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.5, Rotation = 6,
		ZIndex = parent.ZIndex + 3,
	}, parent)
	UI.make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, tag)
	UI.corner(tag, 6)
	UI.gradient(tag, Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 190))
	UI.stroke(tag, darker(color, 0.5), 1.5)
	return tag
end

-- Encabezado de sección: icono + título a pincel + línea de color que se desvanece
function UI.sectionHeader(parent: Instance, iconName: string?, text: string, accent: Color3, layoutOrder: number?)
	local h = UI.make("Frame", { Size = UDim2.new(1, -8, 0, 42), BackgroundTransparency = 1, LayoutOrder = layoutOrder or 0 }, parent)
	local x = 0
	if iconName then
		UI.icon(h, iconName, { Size = UDim2.fromOffset(40, 40) })
		x = 46
	end
	local title = UI.label(h, {
		Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x, 1, -6), Text = text, TextSize = 20,
		Font = UI.TitleFont, TextStrokeTransparency = 0.6,
	})
	UI.gradient(title, Color3.new(1, 1, 1), accent:Lerp(Color3.new(1, 1, 1), 0.4))
	local line = UI.make("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, x, 1, -2), Size = UDim2.new(1, -x, 0, 2),
		BackgroundColor3 = accent, BorderSizePixel = 0,
	}, h)
	UI.make("UIGradient", { Transparency = NumberSequence.new(0, 1) }, line)
	return h
end

-- Barra de progreso con relleno degradado y brillo
function UI.progressBar(parent: Instance, ratio: number, color: Color3, props)
	local back = UI.make("Frame", { BackgroundColor3 = Color3.fromRGB(30, 26, 44), BorderSizePixel = 0 }, parent)
	for k, v in props or {} do
		(back :: any)[k] = v
	end
	UI.corner(back, 999)
	UI.stroke(back, Color3.fromRGB(70, 60, 95), 1)
	local fill = UI.make("Frame", {
		Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1), BackgroundColor3 = color, BorderSizePixel = 0,
	}, back)
	UI.corner(fill, 999)
	UI.gradient(fill, color:Lerp(Color3.new(1, 1, 1), 0.35), darker(color, 0.15))
	return back, fill
end

-- Botón metálico con extremos en ángulo (estilo menú de juego de lucha).
-- Barra de color a la izquierda, icono opcional y texto en mayúsculas en cursiva.
function UI.metalButton(parent: Instance, text: string, accent: Color3, iconName: string?, props)
	local b = UI.make("ImageButton", {
		BackgroundTransparency = 1, Image = `rbxassetid://{UI.Icons.MetalButton}`, ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(40, 12, 560, 84), SliceScale = 0.5, Size = UDim2.fromOffset(240, 48), AutoButtonColor = false,
	}, parent)
	for k, v in props or {} do
		(b :: any)[k] = v
	end
	local bar = UI.make("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.new(0, 5, 0.56, 0),
		BackgroundColor3 = accent, BorderSizePixel = 0, Rotation = 18, ZIndex = b.ZIndex + 1,
	}, b)
	local x = 26
	if iconName then
		local side = math.floor(b.Size.Y.Offset * 0.9)
		UI.icon(b, iconName, {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 22, 0.5, 0), Size = UDim2.fromOffset(side, side),
			ZIndex = b.ZIndex + 1,
		})
		x = 22 + side + 4
	end
	local label = UI.label(b, {
		Name = "Text", Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x - 18, 1, 0), Text = string.upper(text),
		Font = Enum.Font.GothamBlack, TextSize = math.floor(b.Size.Y.Offset * 0.4), TextStrokeTransparency = 0.5,
		ZIndex = b.ZIndex + 1,
	})
	UI.make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 215)) }, label)
	local scale = UI.make("UIScale", {}, b)
	b.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.06 }):Play()
		b.ImageColor3 = accent:Lerp(Color3.new(1, 1, 1), 0.55)
		bar.Size = UDim2.new(0, 9, 0.66, 0)
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
		b.ImageColor3 = Color3.new(1, 1, 1)
		bar.Size = UDim2.new(0, 5, 0.56, 0)
	end)
	b.Activated:Connect(function()
		Sfx.Play("Click")
	end)
	return b, label
end

-- Foto del avatar de Roblox del jugador (redonda). Se carga en segundo plano.
local avatarCache = {}
function UI.avatar(parent: Instance, userId: number?, props): ImageLabel
	local image = UI.make("ImageLabel", {
		BackgroundColor3 = Color3.fromRGB(40, 36, 60), Image = "", ScaleType = Enum.ScaleType.Crop, ZIndex = 4,
	}, parent)
	for k, v in props or {} do
		(image :: any)[k] = v
	end
	UI.corner(image, 999)
	UI.stroke(image, Color3.new(1, 1, 1), 2)
	if userId and userId > 0 then
		task.spawn(function()
			if not avatarCache[userId] then
				local ok, url = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
				avatarCache[userId] = if ok then url else ""
			end
			image.Image = avatarCache[userId]
		end)
	else
		image.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	end
	return image
end

function UI.formatNumber(n: number): string
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

function UI.formatDuration(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local d = seconds // 86400
	local h = (seconds % 86400) // 3600
	local m = (seconds % 3600) // 60
	if d > 0 then
		return `{d}d {h}h`
	elseif h > 0 then
		return `{h}h {m}m`
	end
	return `{m}m {seconds % 60}s`
end

-- Botón que pide confirmación (segundo clic) antes de gastar moneda: evita compras accidentales.
function UI.confirmButton(button: TextButton, onConfirm: () -> ())
	local original = button.Text
	local armed = false
	button.Activated:Connect(function()
		if not armed then
			armed = true
			button.Text = "Confirm?"
			task.delay(3, function()
				if armed then
					armed = false
					button.Text = original
				end
			end)
			return
		end
		armed = false
		button.Text = original
		Sfx.Play("Buy")
		onConfirm()
	end)
end

-- Ventanas modales: solo una abierta a la vez
local modals = {}

-- Kanji de marca de agua según el icono de la ventana
local WATERMARK = {
	Characters = "術", Pass = "札", Store = "店", Play = "戦", Rewards = "賞", Story = "語", Codes = "符", Gems = "晶", Chest = "運",
}

function UI.modal(gui: ScreenGui, title: string, size: UDim2, accent: Color3)
	-- Fondo oscurecido (clic fuera = cerrar)
	local dim = gui:FindFirstChild("Dim") :: TextButton
	if not dim then
		dim = UI.make("TextButton", {
			Name = "Dim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(6, 4, 12), BackgroundTransparency = 0.45,
			Text = "", AutoButtonColor = false, Visible = false, ZIndex = 9,
		}, gui)
	end
	local frame = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = size,
		BackgroundTransparency = 1, Visible = false, ZIndex = 10,
	}, gui)
	UI.make("ImageLabel", {
		Name = "Bg", BackgroundTransparency = 1, Image = `rbxassetid://{UI.Icons.Panel}`, ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(30, 30, 226, 226), Size = UDim2.fromScale(1, 1), ZIndex = 0,
	}, frame)
	-- Borde del color de la ventana con un degradado brillante
	local edge = UI.make("Frame", { Name = "Edge", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 0 }, frame)
	UI.corner(edge, 14)
	local stroke = UI.make("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, edge)
	UI.make("UIGradient", { Rotation = 90, Color = ColorSequence.new(accent:Lerp(Color3.new(1, 1, 1), 0.45), accent:Lerp(Color3.new(0, 0, 0), 0.25)) }, stroke)
	-- Resplandor de color arriba
	UI.make("Frame", {
		Name = "Glow", Size = UDim2.new(1, 0, 0, 90), BackgroundColor3 = accent, BackgroundTransparency = 0.6, ZIndex = 0, BorderSizePixel = 0,
	}, frame)
	UI.make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.2, 1) }, frame:FindFirstChild("Glow"))
	UI.corner(frame:FindFirstChild("Glow"), 14)
	for i, rot in { 0, 90, 270, 180 } do
		local x = if i == 2 or i == 4 then 1 else 0
		local y = if i == 3 or i == 4 then 1 else 0
		UI.make("ImageLabel", {
			Name = "Corner", BackgroundTransparency = 1, Image = `rbxassetid://{UI.Icons.Corner}`, ImageColor3 = accent:Lerp(Color3.new(1, 1, 1), 0.35),
			AnchorPoint = Vector2.new(x, y), Position = UDim2.new(x, if x == 0 then -4 else 4, y, if y == 0 then -4 else 4),
			Size = UDim2.fromOffset(34, 34), Rotation = rot, ZIndex = 3,
		}, frame)
	end

	-- En pantallas pequeñas (móvil) la ventana se encoge para caber entera
	local scale = UI.make("UIScale", {}, frame)
	local function fit()
		local viewport = workspace.CurrentCamera.ViewportSize
		scale.Scale = math.min(1, (viewport.X - 24) / size.X.Offset, (viewport.Y - 24) / size.Y.Offset)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	fit()

	-- Cinta con el título
	local cleanTitle, iconName = UI.splitEmoji(title)
	local ribbonW = math.min(size.X.Offset * 0.62, 420)
	local ribbon = UI.make("ImageLabel", {
		Name = "Ribbon", BackgroundTransparency = 1, Image = `rbxassetid://{UI.Icons.Ribbon}`, ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(30, 10, 470, 54), SliceScale = 0.7, ImageColor3 = accent, Position = UDim2.fromOffset(-12, 6),
		Size = UDim2.fromOffset(ribbonW, 42), ZIndex = 2,
	}, frame)
	UI.make("UIGradient", { Rotation = 0, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200)) }, ribbon)
	if iconName then
		UI.icon(frame, iconName, { Position = UDim2.fromOffset(-20, -8), Size = UDim2.fromOffset(62, 62), ZIndex = 4 })
	end
	UI.display(frame, {
		Position = UDim2.fromOffset(if iconName then 48 else 14, 8), Size = UDim2.fromOffset(ribbonW - 70, 36),
		Text = string.upper(cleanTitle), TextSize = 26, ZIndex = 3, TextScaled = true,
	}):FindFirstChildOfClass("UIStroke").Thickness = 3
	local close = UI.make("ImageButton", {
		Name = "Close", BackgroundTransparency = 1, Image = `rbxassetid://{UI.Icons.Close}`, AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 10, 0, -10), Size = UDim2.fromOffset(44, 44), ZIndex = 5,
	}, frame)
	close.Activated:Connect(function()
		Sfx.Play("Click")
		frame.Visible = false
	end)
	local content = UI.make("Frame", {
		Position = UDim2.fromOffset(16, 70), Size = UDim2.new(1, -32, 1, -84), BackgroundTransparency = 1, ZIndex = 1,
	}, frame)

	-- El fondo oscuro sigue a las ventanas de esta pantalla
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		local any = false
		for _, f in gui:GetChildren() do
			if f:IsA("Frame") and f.ZIndex == 10 and f.Visible then
				any = true
			end
		end
		dim.Visible = any
		if frame.Visible then
			frame.Position = UDim2.new(0.5, 0, 0.5, 30)
			TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Position = UDim2.fromScale(0.5, 0.5) }):Play()
		end
	end)
	dim.Activated:Connect(function()
		frame.Visible = false
	end)
	table.insert(modals, frame)
	return frame, content
end

function UI.show(frame: GuiObject)
	for _, other in modals do
		if other ~= frame then
			other.Visible = false
		end
	end
	frame.Visible = true
end

function UI.toggle(frame: GuiObject)
	if frame.Visible then
		frame.Visible = false
	else
		UI.show(frame)
	end
end

-- Escala un elemento según la altura de la pantalla (720 px = tamaño de diseño).
-- En móviles y ventanas pequeñas la interfaz se encoge para no taparlo todo.
function UI.autoScale(obj: GuiObject, designHeight: number?)
	local scale = UI.make("UIScale", {}, obj)
	local function fit()
		local height = workspace.CurrentCamera.ViewportSize.Y
		scale.Scale = math.clamp(height / (designHeight or 720), 0.55, 1)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	fit()
	return scale
end

-- fullscreen = true -> ocupa toda la pantalla (cinemáticas, controles táctiles, efectos).
-- Si no, se queda en la zona segura: NUNCA debajo de la barra de Roblox (menú, chat) ni de la muesca del móvil.
function UI.screenGui(name: string, displayOrder: number?, fullscreen: boolean?)
	local gui = UI.make("ScreenGui", {
		Name = name, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = displayOrder or 0,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, -- los hijos siempre se dibujan encima de su padre
	}, Players.LocalPlayer:WaitForChild("PlayerGui"))
	if not fullscreen then
		pcall(function()
			gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
		end)
	end
	return gui
end

return UI
