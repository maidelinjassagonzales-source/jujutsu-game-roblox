-- MatchService: colas de emparejamiento y partidas (varias a la vez, cada una en su arena).
--   FFA   -> "Partida rápida": 2 a 4 jugadores, todos contra todos
--   Duel  -> "Duelo 1v1"
--   FFA3  -> Todos contra todos a 3 · FFA4 -> Todos contra todos a 4
--   Team2 -> Equipos 2 vs 2         · Team3 -> Equipos 3 vs 3
--   Los modos con Bots = true se rellenan con luchadores de la CPU si no hay gente suficiente.
-- Flujo de cada partida: votar escenario -> elegir personaje -> Countdown (congelados) -> Fighting
-- -> Results -> vuelta al Lobby.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("CombatConfig"))
local EconomyConfig = require(Shared:WaitForChild("EconomyConfig"))
local StageConfig = require(Shared:WaitForChild("StageConfig"))
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))

local MatchService = {}
MatchService.Handlers = {}

-- Teams = número de equipos (nil = todos contra todos). Max = luchadores en total (jugadores + bots).
local QUEUES = {
	FFA = { Name = "Quick match", Min = 2, Max = 4, Wait = 10, Stocks = 3 },
	Duel = { Name = "1v1 Duel", Min = 2, Max = 2, Wait = 0, Stocks = 3 },
	FFA3 = { Name = "Free-for-all · 3", Min = 1, Max = 3, Wait = 12, Stocks = 3, Bots = true },
	FFA4 = { Name = "Free-for-all · 4", Min = 1, Max = 4, Wait = 12, Stocks = 3, Bots = true },
	Team2 = { Name = "Teams 2v2", Min = 1, Max = 4, Wait = 12, Stocks = 3, Bots = true, Teams = 2 },
	Team3 = { Name = "Teams 3v3", Min = 1, Max = 6, Wait = 15, Stocks = 3, Bots = true, Teams = 2 },
}
MatchService.Queues = QUEUES

local TEAM_COLORS = { Color3.fromRGB(255, 70, 80), Color3.fromRGB(70, 150, 255) }
local TEAM_NAMES = { "Red Team", "Blue Team" }
local CHARACTER_PICK_TIME = 12 -- segundos para elegir personaje antes de la partida

local matchFeedback: RemoteEvent
local services

local queues = {} -- [modo] = array de Player
local readySince = {}
for mode in QUEUES do
	queues[mode] = {}
end
local winStreaks = {} -- [Player] = racha en este servidor

local function result(ok: boolean, msg: string)
	return { ok = ok, msg = msg }
end

local function removeFromQueues(player: Player)
	for _, list in queues do
		local i = table.find(list, player)
		if i then
			table.remove(list, i)
		end
	end
	if player.Parent then
		player:SetAttribute("Queue", nil)
		if player:GetAttribute("Activity") == "Queue" then
			player:SetAttribute("Activity", "Hub")
		end
	end
end

function MatchService.CanChangeLoadout(player: Player): boolean
	local activity = player:GetAttribute("Activity")
	return activity == "Hub" or activity == "Queue"
end

MatchService.Handlers.JoinQueue = function(player: Player, mode: any)
	if type(mode) ~= "string" or not QUEUES[mode] then
		return result(false, "Unknown mode")
	end
	local activity = player:GetAttribute("Activity")
	if activity ~= "Hub" and activity ~= "Queue" then
		return result(false, "Go back to the Lobby to find a match")
	end
	removeFromQueues(player)
	table.insert(queues[mode], player)
	player:SetAttribute("Queue", mode)
	player:SetAttribute("Activity", "Queue")
	local rules = QUEUES[mode]
	local extra = if rules.Bots then ` (if no one joins in {rules.Wait} s, bots fill the match)` else ""
	return result(true, `Buscando {rules.Name}...{extra}`)
end

function MatchService.QueueCount(mode: string): (number, number)
	local rules = QUEUES[mode]
	return #(queues[mode] or {}), if rules then rules.Max else 0
end

MatchService.Handlers.LeaveQueue = function(player: Player)
	removeFromQueues(player)
	return result(true, "You left the queue")
end

local function getHRP(model: Model?): BasePart?
	return model and model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- ===== Votación de escenario antes de cada partida
-- Cada jugador vota un escenario o "Random". Gana el más votado; si nadie vota o hay empate, al azar.
local stageVotes = {} -- [Player] = { Group = {Player}, Votes = {[Player] = stageId | "Random"} }

local function broadcastVotes(session)
	local counts = {}
	for _, choice in session.Votes do
		counts[choice] = (counts[choice] or 0) + 1
	end
	for _, p in session.Group do
		if p.Parent then
			matchFeedback:FireClient(p, "StageVotes", counts)
		end
	end
end

MatchService.Handlers.VoteStage = function(player: Player, choice: any)
	local session = stageVotes[player]
	if not session then
		return result(false, "There's no vote right now")
	end
	if choice ~= "Random" and not (type(choice) == "string" and table.find(StageConfig.MatchPool, choice)) then
		return result(false, "Unknown stage")
	end
	session.Votes[player] = choice
	broadcastVotes(session)
	return result(true, "")
end

local function chooseStage(players: { Player }): string
	local session = { Group = players, Votes = {} }
	for _, p in players do
		stageVotes[p] = session
		matchFeedback:FireClient(p, "StageVote", StageConfig.MatchPool, StageConfig.VoteTime)
	end
	local deadline = os.clock() + StageConfig.VoteTime
	while os.clock() < deadline do
		local voted = 0
		for _, p in players do
			if session.Votes[p] or not p.Parent then
				voted += 1
			end
		end
		if voted >= #players then
			task.wait(0.8) -- que se vea el último voto
			break
		end
		task.wait(0.2)
	end
	for _, p in players do
		stageVotes[p] = nil
	end
	-- Recuento
	local counts, best = {}, 0
	for _, choice in session.Votes do
		if choice ~= "Random" then
			counts[choice] = (counts[choice] or 0) + 1
			best = math.max(best, counts[choice])
		end
	end
	local winners = {}
	for id, n in counts do
		if n == best then
			table.insert(winners, id)
		end
	end
	local stageId = if #winners > 0 then winners[math.random(1, #winners)] else StageConfig.MatchPool[math.random(1, #StageConfig.MatchPool)]
	for _, p in players do
		if p.Parent then
			matchFeedback:FireClient(p, "StageChosen", stageId, #winners ~= 1)
		end
	end
	task.wait(1.6) -- revelación del escenario
	return stageId
end

-- ===== Selección de personaje antes de cada partida
-- Cada jugador elige entre los personajes que POSEE. Si no elige, va con el que tenía.
local pickSessions = {} -- [Player] = { Group, Picks = {[Player] = id} }

local function ownedCharacters(player: Player): { string }
	local data = services.DataService.Get(player)
	local list = {}
	for _, id in CharacterRegistry.GetOrder() do
		if CatalogConfig.Characters[id] and (not data or data.OwnedCharacters[id]) then
			table.insert(list, id)
		end
	end
	table.sort(list, function(a, b)
		return (CatalogConfig.Characters[a].Order or 99) < (CatalogConfig.Characters[b].Order or 99)
	end)
	return list
end

local function broadcastPicks(session)
	local ready = {}
	for p, id in session.Picks do
		table.insert(ready, { Name = p.DisplayName, CharacterId = id })
	end
	for _, p in session.Group do
		if p.Parent then
			matchFeedback:FireClient(p, "CharacterPicks", ready)
		end
	end
end

MatchService.Handlers.PickCharacter = function(player: Player, id: any)
	local session = pickSessions[player]
	if not session then
		return result(false, "Character selection isn't open right now")
	end
	if type(id) ~= "string" or not CharacterRegistry.Get(id) or not table.find(ownedCharacters(player), id) then
		return result(false, "You don't own that character")
	end
	session.Picks[player] = id
	broadcastPicks(session)
	return result(true, "")
end

local function chooseCharacters(players: { Player }, modeName: string): { [Player]: string }
	local session = { Group = players, Picks = {} }
	for _, p in players do
		pickSessions[p] = session
		matchFeedback:FireClient(p, "CharacterSelect", ownedCharacters(p),
			p:GetAttribute("SelectedCharacter") or Config.DefaultCharacter, CHARACTER_PICK_TIME, modeName)
	end
	local deadline = os.clock() + CHARACTER_PICK_TIME
	while os.clock() < deadline do
		local done = 0
		for _, p in players do
			if session.Picks[p] or not p.Parent then
				done += 1
			end
		end
		if done >= #players then
			task.wait(0.8)
			break
		end
		task.wait(0.2)
	end
	local picks = {}
	for _, p in players do
		pickSessions[p] = nil
		if p.Parent then
			picks[p] = session.Picks[p] or p:GetAttribute("SelectedCharacter") or Config.DefaultCharacter
			matchFeedback:FireClient(p, "CharacterSelectEnd", picks[p])
		end
	end
	return picks
end

-- ===== Bots (CPU)
local function randomCharacter(): string
	local ids = {}
	for _, id in CharacterRegistry.GetOrder() do
		if CatalogConfig.Characters[id] then
			table.insert(ids, id)
		end
	end
	return ids[math.random(1, #ids)]
end

local function teamOutline(model: Model, team: number?)
	local old = model:FindFirstChild("TeamOutline")
	if old then
		old:Destroy()
	end
	if not team or not TEAM_COLORS[team] then
		return
	end
	local h = Instance.new("Highlight")
	h.Name = "TeamOutline"
	h.FillTransparency = 1
	h.OutlineColor = TEAM_COLORS[team]
	h.OutlineTransparency = 0.1
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = model
end

-- ===== Partida
local function runMatch(players: { Player }, mode: string, state)
	local rules = QUEUES[mode]
	local isTeams = rules.Teams ~= nil

	local stageId = chooseStage(players)
	local picks = chooseCharacters(players, rules.Name)
	-- Guardar la elección ANTES de entrar en la arena: así el personaje ya aparece con el elegido
	for p, id in picks do
		if p.Parent and id ~= p:GetAttribute("SelectedCharacter") then
			services.DataService.Update(p, function(d)
				d.SelectedCharacter = id
			end)
		end
	end
	for i = #players, 1, -1 do
		if not players[i].Parent then
			table.remove(players, i)
		end
	end
	if #players == 0 then
		return
	end

	local arena = services.ArenaService.Allocate(stageId, "Match")
	state.Arena = arena
	if not arena then
		for _, p in players do
			if p.Parent then
				services.EconomyFeedback:FireClient(p, "Reward", { Reason = "Server full, try again" })
			end
		end
		return
	end

	-- Participantes: jugadores y bots. Entry = { Player?, Model, Bot, Team, KOs, EliminatedAt, Name }
	local entries = {}
	local function modelOf(e)
		if e.Player then
			return e.Player.Character
		end
		return e.Model
	end
	local function entryFor(model: Model)
		local player = Players:GetPlayerFromCharacter(model)
		for _, e in entries do
			if (player and e.Player == player) or e.Model == model then
				return e
			end
		end
		return nil
	end

	-- Equipos: los jugadores se reparten alternando; los bots rellenan los huecos
	local teamCount = { 0, 0 }
	local teamSize = if isTeams then rules.Max // rules.Teams else 1
	for i, player in players do
		local team = if isTeams then ((i - 1) % rules.Teams) + 1 else i
		if isTeams and teamCount[team] >= teamSize then
			team = if team == 1 then 2 else 1
		end
		if isTeams then
			teamCount[team] += 1
		end
		table.insert(entries, { Player = player, Team = team, KOs = 0, Name = player.DisplayName })
	end
	local botCount = if rules.Bots then math.max(0, rules.Max - #players) else 0
	for b = 1, botCount do
		local team
		if isTeams then
			team = if teamCount[1] <= teamCount[2] then 1 else 2
			teamCount[team] += 1
		else
			team = #players + b
		end
		table.insert(entries, { Bot = true, Team = team, KOs = 0, Name = `CPU {b}` })
	end
	-- Equipo 1 primero (para la presentación VS y los puntos de salida)
	if isTeams then
		table.sort(entries, function(a, b)
			if a.Team ~= b.Team then
				return a.Team < b.Team
			end
			return a.Bot ~= true and b.Bot == true
		end)
	end

	local info = arena.Info
	arena.Handler = {
		OnKO = function(model: Model, stocks: number, killer: Model?)
			local killerEntry = killer and entryFor(killer)
			if killerEntry then
				killerEntry.KOs += 1
			end
			local e = entryFor(model)
			if e and stocks <= 0 then
				e.EliminatedAt = os.clock()
				return "eliminate"
			end
			return "respawn"
		end,
	}

	-- Puntos de salida: en equipos, el equipo 1 a la izquierda (1,3,5) y el 2 a la derecha (2,4,6)
	local slotUsed = { 0, 0 }
	local function spawnIndex(e, i: number): number
		if not isTeams then
			return i
		end
		slotUsed[e.Team] += 1
		return (slotUsed[e.Team] - 1) * 2 + e.Team
	end

	-- Entrada: cuenta atrás congelados en sus puntos de salida
	info:SetAttribute("MatchState", "Countdown")
	info:SetAttribute("EndsAt", os.time() + Config.CountdownTime)
	for i, e in entries do
		local index = spawnIndex(e, i)
		local model
		if e.Bot then
			local characterId = randomCharacter()
			local data = CharacterRegistry.Get(characterId)
			model = services.NPCService.Spawn(arena, {
				Character = characterId, Name = `CPU · {data and data.DisplayName or characterId}`,
				Level = math.random(2, 3), Stocks = rules.Stocks,
			}, index)
			model:SetAttribute("MatchBot", true)
			table.insert(state.Bots, model)
			e.Model = model
			e.Name = model:GetAttribute("DisplayName") or e.Name
		else
			local player = e.Player
			player:SetAttribute("Queue", nil)
			services.FighterService.SetZone(player, arena.Id, "Arena", "Match")
			-- Si venía del Dojo ya era un luchador: se recrea con el personaje elegido.
			-- (Un personaje recién creado aún no tiene CharacterId: ese ya sale con el elegido.)
			local current = player.Character
			local currentId = current and current:GetAttribute("CharacterId")
			if currentId ~= nil and picks[player] and currentId ~= picks[player] then
				services.FighterService.SpawnCharacter(player, true)
			end
			model = player.Character
		end
		if model then
			services.CombatService.ClearState(model)
			model:SetAttribute("Team", e.Team)
			model:SetAttribute("Percent", 0)
			model:SetAttribute("Stocks", rules.Stocks)
			model:SetAttribute("Eliminated", false)
			model:SetAttribute("KOing", false)
			services.UltimateService.Reset(model)
			services.FighterService.TeleportToSpawn(model, index)
			teamOutline(model, if isTeams then e.Team else nil)
			local hrp = getHRP(model)
			if hrp then
				hrp.Anchored = true
			end
		end
	end

	local roster = {}
	for _, e in entries do
		local model = modelOf(e)
		table.insert(roster, {
			Name = if isTeams then `{e.Name} ({TEAM_NAMES[e.Team]})` else e.Name,
			UserId = if e.Player then e.Player.UserId else 0,
			CharacterId = (e.Player and picks[e.Player]) or (model and model:GetAttribute("CharacterId")) or Config.DefaultCharacter,
		})
	end
	for _, e in entries do
		if e.Player and e.Player.Parent then
			matchFeedback:FireClient(e.Player, "Countdown", Config.CountdownTime, StageConfig.Stages[stageId].Name, rules.Name, roster)
		end
	end
	task.wait(Config.CountdownTime)

	-- Combate
	info:SetAttribute("MatchState", "Fighting")
	info:SetAttribute("EndsAt", os.time() + Config.MatchDuration)
	for _, e in entries do
		local hrp = getHRP(modelOf(e))
		if hrp then
			hrp.Anchored = false
		end
		if e.Player and e.Player.Parent then
			matchFeedback:FireClient(e.Player, "Start")
		end
	end

	local function isAlive(e): boolean
		if e.EliminatedAt then
			return false
		end
		if e.Player then
			return e.Player.Parent ~= nil and e.Player.Character ~= nil
		end
		return e.Model ~= nil and e.Model.Parent ~= nil
	end

	local deadline = os.clock() + Config.MatchDuration
	while os.clock() < deadline do
		local aliveTeams, teamSeen, humansAlive = 0, {}, 0
		for _, e in entries do
			if isAlive(e) then
				if not teamSeen[e.Team] then
					teamSeen[e.Team] = true
					aliveTeams += 1
				end
				if e.Player then
					humansAlive += 1
				end
			end
		end
		-- Se acaba cuando queda un solo equipo/luchador, o cuando ya no queda ningún jugador vivo
		if aliveTeams <= 1 or humansAlive == 0 then
			break
		end
		task.wait(0.25)
	end

	-- Clasificación
	local function stocksOf(e): number
		local m = modelOf(e)
		return if isAlive(e) and m then m:GetAttribute("Stocks") or 0 else 0
	end
	local function percentOf(e): number
		local m = modelOf(e)
		return m and m:GetAttribute("Percent") or 0
	end
	local winningTeam = nil
	if isTeams then
		-- Gana el equipo con más vidas en total (empate: menos % acumulado)
		local score = { { Stocks = 0, Percent = 0 }, { Stocks = 0, Percent = 0 } }
		for _, e in entries do
			if isAlive(e) then
				score[e.Team].Stocks += stocksOf(e)
				score[e.Team].Percent += percentOf(e)
			end
		end
		if score[1].Stocks ~= score[2].Stocks then
			winningTeam = if score[1].Stocks > score[2].Stocks then 1 else 2
		else
			winningTeam = if score[1].Percent <= score[2].Percent then 1 else 2
		end
	end

	local ranking = {}
	for _, e in entries do
		local m = modelOf(e)
		if m and (not e.Player or e.Player.Parent) then
			table.insert(ranking, { Entry = e, Model = m })
		end
	end
	table.sort(ranking, function(a, b)
		local ea, eb = a.Entry, b.Entry
		if isTeams and ea.Team ~= eb.Team then
			return ea.Team == winningTeam
		end
		local aAlive, bAlive = isAlive(ea), isAlive(eb)
		if aAlive ~= bAlive then
			return aAlive
		end
		if isTeams then
			return ea.KOs > eb.KOs
		end
		if aAlive then
			local aS, bS = stocksOf(ea), stocksOf(eb)
			if aS ~= bS then
				return aS > bS
			end
			return percentOf(ea) < percentOf(eb)
		end
		return (ea.EliminatedAt or 0) > (eb.EliminatedAt or 0)
	end)

	-- ¡GAME!: zoom al ganador antes de la pantalla de resultados
	local winner = ranking[1]
	info:SetAttribute("MatchState", "Finish")
	for _, e in entries do
		if e.Player and e.Player.Parent then
			matchFeedback:FireClient(e.Player, "Finish", winner and winner.Model)
		end
	end
	task.wait(2.6)

	info:SetAttribute("MatchState", "Results")
	info:SetAttribute("EndsAt", os.time() + Config.ResultsTime)
	local summary, winners = {}, {}
	for i, entry in ranking do
		local e = entry.Entry
		local won = if isTeams then e.Team == winningTeam else i == 1
		if won and e.Player then
			table.insert(winners, e.Player.UserId)
		end
		table.insert(summary, {
			Name = if isTeams then `{e.Name} · {TEAM_NAMES[e.Team]}` else e.Name,
			UserId = if e.Player then e.Player.UserId else 0,
			CharacterId = entry.Model:GetAttribute("CharacterId"), KOs = e.KOs, Place = i, Team = if isTeams then e.Team else nil,
		})
	end

	local humansInMatch = 0
	for _, entry in ranking do
		if entry.Entry.Player then
			humansInMatch += 1
		end
	end
	for i, entry in ranking do
		local player = entry.Entry.Player
		if player then
			local won = (if isTeams then entry.Entry.Team == winningTeam else i == 1) and #ranking > 1
			winStreaks[player] = if won then (winStreaks[player] or 0) + 1 else 0
			local reward = if won then EconomyConfig.Rewards.Win else EconomyConfig.Rewards.Participation
			services.EconomyService.GrantCombatReward(player, reward.Coins, reward.XP, if won then "Victory" else "Match", true)
			services.DataService.Update(player, function(data)
				data.Stats.Matches += 1
				if won then
					data.Stats.Wins += 1
					data.Stats.BestStreak = math.max(data.Stats.BestStreak, winStreaks[player])
				end
			end)
			services.DataService.PushState(player)
			services.QuestService.Add(player, "Matches", 1)
			if won then
				services.QuestService.Add(player, "Wins", 1)
			end
		end
	end

	local winnerPlayer = winner and winner.Entry.Player
	if winnerPlayer and #ranking > 1 then
		services.LobbyService.SetChampion(winnerPlayer, winner.Model, winStreaks[winnerPlayer] or 1)
	end
	local payload = {
		WinnerModel = winner and winner.Model,
		WinnerName = if isTeams and winningTeam then TEAM_NAMES[winningTeam] else (winner and winner.Entry.Name),
		WinnerUserId = winnerPlayer and winnerPlayer.UserId,
		WinnerCharacterId = winner and winner.Model:GetAttribute("CharacterId"),
		WinnerSkinId = winner and winner.Model:GetAttribute("SkinId"),
		WinnerTitle = winner and winner.Model:GetAttribute("Title"),
		Winners = winners, -- UserIds de todos los ganadores (en equipos, todo el equipo)
		WinningTeam = winningTeam,
		Streak = winnerPlayer and winStreaks[winnerPlayer] or 0,
		Ranking = summary,
		Mode = rules.Name,
	}
	for _, e in entries do
		if e.Player and e.Player.Parent then
			matchFeedback:FireClient(e.Player, "Results", payload)
		end
	end
	task.wait(Config.ResultsTime)

	for _, e in entries do
		if e.Bot then
			if e.Model then
				e.Model:Destroy()
			end
		elseif e.Player.Parent then
			local m = e.Player.Character
			if m then
				m:SetAttribute("Team", nil)
				teamOutline(m, nil)
			end
			if e.Player:GetAttribute("ArenaId") == arena.Id then
				services.FighterService.SendToHub(e.Player)
			end
		end
	end
	services.ArenaService.Release(arena)
	state.Arena = nil
end

function MatchService.Start(remotes: Folder, s)
	services = s
	matchFeedback = remotes:WaitForChild("MatchFeedback")

	Players.PlayerRemoving:Connect(function(player)
		removeFromQueues(player)
		stageVotes[player] = nil
		pickSessions[player] = nil
		winStreaks[player] = nil
	end)

	-- Emparejador: cada segundo mira si alguna cola puede arrancar
	task.spawn(function()
		while true do
			task.wait(1)
			for mode, rules in QUEUES do
				local list = queues[mode]
				for i = #list, 1, -1 do
					local p = list[i]
					if not p.Parent or p:GetAttribute("Activity") ~= "Queue" or not p.Character then
						table.remove(list, i)
					end
				end
				if #list >= rules.Min then
					readySince[mode] = readySince[mode] or os.clock()
					if #list >= rules.Max or os.clock() - readySince[mode] >= rules.Wait then
						local group = {}
						for _ = 1, math.min(rules.Max, #list) do
							table.insert(group, table.remove(list, 1))
						end
						readySince[mode] = nil
						task.spawn(function()
							local state = { Bots = {}, Arena = nil }
							local ok, err = pcall(runMatch, group, mode, state)
							if not ok then
								warn("[MatchService] Error en la partida:", err)
								for _, bot in state.Bots do
									bot:Destroy()
								end
								for _, p in group do
									if p.Parent then
										if p.Character then
											p.Character:SetAttribute("Team", nil)
										end
										services.FighterService.SendToHub(p)
									end
								end
								if state.Arena then
									services.ArenaService.Release(state.Arena)
								end
							end
						end)
					end
				else
					readySince[mode] = nil
				end
			end
		end
	end)
end

return MatchService
