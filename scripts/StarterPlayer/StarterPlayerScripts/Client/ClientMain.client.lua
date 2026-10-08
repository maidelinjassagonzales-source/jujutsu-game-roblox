-- Punto de entrada del cliente: arranca cada controlador de forma aislada.
local StarterGui = game:GetService("StarterGui")

local Controllers = script.Parent:WaitForChild("Controllers")

-- La lista de jugadores tapa el panel de economía y no aporta en un platform fighter
pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.PlayerList, false)

local CONTROLLERS = {
	"CameraController", "MovementController", "CombatController", "MobileController", "HUDController",
	"EffectsController", "PoseController", "LightingController",
	"StateController", "CurrencyController", "StoreController", "CharacterShopController", "BattlePassController",
	"StoryController", "PlayMenuController", "LobbyController",
	"GoalController", "MatchUIController", "MenuController", "SoundController", "TitleController", "CinematicController", "RewardsController", "TutorialController", "UltimateController",
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
