-- StoreController: la tienda principal.
--   Gemas (Robux) · Pases (Robux) · Boosters · Efectos de KO · Títulos
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))
local EconomyConfig = require(Shared:WaitForChild("EconomyConfig"))
local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local StateController = require(script.Parent:WaitForChild("StateController"))
local CurrencyController = require(script.Parent:WaitForChild("CurrencyController"))

local player = Players.LocalPlayer

local StoreController = {}

local frame: Frame
local scroll: ScrollingFrame
local sectionOrder = {}

local function request(action: string, ...)
	local response = StateController.Request(action, ...)
	CurrencyController.Toast(response.msg, if response.ok then UI.Colors.Green else UI.Colors.Red)
	return response.ok
end

local function clear()
	for _, c in scroll:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local order = 0
local function nextOrder(): number
	order += 1
	return order
end

-- Encabezado de sección con su icono estilo Jujutsu
local HEADER_ICONS = { Gems = "Gems", Passes = "Pass", Boosts = "Boost", Effect = "Characters", Title = "Rewards" }
local HEADER_COLORS = {
	Gems = Color3.fromRGB(90, 220, 255), Passes = Color3.fromRGB(255, 200, 60), Boosts = Color3.fromRGB(255, 150, 60),
	Effect = Color3.fromRGB(190, 90, 255), Title = Color3.fromRGB(255, 90, 130),
}
local function header(id: string, text: string)
	sectionOrder[id] = UI.sectionHeader(scroll, HEADER_ICONS[id] or "Store", text, HEADER_COLORS[id] or UI.Colors.Gold, nextOrder())
end

-- Fila de producto: icono a la izquierda en una "losa" de color, textos y botón a la derecha
local function row(title: string, subtitle: string?, tag: string?, accent: Color3?, iconName: string?)
	accent = accent or UI.Colors.Accent
	local r = UI.make("Frame", { Size = UDim2.new(1, -12, 0, 66), BackgroundColor3 = Color3.new(1, 1, 1), LayoutOrder = nextOrder() }, scroll)
	UI.corner(r, 12)
	UI.gradient(r, Color3.fromRGB(44, 36, 66), Color3.fromRGB(24, 20, 36), 0)
	UI.stroke(r, accent, 1.2).Transparency = 0.45
	local tile = UI.make("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(50, 50), BackgroundColor3 = accent }, r)
	UI.corner(tile, 10)
	UI.gradient(tile, Color3.new(1, 1, 1), Color3.fromRGB(90, 90, 100))
	UI.stroke(tile, accent:Lerp(Color3.new(1, 1, 1), 0.5), 1.5)
	if iconName then
		UI.icon(tile, iconName, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.1, 1.1) })
	end
	UI.label(r, { Position = UDim2.fromOffset(68, 10), Size = UDim2.new(1, -220, 0, 24), Text = title, TextSize = 16, Font = Enum.Font.GothamBlack, TextTruncate = Enum.TextTruncate.AtEnd })
	if subtitle then
		UI.label(r, { Position = UDim2.fromOffset(68, 34), Size = UDim2.new(1, -220, 0, 18), Text = subtitle, TextSize = 12, TextColor3 = UI.Colors.Muted, TextTruncate = Enum.TextTruncate.AtEnd })
	end
	if tag then
		UI.ribbon(r, tag, Color3.fromRGB(230, 60, 90))
	end
	return r, tile
end

local function rowButton(r: Frame, text: string, color: Color3)
	return UI.button(r, text, color, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(136, 40), TextSize = 14,
	})
end

local function rowPrice(r: Frame, currency: string, amount: number, color: Color3)
	local b = UI.priceButton(r, currency, amount, color, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(136, 40), TextSize = 15,
	})
	return b
end

local function sortedItems(kind: string)
	local list = {}
	for id, item in CatalogConfig.StoreItems do
		if item.Kind == kind then
			table.insert(list, { Id = id, Item = item })
		end
	end
	table.sort(list, function(a, b)
		return a.Item.Order < b.Item.Order
	end)
	return list
end

-- Paquetes de gemas como tarjetas grandes en rejilla (la parte que más tiene que "vender")
local function gemGrid()
	local grid = UI.make("Frame", { Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder() }, scroll)
	UI.make("UIGridLayout", {
		CellSize = UDim2.new(1 / 3, -8, 0, 176), CellPadding = UDim2.fromOffset(10, 14), SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	UI.make("UIPadding", { PaddingTop = UDim.new(0, 8) }, grid)
	local gemColor = EconomyConfig.Currencies.Gems.Color
	for i, pack in EconomyConfig.GemPacks do
		local best = i == #EconomyConfig.GemPacks
		local card = UI.make("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), LayoutOrder = i }, grid)
		UI.corner(card, 14)
		UI.gradient(card, if best then Color3.fromRGB(120, 60, 170) else Color3.fromRGB(30, 90, 130), Color3.fromRGB(16, 18, 34))
		if best then
			UI.animatedStroke(card, UI.Colors.Gold, 2.5)
		else
			UI.stroke(card, gemColor, 1.5).Transparency = 0.3
		end
		-- Rayos de luz detrás del icono
		local rays = UI.make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 56), Size = UDim2.fromOffset(86, 86),
			BackgroundColor3 = if best then UI.Colors.Gold else gemColor, BackgroundTransparency = 0.75,
		}, card)
		UI.corner(rays, 999)
		local iconSize = 54 + math.min(i, 5) * 8
		UI.icon(card, if i >= 3 then "GemBig" else "Gems", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 56), Size = UDim2.fromOffset(iconSize, iconSize),
		})
		local amount = UI.label(card, {
			Position = UDim2.fromOffset(0, 100), Size = UDim2.new(1, 0, 0, 24), Text = UI.formatNumber(pack.Gems), TextSize = 24,
			Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4,
		})
		UI.gradient(amount, Color3.new(1, 1, 1), gemColor)
		UI.label(card, {
			Position = UDim2.fromOffset(0, 122), Size = UDim2.new(1, 0, 0, 14), Text = pack.Name, TextSize = 11,
			TextColor3 = UI.Colors.Muted, TextXAlignment = Enum.TextXAlignment.Center,
		})
		if pack.Tag then
			UI.ribbon(card, pack.Tag, if best then Color3.fromRGB(230, 160, 20) else Color3.fromRGB(230, 60, 90))
		end
		local b = UI.priceButton(card, "Robux", pack.RobuxHint, UI.Colors.Green, {
			AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -16, 0, 30), TextSize = 14,
		})
		if best then
			UI.shine(b, 1.4)
		end
		b.Activated:Connect(function()
			if pack.Id == 0 then
				CurrencyController.Toast("Producto sin configurar (pon su ID en EconomyConfig)", UI.Colors.Red)
			else
				MarketplaceService:PromptProductPurchase(player, pack.Id)
			end
		end)
	end
end

local function refresh()
	if not frame.Visible then
		return
	end
	clear()
	order = 0
	local state = StateController.Get() or {}

	-- Gemas con Robux
	header("Gems", "Gemas")
	gemGrid()

	-- Gamepasses con Robux: banners dorados
	header("Passes", "Pases permanentes")
	for key, pass in CatalogConfig.GamePasses do
		local ownedPass = player:GetAttribute(key) == true
		local r = row(pass.Name, pass.Description, if key == "CoinsX2" then "¡El más vendido!" else nil, UI.Colors.Gold, if key == "CoinsX2" then "CoinPile" else "Pass")
		r.Size = UDim2.new(1, -12, 0, 74)
		r:FindFirstChildOfClass("UIGradient").Color = ColorSequence.new(Color3.fromRGB(96, 70, 20), Color3.fromRGB(30, 22, 12))
		if ownedPass then
			rowButton(r, "TUYO", UI.Colors.Disabled)
		else
			local b = rowPrice(r, "Robux", pass.RobuxHint, UI.Colors.Green)
			UI.shine(b, 2)
			b.Activated:Connect(function()
				if pass.Id == 0 then
					CurrencyController.Toast("Gamepass sin configurar (pon su ID en CatalogConfig)", UI.Colors.Red)
				else
					MarketplaceService:PromptGamePassPurchase(player, pass.Id)
				end
			end)
		end
	end

	-- Boosters
	header("Boosts", "Boosters (se acumulan)")
	local now = StateController.Now()
	local boosts = state.Boosts or { CoinsUntil = 0, XPUntil = 0 }
	for _, entry in sortedItems("Boost") do
		local item = entry.Item
		local untilTime = if item.Boost == "Coins" then boosts.CoinsUntil else boosts.XPUntil
		local active = untilTime > now
		local r = row(item.Name, if active then `Activo · quedan {UI.formatDuration(untilTime - now)}` else "Dobla lo que ganas jugando",
			item.Tag, Color3.fromRGB(255, 150, 60), "Boost")
		UI.confirmButton(rowPrice(r, "Gems", item.Gems, UI.Colors.Gems), function()
			request("BuyItem", entry.Id)
		end)
	end

	-- Efectos de KO y Títulos
	for _, kind in { "Effect", "Title" } do
		header(kind, if kind == "Effect" then "Efectos de KO (los ve todo el servidor)" else "Títulos (bajo tu nombre)")
		local owned = if kind == "Effect" then state.OwnedEffects or {} else state.OwnedTitles or {}
		local equipped = if kind == "Effect" then state.EquippedEffect else state.EquippedTitle
		for _, entry in sortedItems(kind) do
			local item = entry.Item
			local has = owned[entry.Id] == true
			local color = item.Accent or item.Color
			local r, tile = row(item.Name, if item.StoryOnly then "Se consigue completando el Modo Historia" elseif kind == "Effect" then "Explota al eliminar a un rival" else "Se ve encima de tu nombre",
				nil, color, nil)
			if kind == "Effect" then
				-- Muestra del efecto: estallido con los colores del efecto
				UI.label(tile, {
					Size = UDim2.fromScale(1, 1), Text = "KO", TextSize = 20, Font = Enum.Font.GothamBlack,
					TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0, TextStrokeColor3 = UI.darker(color, 0.6),
				})
			else
				-- Vista previa del título con su color
				UI.label(tile, {
					Size = UDim2.fromScale(1, 1), Text = "称", TextSize = 28, Font = Enum.Font.GothamBlack,
					TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3,
				})
			end
			if has then
				local isOn = equipped == entry.Id
				rowButton(r, if isOn then "Quitar" else "Equipar", if isOn then UI.Colors.Disabled else UI.Colors.Accent).Activated:Connect(function()
					request("EquipCosmetic", kind, if isOn then false else entry.Id)
				end)
			elseif item.Gems then
				UI.confirmButton(rowPrice(r, "Gems", item.Gems, UI.Colors.Gems), function()
					request("BuyItem", entry.Id)
				end)
			else
				rowButton(r, "Historia", UI.Colors.Disabled)
			end
		end
	end
end

function StoreController.Open(section: string?)
	UI.show(frame)
	refresh()
	local target = section and sectionOrder[section]
	if target then
		task.defer(function()
			scroll.CanvasPosition = Vector2.new(0, target.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y)
		end)
	end
end

function StoreController.Toggle()
	if frame.Visible then
		frame.Visible = false
	else
		StoreController.Open()
	end
end

function StoreController.Start()
	local gui = UI.screenGui("Store", 10)
	local content
	frame, content = UI.modal(gui, "🛒 Tienda", UDim2.fromOffset(680, 540), UI.Colors.Gold)
	scroll = UI.make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 5, BorderSizePixel = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarImageColor3 = UI.Colors.Gold,
	}, content)
	UI.make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
	UI.make("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }, scroll)
	StateController.Changed:Connect(refresh)
	for _, attr in { "VIP", "CoinsX2" } do
		player:GetAttributeChangedSignal(attr):Connect(refresh)
	end
end

return StoreController
