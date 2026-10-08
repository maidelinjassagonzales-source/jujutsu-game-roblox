-- CurrencyController: panel de Monedas Malditas / Gemas / Nivel / Booster, avisos y tienda de gemas.
-- Solo LEE atributos del jugador (los replica el servidor); nunca modifica saldos.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EconomyConfig = require(Shared:WaitForChild("EconomyConfig"))
local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))

local player = Players.LocalPlayer

local CurrencyController = {}

local gui: ScreenGui
local toastList: Frame
local toastOrder = 0

function CurrencyController.Toast(text: string, color: Color3?)
	if not toastList then
		return
	end
	toastOrder += 1
	local label = UI.label(toastList, {
		Size = UDim2.new(1, 0, 0, 24), Text = text, TextSize = 17, Font = Enum.Font.GothamBlack,
		TextColor3 = color or UI.Colors.Text, TextStrokeTransparency = 0.3,
		TextXAlignment = Enum.TextXAlignment.Right, LayoutOrder = toastOrder,
	})
	task.delay(2.2, function()
		TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.wait(0.45)
		label:Destroy()
	end)
end

function CurrencyController.OpenGemShop()
	-- La tienda completa vive en StoreController (require perezoso para evitar dependencias circulares)
	require(script.Parent:WaitForChild("StoreController")).Open("Gems")
end

local function currencyRow(parent: Instance, order: number, currency: string)
	local info = EconomyConfig.Currencies[currency]
	local row = UI.make("Frame", {
		Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = UI.Colors.Panel, BackgroundTransparency = 0.15, LayoutOrder = order,
	}, parent)
	UI.corner(row, 10)
	UI.make("UIStroke", { Color = info.Color, Thickness = 1.5, Transparency = 0.3 }, row)
	UI.icon(row, if currency == "Gems" then "Gems" else "Coins", { Position = UDim2.fromOffset(0, -3), Size = UDim2.fromOffset(40, 40) })
	local amount = UI.label(row, {
		Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -72, 1, 0), Text = "0", TextSize = 18, Font = Enum.Font.GothamBlack,
	})
	local scale = UI.make("UIScale", {}, amount)

	local function refresh()
		amount.Text = UI.formatNumber(player:GetAttribute(currency) or 0)
		scale.Scale = 1.2
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	player:GetAttributeChangedSignal(currency):Connect(refresh)
	refresh()
	return row
end

function CurrencyController.Start()
	gui = UI.screenGui("EconomyHUD", 5)

	local panel = UI.make("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 60), Size = UDim2.fromOffset(200, 160),
		BackgroundTransparency = 1,
	}, gui)
	UI.make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, panel)
	UI.autoScale(panel)

	currencyRow(panel, 1, "Coins")
	local gemsRow = currencyRow(panel, 2, "Gems")
	local plus = UI.button(gemsRow, "+", UI.Colors.Green, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -5, 0.5, 0), Size = UDim2.fromOffset(28, 26), TextSize = 20,
	})

	-- Nivel + barra de XP
	local levelRow = UI.make("Frame", {
		Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = UI.Colors.Panel, BackgroundTransparency = 0.15, LayoutOrder = 3,
	}, panel)
	UI.corner(levelRow, 10)
	local levelLabel = UI.label(levelRow, { Position = UDim2.fromOffset(10, 2), Size = UDim2.new(1, -20, 0, 16), TextSize = 13 })
	local barBack = UI.make("Frame", {
		Position = UDim2.fromOffset(10, 21), Size = UDim2.new(1, -20, 0, 7), BackgroundColor3 = Color3.fromRGB(50, 45, 70),
	}, levelRow)
	UI.corner(barBack, 4)
	local barFill = UI.make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = UI.Colors.Gold }, barBack)
	UI.corner(barFill, 4)

	local function refreshLevel()
		local xp, needed = player:GetAttribute("XP") or 0, player:GetAttribute("XPNeeded") or 100
		levelLabel.Text = `Level {player:GetAttribute("Level") or 1}   ·   {xp}/{needed} XP`
		TweenService:Create(barFill, TweenInfo.new(0.3), { Size = UDim2.fromScale(math.clamp(xp / needed, 0, 1), 1) }):Play()
	end
	for _, attr in { "XP", "XPNeeded", "Level" } do
		player:GetAttributeChangedSignal(attr):Connect(refreshLevel)
	end
	refreshLevel()

	-- Booster activo (skin premium / VIP): se muestra para que se vea el beneficio
	local boostLabel = UI.label(panel, {
		Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 4, TextSize = 13, Font = Enum.Font.GothamBlack,
		TextColor3 = UI.Colors.Gold, TextXAlignment = Enum.TextXAlignment.Right, Visible = false,
	})
	local function refreshBoost()
		local coins, xp = player:GetAttribute("BoostCoins") or 0, player:GetAttribute("BoostXP") or 0
		boostLabel.Visible = coins > 0 or xp > 0
		boostLabel.Text = `+{coins}% {EconomyConfig.Currencies.Coins.Icon}   ·   +{xp}% XP`
	end
	player:GetAttributeChangedSignal("BoostCoins"):Connect(refreshBoost)
	player:GetAttributeChangedSignal("BoostXP"):Connect(refreshBoost)
	refreshBoost()

	toastList = UI.make("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 226), Size = UDim2.fromOffset(340, 200),
		BackgroundTransparency = 1,
	}, gui)
	UI.make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, toastList)
	local toastScale = UI.autoScale(toastList)
	-- los avisos van justo debajo del panel, sea cual sea la escala
	local function placeToasts()
		toastList.Position = UDim2.new(1, -16, 0, 60 + 166 * toastScale.Scale)
	end
	toastScale:GetPropertyChangedSignal("Scale"):Connect(placeToasts)
	placeToasts()

	plus.Activated:Connect(CurrencyController.OpenGemShop)

	local coinInfo, gemInfo = EconomyConfig.Currencies.Coins, EconomyConfig.Currencies.Gems
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EconomyFeedback").OnClientEvent:Connect(function(kind, a, b, c)
		if kind == "Reward" then
			local reason = if a.Reason then ` ({a.Reason})` else ""
			if a.Coins and a.Coins > 0 then
				CurrencyController.Toast(`+{a.Coins} {coinInfo.Icon}{reason}`, coinInfo.Color)
			end
			if a.Gems and a.Gems > 0 then
				CurrencyController.Toast(`+{a.Gems} {gemInfo.Icon}{reason}`, gemInfo.Color)
			end
			if a.XP and a.XP > 0 then
				CurrencyController.Toast(`+{a.XP} XP`, UI.Colors.Gold)
			end
			-- Aviso sin recompensa (p. ej. "X ha cambiado el Dojo", "Servidor lleno")
			if not ((a.Coins or 0) > 0 or (a.Gems or 0) > 0 or (a.XP or 0) > 0) and a.Reason then
				CurrencyController.Toast(a.Reason, UI.Colors.Muted)
			end
		elseif kind == "LevelUp" then
			-- a = nivel, b = monedas, c = gemas
			CurrencyController.Toast(`LEVEL {a}! +{b} {coinInfo.Icon}` .. (if c > 0 then ` +{c} {gemInfo.Icon}` else ""), UI.Colors.Gold)
		elseif kind == "BPTier" then
			CurrencyController.Toast(`Pass tier {a}! Claim your reward`, Color3.fromRGB(255, 150, 60))
		end
	end)
end

return CurrencyController
