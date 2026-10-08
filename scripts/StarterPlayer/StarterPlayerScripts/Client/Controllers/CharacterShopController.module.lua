-- CharacterShopController: catálogo de personajes + movimientos + skins.
-- Muestra rareza, precio, requisito de nivel, Acceso Anticipado / Próximamente con cuenta atrás,
-- la lista de técnicas especiales de cada personaje y sus skins. Toda compra la valida el servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))
local EconomyConfig = require(Shared:WaitForChild("EconomyConfig"))
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))
local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local StateController = require(script.Parent:WaitForChild("StateController"))
local CurrencyController = require(script.Parent:WaitForChild("CurrencyController"))
local Portrait = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Portrait"))
local UltimateConfig = require(Shared:WaitForChild("UltimateConfig"))

local player = Players.LocalPlayer

local CharacterShopController = {}

local frame: Frame
local listFrame: ScrollingFrame
local detailFrame: ScrollingFrame
local selectedId: string = "Brawler"
local statusLabels: { [string]: TextLabel } = {}

local COIN = EconomyConfig.Currencies.Coins.Icon
local GEM = EconomyConfig.Currencies.Gems.Icon

local SPECIAL_SLOTS = {
	{ Key = "Special_Neutral", Input = "E" },
	{ Key = "Special_Side", Input = "+ E" },
	{ Key = "Special_Up", Input = "+ E" },
	{ Key = "Special_Down", Input = "+ E" },
}

local function sortedCharacters(): { string }
	local ids = {}
	for id in CatalogConfig.Characters do
		if CharacterRegistry.Get(id) then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		return CatalogConfig.Characters[a].Order < CatalogConfig.Characters[b].Order
	end)
	return ids
end

local function owns(id: string): boolean
	local state = StateController.Get()
	return state ~= nil and state.OwnedCharacters[id] == true
end

local function statusText(id: string): (string, Color3)
	if owns(id) then
		if player:GetAttribute("SelectedCharacter") == id then
			return "EN USO", UI.Colors.Green
		end
		return "TUYO", UI.Colors.Green
	end
	local now = StateController.Now()
	local status, endsAt = CatalogConfig.GetCharacterStatus(id, now)
	local coins, gems, level = CatalogConfig.GetPrices(id)
	if status == "EarlyAccess" then
		return `ACCESO ANTICIPADO · {UI.formatDuration(endsAt - now)}`, Color3.fromRGB(255, 120, 60)
	elseif status == "Upcoming" then
		return `PRÓXIMAMENTE · {UI.formatDuration(endsAt - now)}`, UI.Colors.Muted
	elseif not coins then
		return `晶 EXCLUSIVO · {UI.formatNumber(gems or 0)} {GEM}`, CatalogConfig.Rarities.Exclusive.Color
	end
	local text = `{UI.formatNumber(coins)} {COIN}`
	if level and (player:GetAttribute("Level") or 1) < level then
		text ..= `  ·  Nv {level}`
	end
	return text, EconomyConfig.Currencies.Coins.Color
end

local function request(action: string, ...)
	local response = StateController.Request(action, ...)
	CurrencyController.Toast(response.msg, if response.ok then UI.Colors.Green else UI.Colors.Red)
	return response.ok
end

local function clear(parent: Instance)
	for _, child in parent:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local refreshDetail -- declarada abajo

local function refreshList()
	clear(listFrame)
	statusLabels = {}
	for i, id in sortedCharacters() do
		local data = CharacterRegistry.Get(id)
		local rarity = CatalogConfig.Rarities[CatalogConfig.Characters[id].Rarity]
		local selected = id == selectedId
		local card = UI.make("TextButton", {
			Size = UDim2.new(1, -8, 0, 70), BackgroundColor3 = Color3.new(1, 1, 1), Text = "", AutoButtonColor = false, LayoutOrder = i,
		}, listFrame)
		UI.corner(card, 12)
		-- Degradado del color de la rareza hacia el fondo
		UI.gradient(card, rarity.Color:Lerp(Color3.fromRGB(20, 18, 30), if selected then 0.45 else 0.7), Color3.fromRGB(22, 20, 34), 0)
		if selected then
			UI.animatedStroke(card, data.Color, 2.5)
		else
			UI.stroke(card, rarity.Color, 1).Transparency = 0.4
		end
		UI.bounce(card, 1.03)
		-- Franja de rareza
		local strip = UI.make("Frame", { Size = UDim2.new(0, 4, 1, -16), Position = UDim2.fromOffset(0, 8), BackgroundColor3 = rarity.Color, BorderSizePixel = 0 }, card)
		UI.corner(strip, 2)
		-- Retrato 3D (busto)
		local bust = UI.make("Frame", { Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(58, 58), BackgroundColor3 = data.Color, BackgroundTransparency = 0.5 }, card)
		UI.corner(bust, 10)
		UI.gradient(bust, Color3.new(1, 1, 1), Color3.fromRGB(60, 60, 70))
		UI.stroke(bust, data.Color, 1.5)
		Portrait.Create(bust, id, "Bust", { Size = UDim2.fromScale(1, 1) })
		UI.label(card, { Position = UDim2.fromOffset(74, 7), Size = UDim2.new(1, -80, 0, 20), Text = data.DisplayName, TextSize = 15, Font = Enum.Font.GothamBlack, TextTruncate = Enum.TextTruncate.AtEnd, TextStrokeTransparency = 0.6 })
		UI.label(card, {
			Position = UDim2.fromOffset(74, 27), Size = UDim2.new(1, -80, 0, 14), Text = string.upper(rarity.Name),
			TextSize = 11, TextColor3 = rarity.Color, Font = Enum.Font.GothamBlack,
		})
		local text, color = statusText(id)
		statusLabels[id] = UI.label(card, {
			Position = UDim2.fromOffset(74, 46), Size = UDim2.new(1, -80, 0, 16), Text = text,
			TextSize = 11, Font = Enum.Font.GothamBlack, TextColor3 = color, TextTruncate = Enum.TextTruncate.AtEnd,
		})
		card.Activated:Connect(function()
			selectedId = id
			refreshList()
			refreshDetail()
		end)
	end
end

local function skinRow(parent: Instance, order: number, skinId: string, skin)
	local state = StateController.Get()
	local ownsSkin = state and state.OwnedSkins[skinId]
	local equipped = state and state.EquippedSkins[skin.Character] == skinId

	local row = UI.make("Frame", { Size = UDim2.new(1, -6, 0, 44), BackgroundColor3 = UI.Colors.Card, LayoutOrder = order }, parent)
	UI.corner(row, 8)
	local swatch = UI.make("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = skin.Colors.Torso }, row)
	UI.corner(swatch, 6)
	if skin.Aura then
		UI.stroke(swatch, skin.Aura, 2)
	end
	UI.label(row, { Position = UDim2.fromOffset(44, 4), Size = UDim2.new(1, -180, 0, 20), Text = skin.Name, TextSize = 14 })
	local tag = if skin.Premium then `PREMIUM · +{math.floor(CatalogConfig.PremiumSkinBoost * 100)}% {COIN}/XP` else "Cosmética"
	UI.label(row, {
		Position = UDim2.fromOffset(44, 23), Size = UDim2.new(1, -180, 0, 16), Text = tag, TextSize = 11,
		Font = Enum.Font.GothamBlack, TextColor3 = if skin.Premium then UI.Colors.Gold else UI.Colors.Muted,
	})

	local props = { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(128, 30), TextSize = 12 }
	if ownsSkin then
		if equipped then
			UI.button(row, "Quitar", UI.Colors.Disabled, props).Activated:Connect(function()
				request("EquipSkin", skin.Character, false)
			end)
		else
			UI.button(row, "Equipar", UI.Colors.Accent, props).Activated:Connect(function()
				request("EquipSkin", skin.Character, skinId)
			end)
		end
	elseif skin.BattlePassOnly then
		UI.button(row, "Pase de Batalla", UI.Colors.Disabled, props).AutoButtonColor = false
	elseif skin.StoryOnly then
		UI.button(row, "Modo Historia", UI.Colors.Disabled, props).AutoButtonColor = false
	elseif skin.RouletteOnly then
		local b = UI.button(row, "Ruleta Maldita", Color3.fromRGB(255, 50, 90), props)
		b.Activated:Connect(function()
			require(script.Parent:WaitForChild("RouletteController")).Open()
		end)
	else
		local gems = skin.PriceGems ~= nil
		local price = skin.PriceGems or skin.PriceCoins
		UI.confirmButton(UI.priceButton(row, if gems then "Gems" else "Coins", price, if gems then UI.Colors.Gems else Color3.fromRGB(150, 80, 230), props), function()
			request("BuySkin", skinId)
		end)
	end
end

local function section(title: string, order: number)
	return UI.sectionHeader(detailFrame, nil, title, UI.Colors.Accent, order)
end

function refreshDetail()
	clear(detailFrame)
	local id = selectedId
	local data = CharacterRegistry.Get(id)
	local entry = CatalogConfig.Characters[id]
	local rarity = CatalogConfig.Rarities[entry.Rarity]
	local now = StateController.Now()
	local status, endsAt = CatalogConfig.GetCharacterStatus(id, now)
	local priceCoins, priceGems, level = CatalogConfig.GetPrices(id)
	local order = 0
	local function nextOrder()
		order += 1
		return order
	end

	-- Escaparate: el personaje entero girando
	local showcase = UI.make("Frame", { Size = UDim2.new(1, -10, 0, 220), BackgroundColor3 = Color3.new(1, 1, 1), LayoutOrder = nextOrder() }, detailFrame)
	UI.corner(showcase, 14)
	UI.make("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, data.Color:Lerp(Color3.fromRGB(18, 16, 28), 0.45)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(26, 20, 40)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 12, 22)),
		}),
	}, showcase)
	UI.stroke(showcase, rarity.Color, 1.5).Transparency = 0.3
	-- Halo detrás del personaje + kanji gigante de su técnica
	local halo = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(190, 190),
		BackgroundColor3 = data.Color, BackgroundTransparency = 0.8,
	}, showcase)
	UI.corner(halo, 999)
	local ult = UltimateConfig.Characters[id]
	UI.label(showcase, {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 4), Size = UDim2.fromOffset(60, 210),
		Text = if ult then (ult.Japanese:gsub("[「」]", "")) else "呪", TextScaled = true, Font = Enum.Font.GothamBlack,
		TextColor3 = data.Color, TextTransparency = 0.75, TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true,
	})
	Portrait.Create(showcase, id, "Full", { Size = UDim2.fromScale(1, 1) })
	-- Insignia de rareza
	local rarityTag = UI.make("TextLabel", {
		Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = rarity.Color, Text = string.upper(rarity.Name), TextSize = 12, Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.4,
	}, showcase)
	UI.make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, rarityTag)
	UI.corner(rarityTag, 6)
	UI.gradient(rarityTag, Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170))

	local nameLabel = UI.label(detailFrame, { Size = UDim2.new(1, -6, 0, 36), Text = data.DisplayName, TextSize = 30, Font = UI.TitleFont, LayoutOrder = nextOrder(), TextStrokeTransparency = 0.5 })
	UI.gradient(nameLabel, Color3.new(1, 1, 1), data.Color:Lerp(Color3.new(1, 1, 1), 0.3))

	-- Estadísticas como barras
	local stats = UI.make("Frame", { Size = UDim2.new(1, -10, 0, 54), BackgroundTransparency = 1, LayoutOrder = nextOrder() }, detailFrame)
	UI.make("UIGridLayout", { CellSize = UDim2.new(1 / 3, -8, 0, 50), CellPadding = UDim2.fromOffset(8, 0) }, stats)
	for _, stat in {
		{ "PESO", data.Weight, 70, 130, Color3.fromRGB(255, 150, 70) },
		{ "VELOCIDAD", data.WalkSpeed, 14, 32, Color3.fromRGB(90, 220, 255) },
		{ "SALTO", data.JumpPower, 45, 80, Color3.fromRGB(120, 255, 140) },
	} do
		local cell = UI.make("Frame", { BackgroundColor3 = Color3.fromRGB(28, 24, 42) }, stats)
		UI.corner(cell, 8)
		UI.label(cell, { Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 0, 16), Text = stat[1], TextSize = 10, Font = Enum.Font.GothamBlack, TextColor3 = UI.Colors.Muted })
		UI.label(cell, { Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 0, 16), Text = tostring(stat[2]), TextSize = 13, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Right })
		UI.progressBar(cell, (stat[2] - stat[3]) / (stat[4] - stat[3]), stat[5], { Position = UDim2.fromOffset(8, 28), Size = UDim2.new(1, -16, 0, 10) })
	end

	-- Acciones del personaje
	local actions = UI.make("Frame", { Size = UDim2.new(1, -6, 0, 48), BackgroundTransparency = 1, LayoutOrder = nextOrder() }, detailFrame)
	UI.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, actions)
	local info = UI.label(detailFrame, { Size = UDim2.new(1, -6, 0, 18), TextSize = 12, TextColor3 = UI.Colors.Muted, Text = "", LayoutOrder = nextOrder(), TextWrapped = true })

	if owns(id) then
		local inUse = player:GetAttribute("SelectedCharacter") == id
		local b = UI.button(actions, if inUse then "EN USO" else "ELEGIR", if inUse then UI.Colors.Disabled else UI.Colors.Green, { Size = UDim2.fromOffset(170, 42), TextSize = 17 })
		if not inUse then
			b.Activated:Connect(function()
				request("SelectCharacter", id)
			end)
		end
	elseif status == "Upcoming" then
		info.Text = `Sale en {UI.formatDuration(endsAt - now)} · después, 14 días de Acceso Anticipado solo con {GEM}`
	else
		if status ~= "EarlyAccess" and priceCoins then
			local coinsBtn = UI.priceButton(actions, "Coins", priceCoins, Color3.fromRGB(150, 80, 230), { Size = UDim2.fromOffset(170, 42), TextSize = 17 })
			UI.confirmButton(coinsBtn, function()
				request("BuyCharacter", id, "Coins")
			end)
			local have = player:GetAttribute("Coins") or 0
			local lines = {}
			if level and (player:GetAttribute("Level") or 1) < level then
				table.insert(lines, `Necesitas Nivel {level} para comprarlo con {COIN}`)
			end
			if have < priceCoins then
				local hours = (priceCoins - have) / EconomyConfig.EstimatedCoinsPerHour
				table.insert(lines, `Te faltan {UI.formatNumber(priceCoins - have)} {COIN} (~{math.max(1, math.ceil(hours))} h de juego)`)
			end
			info.Text = table.concat(lines, "   ·   ")
		end
		if priceGems then
			local gemsBtn = UI.priceButton(actions, "Gems", priceGems, UI.Colors.Gems, { Size = UDim2.fromOffset(170, 42), TextSize = 17 })
			UI.shine(gemsBtn, 1.8)
			UI.confirmButton(gemsBtn, function()
				request("BuyCharacter", id, "Gems")
			end)
		end
		-- Probarlo gratis contra el muñeco del Dojo antes de comprarlo
		local tryBtn = UI.button(actions, "PROBAR", Color3.fromRGB(60, 160, 220), { Size = UDim2.fromOffset(110, 42), TextSize = 15 })
		tryBtn.Activated:Connect(function()
			if request("TryCharacter", id) then
				frame.Visible = false
			end
		end)
		if status == "EarlyAccess" then
			info.Text = `Acceso Anticipado: gratis con {COIN} en {UI.formatDuration(endsAt - now)}`
			info.TextColor3 = Color3.fromRGB(255, 150, 80)
		elseif not priceCoins then
			info.Text = "晶 Personaje exclusivo: solo se consigue con Gemas"
			info.TextColor3 = CatalogConfig.Rarities.Exclusive.Color
		end
	end

	-- Técnicas especiales (+ la ULTI)
	section("Técnicas", nextOrder())
	local function techniqueRow(key: string, name: string, detail: string, color: Color3, big: boolean?)
		local row = UI.make("Frame", { Size = UDim2.new(1, -10, 0, if big then 44 else 34), BackgroundColor3 = Color3.new(1, 1, 1), LayoutOrder = nextOrder() }, detailFrame)
		UI.corner(row, 8)
		UI.gradient(row, color:Lerp(Color3.fromRGB(24, 20, 36), if big then 0.55 else 0.8), Color3.fromRGB(24, 20, 36), 0)
		local badge = UI.make("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(if big then 64 else 44, if big then 30 else 24),
			BackgroundColor3 = color, Text = key, TextSize = 12, Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0.4,
		}, row)
		UI.corner(badge, 6)
		UI.gradient(badge, Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150))
		UI.label(row, { Position = UDim2.fromOffset(if big then 78 else 58, 0), Size = UDim2.new(1, -150, 1, 0), Text = name, TextSize = if big then 15 else 13, Font = Enum.Font.GothamBlack, TextTruncate = Enum.TextTruncate.AtEnd })
		UI.label(row, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.fromOffset(90, if big then 44 else 34), Text = detail, TextSize = 12, TextColor3 = UI.Colors.Muted, TextXAlignment = Enum.TextXAlignment.Right })
	end
	for _, slot in SPECIAL_SLOTS do
		local move = data.Moves[slot.Key]
		if move then
			techniqueRow(slot.Input, move.Name or slot.Key, if move.Damage then `{move.Damage}%` else "movilidad", data.Color)
		end
	end
	if ult then
		local kindText = if ult.Kind == "Domain" then "Expansión de Dominio" elseif ult.Kind == "Transform" then "Transformación" else "Técnica definitiva"
		techniqueRow("ULTI R", `{ult.Name}`, kindText, ult.Color, true)
	end

	-- Skins
	section("Skins", nextOrder())
	local ids = {}
	for skinId, skin in CatalogConfig.Skins do
		if skin.Character == id then
			table.insert(ids, skinId)
		end
	end
	table.sort(ids)
	for _, skinId in ids do
		skinRow(detailFrame, nextOrder(), skinId, CatalogConfig.Skins[skinId])
	end
	if #ids == 0 then
		UI.label(detailFrame, { Size = UDim2.new(1, -6, 0, 20), Text = "Próximamente", TextColor3 = UI.Colors.Muted, TextSize = 13, LayoutOrder = nextOrder() })
	end
end

local function refreshAll()
	if frame and frame.Visible and StateController.Get() then
		refreshList()
		refreshDetail()
	end
end

function CharacterShopController.Open(characterId: string?)
	if characterId and CatalogConfig.Characters[characterId] then
		selectedId = characterId
	end
	UI.show(frame)
	refreshAll()
end

function CharacterShopController.Toggle()
	if frame.Visible then
		frame.Visible = false
	else
		CharacterShopController.Open()
	end
end

function CharacterShopController.Start()
	local gui = UI.screenGui("CharacterShop", 10)
	local content
	frame, content = UI.modal(gui, "🥋 Personajes", UDim2.fromOffset(820, 540), UI.Colors.Accent)

	listFrame = UI.make("ScrollingFrame", {
		Size = UDim2.new(0, 270, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = UI.Colors.Accent,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, BorderSizePixel = 0,
	}, content)
	UI.make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, listFrame)
	UI.make("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, listFrame)

	detailFrame = UI.make("ScrollingFrame", {
		Position = UDim2.fromOffset(284, 0), Size = UDim2.new(1, -284, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 4,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, BorderSizePixel = 0,
	}, content)
	UI.make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, detailFrame)
	UI.make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8) }, detailFrame)

	StateController.Changed:Connect(refreshAll)
	player:GetAttributeChangedSignal("SelectedCharacter"):Connect(refreshAll)

	-- Las cuentas atrás se actualizan cada segundo (solo el texto)
	task.spawn(function()
		while true do
			task.wait(1)
			if frame.Visible and StateController.Get() then
				for id, label in statusLabels do
					if label.Parent then
						label.Text, label.TextColor3 = statusText(id)
					end
				end
			end
		end
	end)
end

return CharacterShopController
