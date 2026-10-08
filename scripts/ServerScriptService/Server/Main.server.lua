-- Punto de entrada del servidor: crea los Remotes y arranca los servicios en orden.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- LO PRIMERO: que Roblox no cargue el avatar por su cuenta (sería R15 y pisaría al R6).
Players.CharacterAutoLoads = false

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CombatConfig"))

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local function ensureRemote(className: string, name: string)
	local remote = remotes:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = remotes
	end
	return remote
end

for _, name in { "CombatRequest", "CombatFeedback", "EconomyFeedback", "MatchFeedback" } do
	ensureRemote("RemoteEvent", name)
end
local shopRequest = ensureRemote("RemoteFunction", "ShopRequest")

workspace.Gravity = Config.Gravity
-- Nota: Workspace.FallenPartsDestroyHeight (-2000) lo fija el instalador; no se puede cambiar en runtime.

local Services = script.Parent:WaitForChild("Services")
local function load(name: string)
	return require(Services:WaitForChild(name))
end

local services = {
	DataService = load("DataService"),
	ArenaService = load("ArenaService"),
	EconomyService = load("EconomyService"),
	FighterService = load("FighterService"),
	CombatService = load("CombatService"),
	KOService = load("KOService"),
	MatchService = load("MatchService"),
	StoryService = load("StoryService"),
	NPCService = load("NPCService"),
	UnlockService = load("UnlockService"),
	BoosterService = load("BoosterService"),
	StoreService = load("StoreService"),
	BattlePassService = load("BattlePassService"),
	LobbyService = load("LobbyService"),
	RewardsService = load("RewardsService"),
	UltimateService = load("UltimateService"),
	ColorSlotService = load("ColorSlotService"),
	ObbyService = load("ObbyService"),
	RouletteService = load("RouletteService"),
	QuestService = load("QuestService"),
	EconomyFeedback = remotes.EconomyFeedback,
}
local S = services

S.ArenaService.Start() -- antes que nada: crea el Lobby 3D y el Dojo
S.DataService.Start() -- los demás servicios esperan al perfil
S.DataService.SetStateRemote(remotes.EconomyFeedback)
S.CombatService.Start(remotes)
S.KOService.Start(remotes, services)
S.UltimateService.Start(remotes, services)
S.EconomyService.Start(remotes, S.CombatService, S.KOService)
S.BoosterService.Start(S.EconomyService)
S.BattlePassService.Start(remotes)
S.UnlockService.Start(services)
S.StoreService.Start(services)
S.NPCService.Start(services)
S.MatchService.Start(remotes, services)
S.StoryService.Start(remotes, services)
S.FighterService.Start()
S.LobbyService.Start(services)
S.RewardsService.Start(services)
S.ColorSlotService.Start() -- colores alternativos si se repite personaje
S.ObbyService.Start(services) -- obby "Ascenso Maldito"
S.RouletteService.Start(services) -- Ruleta Maldita
S.QuestService.Start(services) -- misiones diarias

-- Enrutador de peticiones: el cliente pide, el servidor valida y responde { ok, msg }
local handlers = {}
for _, service in { S.UnlockService, S.BattlePassService, S.MatchService, S.StoryService, S.LobbyService, S.RewardsService, S.StoreService, S.ObbyService, S.RouletteService, S.QuestService } do
	for action, fn in service.Handlers do
		handlers[action] = fn
	end
end
handlers.GetState = function(player)
	S.DataService.WaitFor(player, 15)
	return S.DataService.BuildState(player)
end

-- SOLO EN STUDIO: dinero y XP de prueba para testear tiendas y pase sin jugar horas.
-- Desde la Command Bar (vista Cliente): game.ReplicatedStorage.Remotes.ShopRequest:InvokeServer("DevGrant")
if game:GetService("RunService"):IsStudio() then
	handlers.DevGrant = function(player)
		S.EconomyService.AddCurrency(player, "Coins", 20000, "DevGrant")
		S.EconomyService.AddCurrency(player, "Gems", 3000, "DevGrant")
		S.EconomyService.AddXP(player, 6000)
		return { ok = true, msg = "[Studio] +20.000 呪, +3.000 晶, +6.000 XP" }
	end
	-- Previsualizar un escenario: ShopRequest:InvokeServer("DevStage", "Temple")
	handlers.DevStage = function(player, stageId)
		local arena = S.ArenaService.Allocate(stageId, "Match")
		if not arena then
			return { ok = false, msg = "No se pudo crear la arena" }
		end
		arena.Info:SetAttribute("MatchState", "Practice")
		arena.Handler = { OnKO = function()
			return "respawn"
		end }
		S.FighterService.SetZone(player, arena.Id, "Arena", "Hub")
		if player.Character then
			S.FighterService.TeleportToSpawn(player.Character, 1)
		end
		return { ok = true, msg = `[Studio] Escenario {stageId} en {arena.Id}` }
	end
	handlers.DevTestMoves = function()
		local MoveTester = require(script.Parent:WaitForChild("Dev"):WaitForChild("MoveTester"))
		return { ok = true, msg = "[Studio] MoveTester: " .. MoveTester.Run(services) }
	end
	handlers.DevUnlockStory = function(player)
		S.DataService.Update(player, function(d)
			d.Story.Unlocked = 8
		end)
		S.DataService.PushState(player)
		return { ok = true, msg = "[Studio] Historia desbloqueada" }
	end
end

local lastRequest = setmetatable({}, { __mode = "k" })
shopRequest.OnServerInvoke = function(player, action, ...)
	local now = os.clock()
	if now - (lastRequest[player] or 0) < 0.1 then
		return { ok = false, msg = "Vas demasiado rápido" }
	end
	lastRequest[player] = now

	local handler = type(action) == "string" and handlers[action]
	if not handler then
		return { ok = false, msg = "Acción desconocida" }
	end
	local ok, response = pcall(handler, player, ...)
	if not ok then
		warn(`[ShopRequest] {action} falló:`, response)
		return { ok = false, msg = "Error del servidor" }
	end
	return response
end
