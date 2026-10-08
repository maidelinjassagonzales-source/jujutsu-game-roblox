-- StoryService: modo historia en solitario. Cada capítulo usa su propia arena.
-- Flujo: diálogo de entrada -> oleadas de enemigos con IA -> diálogo final + recompensas.
-- Si el jugador pierde sus 3 stocks puede REVIVIR pagando gemas (o rendirse).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StoryConfig = require(Shared:WaitForChild("StoryConfig"))

local StoryService = {}
StoryService.Handlers = {}

local services
local matchFeedback: RemoteEvent

local sessions = {} -- [Player] = session

local function result(ok: boolean, msg: string)
	return { ok = ok, msg = msg }
end

local function getHRP(model: Model?): BasePart?
	return model and model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function waitFor(session, flagName: string, timeout: number)
	local deadline = os.clock() + timeout
	while not session[flagName] and session.Player.Parent and not session.Ended and os.clock() < deadline do
		task.wait(0.1)
	end
end

local function playDialogue(session, part: string)
	local player = session.Player
	session.DialogueDone = false
	local hrp = getHRP(player.Character)
	if hrp then
		hrp.Anchored = true
	end
	matchFeedback:FireClient(player, "Dialogue", session.Chapter.Id, part)
	waitFor(session, "DialogueDone", 180)
	hrp = getHRP(player.Character)
	if hrp then
		hrp.Anchored = false
	end
end

local function cleanupEnemies(session)
	for _, npc in session.Enemies do
		if npc.Parent then
			npc:Destroy()
		end
	end
	session.Enemies = {}
end

local function resetPlayerFighter(session, spawnIndex: number)
	local model = session.Player.Character
	if not model then
		return
	end
	services.CombatService.ClearState(model)
	model:SetAttribute("Percent", 0)
	model:SetAttribute("Stocks", StoryConfig.PlayerStocks)
	model:SetAttribute("Eliminated", false)
	model:SetAttribute("KOing", false)
	services.FighterService.TeleportToSpawn(model, spawnIndex)
	local hrp = getHRP(model)
	if hrp then
		hrp.Anchored = false
	end
end

local function runChapter(player: Player, chapter)
	local arena = services.ArenaService.Allocate(chapter.Stage, "Story")
	if not arena then
		matchFeedback:FireClient(player, "StoryResult", { Won = false, Chapter = chapter.Id, Reason = "Servidor lleno, inténtalo en un momento" })
		sessions[player] = nil
		return
	end

	local session = { Player = player, Chapter = chapter, Arena = arena, Enemies = {}, Lost = false, Ended = false }
	sessions[player] = session
	arena.Info:SetAttribute("MatchState", "Story")

	arena.Handler = {
		OnKO = function(model: Model, stocks: number)
			if model == player.Character then
				if stocks <= 0 then
					session.Lost = true
					return "eliminate"
				end
				return "respawn"
			end
			-- Enemigo
			if stocks <= 0 then
				local i = table.find(session.Enemies, model)
				if i then
					table.remove(session.Enemies, i)
				end
				task.delay(0.3, function()
					model:Destroy()
				end)
				return "remove"
			end
			return "respawn"
		end,
	}

	services.FighterService.SetZone(player, arena.Id, "Arena", "Story")
	resetPlayerFighter(session, 1)
	playDialogue(session, "Intro")

	local won = true
	for waveIndex, wave in chapter.Waves do
		if not player.Parent or session.Ended then
			won = false
			break
		end
		matchFeedback:FireClient(player, "Wave", waveIndex, #chapter.Waves)
		for i, spec in wave do
			table.insert(session.Enemies, services.NPCService.Spawn(arena, spec, 1 + i))
		end
		-- Esperar a que caigan todos (o a que el jugador pierda)
		while #session.Enemies > 0 and player.Parent and not session.Ended do
			if session.Lost then
				-- Ofrecer revivir con gemas
				session.ReviveChoice = nil
				matchFeedback:FireClient(player, "StoryDefeat", StoryConfig.ReviveGems)
				waitFor(session, "ReviveChoice", 30)
				if session.ReviveChoice == "revive" then
					session.Lost = false
					resetPlayerFighter(session, 1)
				else
					break
				end
			end
			task.wait(0.25)
		end
		if session.Lost or not player.Parent or session.Ended then
			won = false
			break
		end
		task.wait(1)
	end

	cleanupEnemies(session)
	if not player.Parent then
		services.ArenaService.Release(arena)
		sessions[player] = nil
		return
	end

	local payload = { Won = won, Chapter = chapter.Id }
	if won then
		local data = services.DataService.Get(player)
		local firstClear = data and not data.Story.Completed[tostring(chapter.Id)]
		local mult = if firstClear then 1 else StoryConfig.ReplayRewardMultiplier
		local reward = chapter.Reward
		services.EconomyService.GrantCombatReward(player, math.floor(reward.Coins * mult), math.floor(reward.XP * mult), "Historia", true)
		if firstClear and reward.Gems then
			services.EconomyService.AddCurrency(player, "Gems", reward.Gems, `Historia:{chapter.Id}`)
		end
		services.DataService.Update(player, function(d)
			d.Story.Completed[tostring(chapter.Id)] = true
			d.Story.Unlocked = math.max(d.Story.Unlocked, math.min(chapter.Id + 1, #StoryConfig.Chapters))
			d.Stats.StoryClears += 1
			if firstClear and reward.Skin then
				d.OwnedSkins[reward.Skin] = true
			end
			if firstClear and reward.Title then
				d.OwnedTitles[reward.Title] = true
			end
		end)
		services.DataService.PushState(player)
		payload.FirstClear = firstClear
		payload.Coins = math.floor(reward.Coins * mult)
		payload.XP = math.floor(reward.XP * mult)
		payload.Gems = if firstClear then reward.Gems else nil
		payload.Skin = if firstClear then reward.Skin else nil
		playDialogue(session, "Outro")
	end
	matchFeedback:FireClient(player, "StoryResult", payload)
	task.wait(2.5)

	session.Ended = true
	if player.Parent then
		services.FighterService.SendToHub(player)
	end
	services.ArenaService.Release(arena)
	sessions[player] = nil
end

StoryService.Handlers.StartChapter = function(player: Player, chapterId: any)
	if type(chapterId) ~= "number" then
		return result(false, "Capítulo inválido")
	end
	local chapter = StoryConfig.Get(chapterId)
	local data = services.DataService.Get(player)
	if not chapter or not data then
		return result(false, "Capítulo inválido")
	end
	if chapterId > data.Story.Unlocked then
		return result(false, "Completa el capítulo anterior primero")
	end
	if player:GetAttribute("Activity") ~= "Hub" then
		return result(false, "Vuelve al Lobby para empezar un capítulo")
	end
	if sessions[player] then
		return result(false, "Ya estás en un capítulo")
	end
	sessions[player] = { Pending = true }
	task.spawn(function()
		local ok, err = pcall(runChapter, player, chapter)
		if not ok then
			warn("[StoryService] Error en el capítulo:", err)
			sessions[player] = nil
			if player.Parent then
				services.FighterService.SendToHub(player)
			end
		end
	end)
	return result(true, `Capítulo {chapterId}: {chapter.Title}`)
end

StoryService.Handlers.DialogueDone = function(player: Player)
	local session = sessions[player]
	if session then
		session.DialogueDone = true
	end
	return result(true, "")
end

-- choice = "revive" (paga gemas) | "quit"
StoryService.Handlers.StoryRevive = function(player: Player, choice: any)
	local session = sessions[player]
	if not session or not session.Lost then
		return result(false, "No hay nada que revivir")
	end
	if choice == "revive" then
		if not services.EconomyService.SpendCurrency(player, "Gems", StoryConfig.ReviveGems, "Historia:Revivir") then
			return result(false, "No tienes suficientes Gemas")
		end
		session.ReviveChoice = "revive"
		return result(true, "¡Has revivido!")
	end
	session.ReviveChoice = "quit"
	return result(true, "Te has rendido")
end

StoryService.Handlers.QuitStory = function(player: Player)
	local session = sessions[player]
	if session and not session.Pending then
		session.Ended = true
		session.ReviveChoice = "quit"
	end
	return result(true, "Has abandonado el capítulo")
end

function StoryService.Start(remotes: Folder, s)
	services = s
	matchFeedback = remotes:WaitForChild("MatchFeedback")
	Players.PlayerRemoving:Connect(function(player)
		local session = sessions[player]
		if session then
			session.Ended = true
		end
	end)
end

return StoryService
