-- CharacterSelectController: elegir personaje antes de cada partida (después de votar el escenario).
--   * Rejilla con los personajes que posees (retrato 3D, nombre y rareza)
--   * Cuenta atrás: si no eliges, vas con el que tenías seleccionado
--   * Abajo se ve quién ya ha elegido y con quién
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))
local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local Portrait = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Portrait"))
local Sfx = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Sfx"))
local StateController = require(script.Parent:WaitForChild("StateController"))
local CurrencyController = require(script.Parent:WaitForChild("CurrencyController"))

local CharacterSelectController = {}

local gui: ScreenGui
local frame: Frame
local title: TextLabel
local grid: ScrollingFrame
local timerBar: Frame
local pickedLabel: TextLabel
local readyLabel: TextLabel
local cards = {} -- [id] = { Card, Stroke, Check }
local myPick: string? = nil

local function setPicked(id: string)
	myPick = id
	local data = CharacterRegistry.Get(id)
	pickedLabel.Text = `Your fighter: {if data then data.DisplayName else id}`
	for otherId, entry in cards do
		local on = otherId == id
		entry.Check.Visible = on
		entry.Stroke.Thickness = if on then 4 else 2
		entry.Stroke.Color = if on then UI.Colors.Gold else entry.Base
	end
end

local function open(list: { string }, current: string, seconds: number, modeName: string?)
	for _, c in grid:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	cards = {}
	myPick = nil
	title.Text = `CHOOSE YOUR FIGHTER · {modeName or ""}`
	readyLabel.Text = ""
	for i, id in list do
		local data = CharacterRegistry.Get(id)
		local catalog = CatalogConfig.Characters[id] or {}
		local rarity = CatalogConfig.Rarities[catalog.Rarity or ""] or {}
		local accent = rarity.Color or UI.Colors.Accent
		local card = UI.make("TextButton", {
			Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(1, 1, 1), LayoutOrder = i, ClipsDescendants = true,
		}, grid)
		UI.corner(card, 12)
		UI.make("UIGradient", { Rotation = 90, Color = ColorSequence.new((data and data.Color or accent):Lerp(Color3.new(0, 0, 0), 0.35), Color3.fromRGB(14, 12, 22)) }, card)
		local stroke = UI.stroke(card, accent, 2)
		UI.bounce(card, 1.05)
		Portrait.Create(card, id, "Bust", { Size = UDim2.new(1, 0, 1, -30), ZIndex = 2 })
		UI.label(card, {
			AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 4, 1, -14), Size = UDim2.new(1, -8, 0, 18),
			Text = if data then data.DisplayName else id, TextScaled = true, Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4, ZIndex = 3,
		})
		UI.label(card, {
			AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 4, 1, -2), Size = UDim2.new(1, -8, 0, 12),
			Text = rarity.Name or "", TextScaled = true, TextColor3 = accent, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3,
		})
		local check = UI.make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(90, 22),
			BackgroundColor3 = UI.Colors.Green, Text = "ELEGIDO", TextSize = 13, Font = Enum.Font.GothamBlack,
			TextColor3 = Color3.new(1, 1, 1), Visible = false, ZIndex = 4,
		}, card)
		UI.corner(check, 6)
		cards[id] = { Card = card, Stroke = stroke, Check = check, Base = accent }
		card.Activated:Connect(function()
			if myPick == id then
				return
			end
			Sfx.Play("Click")
			local response = StateController.Request("PickCharacter", id)
			if response.ok then
				setPicked(id)
			elseif response.msg and response.msg ~= "" then
				CurrencyController.Toast(response.msg, UI.Colors.Red)
			end
		end)
	end
	-- Marca el que llevabas (sin confirmarlo: si no tocas nada, vas con él)
	if cards[current] then
		cards[current].Stroke.Color = UI.Colors.Gold
		local data = CharacterRegistry.Get(current)
		pickedLabel.Text = `If you don't choose: {if data then data.DisplayName else current}`
	else
		pickedLabel.Text = ""
	end

	gui.Enabled = true
	frame.Visible = true
	local scale = frame:FindFirstChildOfClass("UIScale") :: UIScale
	if scale then
		local target = scale.Scale
		scale.Scale = target * 0.85
		TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = target }):Play()
	end
	timerBar.Size = UDim2.fromScale(1, 1)
	TweenService:Create(timerBar, TweenInfo.new(seconds, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 1) }):Play()
end

local function close()
	frame.Visible = false
	gui.Enabled = false
end

function CharacterSelectController.Start()
	gui = UI.screenGui("CharacterSelect", 41, true)
	gui.Enabled = false
	UI.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, ZIndex = 1 }, gui)
	frame = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(860, 520),
		BackgroundColor3 = Color3.new(1, 1, 1), Visible = false, ZIndex = 2,
	}, gui)
	UI.corner(frame, 18)
	UI.gradient(frame, Color3.fromRGB(40, 28, 62), Color3.fromRGB(12, 10, 20))
	UI.animatedStroke(frame, UI.Colors.Gold, 2.5)
	UI.autoScale(frame)
	title = UI.label(frame, {
		Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, 0, 0, 38), Text = "CHOOSE YOUR FIGHTER", TextSize = 30, Font = UI.TitleFont,
		TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4,
	})
	UI.gradient(title, Color3.new(1, 1, 1), UI.Colors.Gold)
	local timerBack = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 56), Size = UDim2.new(1, -48, 0, 8),
		BackgroundColor3 = Color3.fromRGB(40, 34, 60), BorderSizePixel = 0,
	}, frame)
	UI.corner(timerBack, 999)
	timerBar = UI.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.Colors.Gold, BorderSizePixel = 0 }, timerBack)
	UI.corner(timerBar, 999)

	grid = UI.make("ScrollingFrame", {
		Position = UDim2.fromOffset(20, 76), Size = UDim2.new(1, -40, 1, -146), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
	}, frame)
	UI.make("UIGridLayout", { CellSize = UDim2.fromOffset(122, 150), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
	UI.make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, grid)

	pickedLabel = UI.label(frame, {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 24, 1, -40), Size = UDim2.new(1, -48, 0, 24), Text = "", TextSize = 18,
		Font = Enum.Font.GothamBlack, TextColor3 = UI.Colors.Gold,
	})
	readyLabel = UI.label(frame, {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 24, 1, -12), Size = UDim2.new(1, -48, 0, 22), Text = "", TextSize = 14,
		TextColor3 = UI.Colors.Muted, TextTruncate = Enum.TextTruncate.AtEnd,
	})

	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MatchFeedback").OnClientEvent:Connect(function(kind, a, b, c, d)
		if kind == "CharacterSelect" and type(a) == "table" then
			open(a, b, tonumber(c) or 12, d)
		elseif kind == "CharacterPicks" and type(a) == "table" then
			local parts = {}
			for _, entry in a do
				local data = CharacterRegistry.Get(entry.CharacterId)
				table.insert(parts, `{entry.Name}: {if data then data.DisplayName else entry.CharacterId}`)
			end
			readyLabel.Text = if #parts > 0 then "Listos · " .. table.concat(parts, "  ·  ") else ""
		elseif kind == "CharacterSelectEnd" or kind == "Countdown" then
			close()
		end
	end)

	-- Si se cierra la partida o vuelves al Lobby sin que llegue el final, no se queda abierta
	Players.LocalPlayer:GetAttributeChangedSignal("Activity"):Connect(function()
		local activity = Players.LocalPlayer:GetAttribute("Activity")
		if activity ~= "Queue" and activity ~= "Match" then
			close()
		end
	end)
end

return CharacterSelectController
