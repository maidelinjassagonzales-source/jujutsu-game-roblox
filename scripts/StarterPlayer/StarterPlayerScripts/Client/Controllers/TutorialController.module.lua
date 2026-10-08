-- TutorialController: tutorial guiado la primera vez que entras (o desde Ajustes > "Repetir tutorial").
--   * Cartel de misión arriba en el centro (estilo Jujutsu Zero) con el paso actual y la distancia
--   * Flecha 3D botando sobre el destino + rastro brillante en el suelo desde tu personaje
--   * Flecha en pantalla señalando el botón cuando el paso es de interfaz
-- Al terminar, el servidor da la recompensa (una sola vez).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local Sfx = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Sfx"))
local StateController = require(script.Parent:WaitForChild("StateController"))
local CurrencyController = require(script.Parent:WaitForChild("CurrencyController"))

local player = Players.LocalPlayer

local TutorialController = {}

local function lobbyPos(x: number, y: number, z: number): Vector3?
	local lobby = workspace:FindFirstChild("Lobby")
	return lobby and (lobby:GetPivot().Position + Vector3.new(x, y, z))
end

local function myRoot(): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local usedSpecial = false

-- Cada paso: Text, Target (posición 3D o nil), Button (nombre del botón del menú) y Done() -> bool
local STEPS = {
	{
		Text = "Reclama tu primer [premio diario]", Button = "Premios",
		Done = function()
			local st = StateController.Get()
			local login = st and st.Login
			return login ~= nil and login.LastDay == math.floor(StateController.Now() / 86400)
		end,
	},
	{
		Text = "Visita la [Sala de Personajes] dentro de la Escuela",
		Target = function()
			return lobbyPos(0, 0, -112)
		end,
		Done = function()
			local root, target = myRoot(), lobbyPos(0, 0, -118)
			return root ~= nil and target ~= nil and (root.Position - target).Magnitude < 16
		end,
	},
	{
		Text = "Entra al [Dojo de práctica]: pulsa E en el portal azul",
		Target = function()
			return lobbyPos(114, 0, 20)
		end,
		Done = function()
			return player:GetAttribute("ArenaId") == "Hub"
		end,
	},
	{
		Text = "Golpea al muñeco hasta el [30%]  (Clic / J · Clic derecho / K)",
		Target = function()
			local dummy = workspace:FindFirstChild("TrainingDummy")
			local root = dummy and dummy:FindFirstChild("HumanoidRootPart") :: BasePart?
			return root and root.Position - Vector3.new(0, 3, 0)
		end,
		Done = function()
			local dummy = workspace:FindFirstChild("TrainingDummy")
			return dummy ~= nil and (dummy:GetAttribute("Percent") or 0) >= 30
		end,
	},
	{
		Text = "Usa una [técnica especial]  (E / L)",
		Done = function()
			return usedSpecial
		end,
	},
	{
		Text = "¡Bien! Vuelve al [Lobby]", Button = "LobbyReturn",
		Done = function()
			return player:GetAttribute("ArenaId") == "Lobby"
		end,
	},
	{
		Text = "Busca rivales: pisa el círculo de [Partida Rápida]",
		Target = function()
			return lobbyPos(100, 0, -40)
		end,
		Done = function()
			local a = player:GetAttribute("Activity")
			return a == "Queue" or a == "Match"
		end,
	},
}

local banner: Frame
local bannerText: TextLabel
local bannerStep: TextLabel
local distanceLabel: TextLabel
local uiArrow: TextLabel
local arrow3D: BasePart
local beam: Beam
local att0: Attachment
local att1: Attachment
local active = false

-- "[texto]" se pinta en dorado (RichText)
local function rich(text: string): string
	return (text:gsub("%[(.-)%]", '<font color="#FFD25A">[%1]</font>'))
end

local function findButton(name: string): GuiObject?
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return nil
	end
	if name == "LobbyReturn" then
		local hud = pg:FindFirstChild("LobbyHUD")
		for _, d in (hud and hud:GetDescendants() or {}) do
			if d:IsA("TextButton") and d.Text:find("Lobby") then
				return d
			end
		end
		return nil
	end
	local menu = pg:FindFirstChild("MainMenu")
	for _, d in (menu and menu:GetDescendants() or {}) do
		if d:IsA("TextLabel") and string.upper(d.Text) == string.upper(name) then
			return d.Parent :: GuiObject
		end
	end
	return nil
end

local function build()
	local gui = UI.screenGui("Tutorial", 30)
	banner = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 150), Size = UDim2.fromOffset(620, 58),
		BackgroundColor3 = Color3.fromRGB(14, 12, 22), BackgroundTransparency = 0.15, Visible = false,
	}, gui)
	UI.autoScale(banner)
	UI.stroke(banner, Color3.fromRGB(150, 140, 170), 1.5)
	UI.make("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(60, 50, 80), Color3.fromRGB(14, 12, 22)), Rotation = 90 }, banner)
	bannerStep = UI.label(banner, {
		Position = UDim2.fromOffset(0, 2), Size = UDim2.new(1, 0, 0, 16), TextSize = 12, TextColor3 = Color3.fromRGB(190, 180, 210),
		TextXAlignment = Enum.TextXAlignment.Center, Text = "",
	})
	bannerText = UI.label(banner, {
		Position = UDim2.fromOffset(10, 18), Size = UDim2.new(1, -20, 0, 26), TextSize = 21, Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center, RichText = true, Text = "",
	})
	distanceLabel = UI.label(banner, {
		Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 0, 14), TextSize = 11, TextColor3 = Color3.fromRGB(255, 210, 90),
		TextXAlignment = Enum.TextXAlignment.Center, Text = "",
	})
	uiArrow = UI.label(gui, {
		AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(44, 44), Text = "◀", TextSize = 40, Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.fromRGB(255, 210, 90), TextStrokeTransparency = 0, Visible = false, ZIndex = 50,
	})

	-- Flecha 3D (solo existe en tu cliente)
	arrow3D = Instance.new("Part")
	arrow3D.Name = "TutorialArrow"
	arrow3D.Shape = Enum.PartType.Cylinder
	arrow3D.Size = Vector3.new(0.4, 5, 5)
	arrow3D.Transparency = 1
	arrow3D.Anchored = true
	arrow3D.CanCollide = false
	arrow3D.CanQuery = false
	arrow3D.CanTouch = false
	local chevron = Instance.new("BillboardGui")
	chevron.Size = UDim2.fromScale(6, 6)
	chevron.AlwaysOnTop = true
	chevron.LightInfluence = 0
	chevron.Parent = arrow3D
	local glyph = Instance.new("TextLabel")
	glyph.Size = UDim2.fromScale(1, 1)
	glyph.BackgroundTransparency = 1
	glyph.Text = "▼"
	glyph.TextScaled = true
	glyph.Font = Enum.Font.GothamBlack
	glyph.TextColor3 = Color3.fromRGB(255, 210, 90)
	glyph.TextStrokeTransparency = 0
	glyph.Parent = chevron
	att1 = Instance.new("Attachment")
	att1.Parent = arrow3D

	beam = Instance.new("Beam")
	beam.Attachment1 = att1
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 210, 90), Color3.fromRGB(255, 120, 60))
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Width0 = 1.8
	beam.Width1 = 1.8
	beam.FaceCamera = true
	beam.Segments = 20
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(0.15, 0.25), NumberSequenceKeypoint.new(1, 0.1) })
	beam.Parent = arrow3D
end

local function hideGuides()
	arrow3D.Parent = nil
	uiArrow.Visible = false
	distanceLabel.Text = ""
end

local function modalOpen(): boolean
	local pg = player:FindFirstChildOfClass("PlayerGui")
	for _, g in (pg and pg:GetChildren() or {}) do
		if g:IsA("ScreenGui") and g.Enabled and g.DisplayOrder == 10 then
			for _, f in g:GetChildren() do
				if f:IsA("Frame") and f.Visible and f.ZIndex == 10 then
					return true
				end
			end
		end
	end
	return false
end

local function run(fromStep: number)
	if active then
		return
	end
	active = true
	usedSpecial = false
	banner.Visible = true
	local t0 = os.clock()
	for i = fromStep, #STEPS do
		local step = STEPS[i]
		bannerStep.Text = `TUTORIAL · PASO {i}/{#STEPS}`
		bannerText.Text = rich(step.Text)
		local scale = banner:FindFirstChildOfClass("UIScale")
		banner.Position = UDim2.new(0.5, 0, 0, 124)
		TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0, 150) }):Play()
		while not step.Done() do
			local root = myRoot()
			local target = step.Target and step.Target()
			if target and root then
				local bob = math.sin((os.clock() - t0) * 4) * 0.8
				arrow3D.CFrame = CFrame.new(target + Vector3.new(0, 8 + bob, 0))
				arrow3D.Parent = workspace
				local a = root:FindFirstChild("TutorialAttachment") or Instance.new("Attachment")
				a.Name = "TutorialAttachment"
				a.Position = Vector3.new(0, -2.6, 0)
				a.Parent = root
				beam.Attachment0 = a
				att1.WorldPosition = target + Vector3.new(0, 0.6, 0)
				distanceLabel.Text = `{math.floor((root.Position - target).Magnitude)} m`
			else
				arrow3D.Parent = nil
				distanceLabel.Text = ""
			end
			local button = step.Button and findButton(step.Button)
			if button and button.Visible then
				local p, s = button.AbsolutePosition, button.AbsoluteSize
				uiArrow.Position = UDim2.fromOffset(p.X + s.X + 8 + math.sin(os.clock() * 6) * 6, p.Y + s.Y / 2 + 40)
				uiArrow.Visible = true
			else
				uiArrow.Visible = false
			end
			task.wait()
		end
		hideGuides()
		Sfx.Play("LevelUp", nil, 0.7)
		bannerText.Text = rich("¡Completado!  [" .. step.Text:gsub("[%[%]]", "") .. "]")
		task.wait(1.1)
	end
	banner.Visible = false
	active = false
	local response = StateController.Request("CompleteTutorial")
	if response.msg and response.msg ~= "" then
		CurrencyController.Toast(response.msg, if response.ok then UI.Colors.Gold else UI.Colors.Muted)
	end
end

function TutorialController.Start()
	build()
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CombatFeedback").OnClientEvent:Connect(function(kind, model, key)
		if kind == "MoveStarted" and model == player.Character and typeof(key) == "string" and key:find("Special") then
			usedSpecial = true
		end
	end)
	-- Solo la primera vez (lo dice el servidor) y después de la intro
	task.spawn(function()
		local deadline = os.clock() + 30
		while not StateController.Get() and os.clock() < deadline do
			task.wait(0.5)
		end
		local st = StateController.Get()
		if st and not (st.Tutorial and st.Tutorial.Done) then
			while not player:GetAttribute("TitleDone") do
				task.wait(0.3)
			end
			task.wait(if player:GetAttribute("TitleStart") then 12 else 3)
			run(1)
		end
	end)
end

function TutorialController.Restart()
	task.spawn(run, 1)
end

return TutorialController
