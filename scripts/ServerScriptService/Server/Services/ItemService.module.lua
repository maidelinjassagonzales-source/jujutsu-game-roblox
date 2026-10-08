-- ItemService: OBJETOS en las partidas (y en el Dojo para practicar).
--   * Cada cierto tiempo aparece un objeto flotando sobre el escenario
--   * Pasas por encima y lo coges (solo uno a la vez); se ve en tu mano
--   * F (o cruceta derecha en mando) lo usa. Mantén arriba/abajo para lanzar hacia arriba/abajo.
-- Tipos: Throw (se lanza), Melee (arma con varios usos), Heal (se consume al momento).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local ItemService = {}

local C, V = Color3.fromRGB, Vector3.new
ItemService.Items = {
	Bomb = { Name = "Cursed Bomb", Color = C(130, 40, 210), Shape = "Ball", Size = V(1.6, 1.6, 1.6), Uses = 1, Kind = "Throw",
		Speed = 55, Up = 30, Gravity = 80, HitRadius = 1.5, Explode = 9, Damage = 15, KB = 34, Growth = 82, Angle = 55, Weight = 22 },
	Kunai = { Name = "Kunais", Color = C(185, 185, 195), Shape = "Block", Size = V(0.3, 0.3, 1.8), Uses = 3, Kind = "Throw",
		Speed = 115, Up = 0, Gravity = 0, HitRadius = 1.6, Damage = 6, KB = 12, Growth = 42, Angle = 30, Lifetime = 0.8, Weight = 22 },
	Talisman = { Name = "Sealing Talisman", Color = C(245, 225, 120), Shape = "Block", Size = V(1.3, 0.1, 1.9), Uses = 1, Kind = "Throw",
		Speed = 80, Up = 5, Gravity = 12, HitRadius = 2, Damage = 4, KB = 4, Growth = 0, Angle = 45, Stun = 1.6, Lifetime = 1.3, Weight = 14 },
	Hammer = { Name = "Giant Hammer", Color = C(120, 85, 60), Shape = "Block", Size = V(1.2, 1.2, 3.4), Uses = 5, Kind = "Melee",
		Damage = 12, KB = 30, Growth = 86, Angle = 42, Hitbox = { Size = V(8, 6, 6), Offset = V(4, 0.5, 0) }, Startup = 0.25, Active = 0.12, Endlag = 0.35, Weight = 14 },
	Katana = { Name = "Cursed Katana", Color = C(210, 40, 60), Shape = "Block", Size = V(0.2, 0.3, 4.2), Uses = 6, Kind = "Melee",
		Damage = 8, KB = 18, Growth = 70, Angle = 35, Hitbox = { Size = V(9, 4, 6), Offset = V(4.5, 0, 0) }, Startup = 0.08, Active = 0.1, Endlag = 0.18, Weight = 16 },
	Pill = { Name = "Revitalizing Pill", Color = C(80, 235, 150), Shape = "Ball", Size = V(1.2, 1.2, 1.2), Uses = 1, Kind = "Heal", Heal = 30, Weight = 12 },
}

local SPAWN_EVERY = { 9, 15 } -- segundos entre objetos en cada arena
local MAX_PER_ARENA = 2
local PICKUP_RADIUS = 4.5

local services
local CombatService, ArenaService
local feedback: RemoteEvent
local folder: Folder
local nextSpawn = {} -- [arenaId] = os.clock()
local heldSince = setmetatable({}, { __mode = "k" }) -- [model] = os.clock() (los bots lo usan solos)
local uses = setmetatable({}, { __mode = "k" }) -- [model] = usos que quedan
local rng = Random.new()

local function root(model: Model?): BasePart?
	return model and model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function pickItemId(): string
	local total = 0
	for _, item in ItemService.Items do
		total += item.Weight
	end
	local roll = rng:NextNumber() * total
	for id, item in ItemService.Items do
		roll -= item.Weight
		if roll <= 0 then
			return id
		end
	end
	return "Bomb"
end

local function makeVisual(item, name: string): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = if item.Shape == "Ball" then Enum.PartType.Ball else Enum.PartType.Block
	p.Size = item.Size
	p.Color = item.Color
	p.Material = Enum.Material.Neon
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	return p
end

-- ===== Objeto en la mano
local function setHeldVisual(model: Model, itemId: string?)
	local old = model:FindFirstChild("HeldItem")
	if old then
		old:Destroy()
	end
	local arm = model:FindFirstChild("Right Arm") :: BasePart?
	local item = itemId and ItemService.Items[itemId]
	if not item or not arm then
		return
	end
	local p = makeVisual(item, "HeldItem")
	p.Massless = true
	local offset = if item.Kind == "Melee" then CFrame.new(0, -1.1, -item.Size.Z / 2 - 0.2) else CFrame.new(0, -1.2, -0.4)
	p.CFrame = arm.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = arm
	weld.Part1 = p
	weld.C0 = offset
	weld.Parent = p
	p.Parent = model
end

function ItemService.Clear(model: Model)
	model:SetAttribute("HeldItem", nil)
	model:SetAttribute("ItemUses", nil)
	uses[model] = nil
	heldSince[model] = nil
	setHeldVisual(model, nil)
end

local function give(model: Model, itemId: string)
	local item = ItemService.Items[itemId]
	uses[model] = item.Uses
	heldSince[model] = os.clock()
	model:SetAttribute("HeldItem", itemId)
	model:SetAttribute("ItemUses", item.Uses)
	setHeldVisual(model, itemId)
	local player = Players:GetPlayerFromCharacter(model)
	if player and services.EconomyFeedback then
		services.EconomyFeedback:FireClient(player, "Reward", { Reason = `Picked up: {item.Name} · press F to use it` })
	end
end

local function consumeUse(model: Model)
	local left = (uses[model] or 1) - 1
	if left <= 0 then
		ItemService.Clear(model)
	else
		uses[model] = left
		model:SetAttribute("ItemUses", left)
	end
end

-- ===== Lanzables
local function fighterFromPart(part: BasePart): Model?
	local m = part:FindFirstAncestorWhichIsA("Model")
	while m and not CollectionService:HasTag(m, "Fighter") do
		m = m:FindFirstAncestorWhichIsA("Model")
	end
	return m
end

local function explosion(pos: Vector3, color: Color3, radius: number)
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.Material = Enum.Material.Neon
	ball.Color = color
	ball.Size = Vector3.one * 2
	ball.Position = pos
	ball.Transparency = 0.2
	ball.Parent = folder
	game:GetService("TweenService"):Create(ball, TweenInfo.new(0.35), { Size = Vector3.one * radius * 2, Transparency = 1 }):Play()
	Debris:AddItem(ball, 0.4)
end

local function hit(thrower: Model, victim: Model, item, facing: number)
	local move = { Damage = item.Damage, BaseKnockback = item.KB, KnockbackGrowth = item.Growth, Angle = item.Angle }
	if CombatService.ApplyHit(thrower, victim, move, facing) and item.Stun then
		CombatService.Stun(victim, item.Stun)
	end
end

local function throw(model: Model, item, dir: string, facing: number)
	local hrp = root(model)
	if not hrp then
		return
	end
	local arenaId = model:GetAttribute("ArenaId")
	local arena = ArenaService.Get(arenaId)
	local pos = hrp.Position + Vector3.new(facing * 2.5, 1, 0)
	local vel
	if dir == "Up" then
		vel = Vector3.new(facing * 12, item.Speed * 0.9, 0)
	elseif dir == "Down" then
		vel = Vector3.new(facing * item.Speed * 0.6, -item.Speed * 0.3, 0)
	else
		vel = Vector3.new(facing * item.Speed, item.Up, 0)
	end
	local p = makeVisual(item, "Thrown")
	p.Anchored = true
	p.CFrame = CFrame.lookAt(pos, pos + vel)
	p.Parent = folder
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = { model, folder }
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.RespectCanCollide = true
	local ignore = { folder }
	for _, f in CollectionService:GetTagged("Fighter") do
		table.insert(ignore, f)
	end
	rayParams.FilterDescendantsInstances = ignore

	local born = os.clock()
	local lifetime = item.Lifetime or 2.5
	local conn
	local function finish(at: Vector3, victim: Model?)
		conn:Disconnect()
		p:Destroy()
		if item.Explode then
			explosion(at, item.Color, item.Explode)
			for _, f in CollectionService:GetTagged("Fighter") do
				local r = root(f)
				if f ~= model and r and f:GetAttribute("ArenaId") == arenaId and (r.Position - at).Magnitude <= item.Explode then
					hit(model, f, item, if r.Position.X >= at.X then 1 else -1)
				end
			end
		elseif victim then
			hit(model, victim, item, if vel.X >= 0 then 1 else -1)
		end
	end
	conn = RunService.Heartbeat:Connect(function(dt)
		if not model.Parent or os.clock() - born > lifetime or (arena and ArenaService.IsOutside(arena, pos)) then
			finish(pos, nil)
			return
		end
		vel -= Vector3.new(0, (item.Gravity or 0) * dt, 0)
		local step = vel * dt
		local wall = workspace:Raycast(pos, step, rayParams)
		for _, part in workspace:GetPartBoundsInRadius(pos, item.HitRadius or 1.5, overlap) do
			local f = fighterFromPart(part)
			if f and f ~= model and f:GetAttribute("ArenaId") == arenaId and CombatService.CanHurt(model, f) then
				finish(pos, f)
				return
			end
		end
		if wall then
			finish(wall.Position, nil)
			return
		end
		pos += step
		p.CFrame = CFrame.lookAt(pos, pos + vel) * CFrame.Angles(0, 0, os.clock() * 12)
	end)
end

-- ===== Usar el objeto
function ItemService.Use(model: Model, dir: any, facingHint: any)
	local itemId = model:GetAttribute("HeldItem")
	local item = itemId and ItemService.Items[itemId]
	local hrp = root(model)
	if not item or not hrp or hrp.Anchored or model:GetAttribute("KOing") or model:GetAttribute("MoveMode") == "Free" then
		return
	end
	if CombatService.IsBusy(model) or CombatService.IsStunned(model) then
		return
	end
	if dir ~= "Up" and dir ~= "Down" then
		dir = "Side"
	end
	local facing = if facingHint == 1 or facingHint == -1 then facingHint else (if hrp.CFrame.LookVector.X >= 0 then 1 else -1)

	if item.Kind == "Heal" then
		model:SetAttribute("Percent", math.max(0, (model:GetAttribute("Percent") or 0) - item.Heal))
		explosion(hrp.Position, item.Color, 4)
		consumeUse(model)
	elseif item.Kind == "Throw" then
		CombatService.SetBusy(model, 0.3)
		feedback:FireAllClients("MoveStarted", model, "Special_Neutral", nil, facing)
		throw(model, item, dir, facing)
		consumeUse(model)
	elseif item.Kind == "Melee" then
		local move = {
			Damage = item.Damage, BaseKnockback = item.KB, KnockbackGrowth = item.Growth, Angle = if dir == "Up" then 80 else item.Angle,
			Startup = item.Startup, Active = item.Active, Endlag = item.Endlag, Hitbox = item.Hitbox,
		}
		CombatService.SetBusy(model, item.Startup + item.Active + item.Endlag)
		feedback:FireAllClients("MoveStarted", model, if dir == "Up" then "Heavy_Up" else "Heavy_Neutral", nil, facing)
		task.spawn(CombatService.ExecuteMove, model, move, facing)
		consumeUse(model)
	end
end

-- ===== Aparición de objetos
local function spawnIn(arena)
	local center = arena.Center
	local half = (arena.Stage.HalfWidth or 40) * 0.8
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.RespectCanCollide = true
	local ignore = { folder }
	for _, f in CollectionService:GetTagged("Fighter") do
		table.insert(ignore, f)
	end
	rayParams.FilterDescendantsInstances = ignore
	for _ = 1, 6 do
		local x = center.X + rng:NextNumber(-half, half)
		local hitResult = workspace:Raycast(Vector3.new(x, center.Y + 60, 0), Vector3.new(0, -120, 0), rayParams)
		if hitResult and hitResult.Position.Y > center.Y - 10 and hitResult.Position.Y < center.Y + 45 then
			local itemId = pickItemId()
			local item = ItemService.Items[itemId]
			local p = makeVisual(item, `Pickup_{itemId}`)
			p.Anchored = true
			p.Position = hitResult.Position + Vector3.new(0, 2.2, 0)
			p:SetAttribute("ItemId", itemId)
			p:SetAttribute("ArenaId", arena.Id)
			local light = Instance.new("PointLight")
			light.Color = item.Color
			light.Range = 10
			light.Brightness = 2
			light.Parent = p
			local gui = Instance.new("BillboardGui")
			gui.Size = UDim2.fromOffset(160, 26)
			gui.StudsOffset = Vector3.new(0, 2, 0)
			gui.AlwaysOnTop = true
			gui.MaxDistance = 120
			gui.Parent = p
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.GothamBlack
			label.TextScaled = true
			label.TextColor3 = item.Color:Lerp(Color3.new(1, 1, 1), 0.5)
			label.TextStrokeTransparency = 0.2
			label.Text = item.Name
			label.Parent = gui
			CollectionService:AddTag(p, "ItemPickup")
			p.Parent = folder
			return
		end
	end
end

local function arenaWantsItems(arena): boolean
	if arena.Kind == "Hub" then
		return true
	end
	return arena.Kind == "Match" and arena.Info:GetAttribute("MatchState") == "Fighting"
end

function ItemService.Start(remotes: Folder, s)
	services = s
	CombatService = s.CombatService
	ArenaService = s.ArenaService
	feedback = remotes:WaitForChild("CombatFeedback")
	folder = workspace:FindFirstChild("Items") or Instance.new("Folder")
	folder.Name = "Items"
	folder.Parent = workspace

	CombatService.ItemHandler = ItemService.Use
	-- Al morir (KO) o al empezar una partida se pierde el objeto
	local clearState = CombatService.ClearState
	CombatService.ClearState = function(model: Model)
		clearState(model)
		ItemService.Clear(model)
	end

	-- Aparición y recogida
	task.spawn(function()
		while true do
			task.wait(0.15)
			local now = os.clock()
			local pickups = CollectionService:GetTagged("ItemPickup")
			local count = {}
			for _, p in pickups do
				local id = p:GetAttribute("ArenaId")
				if not ArenaService.Get(id) then
					p:Destroy() -- la arena ya no existe
				else
					count[id] = (count[id] or 0) + 1
				end
			end
			for _, arena in ArenaService.All() do
				if arenaWantsItems(arena) then
					nextSpawn[arena.Id] = nextSpawn[arena.Id] or now + rng:NextNumber(4, 7)
					if now >= nextSpawn[arena.Id] then
						nextSpawn[arena.Id] = now + rng:NextNumber(SPAWN_EVERY[1], SPAWN_EVERY[2])
						if (count[arena.Id] or 0) < MAX_PER_ARENA then
							spawnIn(arena)
						end
					end
				else
					nextSpawn[arena.Id] = nil
				end
			end
			-- Recoger: pasar por encima sin llevar ya otro objeto
			for _, p in CollectionService:GetTagged("ItemPickup") do
				if p.Parent then
					local arenaId = p:GetAttribute("ArenaId")
					for _, f in CollectionService:GetTagged("Fighter") do
						local r = root(f)
						if r and f:GetAttribute("ArenaId") == arenaId and not f:GetAttribute("HeldItem") and not f:GetAttribute("IsDummy")
							and not f:GetAttribute("Eliminated") and not f:GetAttribute("KOing") and (r.Position - p.Position).Magnitude <= PICKUP_RADIUS then
							give(f, p:GetAttribute("ItemId"))
							p:Destroy()
							break
						end
					end
				end
			end
			-- Los bots usan su objeto al rato, hacia el rival más cercano
			for model, since in heldSince do
				if model.Parent and model:GetAttribute("IsNPC") and now - since > 1.2 + rng:NextNumber(0, 1.5) then
					local r = root(model)
					local best, bestDist = nil, 40
					for _, f in CollectionService:GetTagged("Fighter") do
						local fr = root(f)
						if f ~= model and fr and r and f:GetAttribute("ArenaId") == model:GetAttribute("ArenaId") and CombatService.CanHurt(model, f) then
							local d = (fr.Position - r.Position).Magnitude
							if d < bestDist then
								best, bestDist = fr, d
							end
						end
					end
					if best and r then
						heldSince[model] = now
						local item = ItemService.Items[model:GetAttribute("HeldItem") or ""]
						if item and (item.Kind ~= "Melee" or bestDist < 8) then
							ItemService.Use(model, "Side", if best.Position.X >= r.Position.X then 1 else -1)
						end
					end
				end
			end
		end
	end)
end

return ItemService
