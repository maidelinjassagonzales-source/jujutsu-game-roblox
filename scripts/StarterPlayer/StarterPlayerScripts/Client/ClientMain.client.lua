-- Punto de entrada del cliente: arranca cada controlador de forma aislada.
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local Controllers = script.Parent:WaitForChild("Controllers")

-- Interfaz por defecto de Roblox que choca con la nuestra:
--   * lista de jugadores, mochila, vida y emotes -> fuera (tapan el HUD y no aportan en un platform fighter)
--   * controles táctiles de Roblox (joystick + botón de salto) -> fuera: usamos los propios de MobileController.
--     Si se dejan, en móvil salen DOS joysticks y dos botones de saltar superpuestos.
for _, coreType in { Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Backpack, Enum.CoreGuiType.Health, Enum.CoreGuiType.EmotesMenu } do
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, coreType, false)
end
pcall(function()
	GuiService.TouchControlsEnabled = false
end)
-- Por si el PlayerModule ya creó su TouchGui antes de que lo desactiváramos
task.spawn(function()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local function hideTouchGui(child)
		if child.Name == "TouchGui" and child:IsA("ScreenGui") then
			child.Enabled = false
		end
	end
	for _, child in playerGui:GetChildren() do
		hideTouchGui(child)
	end
	playerGui.ChildAdded:Connect(hideTouchGui)
end)

local CONTROLLERS = {
	"CameraController", "MovementController", "CombatController", "MobileController", "HUDController",
	"EffectsController", "PoseController", "LightingController",
	"StateController", "CurrencyController", "StoreController", "CharacterShopController", "BattlePassController",
	"StoryController", "PlayMenuController", "LobbyController",
	"GoalController", "MatchUIController", "MenuController", "SoundController", "TitleController", "CinematicController", "RewardsController", "TutorialController", "UltimateController", "StageSelectController", "ObbyController", "RouletteController", "QuestController", "EventController", "CharacterSelectController", "DomainClashController", "ItemController",
}

for _, name in CONTROLLERS do
	local ok, err = pcall(function()
		require(Controllers:WaitForChild(name)).Start()
	end)
	if not ok then
		warn(`[ClientMain] Error al iniciar {name}:`, err)
	end
end

-- Sin botón de reset: en un platform fighter solo se muere por las blast zones.
task.spawn(function()
	for _ = 1, 10 do
		if pcall(StarterGui.SetCore, StarterGui, "ResetButtonCallback", false) then
			break
		end
		task.wait(1)
	end
end)
