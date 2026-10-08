-- PlayMenuController: ventana "Jugar" (Partida rápida · Duelo · Historia · Dojo · Lobby)
-- y aviso de cola ("Buscando partida...").
local Players = game:GetService("Players")

local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local StateController = require(script.Parent:WaitForChild("StateController"))
local CurrencyController = require(script.Parent:WaitForChild("CurrencyController"))

local player = Players.LocalPlayer

local PlayMenuController = {}

local frame: Frame
local queueBanner: Frame
local queueLabel: TextLabel

local MODES = {
	{ Id = "FFA", Icon = "FFA", Title = "Quick match", Desc = "2 to 4 players · free-for-all · 3 lives", Color = Color3.fromRGB(220, 60, 70) },
	{ Id = "Duel", Icon = "Duel", Title = "1v1 Duel", Desc = "One on one · 3 lives · who's the strongest?", Color = Color3.fromRGB(230, 130, 30) },
	{ Id = "Team2", Icon = "Duel", Title = "Teams 2v2", Desc = "Red vs Blue · no friendly fire · bots if players are missing", Color = Color3.fromRGB(200, 50, 120) },
	{ Id = "Team3", Icon = "Duel", Title = "Teams 3v3", Desc = "6-player battle · no friendly fire · bots if players are missing", Color = Color3.fromRGB(120, 60, 210) },
	{ Id = "FFA3", Icon = "FFA", Title = "Free-for-all · 3 players", Desc = "You vs 2 opponents · bots if players are missing", Color = Color3.fromRGB(40, 150, 110) },
	{ Id = "FFA4", Icon = "FFA", Title = "Free-for-all · 4 players", Desc = "You vs 3 opponents · bots if players are missing", Color = Color3.fromRGB(30, 120, 170) },
	{ Id = "Story", Icon = "Story", Title = "Story Mode", Desc = "Chronicles of the Cursed Seal · 8 chapters", Color = Color3.fromRGB(150, 70, 220) },
	{ Id = "Practice", Icon = "Dojo", Title = "Practice Dojo", Desc = "Practice your combos on the dummy", Color = Color3.fromRGB(60, 160, 220) },
	{ Id = "Lobby", Icon = "Lobby", Title = "Back to Lobby", Desc = "The School courtyard: leaderboards, characters, pass and shop", Color = Color3.fromRGB(255, 190, 40) },
}

-- Modos con cola (nombre que sale en el aviso "Buscando...")
local QUEUE_NAMES = {
	FFA = "Quick match", Duel = "1v1 Duel", Team2 = "Teams 2v2", Team3 = "Teams 3v3",
	FFA3 = "Free-for-all · 3", FFA4 = "Free-for-all · 4",
}

local function request(action: string, ...)
	local response = StateController.Request(action, ...)
	if response.msg and response.msg ~= "" then
		CurrencyController.Toast(response.msg, if response.ok then UI.Colors.Green else UI.Colors.Red)
	end
	return response.ok
end

local function choose(modeId: string)
	local activity = player:GetAttribute("Activity")
	if modeId == "Practice" then
		if activity == "Queue" then
			request("LeaveQueue")
		end
		request("GoPractice")
	elseif modeId == "Lobby" then
		if player:GetAttribute("ArenaId") == "Lobby" then
			CurrencyController.Toast("You're already in the Lobby", UI.Colors.Muted)
		else
			request("ReturnToLobby")
		end
	elseif QUEUE_NAMES[modeId] then
		request("JoinQueue", modeId)
	elseif modeId == "Story" then
		frame.Visible = false
		require(script.Parent:WaitForChild("StoryController")).Open()
		return
	end
	frame.Visible = false
end

function PlayMenuController.Toggle()
	UI.toggle(frame)
end

function PlayMenuController.Start()
	local gui = UI.screenGui("PlayMenu", 10)
	local content
	frame, content = UI.modal(gui, "⚔️ Play", UDim2.fromOffset(660, 640), Color3.fromRGB(220, 60, 70))

	-- Tarjetas: arriba partida rápida y duelo, luego equipos, luego todos contra todos,
	-- después historia y dojo, y abajo el Lobby
	local LAYOUT = {
		FFA = { 0, 0, 0.5, 104 }, Duel = { 0.5, 0, 0.5, 104 },
		Team2 = { 0, 110, 0.5, 92 }, Team3 = { 0.5, 110, 0.5, 92 },
		FFA3 = { 0, 208, 0.5, 92 }, FFA4 = { 0.5, 208, 0.5, 92 },
		Story = { 0, 306, 0.5, 92 }, Practice = { 0.5, 306, 0.5, 92 },
		Lobby = { 0, 404, 1, 76 },
	}
	for _, mode in MODES do
		local l = LAYOUT[mode.Id]
		local card = UI.make("TextButton", {
			Position = UDim2.new(l[1], if l[1] > 0 then 4 else 0, 0, l[2]), Size = UDim2.new(l[3], if l[3] < 1 then -4 else 0, 0, l[4]),
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ClipsDescendants = true,
		}, content)
		local bg = UI.card(card, mode.Color, { Size = UDim2.fromScale(1, 1), ZIndex = 0 })
		UI.rays(card, mode.Color:Lerp(Color3.new(1, 1, 1), 0.5), {
			Position = UDim2.new(0, 56, 0.5, 0), Size = UDim2.fromOffset(l[4] * 1.6, l[4] * 1.6), ImageTransparency = 0.45,
		})
		local big = l[4] >= 130
		local iconSize = if big then 92 else 70
		local icon = UI.icon(card, mode.Icon, {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 56, 0.5, 0), Size = UDim2.fromOffset(iconSize, iconSize), ZIndex = 2,
		})
		UI.display(card, {
			Position = UDim2.fromOffset(108, if big then 18 else 14), Size = UDim2.new(1, -150, 0, if big then 34 else 30),
			Text = string.upper(mode.Title), TextSize = if big then 26 else 24, TextScaled = true, ZIndex = 2,
		})
		UI.label(card, {
			Position = UDim2.fromOffset(108, if big then 56 else 46), Size = UDim2.new(1, -150, 0, 40), Text = mode.Desc, TextSize = 14,
			Font = Enum.Font.FredokaOne, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 2,
			TextColor3 = Color3.fromRGB(235, 230, 245), TextStrokeTransparency = 0.6,
		})
		local play = UI.make("ImageLabel", {
			AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -10), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1,
			Image = `rbxassetid://{UI.Icons.PlayArrow}`, ZIndex = 2, ImageTransparency = 0.1,
		}, card)
		local scale = UI.make("UIScale", {}, card)
		card.MouseEnter:Connect(function()
			game:GetService("TweenService"):Create(scale, TweenInfo.new(0.12), { Scale = 1.03 }):Play()
			bg.ImageColor3 = mode.Color:Lerp(Color3.new(1, 1, 1), 0.2)
			icon.Rotation = -6
		end)
		card.MouseLeave:Connect(function()
			game:GetService("TweenService"):Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
			bg.ImageColor3 = mode.Color
			icon.Rotation = 0
		end)
		card.Activated:Connect(function()
			choose(mode.Id)
		end)
	end

	-- Aviso de cola
	queueBanner = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 104), Size = UDim2.fromOffset(380, 40),
		BackgroundColor3 = UI.Colors.Panel, BackgroundTransparency = 0.1, Visible = false,
	}, gui)
	UI.corner(queueBanner, 10)
	UI.stroke(queueBanner, Color3.fromRGB(220, 60, 70), 2)
	UI.autoScale(queueBanner)
	queueLabel = UI.label(queueBanner, { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -120, 1, 0), TextSize = 15 })
	local cancel = UI.button(queueBanner, "Cancel", UI.Colors.Red, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(96, 28), TextSize = 13,
	})
	cancel.Activated:Connect(function()
		request("LeaveQueue")
	end)

	local dots = 0
	task.spawn(function()
		while true do
			task.wait(0.5)
			local queue = player:GetAttribute("Queue")
			queueBanner.Visible = queue ~= nil
			if queue then
				dots = dots % 3 + 1
				queueLabel.Text = `Searching {QUEUE_NAMES[queue] or "match"}{string.rep(".", dots)}`
			end
		end
	end)
end

return PlayMenuController
