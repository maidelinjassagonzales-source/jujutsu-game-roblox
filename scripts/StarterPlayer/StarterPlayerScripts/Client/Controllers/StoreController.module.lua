-- StoreController: la tienda principal, con pestañas y tarjetas de producto.
--   Gemas (Robux) · Pases permanentes (Robux) · Boosters · Efectos de KO · Títulos
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))
local EconomyConfig = require(Shared:WaitForChild("EconomyConfig"))
local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local StateController = require(script.Parent:WaitForChild("StateController"))
local CurrencyController = require(script.Parent:WaitForChild("CurrencyController"))

local player = Players.LocalPlayer

local StoreController = {}

local ROBUX = utf8.char(0xE002) -- icono de Robux de las fuentes de Roblox
local GEM_COLOR = Color3.fromRGB(50, 140, 240)
local GREEN = Color3.fromRGB(40, 190, 80)

local TABS = {
	{ Id = "Gems", Name = "Gems", Icon = "GemBig", Color = GEM_COLOR },
	{ Id = "Passes", Name = "Passes", Icon = "Crown", Color = Color3.fromRGB(255, 185, 40) },
	{ Id = "Boosts", Name = "Boosters", Icon = "X2", Color = Color3.fromRGB(240, 80, 60) },
	{ Id = "Effect", Name = "KO Effects", Icon = "KO", Color = Color3.fromRGB(160, 70, 240) },
	{ Id = "Title", Name = "Titles", Icon = "Title", Color = Color3.fromRGB(220, 60, 90) },
}

local frame: Frame
local grid: ScrollingFrame
local tabButtons = {}
local currentTab = "Gems"

local function request(action: string, ...)
	local response = StateController.Request(action, ...)
	CurrencyController.Toast(response.msg, if response.ok then UI.Colors.Green else UI.Colors.Red)
	return response.ok
end

local function clear()
	for _, c in grid:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

-- Tarjeta de producto: fondo del color del producto, rayos girando detrás del icono grande,
-- nombre, descripción, etiqueta inclinada y botón de precio abajo.
local function productCard(order: number, opts)
	local card = UI.make("Frame", { BackgroundTransparency = 1, LayoutOrder = order }, grid)
	UI.card(card, opts.Color, { Size = UDim2.fromScale(1, 1), ZIndex = 0 })
	local inner = UI.make("Frame", {
		Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 112), BackgroundColor3 = Color3.fromRGB(10, 8, 18),
		BackgroundTransparency = 0.55, ClipsDescendants = true,
	}, card)
	UI.corner(inner, 10)
	UI.rays(inner, opts.Color:Lerp(Color3.new(1, 1, 1), 0.6), {
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(220, 220), ImageTransparency = 0.35,
	})
	local icon = UI.icon(inner, opts.Icon, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(opts.IconSize or 84, opts.IconSize or 84), ZIndex = 2,
	})
	if opts.Amount then
		UI.display(inner, {
			AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.new(1, 0, 0, 28), Text = opts.Amount,
			TextSize = 26, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3,
		})
	end
	UI.label(card, {
		Position = UDim2.fromOffset(8, 122), Size = UDim2.new(1, -16, 0, 22), Text = opts.Title, TextSize = 16, Font = Enum.Font.FredokaOne,
		TextXAlignment = Enum.TextXAlignment.Center, TextScaled = true, TextStrokeTransparency = 0.5,
	})
	UI.label(card, {
		Position = UDim2.fromOffset(8, 144), Size = UDim2.new(1, -16, 0, 30), Text = opts.Subtitle or "", TextSize = 11,
		Font = Enum.Font.GothamBold, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Color3.fromRGB(230, 225, 240),
	})
	if opts.Tag then
		UI.badge(card, opts.Tag, Color3.fromRGB(230, 40, 60), { Position = UDim2.fromOffset(-6, -6) })
	end
	local button = UI.button(card, opts.ButtonText or "", opts.ButtonColor or GREEN, {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -16, 0, 36), TextSize = 17,
	})
	if opts.PriceIcon then
		local label = button:FindFirstChild("Label") :: TextLabel
		label.Position = UDim2.fromOffset(18, 0)
		UI.icon(button, opts.PriceIcon, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.5, -46, 0.5, -2), Size = UDim2.fromOffset(26, 26), ZIndex = 2 })
	end
	-- Al pasar el ratón la tarjeta "salta" y el icono gira un poco
	local scale = UI.make("UIScale", {}, card)
	card.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.04 }):Play()
		TweenService:Create(icon, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Rotation = -8 }):Play()
	end)
	card.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
		TweenService:Create(icon, TweenInfo.new(0.2), { Rotation = 0 }):Play()
	end)
	return card, button
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

local function refresh()
	if not frame.Visible then
		return
	end
	clear()
	for id, b in tabButtons do
		local on = id == currentTab
		b.BackgroundColor3 = if on then b:GetAttribute("Color") else Color3.fromRGB(45, 40, 62)
		b.Size = UDim2.new(1, 0, 0, if on then 58 else 52)
	end
	local state = StateController.Get() or {}
	local order = 0
	local function nextOrder()
		order += 1
		return order
	end

	if currentTab == "Gems" then
		for i, pack in EconomyConfig.GemPacks do
			local _, b = productCard(nextOrder(), {
				Color = GEM_COLOR:Lerp(Color3.fromRGB(150, 60, 255), (i - 1) / 5), Icon = if i >= 4 then "Chest" else "GemBig",
				IconSize = 70 + i * 6, Amount = UI.formatNumber(pack.Gems), Title = pack.Name, Subtitle = "Gems for characters, skins and more",
				Tag = pack.Tag, ButtonText = `{ROBUX} {pack.RobuxHint}`, ButtonColor = GREEN,
			})
			b.Activated:Connect(function()
				if pack.Id == 0 then
					CurrencyController.Toast("Product not set up (put its ID in EconomyConfig)", UI.Colors.Red)
				else
					MarketplaceService:PromptProductPurchase(player, pack.Id)
				end
			end)
		end
	elseif currentTab == "Passes" then
		for key, pass in CatalogConfig.GamePasses do
			local owned = player:GetAttribute(key) == true
			local _, b = productCard(nextOrder(), {
				Color = if key == "VIP" then Color3.fromRGB(255, 185, 40) else Color3.fromRGB(240, 80, 60),
				Icon = if key == "VIP" then "Crown" else "X2", Title = pass.Name, Subtitle = pass.Description,
				Tag = if key == "CoinsX2" then "BEST SELLER!" else nil,
				ButtonText = if owned then "IT'S YOURS!" else `{ROBUX} {pass.RobuxHint}`, ButtonColor = if owned then UI.Colors.Disabled else GREEN,
			})
			if not owned then
				b.Activated:Connect(function()
					if pass.Id == 0 then
						CurrencyController.Toast("Gamepass not set up (put its ID in CatalogConfig)", UI.Colors.Red)
					else
						MarketplaceService:PromptGamePassPurchase(player, pass.Id)
					end
				end)
			end
		end
	elseif currentTab == "Boosts" then
		local now = StateController.Now()
		local boosts = state.Boosts or { CoinsUntil = 0, XPUntil = 0 }
		for _, entry in sortedItems("Boost") do
			local item = entry.Item
			local untilTime = if item.Boost == "Coins" then boosts.CoinsUntil else boosts.XPUntil
			local active = untilTime > now
			local _, b = productCard(nextOrder(), {
				Color = if item.Boost == "Coins" then Color3.fromRGB(240, 150, 30) else Color3.fromRGB(60, 190, 255),
				Icon = if item.Boost == "Coins" then "X2" else "Star", Title = item.Name,
				Subtitle = if active then `Active! {UI.formatDuration(untilTime - now)} left` else "Double what you earn playing (stacks)",
				Tag = item.Tag, ButtonText = tostring(item.Gems), ButtonColor = GEM_COLOR, PriceIcon = "GemBig",
			})
			UI.confirmButton(b, function()
				request("BuyItem", entry.Id)
			end)
		end
	else
		local kind = currentTab
		local owned = if kind == "Effect" then state.OwnedEffects or {} else state.OwnedTitles or {}
		local equipped = if kind == "Effect" then state.EquippedEffect else state.EquippedTitle
		for _, entry in sortedItems(kind) do
			local item = entry.Item
			local has = owned[entry.Id] == true
			local isOn = equipped == entry.Id
			local color = item.Accent or item.Color
			local opts = {
				Color = color, Icon = if kind == "Effect" then "KO" else "Title", Title = item.Name,
				Subtitle = if item.StoryOnly then "Earned by completing Story Mode"
					elseif kind == "Effect" then "The whole server sees it when you eliminate someone" else "Shows under your name",
			}
			if has then
				opts.ButtonText = if isOn then "REMOVE" else "EQUIP"
				opts.ButtonColor = if isOn then UI.Colors.Disabled else UI.Colors.Accent
				opts.Tag = if isOn then "EQUIPPED" else nil
			elseif item.Gems then
				opts.ButtonText = tostring(item.Gems)
				opts.ButtonColor = GEM_COLOR
				opts.PriceIcon = "GemBig"
			else
				opts.ButtonText = "STORY"
				opts.ButtonColor = UI.Colors.Disabled
			end
			local _, b = productCard(nextOrder(), opts)
			if has then
				b.Activated:Connect(function()
					request("EquipCosmetic", kind, if isOn then false else entry.Id)
				end)
			elseif item.Gems then
				UI.confirmButton(b, function()
					request("BuyItem", entry.Id)
				end)
			end
		end
	end
end

function StoreController.Open(section: string?)
	if section then
		for _, tab in TABS do
			if tab.Id == section then
				currentTab = section
			end
		end
	end
	UI.show(frame)
	refresh()
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
	frame, content = UI.modal(gui, "🛒 Shop", UDim2.fromOffset(820, 520), UI.Colors.Gold)

	-- Pestañas a la izquierda
	local tabs = UI.make("Frame", { Size = UDim2.new(0, 150, 1, 0), BackgroundTransparency = 1 }, content)
	UI.make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, tabs)
	for i, tab in TABS do
		local b = UI.button(tabs, "", tab.Color, { Size = UDim2.new(1, 0, 0, 52), LayoutOrder = i, TextSize = 16 })
		b:SetAttribute("Color", tab.Color)
		local label = b:FindFirstChild("Label") :: TextLabel
		label.Text = tab.Name
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Position = UDim2.fromOffset(50, 0)
		label.Size = UDim2.new(1, -54, 1, -4)
		UI.icon(b, tab.Icon, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, -2), Size = UDim2.fromOffset(40, 40), ZIndex = 2 })
		b.Activated:Connect(function()
			currentTab = tab.Id
			refresh()
		end)
		tabButtons[tab.Id] = b
	end

	grid = UI.make("ScrollingFrame", {
		Position = UDim2.fromOffset(162, 0), Size = UDim2.new(1, -162, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 6,
		BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarImageColor3 = UI.Colors.Gold,
	}, content)
	UI.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(196, 228), CellPadding = UDim2.fromOffset(10, 12), SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	UI.make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 6) }, grid)

	StateController.Changed:Connect(refresh)
	for _, attr in { "VIP", "CoinsX2" } do
		player:GetAttributeChangedSignal(attr):Connect(refresh)
	end
end

return StoreController
