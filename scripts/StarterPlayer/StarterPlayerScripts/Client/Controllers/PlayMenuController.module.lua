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
	{ Id = "FFA", Icon = "FFA", Title = "Partida rápida", Desc = "2 a 4 jugadores · todos contra todos · 3 vidas", Color = Color3.fromRGB(220, 60, 70) },
	{ Id = "Duel", Icon = "Duel", Title = "Duelo 1v1", Desc = "Uno contra uno · 3 vidas · ¿quién es el más fuerte?", Color = Color3.fromRGB(230, 130, 30) },
	{ Id = "Story", Icon = "Story", Title = "Modo Historia", Desc = "Crónicas del Sello Maldito · 8 capítulos", Color = Color3.fromRGB(150, 70, 220) },
	{ Id = "Practice", Icon = "Dojo", Title = "Dojo de práctica", Desc = "Entrena tus combos contra el muñeco", Color = Color3.fromRGB(60, 160, 220) },
	{ Id = "Lobby", Icon = "Lobby", Title = "Volver al Lobby", Desc = "El patio de la Escuela: tablas, personajes, pase y tienda", Color = Color3.fromRGB(255, 190, 40) },
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
			CurrencyController.Toast("Ya estás en el Lobby", UI.Colors.Muted)
		else
			request("ReturnToLobby")
		end
	elseif modeId == "FFA" or modeId == "Duel" then
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
	frame, content = UI.modal(gui, "⚔️ Jugar", UDim2.fromOffset(540, 470), Color3.fromRGB(220, 60, 70))
	UI.make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, content)

	for i, mode in MODES do
		local card = UI.make("TextButton", {
			Size = UDim2.new(1, -8, 0, 64), BackgroundColor3 = Color3.new(1, 1, 1), Text = "", AutoButtonColor = false, LayoutOrder = i,
		}, content)
		UI.corner(card, 12)
		UI.gradient(card, mode.Color:Lerp(Color3.fromRGB(20, 18, 30), 0.6), Color3.fromRGB(22, 20, 34), 0)
		UI.stroke(card, mode.Color, 2)
		UI.bounce(card, 1.03)
		UI.icon(card, mode.Icon, { Position = UDim2.fromOffset(4, 2), Size = UDim2.fromOffset(60, 60) })
		UI.label(card, { Position = UDim2.fromOffset(70, 6), Size = UDim2.new(1, -110, 0, 28), Text = mode.Title, TextSize = 22, Font = UI.TitleFont, TextStrokeTransparency = 0.5 })
		UI.label(card, {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(20, 30), Text = ">",
			TextSize = 24, Font = Enum.Font.GothamBlack, TextColor3 = mode.Color, TextXAlignment = Enum.TextXAlignment.Center,
		})
		UI.label(card, { Position = UDim2.fromOffset(70, 34), Size = UDim2.new(1, -110, 0, 20), Text = mode.Desc, TextSize = 13, TextColor3 = UI.Colors.Muted })
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
	local cancel = UI.button(queueBanner, "Cancelar", UI.Colors.Red, {
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
				queueLabel.Text = `Buscando {if queue == "Duel" then "Duelo 1v1" else "Partida rápida"}{string.rep(".", dots)}`
			end
		end
	end)
end

return PlayMenuController
