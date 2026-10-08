-- GoalController: "muro de grind" siempre visible (Fase 5).
-- Muestra el próximo personaje desbloqueable con barra de progreso y horas estimadas,
-- y el atajo de pago al lado (efecto "goal gradient": cuanto más cerca, más motiva).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))
local EconomyConfig = require(Shared:WaitForChild("EconomyConfig"))
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))
local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local StateController = require(script.Parent:WaitForChild("StateController"))
local CharacterShopController = require(script.Parent:WaitForChild("CharacterShopController"))

local player = Players.LocalPlayer

local GoalController = {}

local COIN = EconomyConfig.Currencies.Coins.Icon
local GEM = EconomyConfig.Currencies.Gems.Icon

-- El objetivo es el personaje NO poseído más barato que ya se puede comprar con Monedas
local function findGoal(): string?
	local state = StateController.Get()
	if not state then
		return nil
	end
	local best, bestPrice = nil, math.huge
	for id in CatalogConfig.Characters do
		local coins = CatalogConfig.GetPrices(id)
		if not state.OwnedCharacters[id] and CharacterRegistry.Get(id) and coins then
			local status = CatalogConfig.GetCharacterStatus(id, StateController.Now())
			if status == "Available" and coins < bestPrice then
				best, bestPrice = id, coins
			end
		end
	end
	return best
end

-- Personaje en Acceso Anticipado que el jugador aún no tiene (para el aviso de FOMO)
local function findEarlyAccess(): (string?, number?)
	local state = StateController.Get()
	for id in CatalogConfig.Characters do
		local status, endsAt = CatalogConfig.GetCharacterStatus(id, StateController.Now())
		if status == "EarlyAccess" and state and not state.OwnedCharacters[id] then
			return id, endsAt
		end
	end
	return nil, nil
end

function GoalController.Start()
	local gui = UI.screenGui("GoalHUD", 3)
	local container = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(420, 90),
		BackgroundTransparency = 1,
	}, gui)
	UI.make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, container)
	UI.autoScale(container)

	local panel = UI.make("Frame", {
		Size = UDim2.fromOffset(420, 52), LayoutOrder = 1,
		BackgroundColor3 = UI.Colors.Panel, BackgroundTransparency = 0.15, Visible = false,
	}, container)
	UI.corner(panel, 12)
	UI.stroke(panel, EconomyConfig.Currencies.Coins.Color, 1.5)

	local title = UI.label(panel, { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -130, 0, 18), TextSize = 13 })
	local barBack = UI.make("Frame", {
		Position = UDim2.fromOffset(12, 25), Size = UDim2.new(1, -130, 0, 8), BackgroundColor3 = Color3.fromRGB(50, 45, 70),
	}, panel)
	UI.corner(barBack, 4)
	local barFill = UI.make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = EconomyConfig.Currencies.Coins.Color }, barBack)
	UI.corner(barFill, 4)
	local sub = UI.label(panel, { Position = UDim2.fromOffset(12, 35), Size = UDim2.new(1, -130, 0, 14), TextSize = 11, TextColor3 = UI.Colors.Muted })
	local shortcut = UI.button(panel, "", UI.Colors.Gems, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(106, 34), TextSize = 13,
	})

	local eaBanner = UI.button(container, "", Color3.fromRGB(150, 40, 20), {
		Size = UDim2.fromOffset(420, 26), TextSize = 12, Visible = false, LayoutOrder = 2,
	})

	local goalId: string? = nil
	local eaId: string? = nil
	shortcut.Activated:Connect(function()
		if goalId then
			CharacterShopController.Open(goalId)
		end
	end)
	eaBanner.Activated:Connect(function()
		if eaId then
			CharacterShopController.Open(eaId)
		end
	end)

	local function refresh()
		local activity = player:GetAttribute("Activity")
		local inHub = activity == "Hub" or activity == "Queue" or activity == nil
		goalId = findGoal()
		panel.Visible = goalId ~= nil and inHub
		if goalId then
			local priceCoins, priceGems, level = CatalogConfig.GetPrices(goalId)
			local coins = player:GetAttribute("Coins") or 0
			local progress = math.clamp(coins / priceCoins, 0, 1)
			title.Text = `Próximo objetivo: {CharacterRegistry.Get(goalId).DisplayName}`
			TweenService:Create(barFill, TweenInfo.new(0.3), { Size = UDim2.fromScale(progress, 1) }):Play()
			local myLevel = player:GetAttribute("Level") or 1
			if coins >= priceCoins and (not level or myLevel >= level) then
				sub.Text = "¡Ya puedes desbloquearlo! Abre Personajes"
				sub.TextColor3 = UI.Colors.Green
			else
				local hours = math.max(1, math.ceil(math.max(0, priceCoins - coins) / EconomyConfig.EstimatedCoinsPerHour))
				local levelText = if level and myLevel < level then `  ·  Nv {level}` else ""
				sub.Text = `{UI.formatNumber(coins)} / {UI.formatNumber(priceCoins)} {COIN}   ·   ~{hours} h de juego{levelText}`
				sub.TextColor3 = UI.Colors.Muted
			end
			shortcut.Text = if priceGems then `Ya: {priceGems} {GEM}` else "Ver"
		end

		local endsAt
		eaId, endsAt = findEarlyAccess()
		eaBanner.Visible = eaId ~= nil and inHub
		if eaId and endsAt then
			eaBanner.Text = `{CharacterRegistry.Get(eaId).DisplayName} en Acceso Anticipado · gratis con {COIN} en {UI.formatDuration(endsAt - StateController.Now())}`
		end
	end

	StateController.Changed:Connect(refresh)
	player:GetAttributeChangedSignal("Coins"):Connect(refresh)
	player:GetAttributeChangedSignal("Activity"):Connect(refresh)
	task.spawn(function()
		while true do
			task.wait(1) -- la cuenta atrás del Acceso Anticipado
			refresh()
		end
	end)
end

return GoalController
