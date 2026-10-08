-- MoveTester (SOLO STUDIO): prueba automática de TODOS los movimientos de TODOS los personajes.
-- Para cada personaje crea un atacante y un muñeco delante (lejos de las arenas, en el aire y anclados)
-- y ejecuta cada golpe/especial comprobando que: no da error, golpea (si tiene hitbox o proyectil)
-- y suma el % esperado. Desde la Command Bar (vista Cliente, durante el Play):
--   game.ReplicatedStorage.Remotes.ShopRequest:InvokeServer("DevTestMoves")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))
local KnockbackSimulator = require(Shared:WaitForChild("KnockbackSimulator"))

local MoveTester = {}

local ORIGIN = Vector3.new(8000, 400, 0)
local SPACING = 60
local REQUIRED = { "Light_Neutral", "Heavy_Neutral", "Special_Neutral", "Special_Side", "Special_Up" }

local function validateMove(key: string, move): string?
	local hits = move.Hitbox ~= nil or move.Projectile ~= nil
	if hits then
		for _, field in { "Damage", "BaseKnockback", "KnockbackGrowth", "Angle" } do
			if type(move[field]) ~= "number" then
				return `{key}: falta {field}`
			end
		end
	end
	if move.Hitbox and (typeof(move.Hitbox.Size) ~= "Vector3" or typeof(move.Hitbox.Offset) ~= "Vector3") then
		return `{key}: Hitbox mal definida`
	end
	local p = move.Projectile
	if p and (type(p.Speed) ~= "number" or type(p.Lifetime) ~= "number" or typeof(p.Size) ~= "Vector3" or typeof(p.Color) ~= "Color3") then
		return `{key}: Projectile mal definido`
	end
	if move.FollowUp and type(move.FollowUp.Damage) ~= "number" then
		return `{key}: FollowUp sin Damage`
	end
	if key:find("^Special") and not move.Name then
		return `{key}: el especial no tiene Name (no se verá en la tienda)`
	end
	return nil
end

local function anchorAt(model: Model, pos: Vector3, facing: number)
	model:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(facing, 0, 0)))
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart
	hrp.Anchored = true
	hrp.AssemblyLinearVelocity = Vector3.zero
end

local function testCharacter(services, characterId: string, index: number, results)
	local data = CharacterRegistry.Get(characterId)
	local base = ORIGIN + Vector3.new(index * SPACING, 0, 0)
	local attacker = services.FighterService.BuildNPC(characterId, `Test_{characterId}`, 99)
	local victim = services.FighterService.BuildNPC("Brawler", `Dummy_{characterId}`, 99)
	victim:SetAttribute("IsNPC", false) -- los NPC no se golpean entre sí
	for _, m in { attacker, victim } do
		m:SetAttribute("ArenaId", `MoveTest{index}`)
		m.Parent = workspace
	end

	for _, key in (if data.Playable == false then {} else REQUIRED) do
		if not data.Moves[key] then
			table.insert(results.Errors, `{characterId}: falta el movimiento {key}`)
		end
	end

	local keys = {}
	for key in data.Moves do
		table.insert(keys, key)
	end
	table.sort(keys)

	for _, key in keys do
		local move = data.Moves[key]
		results.Total += 1
		local problem = validateMove(key, move)
		if problem then
			table.insert(results.Errors, `{characterId}: {problem}`)
			continue
		end
		services.CombatService.ClearState(attacker)
		services.CombatService.ClearState(victim)
		KnockbackSimulator.Cancel(victim)
		victim:SetAttribute("Percent", 0)
		anchorAt(attacker, base, 1)
		-- El muñeco se coloca donde debería impactar el golpe
		local target = base + Vector3.new(12, 0, 0)
		if move.Hitbox then
			target = base + Vector3.new(move.Hitbox.Offset.X, move.Hitbox.Offset.Y, 0)
		end
		anchorAt(victim, target, -1)

		local ok, err = pcall(services.CombatService.ExecuteMove, attacker, move, 1)
		if not ok then
			table.insert(results.Errors, `{characterId}.{key}: ERROR {err}`)
			continue
		end
		local wait = (move.Active or 0) + 0.25
		if move.Projectile then
			wait = math.min(move.Projectile.Lifetime, 12 / move.Projectile.Speed + 0.3)
		end
		if move.FollowUp then
			wait += (move.FollowUp.Delay or 0.2) + 0.1
		end
		task.wait(wait)
		local dealt = victim:GetAttribute("Percent") or 0
		if move.Hitbox or move.Projectile then
			local expected = move.Damage + (if move.FollowUp then move.FollowUp.Damage else 0)
			if dealt <= 0 then
				table.insert(results.Misses, `{characterId}.{key} ({move.Name or "-"}) NO golpea`)
			elseif not move.Projectile and not move.Swap and dealt < expected then
				table.insert(results.Misses, `{characterId}.{key}: hizo {dealt}% de {expected}%`)
			else
				results.Hits += 1
			end
		else
			results.Utility += 1 -- recuperaciones sin hitbox
		end
	end
	attacker:Destroy()
	victim:Destroy()
end

function MoveTester.Run(services): string
	local results = { Total = 0, Hits = 0, Utility = 0, Errors = {}, Misses = {} }
	local ids = CharacterRegistry.GetOrder()
	local pending = #ids
	for i, id in ids do
		task.spawn(function()
			local ok, err = pcall(testCharacter, services, id, i, results)
			if not ok then
				table.insert(results.Errors, `{id}: FALLO GENERAL {err}`)
			end
			pending -= 1
		end)
	end
	local deadline = os.clock() + 90
	while pending > 0 and os.clock() < deadline do
		task.wait(0.25)
	end
	print(`[MoveTester] {#ids} personajes · {results.Total} movimientos · {results.Hits} golpean · {results.Utility} de movilidad`)
	for _, line in results.Errors do
		warn("[MoveTester] ERROR", line)
	end
	for _, line in results.Misses do
		warn("[MoveTester] FALLA", line)
	end
	if #results.Errors == 0 and #results.Misses == 0 then
		print("[MoveTester] Todos los movimientos funcionan")
	end
	return `{results.Total} movimientos · {#results.Errors} errores · {#results.Misses} fallos`
end

return MoveTester
