-- CinematicController: cinemáticas con cámara, franjas de cine y títulos.
--   * Intro al entrar: vuelo sobre Tokio y el Velo -> la Escuela -> el patio -> tu personaje (saltable)
--   * Presentación VS antes de cada partida (retratos de los luchadores + barrido del escenario)
--   * "¡GAME!" al terminar la partida: zoom al ganador con destello
--   * Modo Historia: paneo lento del escenario durante el diálogo inicial
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))
local ArenaInfo = require(Shared:WaitForChild("ArenaInfo"))
local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local Portrait = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Portrait"))
local Sfx = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Sfx"))
local CameraController = require(script.Parent:WaitForChild("CameraController"))

local player = Players.LocalPlayer

local CinematicController = {}

local GAME_TITLE = "JUJUTSU SMASH"
local GAME_SUBTITLE = "Arena de hechiceros"

local gui: ScreenGui
local topBar: Frame
local bottomBar: Frame
local titleLabel: TextLabel
local subtitleLabel: TextLabel
local skipButton: TextButton
local flashFrame: Frame
local vsFrame: Frame

local playingToken = nil
local hiddenGuis = {}

local function ease(t: number): number
	return t * t * (3 - 2 * t) -- smoothstep
end

-- ===== Interfaz de cine
local function setBars(on: boolean)
	local info = TweenInfo.new(0.45, Enum.EasingStyle.Quad)
	TweenService:Create(topBar, info, { Size = UDim2.new(1, 0, if on then 0.11 else 0, 0) }):Play()
	TweenService:Create(bottomBar, info, { Size = UDim2.new(1, 0, if on then 0.11 else 0, 0) }):Play()
end

-- Oculta el resto de la interfaz durante la cinemática (y la devuelve al acabar)
local function hideOtherGuis(hide: boolean)
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return
	end
	if hide then
		for _, g in playerGui:GetChildren() do
			if g:IsA("ScreenGui") and g ~= gui and g.Enabled and g.Name ~= "MatchUI" and g.Name ~= "StoryUI" then
				g.Enabled = false
				table.insert(hiddenGuis, g)
			end
		end
	else
		for _, g in hiddenGuis do
			if g.Parent then
				g.Enabled = true
			end
		end
		table.clear(hiddenGuis)
	end
end

local function showTitle(title: string, subtitle: string?, color: Color3?)
	titleLabel.Text = title
	titleLabel.TextColor3 = color or Color3.new(1, 1, 1)
	subtitleLabel.Text = subtitle or ""
	for _, l in { titleLabel, subtitleLabel } do
		l.TextTransparency = 1
		l.TextStrokeTransparency = 1
		TweenService:Create(l, TweenInfo.new(0.6), { TextTransparency = 0, TextStrokeTransparency = 0.3 }):Play()
	end
	local scale = titleLabel:FindFirstChildOfClass("UIScale") :: UIScale
	scale.Scale = 1.25
	TweenService:Create(scale, TweenInfo.new(1.6, Enum.EasingStyle.Quart), { Scale = 1 }):Play()
end

local function hideTitle()
	for _, l in { titleLabel, subtitleLabel } do
		TweenService:Create(l, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end
end

local function flashWhite(strength: number?)
	flashFrame.BackgroundTransparency = 1 - (strength or 0.8)
	TweenService:Create(flashFrame, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
end

-- ===== Reproductor de planos
-- shots = { { From = CFrame, To = CFrame, Time = s, Fov = n?, Title = {t, sub, color}? }, ... }
function CinematicController.Play(shots, options)
	options = options or {}
	local token = {}
	playingToken = token
	local camera = workspace.CurrentCamera
	local baseFov = 70
	setBars(true)
	if options.HideUI then
		hideOtherGuis(true)
	end
	skipButton.Visible = options.Skippable == true

	local index, elapsed = 1, 0
	local finished = false
	CameraController.SetOverride(function(dt)
		if playingToken ~= token then
			return nil
		end
		local shot = shots[index]
		if not shot then
			return nil
		end
		elapsed += dt
		local alpha = math.clamp(elapsed / shot.Time, 0, 1)
		local from = if typeof(shot.From) == "function" then shot.From() else shot.From
		local to = if typeof(shot.To) == "function" then shot.To() else shot.To
		camera.FieldOfView = baseFov + ((shot.Fov or 0) * (1 - ease(alpha)))
		local cf = from:Lerp(to, ease(alpha))
		if alpha >= 1 then
			index += 1
			elapsed = 0
			local nextShot = shots[index]
			if nextShot and nextShot.Title then
				showTitle(table.unpack(nextShot.Title))
			end
		end
		return cf
	end)
	if shots[1] and shots[1].Title then
		showTitle(table.unpack(shots[1].Title))
	end

	local total = 0
	for _, shot in shots do
		total += shot.Time
	end
	task.spawn(function()
		local deadline = os.clock() + total
		while os.clock() < deadline and playingToken == token do
			task.wait(0.05)
		end
		if playingToken == token then
			CinematicController.Stop()
		end
		finished = true
	end)
	return function()
		return finished
	end
end

function CinematicController.Stop()
	playingToken = nil
	CameraController.SetOverride(nil)
	workspace.CurrentCamera.FieldOfView = 70
	setBars(false)
	hideTitle()
	skipButton.Visible = false
	hideOtherGuis(false)
end

-- ===== 1) Intro al entrar al juego
local function lobbyOrigin(): Vector3?
	local lobby = workspace:FindFirstChild("Lobby")
	return lobby and lobby:GetPivot().Position
end

local function playIntro()
	local origin = lobbyOrigin()
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not origin or not hrp then
		return
	end
	local function o(x, y, z)
		return origin + Vector3.new(x, y, z)
	end
	local playerView = function()
		local root = (player.Character and player.Character:FindFirstChild("HumanoidRootPart")) :: BasePart?
		local p = if root then root.Position else o(0, 4, 64)
		return CFrame.lookAt(p + Vector3.new(0, 9, 24), p + Vector3.new(0, 2, 0))
	end
	Sfx.Play("Domain", nil, 0.5)
	CinematicController.Play({
		{ From = CFrame.lookAt(o(-60, 150, -260), o(-260, 40, -560)), To = CFrame.lookAt(o(80, 110, -220), o(-200, 60, -560)), Time = 3.6, Fov = -10,
			Title = { "東京 · TOKIO", "El Velo ha caído sobre la ciudad...", Color3.fromRGB(200, 160, 255) } },
		{ From = CFrame.lookAt(o(0, 70, -40), o(0, 30, -128)), To = CFrame.lookAt(o(0, 22, -60), o(0, 18, -128)), Time = 3,
			Title = { GAME_TITLE, GAME_SUBTITLE, Color3.fromRGB(255, 215, 120) } },
		{ From = CFrame.lookAt(o(60, 48, 20), o(0, 6, 0)), To = CFrame.lookAt(o(-40, 34, 30), o(0, 6, 0)), Time = 3,
			Title = { "呪術高専", "Escuela de Hechicería", Color3.fromRGB(255, 190, 210) } },
		{ From = CFrame.lookAt(o(0, 30, 110), o(0, 4, 60)), To = playerView, Time = 2 },
	}, { Skippable = true, HideUI = true })
end

-- ===== 2) Presentación VS antes de la partida
local function showVersus(roster, stageName: string?, modeName: string?)
	for _, child in vsFrame:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	vsFrame.Visible = true
	local count = #roster
	local stage = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(900, 420),
		BackgroundTransparency = 1,
	}, vsFrame)
	UI.autoScale(stage, 520)
	UI.label(stage, {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(1, 0, 0, 40),
		Text = `{modeName or ""} · {stageName or ""}`, TextSize = 26, Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = UI.Colors.Gold, TextStrokeTransparency = 0.3,
	})
	local cardW = math.min(210, 860 / math.max(count, 1) - 20)
	local totalW = count * cardW + (count - 1) * 30
	for i, entry in roster do
		local data = CharacterRegistry.Get(entry.CharacterId)
		local accent = if data then data.Color else UI.Colors.Accent
		local x = 450 - totalW / 2 + (i - 1) * (cardW + 30)
		local fromLeft = i <= count / 2
		local card = UI.make("Frame", {
			Position = UDim2.fromOffset(x + (if fromLeft then -600 else 600), 60), Size = UDim2.fromOffset(cardW, 320),
			BackgroundColor3 = UI.Colors.Panel, BackgroundTransparency = 0.15,
		}, stage)
		UI.corner(card, 14)
		UI.stroke(card, accent, 3)
		UI.make("UIGradient", { Rotation = 90, Color = ColorSequence.new(accent:Lerp(Color3.new(0, 0, 0), 0.5), Color3.fromRGB(10, 8, 18)) }, card)
		Portrait.Create(card, entry.CharacterId, "Full", { Size = UDim2.new(1, 0, 0, 230), Position = UDim2.fromOffset(0, 6) })
		-- Su avatar de Roblox en la esquina: el jugador Y su luchador
		UI.avatar(card, entry.UserId, { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(64, 64), ZIndex = 6 })
		UI.label(card, {
			Position = UDim2.fromOffset(8, 236), Size = UDim2.new(1, -16, 0, 34), Text = entry.Name, TextSize = 22,
			Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextScaled = true,
		})
		UI.label(card, {
			Position = UDim2.fromOffset(8, 272), Size = UDim2.new(1, -16, 0, 26), Text = if data then data.DisplayName else "",
			TextSize = 16, TextColor3 = accent, TextXAlignment = Enum.TextXAlignment.Center, TextScaled = true,
		})
		TweenService:Create(card, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.08 * i), {
			Position = UDim2.fromOffset(x, 60),
		}):Play()
		if i < count then
			local vs = UI.label(stage, {
				Position = UDim2.fromOffset(x + cardW - 10, 170), Size = UDim2.fromOffset(50, 60), Text = "VS", TextSize = 46,
				Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(255, 70, 80), TextXAlignment = Enum.TextXAlignment.Center,
				TextStrokeTransparency = 0, ZIndex = 5, TextTransparency = 1,
			})
			TweenService:Create(vs, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.5), { TextTransparency = 0 }):Play()
		end
	end
	Sfx.Play("Special", nil, 0.8, 0.8)
	task.delay(2.6, function()
		TweenService:Create(stage, TweenInfo.new(0.3), { Position = UDim2.new(0.5, 0, -0.6, 0) }):Play()
		task.wait(0.35)
		vsFrame.Visible = false
	end)
end

local function arenaSweep(arenaId: string, duration: number)
	local info = ArenaInfo.Get(arenaId)
	local cx = if info then info:GetAttribute("CenterX") or 0 else 0
	local c = Vector3.new(cx, 8, 0)
	CinematicController.Play({
		{ From = CFrame.lookAt(c + Vector3.new(-140, 70, 150), c), To = CFrame.lookAt(c + Vector3.new(60, 30, 90), c + Vector3.new(0, 4, 0)), Time = duration, Fov = -15 },
	})
end

-- ===== 3) ¡GAME!
local function playFinish(winner: Model?)
	local root = winner and winner:FindFirstChild("HumanoidRootPart") :: BasePart?
	flashWhite(0.85)
	CameraController.Shake(1.5, 0.35)
	Sfx.Play("KO", nil, 1, 0.8)
	local camera = workspace.CurrentCamera
	local start = camera.CFrame
	local shots = {}
	if root then
		local target = function()
			local p = root.Position
			return CFrame.lookAt(p + Vector3.new(0, 5, 16), p + Vector3.new(0, 1.5, 0))
		end
		table.insert(shots, { From = start, To = target, Time = 1.2, Fov = 10, Title = { "¡GAME!", nil, Color3.fromRGB(255, 220, 90) } })
		table.insert(shots, { From = target, To = target, Time = 1.3 })
	else
		table.insert(shots, { From = start, To = start, Time = 2.5, Title = { "¡GAME!", nil, Color3.fromRGB(255, 220, 90) } })
	end
	CinematicController.Play(shots)
end

function CinematicController.Start()
	gui = UI.screenGui("Cinematic", 40, true)
	gui.IgnoreGuiInset = true
	topBar = UI.make("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 2 }, gui)
	bottomBar = UI.make("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 2,
	}, gui)
	flashFrame = UI.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 10 }, gui)
	titleLabel = UI.label(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.new(0.9, 0, 0.14, 0),
		Text = "", TextScaled = true, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center,
		TextTransparency = 1, TextStrokeTransparency = 1, ZIndex = 3,
	})
	UI.make("UIScale", {}, titleLabel)
	UI.make("UITextSizeConstraint", { MaxTextSize = 96 }, titleLabel)
	subtitleLabel = UI.label(gui, {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.8, 0, 0.05, 0),
		Text = "", TextScaled = true, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center,
		TextTransparency = 1, TextStrokeTransparency = 1, ZIndex = 3,
	})
	UI.make("UITextSizeConstraint", { MaxTextSize = 34 }, subtitleLabel)
	skipButton = UI.button(gui, "Saltar ", UI.Colors.Panel, {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(120, 36), Visible = false, ZIndex = 4,
	})
	skipButton.Activated:Connect(CinematicController.Stop)
	vsFrame = UI.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 6 }, gui)

	-- Intro: una vez por sesión, al aparecer por primera vez en el Lobby
	task.spawn(function()
		-- Primero la pantalla de título; la intro solo si se eligió "Comenzar"
		local titleDeadline = os.clock() + 300
		while not player:GetAttribute("TitleDone") and os.clock() < titleDeadline do
			task.wait(0.2)
		end
		if not player:GetAttribute("TitleStart") then
			return
		end
		local deadline = os.clock() + 30
		while os.clock() < deadline do
			local character = player.Character
			if character and character:GetAttribute("ArenaId") == "Lobby" and character:FindFirstChild("HumanoidRootPart")
				and workspace:FindFirstChild("Lobby") then
				task.wait(0.8)
				playIntro()
				return
			end
			task.wait(0.3)
		end
	end)

	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MatchFeedback").OnClientEvent:Connect(function(kind, a, b, c, d)
		if kind == "Countdown" and type(d) == "table" then
			-- a = segundos, b = escenario, c = modo, d = participantes
			showVersus(d, b, c)
			local character = player.Character
			arenaSweep(character and character:GetAttribute("ArenaId") or "", math.max(2, (a or 5) - 1.2))
		elseif kind == "Finish" then
			playFinish(if typeof(a) == "Instance" then a else nil)
		elseif kind == "Dialogue" and b == "Intro" then
			local character = player.Character
			arenaSweep(character and character:GetAttribute("ArenaId") or "", 6)
		elseif kind == "Results" then
			CinematicController.Stop()
		end
	end)

	-- Atajo de teclado para saltar
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and skipButton.Visible and input.KeyCode == Enum.KeyCode.Return then
			CinematicController.Stop()
		end
	end)
end

return CinematicController
