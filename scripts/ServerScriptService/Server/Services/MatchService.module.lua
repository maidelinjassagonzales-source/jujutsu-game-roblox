-- MatchService: colas de emparejamiento y partidas (varias a la vez, cada una en su arena).
--   FFA  -> "Partida rápida": 2 a 4 jugadores, todos contra todos
--   Duel -> "Duelo 1v1"
-- Flujo de cada partida: Countdown (congelados) -> Fighting -> Results -> vuelta al Lobby.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("CombatConfig"))
local EconomyConfig = require(Shared:WaitForChild("EconomyConfig"))
local StageConfig = require(Shared:WaitForChild("StageConfig"))

local MatchService = {}
MatchService.Handlers = {}

local QUEUES = {
	FFA = { Name = "Partida rápida", Min = 2, Max = 4, Wait = 10, Stocks = 3 },
	Duel = { Name = "Duelo 1v1", Min = 2, Max = 2, Wait = 0, Stocks = 3 },
}

local matchFeedback: RemoteEvent
local services

local queues = { FFA = {}, Duel = {} } -- arrays de Player
local readySince = { FFA = nil, Duel = nil }
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
		return result(false, "Modo desconocido")
	end
	local activity = player:GetAttribute("Activity")
	if activity ~= "Hub" and activity ~= "Queue" then
		return result(false, "Vuelve al Lobby para buscar partida")
	end
	removeFromQueues(player)
	table.insert(queues[mode], player)
	player:SetAttribute("Queue", mode)
	player:SetAttribute("Activity", "Queue")
	return result(true, `Buscando {QUEUES[mode].Name}...`)
end

function MatchService.QueueCount(mode: string): (number, number)
	local rules = QUEUES[mode]
	return #(queues[mode] or {}), if rules then rules.Max else 0
end

MatchService.Handlers.LeaveQueue = function(player: Player)
	removeFromQueues(player)
	return result(true, "Has salido de la cola")
end

local function getHRP(model: Model?): BasePart?
	return model and model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function runMatch(players: { Player }, mode: string)
	local rules = QUEUES[mode]
	local stageId = StageConfig.MatchPool[math.random(1, #StageConfig.MatchPool)]
	local arena = services.ArenaService.Allocate(stageId, "Match")
	if not arena then
		for _, p in players do
			if p.Parent then
				services.EconomyFeedback:FireClient(p, "Reward", { Reason = "Servidor lleno, vuelve a intentarlo" })
			end
		end
		return
	end

	local participants = {} -- [Player] = { KOs, EliminatedAt }
	local info = arena.Info
	arena.Handler = {
		OnKO = function(model: Model, stocks: number, killer: Model?)
			local killerPlayer = killer and Players:GetPlayerFromCharacter(killer)
			if killerPlayer and participants[killerPlayer] then
				participants[killerPlayer].KOs += 1
			end
			local player = Players:GetPlayerFromCharacter(model)
			if player and participants[player] and stocks <= 0 then
				participants[player].EliminatedAt = os.clock()
				return "eliminate"
			end
			return "respawn"
		end,
	}

	-- Entrada: cuenta atrás congelados en sus puntos de salida
	info:SetAttribute("MatchState", "Countdown")
	info:SetAttribute("EndsAt", os.time() + Config.CountdownTime)
	local roster = {}
	for _, player in players do
		table.insert(roster, { Name = player.DisplayName, UserId = player.UserId, CharacterId = player:GetAttribute("SelectedCharacter") or Config.DefaultCharacter })
	end
	for i, player in players do
		participants[player] = { KOs = 0 }
		player:SetAttribute("Queue", nil)
		services.FighterService.SetZone(player, arena.Id, "Arena", "Match")
		local model = player.Character
		if model then
			services.CombatService.ClearState(model)
			model:SetAttribute("Percent", 0)
			model:SetAttribute("Stocks", rules.Stocks)
			model:SetAttribute("Eliminated", false)
			model:SetAttribute("KOing", false)
			services.UltimateService.Reset(model)
			services.FighterService.TeleportToSpawn(model, i)
			local hrp = getHRP(model)
			if hrp then
				hrp.Anchored = true
			end
		end
		matchFeedback:FireClient(player, "Countdown", Config.CountdownTime, StageConfig.Stages[stageId].Name, rules.Name, roster)
	end
	task.wait(Config.CountdownTime)

	-- Combate
	info:SetAttribute("MatchState", "Fighting")
	info:SetAttribute("EndsAt", os.time() + Config.MatchDuration)
	for player in participants do
		local hrp = getHRP(player.Character)
		if hrp then
			hrp.Anchored = false
		end
		if player.Parent then
			matchFeedback:FireClient(player, "Start")
		end
	end

	local deadline = os.clock() + Config.MatchDuration
	while os.clock() < deadline do
		local alive = 0
		for player, info2 in participants do
			if player.Parent and player.Character and not info2.EliminatedAt then
				alive += 1
			end
		end
		if alive <= 1 then
			break
		end
		task.wait(0.25)
	end

	-- Clasificación: vivos primero (más stocks, menos %), luego orden inverso de eliminación
	local ranking = {}
	for player, pinfo in participants do
		if player.Parent and player.Character then
			table.insert(ranking, { Player = player, Info = pinfo, Model = player.Character })
		end
	end
	table.sort(ranking, function(a, b)
		local aAlive, bAlive = not a.Info.EliminatedAt, not b.Info.EliminatedAt
		if aAlive ~= bAlive then
			return aAlive
		end
		if aAlive then
			local aS, bS = a.Model:GetAttribute("Stocks") or 0, b.Model:GetAttribute("Stocks") or 0
			if aS ~= bS then
				return aS > bS
			end
			return (a.Model:GetAttribute("Percent") or 0) < (b.Model:GetAttribute("Percent") or 0)
		end
		return a.Info.EliminatedAt > b.Info.EliminatedAt
	end)

	-- ¡GAME!: zoom al ganador antes de la pantalla de resultados
	local winner = ranking[1]
	info:SetAttribute("MatchState", "Finish")
	for player in participants do
		if player.Parent then
			matchFeedback:FireClient(player, "Finish", winner and winner.Model)
		end
	end
	task.wait(2.6)

	info:SetAttribute("MatchState", "Results")
	info:SetAttribute("EndsAt", os.time() + Config.ResultsTime)
	local summary = {}
	for i, entry in ranking do
		table.insert(summary, {
			Name = entry.Player.DisplayName, UserId = entry.Player.UserId,
			CharacterId = entry.Model:GetAttribute("CharacterId"), KOs = entry.Info.KOs, Place = i,
		})
	end

	for i, entry in ranking do
		local player = entry.Player
		local won = i == 1 and #ranking > 1
		winStreaks[player] = if won then (winStreaks[player] or 0) + 1 else 0
		local reward = if won then EconomyConfig.Rewards.Win else EconomyConfig.Rewards.Participation
		services.EconomyService.GrantCombatReward(player, reward.Coins, reward.XP, if won then "Victoria" else "Partida", true)
		services.DataService.Update(player, function(data)
			data.Stats.Matches += 1
			if won then
				data.Stats.Wins += 1
				data.Stats.BestStreak = math.max(data.Stats.BestStreak, winStreaks[player])
			end
		end)
		services.DataService.PushState(player)
	end

	if winner and #ranking > 1 then
		services.LobbyService.SetChampion(winner.Player, winner.Model, winStreaks[winner.Player] or 1)
	end
	local payload = {
		WinnerModel = winner and winner.Model,
		WinnerName = winner and winner.Player.DisplayName,
		WinnerUserId = winner and winner.Player.UserId,
		WinnerCharacterId = winner and winner.Model:GetAttribute("CharacterId"),
		WinnerSkinId = winner and winner.Model:GetAttribute("SkinId"),
		WinnerTitle = winner and winner.Model:GetAttribute("Title"),
		Streak = winner and winStreaks[winner.Player] or 0,
		Ranking = summary,
		Mode = rules.Name,
	}
	for player in participants do
		if player.Parent then
			matchFeedback:FireClient(player, "Results", payload)
		end
	end
	task.wait(Config.ResultsTime)

	for player in participants do
		if player.Parent and player:GetAttribute("ArenaId") == arena.Id then
			services.FighterService.SendToHub(player)
		end
	end
	services.ArenaService.Release(arena)
end

function MatchService.Start(remotes: Folder, s)
	services = s
	matchFeedback = remotes:WaitForChild("MatchFeedback")

	Players.PlayerRemoving:Connect(function(player)
		removeFromQueues(player)
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
							local ok, err = pcall(runMatch, group, mode)
							if not ok then
								warn("[MatchService] Error en la partida:", err)
								for _, p in group do
									if p.Parent then
										services.FighterService.SendToHub(p)
									end
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
