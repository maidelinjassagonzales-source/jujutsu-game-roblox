-- NPCService: enemigos con IA para el modo historia (corren en el servidor).
-- Comportamiento: perseguir al jugador, atacar en cuerpo a cuerpo, usar especiales a distancia
-- y, si salen despedidos, volver al escenario con salto doble + especial hacia arriba.
-- Level 1..5 controla reflejos, agresividad y puntería.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local NPCService = {}

local FighterService, CombatService, ArenaService

local LEVELS = {
	[1] = { Think = 0.6, Aggro = 0.45, Special = 0.10, Smart = 0.2 },
	[2] = { Think = 0.45, Aggro = 0.6, Special = 0.18, Smart = 0.4 },
	[3] = { Think = 0.32, Aggro = 0.72, Special = 0.25, Smart = 0.6 },
	[4] = { Think = 0.24, Aggro = 0.82, Special = 0.3, Smart = 0.8 },
	[5] = { Think = 0.17, Aggro = 0.92, Special = 0.35, Smart = 0.95 },
}

local function getHRP(model: Model?): BasePart?
	return model and model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function findTarget(npc: Model): Model?
	local arenaId = npc:GetAttribute("ArenaId")
	local best, bestDist = nil, math.huge
	local hrp = getHRP(npc)
	if not hrp then
		return nil
	end
	for _, model in CollectionService:GetTagged("Fighter") do
		if model ~= npc and not model:GetAttribute("IsNPC") and model:GetAttribute("ArenaId") == arenaId
			and not model:GetAttribute("Eliminated") and not model:GetAttribute("KOing") then
			local thrp = getHRP(model)
			if thrp then
				local d = (thrp.Position - hrp.Position).Magnitude
				if d < bestDist then
					best, bestDist = model, d
				end
			end
		end
	end
	return best
end

local function think(npc: Model, arena, stats, state)
	local hrp = getHRP(npc)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid or hrp.Anchored or npc:GetAttribute("KOing") then
		return
	end
	if CombatService.IsStunned(npc) then
		humanoid:Move(Vector3.zero)
		return
	end

	-- Los enemigos listos (nivel 3+) también usan su ulti cuando la tienen cargada
	if (npc:GetAttribute("Ult") or 0) >= 100 and stats.Smart >= 0.6 and CombatService.UltimateHandler and math.random() < 0.5 then
		CombatService.UltimateHandler(npc)
		return
	end

	local pos = hrp.Position
	local center = arena.Center
	local half = arena.Stage.HalfWidth
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	if grounded then
		state.AirJumps = 0
	end

	-- 1) Recuperación: fuera del suelo principal o por debajo
	local offStageX = math.abs(pos.X - center.X) > half - 1
	local belowStage = pos.Y < center.Y - 1
	if (offStageX or belowStage) and not grounded and math.random() < 0.4 + stats.Smart * 0.6 then
		local towardCenter = if pos.X < center.X then 1 else -1
		humanoid:Move(Vector3.new(towardCenter, 0, 0))
		hrp.CFrame = CFrame.lookAt(pos, pos + Vector3.new(towardCenter, 0, 0))
		local vy = hrp.AssemblyLinearVelocity.Y
		if vy < 5 and state.AirJumps < 1 then
			state.AirJumps += 1
			hrp.AssemblyLinearVelocity = Vector3.new(towardCenter * 25, 62, 0)
		elseif vy < 0 and pos.Y < center.Y + 2 then
			CombatService.PerformAttack(npc, "Special", "Up", towardCenter)
		end
		return
	end

	local target = findTarget(npc)
	local thrp = getHRP(target)
	if not target or not thrp then
		humanoid:Move(Vector3.zero)
		return
	end

	local delta = thrp.Position - pos
	local facing = if delta.X >= 0 then 1 else -1
	local dist = math.abs(delta.X)

	-- No perseguir al jugador fuera del escenario (los listos se quedan en el borde)
	local wantX = thrp.Position.X
	if stats.Smart > 0.5 then
		wantX = math.clamp(wantX, center.X - half + 3, center.X + half - 3)
	end
	local moveDir = math.sign(wantX - pos.X)

	if dist > 7 then
		humanoid:Move(Vector3.new(moveDir, 0, 0))
		-- Saltar a plataformas si el objetivo está arriba
		if delta.Y > 6 and grounded and math.random() < 0.6 then
			humanoid.Jump = true
		end
		-- Especial a distancia de vez en cuando
		if dist > 14 and math.random() < stats.Special then
			hrp.CFrame = CFrame.lookAt(pos, pos + Vector3.new(facing, 0, 0))
			CombatService.PerformAttack(npc, "Special", if math.random() < 0.5 then "Neutral" else "Side", facing)
		end
		return
	end

	-- Cerca: encararse y atacar
	humanoid:Move(Vector3.zero)
	hrp.CFrame = CFrame.lookAt(pos, pos + Vector3.new(facing, 0, 0))
	if CombatService.IsBusy(npc) then
		return
	end
	-- Si el jugador se escuda, los listos le agarran (el agarre atraviesa el escudo)
	if target:GetAttribute("Shielding") and dist < 5 and math.random() < stats.Smart then
		local throws = { "Side", "Up", "Back", "Down" }
		CombatService.Grab(npc, throws[math.random(1, #throws)], facing)
		return
	end
	-- A veces se protegen con el escudo un momento
	if grounded and math.random() < stats.Smart * 0.12 then
		CombatService.SetShield(npc, true)
		task.delay(0.35 + math.random() * 0.3, CombatService.SetShield, npc, false)
		return
	end
	if math.random() > stats.Aggro then
		return
	end

	local targetPercent = target:GetAttribute("Percent") or 0
	local kind, dir = "Light", "Side"
	local roll = math.random()
	if delta.Y > 4 then
		kind, dir = (if roll < 0.5 then "Light" else "Heavy"), "Up"
	elseif delta.Y < -3 and not grounded then
		kind, dir = "Light", "Down"
	elseif targetPercent > 90 and roll < 0.3 + stats.Smart * 0.4 then
		kind, dir = "Heavy", "Neutral" -- remate
	elseif roll < 0.15 then
		kind, dir = "Special", "Neutral"
	elseif roll < 0.35 then
		kind, dir = "Heavy", (if math.random() < 0.5 then "Neutral" else "Down")
	else
		dir = if math.random() < 0.4 then "Neutral" else "Side"
	end
	CombatService.PerformAttack(npc, kind, dir, facing)
end

-- Crea un enemigo en la arena. spec = { Character, Name, Level, Stocks }
function NPCService.Spawn(arena, spec, spawnIndex: number): Model
	local npc = FighterService.BuildNPC(spec.Character, spec.Name, spec.Stocks or 1)
	npc:SetAttribute("ArenaId", arena.Id)
	npc:SetAttribute("Level", spec.Level or 1)
	npc.Parent = workspace
	npc:PivotTo(ArenaService.SpawnCFrame(arena, spawnIndex))
	local hrp = getHRP(npc)
	if hrp then
		hrp:SetNetworkOwner(nil)
	end

	local stats = LEVELS[math.clamp(spec.Level or 1, 1, 5)]
	local state = { AirJumps = 0 }
	task.spawn(function()
		task.wait(0.8) -- pequeña pausa al aparecer
		while npc.Parent do
			local ok, err = pcall(think, npc, arena, stats, state)
			if not ok then
				warn("[NPCService] Error en la IA:", err)
			end
			task.wait(stats.Think * (0.8 + math.random() * 0.4))
		end
	end)
	return npc
end

function NPCService.Start(services)
	FighterService = services.FighterService
	CombatService = services.CombatService
	ArenaService = services.ArenaService
end

return NPCService
