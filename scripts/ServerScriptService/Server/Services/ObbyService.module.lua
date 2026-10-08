-- ObbyService: la obby "Ascenso Maldito" (se construye con ObbyBuilder lejos del patio del Lobby).
--   EnterObby / LeaveObby   -> entrar desde el portal del Lobby / volver
--   ObbyCheckpoint(i)       -> el servidor comprueba que de verdad estás en el checkpoint i (en orden)
--   ObbyRespawn             -> volver al último checkpoint
--   ObbyFinish              -> meta: premio una vez al día + mejor tiempo (con comprobaciones anti-trampas)
-- Lo que se mueve y las caídas lo gestiona el cliente (ObbyController), que te devuelve al checkpoint.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local ObbyBuilder = require(script.Parent.Parent:WaitForChild("Builders"):WaitForChild("ObbyBuilder"))

local ObbyService = {}
ObbyService.Handlers = {}

local OBBY_OFFSET = Vector3.new(-700, 80, 0) -- respecto al origen del Lobby (lejos del patio, flotando)
local MIN_TIME = 40 -- segundos: menos que esto es imposible sin trampas
local REWARD = { Coins = 600, XP = 250 }

local services
local model: Model
local progress = {} -- [Player] = { Checkpoint = n, StartedAt = os.clock() }

local function result(ok: boolean, msg: string)
	return { ok = ok, msg = msg }
end

local function root(player: Player): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function checkpointPart(index: number): BasePart?
	if index <= 0 then
		for _, p in CollectionService:GetTagged("ObbyStart") do
			if p:IsDescendantOf(model) then
				return p
			end
		end
		return nil
	end
	for _, p in CollectionService:GetTagged("ObbyCheckpoint") do
		if p:IsDescendantOf(model) and p:GetAttribute("Index") == index then
			return p
		end
	end
	return nil
end

local function teleportTo(player: Player, index: number)
	local p = checkpointPart(index)
	local c = player.Character
	if p and c then
		local pos = p.Position + Vector3.new(0, 4, 0)
		c:PivotTo(CFrame.lookAt(pos, pos + Vector3.xAxis))
		local r = root(player)
		if r then
			r.AssemblyLinearVelocity = Vector3.zero
		end
	end
end

ObbyService.Handlers.EnterObby = function(player: Player)
	if player:GetAttribute("ArenaId") ~= "Lobby" then
		return result(false, "La obby se juega desde el Lobby")
	end
	local activity = player:GetAttribute("Activity")
	if activity ~= "Hub" and activity ~= nil then
		return result(false, "Termina lo que estás haciendo primero")
	end
	progress[player] = { Checkpoint = 0, StartedAt = os.clock() }
	player:SetAttribute("InObby", true)
	player:SetAttribute("ObbyCheckpoint", 0)
	player:SetAttribute("ObbyStartedAt", workspace:GetServerTimeNow())
	teleportTo(player, 0)
	return result(true, "¡Ascenso Maldito! Llega a la meta sin caerte")
end

ObbyService.Handlers.LeaveObby = function(player: Player)
	progress[player] = nil
	player:SetAttribute("InObby", nil)
	player:SetAttribute("ObbyCheckpoint", nil)
	local c = player.Character
	if c then
		c:PivotTo(services.ArenaService.LobbySpawnCFrame())
	end
	return result(true, "De vuelta al Lobby")
end

ObbyService.Handlers.ObbyCheckpoint = function(player: Player, index: any)
	local state = progress[player]
	if not state or type(index) ~= "number" then
		return result(false, "")
	end
	if index <= state.Checkpoint then
		return result(true, "")
	end
	if index ~= state.Checkpoint + 1 then
		return result(false, "Te has saltado un checkpoint")
	end
	local p, r = checkpointPart(index), root(player)
	if not p or not r or (p.Position - r.Position).Magnitude > 16 then
		return result(false, "")
	end
	state.Checkpoint = index
	player:SetAttribute("ObbyCheckpoint", index)
	return result(true, `¡Checkpoint {index}/{ObbyBuilder.Checkpoints}!`)
end

ObbyService.Handlers.ObbyRespawn = function(player: Player)
	local state = progress[player]
	if not state then
		return result(false, "")
	end
	teleportTo(player, state.Checkpoint)
	return result(true, "")
end

-- Reiniciar desde el principio (el cronómetro también)
ObbyService.Handlers.ObbyRestart = function(player: Player)
	if not progress[player] then
		return result(false, "")
	end
	return ObbyService.Handlers.EnterObby(player)
end

ObbyService.Handlers.ObbyFinish = function(player: Player)
	local state = progress[player]
	if not state then
		return result(false, "")
	end
	if state.Checkpoint < ObbyBuilder.Checkpoints then
		return result(false, "Te faltan checkpoints")
	end
	local finish
	for _, p in CollectionService:GetTagged("ObbyFinish") do
		if p:IsDescendantOf(model) then
			finish = p
		end
	end
	local r = root(player)
	if not finish or not r or (finish.Position - r.Position).Magnitude > 18 then
		return result(false, "")
	end
	local elapsed = os.clock() - state.StartedAt
	if elapsed < MIN_TIME then
		return result(false, "Demasiado rápido... ¿seguro?")
	end
	progress[player] = nil
	player:SetAttribute("InObby", nil)
	player:SetAttribute("ObbyCheckpoint", nil)

	local data = services.DataService.Get(player)
	if not data then
		return result(false, "")
	end
	local today = math.floor(os.time() / 86400)
	local best = data.Obby.BestTime
	local isRecord = best == 0 or elapsed < best
	local gotReward = data.Obby.LastRewardDay ~= today
	services.DataService.Update(player, function(d)
		d.Obby.Clears += 1
		if isRecord then
			d.Obby.BestTime = math.floor(elapsed * 10) / 10
		end
		if gotReward then
			d.Obby.LastRewardDay = today
		end
	end)
	local text = ""
	if gotReward then
		services.EconomyService.AddCurrency(player, "Coins", REWARD.Coins, "Obby")
		services.EconomyService.AddXP(player, REWARD.XP)
		text = `  +{REWARD.Coins} 呪 +{REWARD.XP} XP`
	else
		text = "  (premio de hoy ya cobrado)"
	end
	services.DataService.PushState(player)
	services.QuestService.Add(player, "Obby", 1)
	local t = string.format("%d:%04.1f", elapsed // 60, elapsed % 60)
	return { ok = true, msg = `¡Obby completada en {t}!{if isRecord then " ¡NUEVO RÉCORD!" else ""}{text}`, Time = elapsed, Record = isRecord }
end

function ObbyService.Start(s)
	services = s
	local lobby = services.ArenaService.Lobby()
	local origin = (if lobby then lobby.Origin else Vector3.new(-3000, 0, 0)) + OBBY_OFFSET
	model = ObbyBuilder.Build(origin)
	model.Parent = workspace
	Players.PlayerRemoving:Connect(function(player)
		progress[player] = nil
	end)
	-- Si sales de la zona del Lobby (partida, Dojo...) se acaba la obby
	task.spawn(function()
		while true do
			task.wait(1)
			for player in progress do
				if player:GetAttribute("ArenaId") ~= "Lobby" then
					progress[player] = nil
					player:SetAttribute("InObby", nil)
					player:SetAttribute("ObbyCheckpoint", nil)
				end
			end
		end
	end)
end

return ObbyService
