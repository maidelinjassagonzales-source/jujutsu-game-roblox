-- KOService: detecta cuando un luchador sale de la blast zone de SU arena.
-- La decisión de qué pasa después la toma el "Handler" de la arena:
--   "respawn"   -> reaparece arriba con invulnerabilidad (por defecto, modo práctica)
--   "eliminate" -> se queda como espectador (sin stocks en una partida)
--   "remove"    -> el handler se encarga (p.ej. destruir un enemigo de la historia)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CombatConfig"))

local KOService = {}

local feedback: RemoteEvent
local matchFeedback: RemoteEvent
local CombatService, ArenaService

local koListeners = {}
local KO_CREDIT_WINDOW = 8 -- segundos: el último que te golpeó se lleva el KO

-- fn(victim, killer?) -> economía, misiones...
function KOService.OnKO(fn)
	table.insert(koListeners, fn)
end

local function getHRP(model: Model?): BasePart?
	return model and model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function KOService.Spectate(model: Model, arena)
	local hrp = getHRP(model)
	model:SetAttribute("Eliminated", true)
	model:SetAttribute("KOing", false)
	if hrp then
		hrp.Anchored = true
		model:PivotTo(ArenaService.SpectatorCFrame(arena))
	end
end

function KOService.Respawn(model: Model, arena, delay: number?)
	local hrp = getHRP(model)
	if not hrp then
		return
	end
	task.wait(delay or Config.RespawnDelay)
	if not model.Parent or not hrp.Parent or model:GetAttribute("Eliminated") then
		return
	end
	model:SetAttribute("Percent", 0)
	model:PivotTo(ArenaService.RespawnCFrame(arena))
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.Anchored = false

	local player = Players:GetPlayerFromCharacter(model)
	if player then
		feedback:FireClient(player, "Respawned")
	end
	model:SetAttribute("Invulnerable", true)
	model:SetAttribute("KOing", false)
	task.delay(Config.RespawnInvulnerability, function()
		if model.Parent then
			model:SetAttribute("Invulnerable", false)
		end
	end)
end

local function knockOut(model: Model, hrp: BasePart, arena)
	model:SetAttribute("KOing", true)
	local killer = CombatService.GetLastAttacker(model, KO_CREDIT_WINDOW)
	feedback:FireAllClients("KO", model, hrp.Position, killer)
	for _, fn in koListeners do
		task.spawn(fn, model, killer)
	end

	local stocks = math.max((model:GetAttribute("Stocks") or 1) - 1, 0)
	model:SetAttribute("Stocks", stocks)
	CombatService.ClearState(model)
	hrp.Anchored = true -- congelado fuera de pantalla mientras se decide

	local decision = "respawn"
	if arena.Handler and arena.Handler.OnKO then
		local ok, result = pcall(arena.Handler.OnKO, model, stocks, killer)
		if ok and result then
			decision = result
		elseif not ok then
			warn("[KOService] Error en OnKO:", result)
		end
	elseif stocks <= 0 then
		-- Modo práctica: aviso y stocks rellenadas
		matchFeedback:FireAllClients("Eliminated", model)
		model:SetAttribute("Stocks", Config.DefaultStocks)
	end

	if decision == "eliminate" then
		KOService.Spectate(model, arena)
		matchFeedback:FireAllClients("Eliminated", model)
	elseif decision == "respawn" then
		KOService.Respawn(model, arena)
	end
end

function KOService.Start(remotes: Folder, services)
	feedback = remotes:WaitForChild("CombatFeedback")
	matchFeedback = remotes:WaitForChild("MatchFeedback")
	CombatService = services.CombatService
	ArenaService = services.ArenaService

	RunService.Heartbeat:Connect(function()
		for _, model in CollectionService:GetTagged("Fighter") do
			local hrp = getHRP(model)
			if not hrp or not model:IsDescendantOf(workspace) or model:GetAttribute("Eliminated") then
				continue
			end
			local arena = ArenaService.Get(model:GetAttribute("ArenaId"))
			if not arena then
				continue -- fuera de las arenas 2D (p.ej. la obby)
			end

			-- Los NPC los bloquea el servidor en el plano 2D (los jugadores lo hacen en su cliente)
			if not Players:GetPlayerFromCharacter(model) and not hrp.Anchored then
				local pos = hrp.Position
				if math.abs(pos.Z - Config.PlaneZ) > 0.05 then
					hrp.CFrame += Vector3.new(0, 0, Config.PlaneZ - pos.Z)
				end
			end

			if not model:GetAttribute("KOing") and ArenaService.IsOutside(arena, hrp.Position) then
				task.spawn(knockOut, model, hrp, arena)
			end
		end
	end)
end

return KOService
