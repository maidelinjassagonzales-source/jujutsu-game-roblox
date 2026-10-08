-- LobbyService: vida del Lobby 3D (patio de la Escuela de Hechicería).
--   * Tablas de clasificación GLOBALES (OrderedDataStore): victorias y nivel
--   * Estatua del último campeón en el centro del patio
--   * Sala de Personajes: una estatua de cada luchador (abre su ficha en la tienda)
--   * Sala de Combate: súbete al círculo de un portal para entrar en la cola
--   * Dojo de práctica / vuelta al Lobby
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StageConfig"))
local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local ArenaService = require(script.Parent:WaitForChild("ArenaService"))

local LobbyService = {}
LobbyService.Handlers = {}

local TOP_COUNT = 10
local PAD_RADIUS = 8
local FALL_LIMIT = -40
local STORE_SUFFIX = if RunService:IsStudio() then "_Studio" else ""

local services
local lobbyModel: Model
local origin: Vector3
local folder: Folder
local statue: Model? = nil
local championLabel: TextLabel
local boards = {} -- [statKey] = { Rows = {TextLabel}, Store = OrderedDataStore? }
local padQueued = {} -- [Player] = modo en el que entró pisando el círculo
local nameCache = {}

local function result(ok: boolean, msg: string)
	return { ok = ok, msg = msg }
end

local function lobbyPart(name: string): BasePart?
	return lobbyModel:FindFirstChild(name, true) :: BasePart?
end

local function billboard(parent: BasePart, size: UDim2, offset: Vector3, color: Color3, text: string): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = size
	gui.StudsOffsetWorldSpace = offset
	gui.LightInfluence = 0
	gui.MaxDistance = 160
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.PermanentMarker -- pincel, estilo Jujutsu
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = gui
	return label
end

-- Modelo estático (sin scripts ni colisiones) a partir de un luchador o retrato
local function freeze(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BaseScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	for _, tag in CollectionService:GetTags(model) do
		CollectionService:RemoveTag(model, tag)
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

-- Coloca un modelo R6 de pie con los pies en feetPos mirando hacia facing (su raíz puede ser la cabeza)
local function standAt(model: Model, feetPos: Vector3, facing: Vector3)
	model:PivotTo(CFrame.lookAt(feetPos + Vector3.new(0, 3, 0), feetPos + Vector3.new(0, 3, 0) + facing))
	local leg = model:FindFirstChild("Left Leg") :: BasePart?
	if leg then
		local bottom = leg.Position.Y - leg.Size.Y / 2
		model:PivotTo(model:GetPivot() + Vector3.new(0, feetPos.Y - bottom, 0))
	end
end

-- ===== Tablas de clasificación
local function playerName(userId: number): string
	if nameCache[userId] then
		return nameCache[userId]
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		nameCache[userId] = player.DisplayName
		return player.DisplayName
	end
	if userId <= 0 then
		return `Jugador de prueba {-userId}`
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	nameCache[userId] = if ok then name else `#{userId}`
	return nameCache[userId]
end

local function buildBoard(statKey: string, partName: string, title: string, unit: string)
	local board = lobbyPart(partName)
	if not board then
		return
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back -- la cara +Z mira al patio
	gui.CanvasSize = Vector2.new(680, 520)
	gui.LightInfluence = 0
	gui.Parent = board
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 64)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.PermanentMarker
	header.TextSize = 42
	header.TextColor3 = Color3.fromRGB(255, 215, 80)
	header.Text = title
	header.Parent = gui
	local rows = {}
	for i = 1, TOP_COUNT do
		local row = Instance.new("TextLabel")
		row.Position = UDim2.fromOffset(30, 66 + (i - 1) * 44)
		row.Size = UDim2.new(1, -60, 0, 42)
		row.BackgroundTransparency = if i % 2 == 0 then 1 else 0.85
		row.BackgroundColor3 = Color3.fromRGB(120, 70, 200)
		row.BorderSizePixel = 0
		row.Font = Enum.Font.GothamBold
		row.TextSize = 26
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = if i == 1 then Color3.fromRGB(255, 215, 80) elseif i <= 3 then Color3.fromRGB(220, 220, 240) else Color3.new(1, 1, 1)
		row.Text = ""
		row.Parent = gui
		rows[i] = row
	end
	local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, `Top{statKey}{STORE_SUFFIX}`)
	boards[statKey] = { Rows = rows, Store = if ok then store else nil, Unit = unit }
end

local function statOf(data, statKey: string): number
	return if statKey == "Wins" then data.Stats.Wins else data.Level
end

local function refreshBoards()
	for statKey, board in boards do
		-- 1) Guardar a los jugadores de este servidor
		local entries = nil
		if board.Store then
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				if data and player.UserId > 0 then
					pcall(board.Store.SetAsync, board.Store, tostring(player.UserId), statOf(data, statKey))
				end
			end
			-- 2) Leer el top global
			local ok, pages = pcall(board.Store.GetSortedAsync, board.Store, false, TOP_COUNT)
			if ok and pages then
				entries = {}
				for _, item in pages:GetCurrentPage() do
					table.insert(entries, { Name = playerName(tonumber(item.key) or 0), Value = item.value })
				end
			end
		end
		-- Plan B (sin DataStores): solo este servidor
		if not entries or #entries == 0 then
			entries = {}
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				if data then
					table.insert(entries, { Name = player.DisplayName, Value = statOf(data, statKey) })
				end
			end
			table.sort(entries, function(a, b)
				return a.Value > b.Value
			end)
		end
		for i, row in board.Rows do
			local e = entries[i]
			local medal = if i == 1 then "" elseif i == 2 then "" elseif i == 3 then "" else `#{i}`
			row.Text = if e then `  {medal}  {e.Name}   ·   {e.Value} {board.Unit}` else ""
		end
	end
end

-- ===== Estatua del campeón (llamado por MatchService)
function LobbyService.SetChampion(player: Player, model: Model, streak: number)
	if statue then
		statue:Destroy()
		statue = nil
	end
	local pedestal = lobbyPart("ChampionPedestal")
	local ok, clone = pcall(function()
		model.Archivable = true
		return model:Clone()
	end)
	if ok and clone and pedestal then
		freeze(clone)
		for _, attr in { "Percent", "Stocks", "KOing", "Eliminated", "Invulnerable" } do
			clone:SetAttribute(attr, nil)
		end
		clone.Name = "ChampionStatue"
		standAt(clone, pedestal.Position + Vector3.new(0, pedestal.Size.Y / 2 + 0.3, 0), Vector3.zAxis) -- mirando a la entrada
		clone.Parent = folder
		statue = clone
	end
	local character = CharacterRegistry.Get(model:GetAttribute("CharacterId"))
	local skin = CatalogConfig.Skins[model:GetAttribute("SkinId") or ""]
	local look = if skin then skin.Name elseif character then character.DisplayName else ""
	championLabel.Text = `{player.DisplayName}  ·  {look}` .. (if streak > 1 then `  ·  Racha x{streak}` else "")
	task.spawn(refreshBoards)
end

-- ===== Sala de Personajes: estatuas con su ficha
local function buildHall()
	local portraits = ReplicatedStorage:WaitForChild("Portraits", 30)
	if not portraits then
		return
	end
	local spots, rings = {}, {}
	for _, d in lobbyModel:GetDescendants() do
		if d.Name == "HallSpot" and d:IsA("BasePart") then
			spots[d:GetAttribute("Index")] = d
		elseif d.Name == "HallRing" and d:IsA("BasePart") then
			rings[d:GetAttribute("Index")] = d
		end
	end
	local ids = {}
	for _, id in CharacterRegistry.GetOrder() do
		local data = CharacterRegistry.Get(id)
		if data and data.Playable ~= false and CatalogConfig.Characters[id] then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		return (CatalogConfig.Characters[a].Order or 99) < (CatalogConfig.Characters[b].Order or 99)
	end)

	for i, id in ids do
		local spot = spots[i]
		if not spot then
			break
		end
		local template = portraits:WaitForChild(id, 20)
		local data = CharacterRegistry.Get(id)
		local catalog = CatalogConfig.Characters[id]
		local rarity = CatalogConfig.Rarities[catalog.Rarity] or {}
		if template then
			local model = template:Clone()
			freeze(model)
			local top = spot.Position + Vector3.new(0, spot.Size.X / 2, 0)
			standAt(model, top, spot:GetAttribute("Facing") or Vector3.xAxis) -- miran al pasillo
			model.Parent = folder
		end
		if rings[i] then
			rings[i].Color = rarity.Color or rings[i].Color
		end
		billboard(spot, UDim2.new(8, 0, 1.2, 0), Vector3.new(0, 8.2, 0), Color3.new(1, 1, 1), data.DisplayName)
		billboard(spot, UDim2.new(6, 0, 0.8, 0), Vector3.new(0, 7.1, 0), rarity.Color or Color3.new(1, 1, 1), rarity.Name or catalog.Rarity)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Ver personaje"
		prompt.ObjectText = data.DisplayName
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Action", "OpenCharacter")
		prompt:SetAttribute("CharacterId", id)
		prompt.Parent = spot
	end
end

-- ===== Sala de Combate: círculos de cola
local function startQueuePads()
	local pads = {}
	for _, pad in CollectionService:GetTagged("QueuePad") do
		if pad:IsDescendantOf(lobbyModel) then
			table.insert(pads, pad)
		end
	end
	local signs = {}
	for _, pad in pads do
		local mode = pad:GetAttribute("Mode")
		local signAnchor = lobbyModel:FindFirstChild(`QueueSign_{mode}`, true)
		signs[mode] = signAnchor and signAnchor:FindFirstChild("QueueText", true)
	end
	local baseText = {}
	for mode, label in signs do
		baseText[mode] = label.Text
	end

	task.spawn(function()
		while true do
			task.wait(0.3)
			for _, player in Players:GetPlayers() do
				local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local onPad = nil
				if hrp and player:GetAttribute("ArenaId") == "Lobby" then
					for _, pad in pads do
						local offset = hrp.Position - pad.Position
						if Vector2.new(offset.X, offset.Z).Magnitude <= PAD_RADIUS and offset.Y < 8 then
							onPad = pad:GetAttribute("Mode")
							break
						end
					end
					-- Caída fuera del patio
					if hrp.Position.Y < origin.Y + FALL_LIMIT then
						services.FighterService.TeleportToSpawn(player.Character)
					end
				end
				local activity = player:GetAttribute("Activity")
				if onPad and padQueued[player] ~= onPad and (activity == "Hub" or activity == "Queue") then
					local response = services.MatchService.Handlers.JoinQueue(player, onPad)
					if response.ok then
						padQueued[player] = onPad
						services.EconomyFeedback:FireClient(player, "Reward", { Reason = response.msg })
					end
				elseif not onPad and padQueued[player] then
					padQueued[player] = nil
					if player:GetAttribute("Activity") == "Queue" then
						services.MatchService.Handlers.LeaveQueue(player)
						services.EconomyFeedback:FireClient(player, "Reward", { Reason = "Has salido de la cola" })
					end
				elseif padQueued[player] and activity ~= "Queue" then
					padQueued[player] = nil -- la partida empezó o canceló desde el menú
				end
			end
			for mode, label in signs do
				local count, max = services.MatchService.QueueCount(mode)
				label.Text = `{baseText[mode]}  ·  {count}/{max}`
			end
		end
	end)
end

-- ===== Peticiones
LobbyService.Handlers.GoPractice = function(player: Player)
	local activity = player:GetAttribute("Activity")
	if activity ~= "Hub" and activity ~= "Queue" then
		return result(false, "Termina lo que estás haciendo primero")
	end
	if player:GetAttribute("ArenaId") == "Hub" then
		return result(false, "Ya estás en el Dojo")
	end
	services.FighterService.SendToDojo(player)
	return result(true, "Dojo de práctica · pulsa ‘Lobby’ para volver")
end

-- Elegir el escenario del Dojo (o uno al azar). El Dojo es compartido: cambia para todos los que están dentro.
local lastDojoStageChange = 0
LobbyService.Handlers.SetDojoStage = function(player: Player, stageId: any)
	if player:GetAttribute("ArenaId") ~= "Hub" then
		return result(false, "Solo dentro del Dojo")
	end
	if os.clock() - lastDojoStageChange < 4 then
		return result(false, "Espera un momento antes de cambiar otra vez")
	end
	local current = services.ArenaService.Hub().StageId
	if stageId == "Random" then
		local options = {}
		for _, id in StageConfig.MatchPool do
			if id ~= current then
				table.insert(options, id)
			end
		end
		stageId = options[math.random(1, #options)]
	end
	if type(stageId) ~= "string" or not StageConfig.Stages[stageId] then
		return result(false, "Escenario desconocido")
	end
	if stageId == current then
		return result(false, "Ya estás en ese escenario")
	end
	lastDojoStageChange = os.clock()
	services.ArenaService.SetHubStage(stageId)
	-- Todos los del Dojo vuelven a su punto de salida en el escenario nuevo
	local name = StageConfig.Stages[stageId].Name
	for _, other in Players:GetPlayers() do
		if other:GetAttribute("ArenaId") == "Hub" and other.Character then
			other.Character:SetAttribute("Percent", 0)
			services.FighterService.TeleportToSpawn(other.Character)
			if other ~= player then
				services.EconomyFeedback:FireClient(other, "Reward", { Reason = `{player.DisplayName} ha cambiado el Dojo a {name}` })
			end
		end
	end
	services.FighterService.SetDummyEnabled(true)
	return result(true, `Escenario: {name}`)
end

LobbyService.Handlers.ReturnToLobby = function(player: Player)
	if player:GetAttribute("ArenaId") ~= "Hub" then
		return result(false, "Solo desde el Dojo")
	end
	services.FighterService.SendToHub(player)
	return result(true, "De vuelta al Lobby")
end

function LobbyService.Start(s)
	services = s
	local lobby = ArenaService.Lobby()
	lobbyModel = lobby.Model
	origin = lobby.Origin

	folder = Instance.new("Folder")
	folder.Name = "LobbyDynamic"
	folder.Parent = workspace

	local pedestal = lobbyPart("ChampionPedestal")
	if pedestal then
		championLabel = billboard(pedestal, UDim2.new(26, 0, 2.5, 0), Vector3.new(0, 12, 0), Color3.fromRGB(255, 215, 80), "Gana una partida para aparecer aquí")
	end
	buildBoard("Wins", "LeaderboardWins", "MURO DE LEYENDAS", "victorias")
	buildBoard("Level", "LeaderboardLevel", "TOP NIVELES", "nv")
	task.spawn(buildHall)
	startQueuePads()

	Players.PlayerRemoving:Connect(function(player)
		padQueued[player] = nil
	end)
	task.spawn(function()
		task.wait(5)
		while true do
			refreshBoards()
			task.wait(60)
		end
	end)
end

return LobbyService
