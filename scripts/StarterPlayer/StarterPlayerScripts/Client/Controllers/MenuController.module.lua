-- MenuController: botones laterales (Jugar, Personajes, Pase, Tienda) con aviso de recompensas pendientes.
local UserInputService = game:GetService("UserInputService")

local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local CharacterShopController = require(script.Parent:WaitForChild("CharacterShopController"))
local BattlePassController = require(script.Parent:WaitForChild("BattlePassController"))
local PlayMenuController = require(script.Parent:WaitForChild("PlayMenuController"))
local StoreController = require(script.Parent:WaitForChild("StoreController"))

local MenuController = {}

local function menuButton(parent: Instance, order: number, icon: string, text: string, color: Color3)
	return (UI.metalButton(parent, text, color, icon, { Size = UDim2.fromOffset(196, 48), LayoutOrder = order }))
end

function MenuController.Start()
	local gui = UI.screenGui("MainMenu", 4)
	-- Abajo a la izquierda: arriba a la izquierda está la ventana del chat de Roblox
	local column = UI.make("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -84), Size = UDim2.fromOffset(200, 460),
		BackgroundTransparency = 1,
	}, gui)
	UI.make("UIListLayout", {
		Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom,
	}, column)
	UI.autoScale(column)
	-- En móvil abajo a la izquierda va el joystick: el menú sube arriba (el chat allí está plegado)
	if UserInputService.TouchEnabled then
		column.AnchorPoint = Vector2.new(0, 0)
		column.Position = UDim2.fromOffset(16, 12) -- ya va por debajo de la barra de Roblox (zona segura)
		column:FindFirstChildOfClass("UIListLayout").VerticalAlignment = Enum.VerticalAlignment.Top
	end

	-- En las arenas el menú se esconde (ahí mandan las teclas y el rombo de habilidades)
	task.spawn(function()
		local player = game:GetService("Players").LocalPlayer
		while true do
			task.wait(0.3)
			local character = player.Character
			local arena = character and character:GetAttribute("ArenaId")
			column.Visible = arena == nil or arena == "Lobby"
		end
	end)

	menuButton(column, 1, "Play", "Jugar", Color3.fromRGB(220, 60, 70)).Activated:Connect(PlayMenuController.Toggle)
	menuButton(column, 2, "Characters", "Personajes", UI.Colors.Accent).Activated:Connect(CharacterShopController.Toggle)

	local passButton = menuButton(column, 3, "Pass", "Pase", Color3.fromRGB(255, 190, 40))
	passButton.Activated:Connect(BattlePassController.Toggle)
	-- Punto rojo con el nº de recompensas sin reclamar (efecto "pendiente")
	local badge = UI.label(passButton, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 0, BackgroundColor3 = UI.Colors.Red, Text = "", TextSize = 12, Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center, Visible = false, ZIndex = 3,
	})
	UI.corner(badge, 12)
	BattlePassController.ClaimableChanged:Connect(function(count)
		badge.Visible = count > 0
		badge.Text = if count > 9 then "9+" else tostring(count)
	end)

	menuButton(column, 4, "Store", "Tienda", Color3.fromRGB(90, 220, 255)).Activated:Connect(StoreController.Toggle)
	-- Ruleta Maldita (con aviso cuando tienes la tirada gratis del día)
	local rouletteButton = menuButton(column, 5, "Chest", "Ruleta", Color3.fromRGB(255, 50, 90))
	rouletteButton.Activated:Connect(function()
		require(script.Parent:WaitForChild("RouletteController")).Toggle()
	end)
	local freeBadge = UI.label(rouletteButton, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -10, 0, 4), Size = UDim2.fromOffset(58, 22),
		BackgroundTransparency = 0, BackgroundColor3 = UI.Colors.Green, Text = "¡GRATIS!", TextSize = 11, Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center, Visible = false, ZIndex = 3,
	})
	UI.corner(freeBadge, 11)
	local StateController = require(script.Parent:WaitForChild("StateController"))
	local function refreshBadge()
		local st = StateController.Get()
		local r = st and st.Roulette
		local todayDay = math.floor(StateController.Now() / 86400)
		freeBadge.Visible = st ~= nil and (not r or r.Day ~= todayDay or not r.FreeUsed)
	end
	StateController.Changed:Connect(refreshBadge)
	task.spawn(function()
		while true do
			refreshBadge()
			task.wait(30)
		end
	end)

	-- Misiones diarias (con el nº de misiones para cobrar)
	local questButton = menuButton(column, 6, "Codes", "Misiones", Color3.fromRGB(80, 230, 130))
	local QuestController = require(script.Parent:WaitForChild("QuestController"))
	questButton.Activated:Connect(QuestController.Toggle)
	local questBadge = UI.label(questButton, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 0, BackgroundColor3 = UI.Colors.Red, Text = "", TextSize = 12, Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center, Visible = false, ZIndex = 3,
	})
	UI.corner(questBadge, 12)
	QuestController.ClaimableChanged:Connect(function(count)
		questBadge.Visible = count > 0
		questBadge.Text = tostring(count)
	end)

	-- El tutorial es opcional: se puede empezar (o repetir) cuando quieras desde aquí
	menuButton(column, 7, "Story", "Tutorial", Color3.fromRGB(120, 230, 150)).Activated:Connect(function()
		require(script.Parent:WaitForChild("TutorialController")).Restart()
	end)

	-- Mando: la cruceta abre los menús (arriba Jugar · izquierda Personajes · derecha Tienda · abajo Pase)
	local DPAD = {
		[Enum.KeyCode.DPadUp] = PlayMenuController.Toggle,
		[Enum.KeyCode.DPadLeft] = CharacterShopController.Toggle,
		[Enum.KeyCode.DPadRight] = StoreController.Toggle,
		[Enum.KeyCode.DPadDown] = BattlePassController.Toggle,
	}
	game:GetService("ContextActionService"):BindAction("GamepadMenus", function(_, state, input)
		local character = game:GetService("Players").LocalPlayer.Character
		local inLobby = character == nil or character:GetAttribute("ArenaId") == "Lobby"
		if state == Enum.UserInputState.Begin and DPAD[input.KeyCode] and inLobby then
			DPAD[input.KeyCode]()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight, Enum.KeyCode.DPadDown)
end

return MenuController
