-- StageSelectController: elegir escenario.
--   * Dojo de práctica: ventana con los escenarios (o "Aleatorio"); cambia el Dojo para todos los que están dentro
--   * Antes de cada duelo / partida rápida: votación con cuenta atrás. Gana el más votado;
--     si nadie vota o hay empate, sale al azar.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StageConfig = require(Shared:WaitForChild("StageConfig"))
local ArenaInfo = require(Shared:WaitForChild("ArenaInfo"))
local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local Sfx = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Sfx"))
local StateController = require(script.Parent:WaitForChild("StateController"))
local CurrencyController = require(script.Parent:WaitForChild("CurrencyController"))

local player = Players.LocalPlayer

local StageSelectController = {}

local RANDOM_CARD = { Kanji = "?", Description = "Que decida el destino", Colors = { Color3.fromRGB(200, 200, 210), Color3.fromRGB(30, 28, 40) } }

local dojoFrame: Frame
local dojoGrid: Frame
local voteGui: ScreenGui
local voteFrame: Frame
local voteGrid: Frame
local voteTitle: TextLabel
local voteTimer: Frame
local voteCards = {} -- [id] = { Card, Count, Check }
local myVote: string? = nil

-- Tarjeta de escenario: degradado con los colores del escenario, kanji gigante, nombre y descripción
local function stageCard(parent: Instance, id: string, order: number, onPick: () -> ())
	local info = if id == "Random" then RANDOM_CARD else StageConfig.Cards[id] or RANDOM_CARD
	local stageName = if id == "Random" then "Aleatorio" else (StageConfig.Stages[id] and StageConfig.Stages[id].Name or id)
	local card = UI.make("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(1, 1, 1), LayoutOrder = order, ClipsDescendants = true,
	}, parent)
	UI.corner(card, 14)
	UI.make("UIGradient", { Rotation = 90, Color = ColorSequence.new(info.Colors[1], info.Colors[2]) }, card)
	local stroke = UI.stroke(card, info.Colors[1]:Lerp(Color3.new(1, 1, 1), 0.4), 2)
	UI.bounce(card, 1.04)
	-- Oscurece la parte de abajo para que se lea el texto (va por debajo de los textos)
	local shade = UI.make("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 1,
	}, card)
	UI.make("UIGradient", { Rotation = -90, Transparency = NumberSequence.new(0, 1) }, shade)
	UI.label(card, {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 6, 0, -14), Size = UDim2.fromOffset(120, 120), Text = info.Kanji,
		TextScaled = true, Font = Enum.Font.GothamBlack, TextTransparency = 0.55, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 1,
	})
	UI.label(card, {
		Position = UDim2.new(0, 12, 1, -56), Size = UDim2.new(1, -24, 0, 28), Text = stageName, TextSize = 21, Font = UI.TitleFont,
		TextStrokeTransparency = 0.3, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2,
	})
	UI.label(card, {
		Position = UDim2.new(0, 12, 1, -28), Size = UDim2.new(1, -24, 0, 18), Text = info.Description, TextSize = 12,
		TextColor3 = Color3.fromRGB(230, 225, 240), TextStrokeTransparency = 0.5, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2,
	})
	card.Activated:Connect(onPick)
	return card, stroke
end

-- ===== Dojo
local function refreshDojo()
	for _, c in dojoGrid:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local hubInfo = ArenaInfo.Get("Hub")
	local current = hubInfo and hubInfo:GetAttribute("StageId")
	local ids = table.clone(StageConfig.MatchPool)
	table.insert(ids, "Random")
	for i, id in ids do
		local card, stroke = stageCard(dojoGrid, id, i, function()
			local response = StateController.Request("SetDojoStage", id)
			CurrencyController.Toast(response.msg, if response.ok then UI.Colors.Green else UI.Colors.Red)
			if response.ok then
				dojoFrame.Visible = false
			end
		end)
		if id == current then
			stroke.Color = UI.Colors.Gold
			stroke.Thickness = 3
			UI.ribbon(card, "Actual", Color3.fromRGB(230, 160, 20))
		end
	end
end

function StageSelectController.OpenDojo()
	UI.show(dojoFrame)
	refreshDojo()
end

-- ===== Votación antes de la partida
local function showVote(options: { string }, seconds: number)
	myVote = nil
	voteCards = {}
	for _, c in voteGrid:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local ids = table.clone(options)
	table.insert(ids, "Random")
	for i, id in ids do
		local card, stroke = stageCard(voteGrid, id, i, function()
			if myVote == id then
				return
			end
			myVote = id
			Sfx.Play("Click")
			StateController.Request("VoteStage", id)
			for otherId, entry in voteCards do
				entry.Check.Visible = otherId == id
				entry.Stroke.Thickness = if otherId == id then 4 else 2
			end
		end)
		local count = UI.make("TextLabel", {
			Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Color3.fromRGB(20, 18, 30), BackgroundTransparency = 0.2, Text = "0 votos", TextSize = 13,
			Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1), Visible = false, ZIndex = 3,
		}, card)
		UI.make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, count)
		UI.corner(count, 8)
		local check = UI.make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromOffset(150, 34),
			BackgroundColor3 = UI.Colors.Green, Text = "TU VOTO", TextSize = 16, Font = Enum.Font.GothamBlack,
			TextColor3 = Color3.new(1, 1, 1), Visible = false, Rotation = -6, ZIndex = 3,
		}, card)
		UI.corner(check, 8)
		UI.stroke(check, Color3.new(1, 1, 1), 2)
		voteCards[id] = { Card = card, Count = count, Check = check, Stroke = stroke }
	end
	voteTitle.Text = "ELIGE EL ESCENARIO"
	voteGui.Enabled = true
	voteFrame.Visible = true
	local scale = voteFrame:FindFirstChildOfClass("UIScale") :: UIScale
	local target = scale.Scale
	scale.Scale = target * 0.85
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = target }):Play()
	-- barra de tiempo
	voteTimer.Size = UDim2.fromScale(1, 1)
	TweenService:Create(voteTimer, TweenInfo.new(seconds, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 1) }):Play()
end

local function updateVotes(counts)
	for id, entry in voteCards do
		local n = counts[id] or 0
		entry.Count.Visible = n > 0
		entry.Count.Text = if n == 1 then "1 voto" else `{n} votos`
	end
end

local function revealStage(stageId: string, wasRandom: boolean)
	local name = StageConfig.Stages[stageId] and StageConfig.Stages[stageId].Name or stageId
	voteTitle.Text = if wasRandom then `AL AZAR: {string.upper(name)}` else `¡{string.upper(name)}!`
	Sfx.Play("LevelUp", nil, 0.8)
	for id, entry in voteCards do
		if id == stageId then
			entry.Stroke.Color = UI.Colors.Gold
			entry.Stroke.Thickness = 5
			local s = entry.Card:FindFirstChildOfClass("UIScale")
			if s then
				TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1.12 }):Play()
			end
		else
			TweenService:Create(entry.Card, TweenInfo.new(0.3), { BackgroundTransparency = 0.7 }):Play()
		end
	end
	task.delay(1.5, function()
		voteFrame.Visible = false
		voteGui.Enabled = false
	end)
end

function StageSelectController.Start()
	-- Ventana del Dojo
	local gui = UI.screenGui("StageSelect", 10)
	local content
	dojoFrame, content = UI.modal(gui, "🏯 Escenario del Dojo", UDim2.fromOffset(700, 440), Color3.fromRGB(60, 160, 220))
	dojoGrid = UI.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, content)
	UI.make("UIGridLayout", { CellSize = UDim2.new(1 / 3, -10, 0.5, -8), CellPadding = UDim2.fromOffset(12, 14), SortOrder = Enum.SortOrder.LayoutOrder }, dojoGrid)
	UI.make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, dojoGrid)

	-- Pantalla de votación (no se puede cerrar: dura lo que dura la cuenta atrás)
	voteGui = UI.screenGui("StageVote", 40)
	voteGui.Enabled = false
	UI.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, ZIndex = 1 }, voteGui)
	voteFrame = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(820, 470),
		BackgroundColor3 = Color3.new(1, 1, 1), Visible = false, ZIndex = 2,
	}, voteGui)
	UI.corner(voteFrame, 18)
	UI.gradient(voteFrame, Color3.fromRGB(40, 28, 62), Color3.fromRGB(12, 10, 20))
	UI.animatedStroke(voteFrame, UI.Colors.Gold, 2.5)
	UI.glow(voteFrame, UI.Colors.Gold, 18)
	UI.autoScale(voteFrame)
	voteTitle = UI.label(voteFrame, {
		Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, 0, 0, 40), Text = "ELIGE EL ESCENARIO", TextSize = 32, Font = UI.TitleFont,
		TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4,
	})
	UI.gradient(voteTitle, Color3.new(1, 1, 1), UI.Colors.Gold)
	local timerBack = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 58), Size = UDim2.new(1, -48, 0, 8),
		BackgroundColor3 = Color3.fromRGB(40, 34, 60), BorderSizePixel = 0,
	}, voteFrame)
	UI.corner(timerBack, 999)
	voteTimer = UI.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.Colors.Gold, BorderSizePixel = 0 }, timerBack)
	UI.corner(voteTimer, 999)
	voteGrid = UI.make("Frame", { Position = UDim2.fromOffset(20, 80), Size = UDim2.new(1, -40, 1, -100), BackgroundTransparency = 1 }, voteFrame)
	UI.make("UIGridLayout", { CellSize = UDim2.new(1 / 3, -10, 0.5, -8), CellPadding = UDim2.fromOffset(12, 14), SortOrder = Enum.SortOrder.LayoutOrder }, voteGrid)

	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MatchFeedback").OnClientEvent:Connect(function(kind, a, b)
		if kind == "StageVote" and type(a) == "table" then
			showVote(a, tonumber(b) or StageConfig.VoteTime)
		elseif kind == "StageVotes" and type(a) == "table" then
			updateVotes(a)
		elseif kind == "StageChosen" and type(a) == "string" then
			revealStage(a, b == true)
		elseif kind == "Countdown" then
			voteFrame.Visible = false
			voteGui.Enabled = false
		end
	end)
end

return StageSelectController
