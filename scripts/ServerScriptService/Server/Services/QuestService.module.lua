-- QuestService: MISIONES DIARIAS. Los demás servicios avisan con QuestService.Add(player, tipo, cantidad).
--   ClaimQuest(i)       -> cobrar una misión completada
--   ClaimQuestBonus     -> cofre extra al completar las 3
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("QuestConfig"))

local QuestService = {}
QuestService.Handlers = {}

local services
local dirty = {} -- [Player] = true -> hay que mandar el estado (se agrupa para no saturar)

local function result(ok: boolean, msg: string)
	return { ok = ok, msg = msg }
end

local function today(): number
	return math.floor(os.time() / 86400)
end

-- Genera las misiones del día si ha cambiado el día
local function ensure(player: Player)
	local data = services.DataService.Get(player)
	if not data then
		return nil
	end
	if data.Quests.Day ~= today() then
		local ids = QuestConfig.ForDay(today(), player.UserId)
		services.DataService.Update(player, function(d)
			d.Quests.Day = today()
			d.Quests.BonusClaimed = false
			d.Quests.List = {}
			for _, id in ids do
				table.insert(d.Quests.List, { Id = id, Progress = 0, Claimed = false })
			end
		end)
		dirty[player] = true
	end
	return data
end

local function grantText(player: Player, reward, reason: string): string
	local parts = {}
	if reward.Coins then
		services.EconomyService.AddCurrency(player, "Coins", reward.Coins, reason)
		table.insert(parts, `+{reward.Coins} 呪`)
	end
	if reward.Gems then
		services.EconomyService.AddCurrency(player, "Gems", reward.Gems, reason)
		table.insert(parts, `+{reward.Gems} 晶`)
	end
	if reward.XP then
		services.EconomyService.AddXP(player, reward.XP)
		table.insert(parts, `+{reward.XP} XP`)
	end
	return table.concat(parts, "  ")
end

-- Suma progreso a las misiones de ese tipo (se llama desde combate, partidas, obby, ruleta...)
function QuestService.Add(player: Player?, kind: string, amount: number?)
	if not player or not player.Parent then
		return
	end
	local data = ensure(player)
	if not data then
		return
	end
	for _, entry in data.Quests.List do
		local quest = QuestConfig.Get(entry.Id)
		if quest and quest.Kind == kind and entry.Progress < quest.Goal then
			local before = entry.Progress
			services.DataService.Update(player, function()
				entry.Progress = math.min(quest.Goal, entry.Progress + (amount or 1))
			end)
			dirty[player] = true
			if before < quest.Goal and entry.Progress >= quest.Goal then
				services.EconomyFeedback:FireClient(player, "Reward", { Reason = `Quest completed: {quest.Text}! Claim it in Quests` })
			end
		end
	end
end

QuestService.Handlers.GetQuests = function(player: Player)
	ensure(player)
	services.DataService.PushState(player)
	return result(true, "")
end

QuestService.Handlers.ClaimQuest = function(player: Player, index: any)
	local data = ensure(player)
	if not data or type(index) ~= "number" then
		return result(false, "")
	end
	local entry = data.Quests.List[index]
	local quest = entry and QuestConfig.Get(entry.Id)
	if not quest then
		return result(false, "Unknown quest")
	end
	if entry.Claimed then
		return result(false, "You already claimed it")
	end
	if entry.Progress < quest.Goal then
		return result(false, "You haven't completed it yet")
	end
	services.DataService.Update(player, function()
		entry.Claimed = true
	end)
	local text = grantText(player, quest.Reward, `Mision:{quest.Id}`)
	services.DataService.PushState(player)
	return result(true, `Quest claimed: {text}`)
end

QuestService.Handlers.ClaimQuestBonus = function(player: Player)
	local data = ensure(player)
	if not data then
		return result(false, "")
	end
	if data.Quests.BonusClaimed then
		return result(false, "You already opened today's chest")
	end
	for _, entry in data.Quests.List do
		if not entry.Claimed then
			return result(false, "Claim the 3 quests first")
		end
	end
	services.DataService.Update(player, function(d)
		d.Quests.BonusClaimed = true
	end)
	local text = grantText(player, QuestConfig.AllDoneBonus, "Mision:Cofre")
	services.DataService.PushState(player)
	return result(true, `Quest chest! {text}`)
end

function QuestService.Start(s)
	services = s
	-- KOs y daño (solo cuentan los jugadores)
	services.KOService.OnKO(function(_victim: Model, killer: Model?)
		QuestService.Add(killer and Players:GetPlayerFromCharacter(killer), "KOs", 1)
	end)
	services.CombatService.OnHit(function(attacker: Model, _victim: Model, damage: number)
		QuestService.Add(Players:GetPlayerFromCharacter(attacker), "Damage", math.floor(damage + 0.5))
	end)
	services.CombatService.OnMoveStarted(function(model: Model, key: string)
		if key:find("Special") then
			QuestService.Add(Players:GetPlayerFromCharacter(model), "Specials", 1)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		dirty[player] = nil
	end)
	-- El progreso se manda agrupado (el daño cuenta en cada golpe)
	task.spawn(function()
		while true do
			task.wait(2)
			for player in dirty do
				dirty[player] = nil
				if player.Parent then
					services.DataService.PushState(player)
				end
			end
		end
	end)
end

return QuestService
