-- StoryController: Modo Historia en el cliente.
--   * Lista de capítulos (bloqueados / disponibles / completados) con sus recompensas
--   * Diálogos con efecto máquina de escribir (clic o toque para avanzar, botón Saltar)
--   * Aviso de oleadas, opción de revivir con Gemas y pantalla de resultado
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StoryConfig = require(Shared:WaitForChild("StoryConfig"))
local StageConfig = require(Shared:WaitForChild("StageConfig"))
local EconomyConfig = require(Shared:WaitForChild("EconomyConfig"))
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))
local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local StateController = require(script.Parent:WaitForChild("StateController"))
local CurrencyController = require(script.Parent:WaitForChild("CurrencyController"))

local player = Players.LocalPlayer

local StoryController = {}

local gui: ScreenGui
local listFrame: Frame
local listContent: ScrollingFrame
local dialogue: Frame
local portrait: Frame
local portraitIcon: TextLabel
local speakerLabel: TextLabel
local textLabel: TextLabel
local banner: TextLabel
local quitButton: TextButton
local prompt: Frame

local COIN = EconomyConfig.Currencies.Coins.Icon
local GEM = EconomyConfig.Currencies.Gems.Icon

local advance = Instance.new("BindableEvent")
local skipAll = false

local function request(action: string, ...)
	local response = StateController.Request(action, ...)
	if response.msg and response.msg ~= "" then
		CurrencyController.Toast(response.msg, if response.ok then UI.Colors.Green else UI.Colors.Red)
	end
	return response.ok
end

local function showBanner(text: string, color: Color3, duration: number)
	banner.Text = text
	banner.TextColor3 = color
	banner.TextTransparency = 0
	banner.TextStrokeTransparency = 0.2
	local scale = banner:FindFirstChildOfClass("UIScale") :: UIScale
	scale.Scale = 1.5
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(duration, function()
		if banner.Text == text then
			TweenService:Create(banner, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

local function rewardText(reward): string
	local parts = { `{UI.formatNumber(reward.Coins)} {COIN}`, `{reward.XP} XP` }
	if reward.Gems then
		table.insert(parts, `{reward.Gems} {GEM}`)
	end
	if reward.Skin then
		local skin = CatalogConfig.Skins[reward.Skin]
		table.insert(parts, `Skin «{if skin then skin.Name else reward.Skin}»`)
	end
	return table.concat(parts, " · ")
end

local function refreshList()
	for _, child in listContent:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local state = StateController.Get()
	local unlocked = if state and state.Story then state.Story.Unlocked else 1
	local completed = if state and state.Story then state.Story.Completed else {}

	for _, chapter in StoryConfig.Chapters do
		local done = completed[tostring(chapter.Id)] == true
		local available = chapter.Id <= unlocked
		local row = UI.make("Frame", { Size = UDim2.new(1, -8, 0, 70), BackgroundColor3 = UI.Colors.Card, LayoutOrder = chapter.Id }, listContent)
		UI.corner(row, 10)
		if available and not done then
			UI.stroke(row, Color3.fromRGB(150, 70, 220), 2)
		end
		UI.label(row, {
			Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -150, 0, 22),
			Text = `Capítulo {chapter.Id} · {chapter.Title}`, TextSize = 16, Font = Enum.Font.GothamBlack,
			TextColor3 = if available then UI.Colors.Text else UI.Colors.Muted,
		})
		UI.label(row, {
			Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -150, 0, 16),
			Text = `{StageConfig.Stages[chapter.Stage].Name} · {#chapter.Waves} oleada(s)`, TextSize = 12, TextColor3 = UI.Colors.Muted,
		})
		UI.label(row, {
			Position = UDim2.fromOffset(12, 46), Size = UDim2.new(1, -150, 0, 16),
			Text = if done then `Completado · repetir da el {math.floor(StoryConfig.ReplayRewardMultiplier * 100)}%` else `{rewardText(chapter.Reward)}`,
			TextSize = 12, TextColor3 = if done then UI.Colors.Green else UI.Colors.Gold,
		})
		local btnProps = { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(120, 38) }
		if available then
			local b = UI.button(row, if done then "Repetir" else "▶ Jugar", if done then UI.Colors.Accent else UI.Colors.Green, btnProps)
			b.Activated:Connect(function()
				listFrame.Visible = false
				request("StartChapter", chapter.Id)
			end)
		else
			UI.button(row, "Bloqueado", UI.Colors.Disabled, btnProps).AutoButtonColor = false
		end
	end
end

function StoryController.Open()
	UI.show(listFrame)
	refreshList()
end

-- Reproduce un diálogo completo. Devuelve cuando el jugador termina o lo salta.
local function playDialogue(lines)
	skipAll = false
	dialogue.Visible = true
	for _, line in lines do
		if skipAll then
			break
		end
		local speaker = StoryConfig.Speakers[line.Speaker] or StoryConfig.Speakers.Narrador
		speakerLabel.Text = speaker.Name
		speakerLabel.TextColor3 = speaker.Color
		portrait.BackgroundColor3 = speaker.Color
		portraitIcon.Text = speaker.Icon
		textLabel.Text = line.Text
		textLabel.MaxVisibleGraphemes = 0
		-- Máquina de escribir (un toque la completa; otro toque avanza)
		local total = utf8.len(line.Text) or #line.Text
		local typing = true
		local conn = advance.Event:Connect(function()
			typing = false
		end)
		for i = 1, total do
			if not typing or skipAll then
				break
			end
			textLabel.MaxVisibleGraphemes = i
			task.wait(0.018)
		end
		conn:Disconnect()
		textLabel.MaxVisibleGraphemes = -1
		if not skipAll then
			advance.Event:Wait()
		end
	end
	dialogue.Visible = false
	request("DialogueDone")
end

local function showPrompt(gems: number)
	for _, c in prompt:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	prompt.Visible = true
	UI.label(prompt, {
		Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 30), Text = "Has caído...",
		TextSize = 24, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center,
	})
	UI.label(prompt, {
		Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 20), Text = "¿Seguir luchando con 3 vidas nuevas?",
		TextSize = 14, TextColor3 = UI.Colors.Muted, TextXAlignment = Enum.TextXAlignment.Center,
	})
	local revive = UI.button(prompt, `Revivir · {gems} {GEM}`, UI.Colors.Gems, {
		Position = UDim2.new(0, 16, 1, -54), Size = UDim2.new(0.5, -22, 0, 40),
	})
	local quit = UI.button(prompt, "Rendirse", UI.Colors.Disabled, {
		Position = UDim2.new(0.5, 6, 1, -54), Size = UDim2.new(0.5, -22, 0, 40),
	})
	revive.Activated:Connect(function()
		if request("StoryRevive", "revive") then
			prompt.Visible = false
		end
	end)
	quit.Activated:Connect(function()
		prompt.Visible = false
		request("StoryRevive", "quit")
	end)
	task.delay(28, function()
		prompt.Visible = false
	end)
end

function StoryController.Start()
	gui = UI.screenGui("Story", 12)

	-- Lista de capítulos
	local content
	listFrame, content = UI.modal(gui, "📖 Crónicas del Sello Maldito", UDim2.fromOffset(620, 460), Color3.fromRGB(150, 70, 220))
	listContent = UI.make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 5, BorderSizePixel = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, content)
	UI.make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, listContent)
	StateController.Changed:Connect(function()
		if listFrame.Visible then
			refreshList()
		end
	end)

	-- Caja de diálogo
	dialogue = UI.make("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(760, 150),
		BackgroundColor3 = UI.Colors.Panel, BackgroundTransparency = 0.05, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 20,
	}, gui)
	UI.corner(dialogue, 14)
	UI.stroke(dialogue, Color3.fromRGB(150, 70, 220), 2)
	UI.autoScale(dialogue)
	portrait = UI.make("Frame", { Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(84, 84), BackgroundColor3 = Color3.new(1, 1, 1) }, dialogue)
	UI.corner(portrait, 42)
	portraitIcon = UI.label(portrait, { Size = UDim2.fromScale(1, 1), TextSize = 44, TextXAlignment = Enum.TextXAlignment.Center })
	speakerLabel = UI.label(dialogue, { Position = UDim2.fromOffset(116, 14), Size = UDim2.new(1, -240, 0, 26), TextSize = 20, Font = Enum.Font.GothamBlack })
	textLabel = UI.label(dialogue, {
		Position = UDim2.fromOffset(116, 44), Size = UDim2.new(1, -132, 1, -60), TextSize = 18, Font = Enum.Font.Gotham,
		TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
	})
	UI.label(dialogue, {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -8), Size = UDim2.fromOffset(200, 18),
		Text = "Clic / toca para continuar ▶", TextSize = 12, TextColor3 = UI.Colors.Muted, TextXAlignment = Enum.TextXAlignment.Right,
	})
	local skip = UI.button(dialogue, "Saltar ", UI.Colors.Disabled, {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(100, 28), TextSize = 13,
	})
	skip.Activated:Connect(function()
		skipAll = true
		advance:Fire()
	end)
	dialogue.Activated:Connect(function()
		advance:Fire()
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if dialogue.Visible and not processed and (input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return) then
			advance:Fire()
		end
	end)

	-- Banner (oleadas / resultados)
	banner = UI.label(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.new(1, 0, 0, 80),
		TextSize = 54, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center,
		TextTransparency = 1, TextStrokeTransparency = 1, ZIndex = 15,
	})
	UI.make("UIScale", {}, banner)

	-- Abandonar capítulo
	quitButton = UI.button(gui, "Abandonar", UI.Colors.Disabled, {
		AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromOffset(16, 110), Size = UDim2.fromOffset(130, 32), TextSize = 13, Visible = false,
	})
	quitButton.Activated:Connect(function()
		request("QuitStory")
	end)
	player:GetAttributeChangedSignal("Activity"):Connect(function()
		quitButton.Visible = player:GetAttribute("Activity") == "Story"
	end)

	-- Revivir
	prompt = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(380, 150),
		BackgroundColor3 = UI.Colors.Panel, Visible = false, ZIndex = 25,
	}, gui)
	UI.corner(prompt, 14)
	UI.stroke(prompt, UI.Colors.Red, 2)

	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MatchFeedback").OnClientEvent:Connect(function(kind, a, b)
		if kind == "Dialogue" then
			local chapter = StoryConfig.Get(a)
			if chapter then
				if b == "Intro" then
					showBanner(`Capítulo {chapter.Id}`, Color3.fromRGB(200, 160, 255), 1.5)
					task.wait(1.2)
				end
				playDialogue(chapter[b] or {})
			else
				request("DialogueDone")
			end
		elseif kind == "Wave" then
			showBanner(if a == b and b > 1 then "¡OLEADA FINAL!" else `Oleada {a}/{b}`, Color3.fromRGB(255, 200, 80), 1.6)
		elseif kind == "StoryDefeat" then
			showPrompt(a)
		elseif kind == "StoryResult" then
			prompt.Visible = false
			if a.Won then
				showBanner("¡CAPÍTULO COMPLETADO!", UI.Colors.Gold, 2.5)
				if a.Gems then
					CurrencyController.Toast(`+{a.Gems} {GEM} (Historia)`, EconomyConfig.Currencies.Gems.Color)
				end
				if a.Skin then
					CurrencyController.Toast("¡Nueva skin desbloqueada!", UI.Colors.Gold)
				end
			else
				showBanner(a.Reason or "DERROTA", UI.Colors.Red, 2.5)
			end
		end
	end)
end

return StoryController
