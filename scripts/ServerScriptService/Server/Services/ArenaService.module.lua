-- ArenaService: varias arenas a la vez, cada una con su escenario y su X propio.
--   Lobby     -> patio 3D de la Escuela en (-3000, 0, 0): donde aparece todo el mundo
--   "Hub"     -> X = 0, Dojo de práctica 2D permanente (escenario de la Escuela)
--   ArenaN    -> X = N * 1000, se crean para partidas e historia y se destruyen al acabar
-- Cada arena replica su información en ReplicatedStorage.ArenaInfo.<Id> (límites, estado...).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local StageConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StageConfig"))
local StageBuilder = require(script.Parent.Parent:WaitForChild("Builders"):WaitForChild("StageBuilder"))
local LobbyBuilder = require(script.Parent.Parent:WaitForChild("Builders"):WaitForChild("LobbyBuilder"))

local ArenaService = {}

local SPACING = 1000
local MAX_SLOTS = 10

local LOBBY_ORIGIN = Vector3.new(-3000, 0, 0)

local arenas = {} -- [id] = arena
local lobby = nil -- { Model, Origin }
local slots = {} -- [slot] = arenaId
local infoFolder: Folder
local worldFolder: Folder

local function stageModel(stageId: string): Model
	local templates = ServerStorage:FindFirstChild("Templates")
	local stages = templates and templates:FindFirstChild("Stages")
	local template = stages and stages:FindFirstChild(stageId)
	if template then
		return template:Clone()
	end
	return StageBuilder.Build(stageId) :: Model -- plan B: construir en vivo
end

local function create(id: string, stageId: string, center: Vector3, kind: string)
	local stage = StageConfig.Stages[stageId]
	assert(stage, `Escenario desconocido: {stageId}`)

	local model = stageModel(stageId)
	model.Name = id
	model:PivotTo(CFrame.new(center))
	model.Parent = worldFolder

	local info = Instance.new("Configuration")
	info.Name = id
	info:SetAttribute("StageId", stageId)
	info:SetAttribute("Kind", kind)
	info:SetAttribute("CenterX", center.X)
	info:SetAttribute("Left", center.X + stage.Bounds.Left)
	info:SetAttribute("Right", center.X + stage.Bounds.Right)
	info:SetAttribute("Top", center.Y + stage.Bounds.Top)
	info:SetAttribute("Bottom", center.Y + stage.Bounds.Bottom)
	info:SetAttribute("MatchState", if kind == "Hub" then "Practice" else "Starting")
	info:SetAttribute("EndsAt", 0)
	info.Parent = infoFolder

	local arena = {
		Id = id,
		Kind = kind, -- "Hub" | "Match" | "Story"
		StageId = stageId,
		Stage = stage,
		Center = center,
		Model = model,
		Info = info,
		Handler = nil, -- { OnKO = function(model, stocksLeft, killer) -> "respawn" | "eliminate" | "remove" }
	}
	arenas[id] = arena
	return arena
end

-- Reserva una arena libre para una partida o capítulo. Devuelve nil si están todas ocupadas.
function ArenaService.Allocate(stageId: string, kind: string)
	for slot = 1, MAX_SLOTS do
		if not slots[slot] then
			local id = `Arena{slot}`
			slots[slot] = id
			local ok, arenaOrErr = pcall(create, id, stageId, Vector3.new(slot * SPACING, 0, 0), kind)
			if ok then
				arenaOrErr.Slot = slot
				return arenaOrErr
			end
			slots[slot] = nil
			warn("[ArenaService] No se pudo crear la arena:", arenaOrErr)
			return nil
		end
	end
	return nil
end

function ArenaService.Release(arena)
	if not arena or arena.Kind == "Hub" then
		return
	end
	arenas[arena.Id] = nil
	if arena.Slot then
		slots[arena.Slot] = nil
	end
	arena.Model:Destroy()
	arena.Info:Destroy()
end

-- Cambia el escenario del Dojo de práctica (lo reconstruye en el mismo sitio)
function ArenaService.SetHubStage(stageId: string): boolean
	local hub = arenas.Hub
	local stage = StageConfig.Stages[stageId]
	if not hub or not stage or hub.StageId == stageId then
		return false
	end
	local model = stageModel(stageId)
	model.Name = "Hub"
	model:PivotTo(CFrame.new(hub.Center))
	hub.Model:Destroy()
	model.Parent = worldFolder
	hub.Model = model
	hub.StageId = stageId
	hub.Stage = stage
	local info = hub.Info
	info:SetAttribute("StageId", stageId)
	info:SetAttribute("Left", hub.Center.X + stage.Bounds.Left)
	info:SetAttribute("Right", hub.Center.X + stage.Bounds.Right)
	info:SetAttribute("Top", hub.Center.Y + stage.Bounds.Top)
	info:SetAttribute("Bottom", hub.Center.Y + stage.Bounds.Bottom)
	return true
end

function ArenaService.Get(id: string?)
	return if id then arenas[id] else nil
end

function ArenaService.Hub()
	return arenas.Hub
end

-- ===== Lobby 3D
function ArenaService.Lobby()
	return lobby
end

function ArenaService.LobbySpawnCFrame(): CFrame
	local spawnPart = lobby.Model:FindFirstChild("SpawnPoint") :: BasePart?
	local base = if spawnPart then spawnPart.Position else LOBBY_ORIGIN + Vector3.new(0, 0, 80)
	local pos = base + Vector3.new(math.random(-4, 4), 4, math.random(-3, 3))
	return CFrame.lookAt(pos, pos - Vector3.zAxis)
end

function ArenaService.SpawnCFrame(arena, index: number): CFrame
	local spawns = arena.Stage.Spawns
	local rel = spawns[(index - 1) % #spawns + 1]
	local pos = arena.Center + rel
	local facing = if rel.X <= 0 then 1 else -1
	return CFrame.lookAt(pos, pos + Vector3.new(facing, 0, 0))
end

function ArenaService.RespawnCFrame(arena): CFrame
	local pos = arena.Center + arena.Stage.Respawn
	return CFrame.lookAt(pos, pos + Vector3.xAxis)
end

function ArenaService.SpectatorCFrame(arena): CFrame
	return CFrame.new(arena.Center + Vector3.new(0, 300, -30))
end

function ArenaService.IsOutside(arena, pos: Vector3): boolean
	local b = arena.Stage.Bounds
	local rel = pos - arena.Center
	return rel.X < b.Left or rel.X > b.Right or rel.Y > b.Top or rel.Y < b.Bottom
end

function ArenaService.Start()
	infoFolder = ReplicatedStorage:FindFirstChild("ArenaInfo") or Instance.new("Folder")
	infoFolder.Name = "ArenaInfo"
	infoFolder.Parent = ReplicatedStorage

	worldFolder = workspace:FindFirstChild("Arenas") or Instance.new("Folder")
	worldFolder.Name = "Arenas"
	worldFolder.Parent = workspace

	-- El escenario antiguo de la Fase 1 ya no se usa
	local legacy = workspace:FindFirstChild("Stage")
	if legacy then
		legacy:Destroy()
	end

	create("Hub", StageConfig.HubStage, Vector3.zero, "Hub")

	local templates = ServerStorage:FindFirstChild("Templates")
	local template = templates and templates:FindFirstChild("Lobby")
	local model = if template then template:Clone() else LobbyBuilder.Build()
	model.Name = "Lobby"
	model:PivotTo(CFrame.new(LOBBY_ORIGIN))
	model.Parent = workspace
	lobby = { Model = model, Origin = LOBBY_ORIGIN }
end

return ArenaService
