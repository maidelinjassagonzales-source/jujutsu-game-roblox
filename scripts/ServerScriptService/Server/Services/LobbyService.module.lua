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
		return `Test player {-userId}`
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
	championLabel.Text = `{player.DisplayName}  ·  {look}` .. (if streak > 1 then `  ·  Streak x{streak}` else "")
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
		prompt.ActionText = "View character"
		prompt.ObjectText = data.DisplayName
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Action", "OpenCharacter")
		prompt:SetAttribute("CharacterId", id)
		prompt.Parent = spot
	end
end

-- ===== NPCs del patio: personajes que dan consejos (E para hablar) y te miran al pasar
-- Solo hechiceros y maldiciones de Jujutsu (los de otros animes no salen en el patio de la Escuela)
local LOBBY_NPCS = {
	{ Id = "Sorcerer", Lines = {
		"Hold the heavy attack (right click or K) on the ground to charge it: up to +40% damage!",
		"If two players expand their domains at once, the domains clash! Press the keys on your side without missing.",
		"I'm the strongest... but you can try.",
	} },
	{ Id = "Brawler", Lines = {
		"In Play you'll find 2v2 and 3v3 Teams. Relax: there's no friendly fire.",
		"If the queue is empty, bots fill the match. You'll never be left without a fight!",
		"Grab the items that appear on the stage and use them with F!",
	} },
	{ Id = "ShadowSummoner", Lines = {
		"Shield (Q) + left/right = roll. If you keep holding Q, the shield comes back up by itself.",
		"Grab with G and choose where to throw while you're holding them.",
	} },
	{ Id = "NailWitch", Lines = {
		"Before each match you vote on the stage and then choose your fighter.",
		"In the Practice Dojo press T to try any character.",
	} },
	{ Id = "Executor", Lines = {
		"Deal and take hits to fill your ult bar, then press R. It's overtime, but it's worth it.",
		"The portals in the Battle Hall put you in the queue. There are portals for 6-player and 4-player matches.",
	} },
	{ Id = "Gambler", Lines = {
		"Try your luck on the Cursed Roulette! If you win a skin for a character you don't own, you get the character too.",
		"Win matches to appear on the Wall of Legends. Jackpot!",
	} },
}

local function buildLobbyNPCs()
	local portraits = ReplicatedStorage:WaitForChild("Portraits", 30)
	if not portraits then
		return
	end
	local spawnPart = lobbyModel:FindFirstChild("SpawnPoint", true) :: BasePart?
	local center = if spawnPart then spawnPart.Position else origin + Vector3.new(0, 0, 80)
	local npcFolder = Instance.new("Folder")
	npcFolder.Name = "LobbyNPCs"
	npcFolder.Parent = folder

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.RespectCanCollide = true
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.RespectCanCollide = true

	-- Posiciones de los puestos del patio (todo lo que tiene un ProximityPrompt o un cartel)
	local stalls = {}
	for _, d in lobbyModel:GetDescendants() do
		if (d:IsA("ProximityPrompt") or d:IsA("BillboardGui")) and d.Parent and d.Parent:IsA("BasePart") then
			table.insert(stalls, (d.Parent :: BasePart).Position)
		end
	end

	local npcs = {}
	for i, spec in LOBBY_NPCS do
		local template = portraits:FindFirstChild(spec.Id) or portraits:WaitForChild(spec.Id, 10)
		local data = CharacterRegistry.Get(spec.Id)
		if not template or not data then
			continue
		end
		local ignore = { folder }
		for _, p in Players:GetPlayers() do
			if p.Character then
				table.insert(ignore, p.Character)
			end
		end
		rayParams.FilterDescendantsInstances = ignore
		overlap.FilterDescendantsInstances = ignore
		-- Busca un hueco libre de obstáculos en un anillo alrededor del punto de aparición
		local spot: Vector3? = nil
		for attempt = 0, 47 do
			local angle = math.rad((i - 1) * (360 / #LOBBY_NPCS) + attempt * 15)
			local radius = 12 + (attempt % 6) * 4
			local probe = center + Vector3.new(math.cos(angle) * radius, 40, math.sin(angle) * radius)
			local hit = workspace:Raycast(probe, Vector3.new(0, -90, 0), rayParams)
			if hit and math.abs(hit.Position.Y - center.Y) < 6 then
				local blocked = #workspace:GetPartBoundsInBox(CFrame.new(hit.Position + Vector3.new(0, 3.4, 0)), Vector3.new(3, 5, 3), overlap) > 0
				local crowded = false
				for _, other in npcs do
					if (other.Spot - hit.Position).Magnitude < 7 then
						crowded = true
					end
				end
				-- Lejos de los puestos (Tienda, Pase, Historia, estatuas...): que no tapen sus carteles
				for _, stall in stalls do
					if (Vector3.new(stall.X, 0, stall.Z) - Vector3.new(hit.Position.X, 0, hit.Position.Z)).Magnitude < 13 then
						crowded = true
					end
				end
				if not blocked and not crowded then
					spot = hit.Position
					break
				end
			end
		end
		if not spot then
			continue
		end

		local model = template:Clone()
		freeze(model)
		model.Name = `NPC_{spec.Id}`
		local look = Vector3.new(center.X - spot.X, 0, center.Z - spot.Z)
		standAt(model, spot, if look.Magnitude > 0.1 then look.Unit else Vector3.zAxis)
		model.Parent = npcFolder

		local root = (model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")) :: BasePart?
		if root then
			-- Nombre pequeño y solo de cerca: si no, tapaba los carteles de los puestos (Tienda, Pase, Historia...)
			local nameLabel = billboard(root, UDim2.new(4.5, 0, 0.6, 0), Vector3.new(0, 3.3, 0), data.Color or Color3.new(1, 1, 1), data.DisplayName)
			local nameGui = nameLabel.Parent :: BillboardGui
			nameGui.MaxDistance = 28
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Talk"
			prompt.ObjectText = data.DisplayName
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt:SetAttribute("Action", "Talk")
			prompt:SetAttribute("Speaker", data.DisplayName)
			prompt:SetAttribute("Lines", table.concat(spec.Lines, "|"))
			prompt.Parent = root
		end
		table.insert(npcs, { Model = model, Spot = spot })
	end

	-- Se giran hacia el jugador más cercano (solo si está a menos de 16 studs)
	task.spawn(function()
		while npcFolder.Parent do
			task.wait(0.4)
			for _, npc in npcs do
				local pivot = npc.Model:GetPivot()
				local best, bestDist = nil, 16
				for _, p in Players:GetPlayers() do
					local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if hrp and p:GetAttribute("ArenaId") == "Lobby" then
						local d = (hrp.Position - pivot.Position).Magnitude
						if d < bestDist then
							best, bestDist = hrp.Position, d
						end
					end
				end
				if best then
					local flat = Vector3.new(best.X, pivot.Position.Y, best.Z)
					if (flat - pivot.Position).Magnitude > 0.5 then
						npc.Model:PivotTo(CFrame.lookAt(pivot.Position, flat))
					end
				end
			end
		end
	end)
end

-- ===== Portales extra de la Sala de Combate (partidas con más jugadores)
-- Se copian del portal de "Partida rápida" y se colocan en la misma fila, en huecos libres.
local EXTRA_PORTALS = {
	{ Mode = "Team3", Text = "TEAMS 3V3" },
	{ Mode = "FFA4", Text = "FREE-FOR-ALL · 4" },
}

local function buildExtraPortals()
	local pad = lobbyModel:FindFirstChild("QueuePad_FFA", true) :: BasePart?
	if not pad then
		return
	end
	local group = {}
	for _, d in lobbyModel:GetDescendants() do
		if d:IsA("BasePart") and (d.Name:find("Portal") or d.Name == "QueueSign_FFA" or d == pad)
			and math.abs(d.Position.Z - pad.Position.Z) < 6 and math.abs(d.Position.X - pad.Position.X) < 30 then
			table.insert(group, d)
		end
	end
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.RespectCanCollide = true
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.RespectCanCollide = true
	local placed = {}
	-- Huecos posibles (desplazamiento en Z respecto al portal de Partida rápida; los portales van cada 30)
	local candidates = { 90, -30, 120, -60, 150 }
	for _, spec in EXTRA_PORTALS do
		for ci, dz in candidates do
			if placed[dz] then
				continue
			end
			local probe = pad.Position + Vector3.new(0, 10, dz)
			local floor = workspace:Raycast(probe, Vector3.new(0, -20, 0), rayParams)
			local free = floor ~= nil and math.abs(floor.Position.Y - pad.Position.Y) < 2.5
			if free then
				-- que no haya paredes ni objetos donde va el arco del portal
				for _, d in group do
					if d.Name == "Env_PortalStone" then
						local cf = d.CFrame + Vector3.new(0, 1.5, dz)
						if #workspace:GetPartBoundsInBox(cf, d.Size * 0.8, overlap) > 0 then
							free = false
						end
					end
				end
			end
			if free then
				placed[dz] = true
				table.remove(candidates, ci)
				for _, d in group do
					local c = d:Clone()
					c.CFrame = d.CFrame + Vector3.new(0, 0, dz)
					if d == pad then
						c.Name = `QueuePad_{spec.Mode}`
						c:SetAttribute("Mode", spec.Mode)
					elseif d.Name == "QueueSign_FFA" then
						c.Name = `QueueSign_{spec.Mode}`
						local text = c:FindFirstChild("QueueText", true)
						if text and text:IsA("TextLabel") then
							text.Text = spec.Text
						end
					end
					c.Parent = lobbyModel
				end
				break
			end
		end
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
	-- Que ningún cartel se corte:
	--  * el texto (un BillboardGui) estaba DETRÁS del tablón del portal y la madera tapaba la mitad:
	--    se adelanta un poco hacia la sala
	--  * el texto se ajusta al tamaño del cartel (también el del Dojo, que no tiene cola)
	-- Todos los carteles del patio (portales, Tienda, Pase, Historia, Obby...): el texto se dibuja siempre
	-- por encima de su tablón y de los árboles (si no, la madera o un cerezo tapaban media palabra)
	local spawnPart = lobbyModel:FindFirstChild("SpawnPoint", true) :: BasePart?
	local plaza = if spawnPart then spawnPart.Position else origin
	for _, d in lobbyModel:GetDescendants() do
		if d:IsA("BillboardGui") and d.Parent and d.Parent:IsA("BasePart") then
			local pos = (d.Parent :: BasePart).Position
			local toPlaza = Vector3.new(plaza.X - pos.X, 0, plaza.Z - pos.Z)
			if toPlaza.Magnitude > 0.1 then
				d.StudsOffsetWorldSpace = toPlaza.Unit * 3
			end
			d.AlwaysOnTop = true
			d.MaxDistance = math.min(d.MaxDistance, 140)
			if d.Parent.Name:sub(1, 10) == "QueueSign_" then
				d.Size = UDim2.new(15, 0, 2.6, 0) -- del ancho del tablón (antes 20: se salía por los lados)
			end
		end
	end
	for _, d in lobbyModel:GetDescendants() do
		if d.Name == "QueueText" and d:IsA("TextLabel") then
			d.TextScaled = true
			d.TextWrapped = true
			d.TextXAlignment = Enum.TextXAlignment.Center
			if not d:FindFirstChildOfClass("UIPadding") then
				local pad = Instance.new("UIPadding")
				pad.PaddingLeft = UDim.new(0.06, 0)
				pad.PaddingRight = UDim.new(0.06, 0)
				pad.PaddingTop = UDim.new(0.18, 0)
				pad.PaddingBottom = UDim.new(0.18, 0)
				pad.Parent = d
			end
		end
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
						services.EconomyFeedback:FireClient(player, "Reward", { Reason = "You left the queue" })
					end
				elseif padQueued[player] and activity ~= "Queue" then
					padQueued[player] = nil -- la partida empezó o canceló desde el menú
				end
			end
			for mode, label in signs do
				local count, max = services.MatchService.QueueCount(mode)
				label.Text = `{baseText[mode]} · {count}/{max}`
			end
		end
	end)
end

-- ===== Peticiones
LobbyService.Handlers.GoPractice = function(player: Player)
	local activity = player:GetAttribute("Activity")
	if activity ~= "Hub" and activity ~= "Queue" then
		return result(false, "Finish what you're doing first")
	end
	if player:GetAttribute("ArenaId") == "Hub" then
		return result(false, "You're already in the Dojo")
	end
	services.FighterService.SendToDojo(player)
	return result(true, "Practice Dojo · press ‘Lobby’ to go back")
end

-- Elegir el escenario del Dojo (o uno al azar). El Dojo es compartido: cambia para todos los que están dentro.
local lastDojoStageChange = 0
LobbyService.Handlers.SetDojoStage = function(player: Player, stageId: any)
	if player:GetAttribute("ArenaId") ~= "Hub" then
		return result(false, "Only inside the Dojo")
	end
	if os.clock() - lastDojoStageChange < 4 then
		return result(false, "Wait a moment before switching again")
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
		return result(false, "Unknown stage")
	end
	if stageId == current then
		return result(false, "You're already on that stage")
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
				services.EconomyFeedback:FireClient(other, "Reward", { Reason = `{player.DisplayName} changed the Dojo to {name}` })
			end
		end
	end
	services.FighterService.SetDummyEnabled(true)
	return result(true, `Stage: {name}`)
end

LobbyService.Handlers.ReturnToLobby = function(player: Player)
	if player:GetAttribute("ArenaId") ~= "Hub" then
		return result(false, "Only from the Dojo")
	end
	services.FighterService.SendToHub(player)
	return result(true, "Back to the Lobby")
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
		championLabel = billboard(pedestal, UDim2.new(26, 0, 2.5, 0), Vector3.new(0, 12, 0), Color3.fromRGB(255, 215, 80), "Win a match to appear here")
	end
	buildBoard("Wins", "LeaderboardWins", "WALL OF LEGENDS", "wins")
	buildBoard("Level", "LeaderboardLevel", "TOP LEVELS", "lv")
	task.spawn(buildHall)
	task.spawn(buildLobbyNPCs)
	pcall(buildExtraPortals)
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

