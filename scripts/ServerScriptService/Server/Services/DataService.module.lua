-- DataService: guardado robusto con DataStoreService (sin dependencias externas).
--   * Session locking: un perfil solo puede estar abierto en un servidor a la vez (evita duplicar objetos)
--   * Reintentos con espera exponencial
--   * Autoguardado periódico + guardado al salir + BindToClose
--   * Reconciliación con DataTemplate (campos nuevos se añaden solos)
--   * Modo simulado en Studio si el juego no está publicado / sin acceso a API
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EconomyConfig"))
local Template = require(script.Parent.Parent:WaitForChild("Data"):WaitForChild("DataTemplate"))

local DataService = {}

-- En Studio se usa un almacén aparte: las pruebas nunca tocan los datos de los jugadores reales
local STORE_NAME = if RunService:IsStudio() then "PlayerData_v1_Studio" else "PlayerData_v1"
local SESSION_TIMEOUT = 1800 -- un bloqueo sin refrescar en 30 min se considera abandonado
local LOCK_RETRY_WAIT = 5
local LOCK_RETRIES = 6 -- ~30 s esperando a que otro servidor libere el perfil
local MAX_RETRIES = 4
local AUTOSAVE_INTERVAL = 120
local REPLICATED_FIELDS = { "Coins", "Gems", "XP", "Level", "SelectedCharacter" }

local store: DataStore? = nil
local mockMode = false
local profiles = {} -- [Player] = data
local loadedEvent = Instance.new("BindableEvent")

DataService.ProfileLoaded = loadedEvent.Event -- (player, data)

local function deepCopy(t)
	local copy = {}
	for k, v in t do
		copy[k] = if type(v) == "table" then deepCopy(v) else v
	end
	return copy
end

local function reconcile(data, template)
	for k, v in template do
		if data[k] == nil then
			data[k] = if type(v) == "table" then deepCopy(v) else v
		elseif type(v) == "table" and type(data[k]) == "table" and next(v) ~= nil then
			reconcile(data[k], v)
		end
	end
end

local function keyFor(player: Player): string
	return `Player_{player.UserId}`
end

local function syncAttributes(player: Player, data)
	for _, field in REPLICATED_FIELDS do
		player:SetAttribute(field, data[field])
	end
	player:SetAttribute("XPNeeded", EconomyConfig.XPForLevel(data.Level))
end

local function withRetries(label: string, fn)
	local lastErr
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		warn(`[DataService] {label} falló (intento {attempt}/{MAX_RETRIES}):`, result)
		task.wait(2 ^ attempt)
	end
	return false, lastErr
end

local function loadProfile(player: Player)
	if mockMode then
		local data = deepCopy(Template)
		data.FirstJoin = os.time()
		return data
	end

	local key = keyFor(player)
	for lockAttempt = 1, LOCK_RETRIES do
		local lockedElsewhere = false
		local forceSteal = lockAttempt == LOCK_RETRIES

		local ok, result = withRetries("Cargar perfil", function()
			return (store :: DataStore):UpdateAsync(key, function(old)
				old = old or deepCopy(Template)
				local lock = old.SessionLock
				if not forceSteal and lock and lock.JobId ~= game.JobId and os.time() - lock.Time < SESSION_TIMEOUT then
					lockedElsewhere = true
					return nil -- no tocar: otro servidor lo tiene abierto
				end
				old.SessionLock = { JobId = game.JobId, Time = os.time() }
				return old
			end)
		end)

		if not ok then
			return nil
		end
		if not lockedElsewhere and result then
			return result
		end
		task.wait(LOCK_RETRY_WAIT)
		if not player.Parent then
			return nil
		end
	end
	return nil
end

function DataService.Save(player: Player, release: boolean?): boolean
	local data = profiles[player]
	if not data then
		return true
	end
	if mockMode then
		return true
	end

	local stolen = false
	local ok = withRetries("Guardar perfil", function()
		(store :: DataStore):UpdateAsync(keyFor(player), function(old)
			if old and old.SessionLock and old.SessionLock.JobId ~= game.JobId then
				stolen = true
				return nil -- otro servidor tomó el perfil: no sobrescribimos sus datos
			end
			data.SessionLock = if release then nil else { JobId = game.JobId, Time = os.time() }
			return data
		end)
	end)

	if stolen then
		warn(`[DataService] El perfil de {player.Name} está abierto en otro servidor; no se guardó.`)
		return false
	end
	return ok
end

function DataService.Get(player: Player)
	return profiles[player]
end

function DataService.WaitFor(player: Player, timeout: number?)
	local deadline = os.clock() + (timeout or 30)
	while not profiles[player] and player.Parent and os.clock() < deadline do
		task.wait(0.1)
	end
	return profiles[player]
end

-- Único punto de escritura: modifica los datos y replica los campos visibles.
function DataService.Update(player: Player, mutator: (any) -> ())
	local data = profiles[player]
	if not data then
		return false
	end
	mutator(data)
	syncAttributes(player, data)
	return true
end

function DataService.IsMock(): boolean
	return mockMode
end

-- Estado "de colección" que la UI necesita (personajes, skins, pase). Se envía entero al cambiar.
local stateRemote: RemoteEvent? = nil

function DataService.SetStateRemote(remote: RemoteEvent)
	stateRemote = remote
end

function DataService.BuildState(player: Player)
	local d = profiles[player]
	if not d then
		return nil
	end
	return {
		OwnedCharacters = d.OwnedCharacters,
		OwnedSkins = d.OwnedSkins,
		EquippedSkins = d.EquippedSkins,
		OwnedEffects = d.OwnedEffects,
		OwnedTitles = d.OwnedTitles,
		EquippedEffect = d.EquippedEffect,
		EquippedTitle = d.EquippedTitle,
		Boosts = d.Boosts,
		BattlePass = d.BattlePass,
		Story = d.Story,
		Login = d.Login,
		RedeemedCodes = d.RedeemedCodes,
		Tutorial = d.Tutorial,
		Obby = d.Obby,
		Roulette = d.Roulette,
		Quests = d.Quests,
		Stats = { Wins = d.Stats.Wins, KOs = d.Stats.KOs, Matches = d.Stats.Matches, BestStreak = d.Stats.BestStreak, StoryClears = d.Stats.StoryClears },
	}
end

function DataService.PushState(player: Player)
	local state = DataService.BuildState(player)
	if stateRemote and state then
		stateRemote:FireClient(player, "State", state)
	end
end

local function onPlayerAdded(player: Player)
	local data = loadProfile(player)
	if not player.Parent then
		return
	end
	if not data then
		if RunService:IsStudio() then
			warn("[DataService] No se pudo cargar el perfil; usando datos temporales.")
			data = deepCopy(Template)
		else
			player:Kick("No pudimos cargar tus datos de forma segura. Vuelve a entrar en un momento.")
			return
		end
	end

	reconcile(data, Template)
	data.LastJoin = os.time()
	if data.FirstJoin == 0 then
		data.FirstJoin = os.time()
	end

	-- Un personaje seleccionado que ya no se posee (p.ej. datos antiguos) vuelve al inicial
	if not data.OwnedCharacters[data.SelectedCharacter] then
		data.SelectedCharacter = "Brawler"
	end

	profiles[player] = data
	syncAttributes(player, data)
	player:SetAttribute("DataLoaded", true)
	loadedEvent:Fire(player, data)
	DataService.PushState(player)
end

local function onPlayerRemoving(player: Player)
	if profiles[player] then
		DataService.Save(player, true)
		profiles[player] = nil
	end
end

function DataService.Start()
	local ok, result = pcall(function()
		local s = DataStoreService:GetDataStore(STORE_NAME)
		s:GetAsync("__probe") -- falla si no está publicado o sin acceso a API en Studio
		return s
	end)
	if ok then
		store = result
	elseif RunService:IsStudio() then
		mockMode = true
		warn("[DataService] DataStores no disponibles en Studio (publica el juego y activa "
			.. "'Enable Studio Access to API Services'). Modo SIMULADO: los datos no se guardan.")
	else
		warn("[DataService] DataStore no disponible:", result)
		store = DataStoreService:GetDataStore(STORE_NAME)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	-- Autoguardado
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in profiles do
				task.spawn(DataService.Save, player, false)
			end
		end
	end)

	-- Al cerrar el servidor: guardar a todos en paralelo
	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				DataService.Save(player, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
