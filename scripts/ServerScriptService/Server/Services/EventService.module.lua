-- EventService: EVENTOS ALEATORIOS para todo el servidor.
-- Cada 8-14 minutos empieza uno (nunca el mismo dos veces seguidas) y dura unos minutos:
--   BloodMoon  · Luna de Sangre       -> x2 Monedas Malditas (el cielo se vuelve rojo)
--   XPRush     · Hora del Hechicero   -> x2 XP
--   CurseRain  · Lluvia de Maldiciones -> caen espíritus malditos por el patio: tócalos = monedas
--   GemFall    · Gemas Caídas         -> caen cristales de gemas (raro; máximo por jugador)
--   Fortune    · Fortuna Maldita      -> la Ruleta Maldita a mitad de precio
-- El estado se replica en ReplicatedStorage.EventInfo (atributos) y el cliente lo enseña.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local EventService = {}
EventService.Handlers = {}

local C = Color3.fromRGB

local EVENTS = {
	BloodMoon = { Name = "Luna de Sangre", Description = "x2 Monedas Malditas en todo", Duration = 240, Weight = 3, Color = C(230, 40, 50) },
	XPRush = { Name = "Hora del Hechicero", Description = "x2 XP en todo", Duration = 240, Weight = 3, Color = C(120, 200, 255) },
	CurseRain = { Name = "Lluvia de Maldiciones", Description = "Toca los espíritus malditos del patio: +monedas", Duration = 150, Weight = 3, Color = C(170, 80, 255) },
	GemFall = { Name = "Gemas Caídas", Description = "¡Llueven gemas en el patio! Cógelas rápido", Duration = 100, Weight = 1, Color = C(90, 220, 255) },
	Fortune = { Name = "Fortuna Maldita", Description = "Ruleta Maldita a mitad de precio", Duration = 240, Weight = 2, Color = C(255, 200, 60) },
}
local FIRST_DELAY = 180
local GAP_MIN, GAP_MAX = 480, 840
local GEMS_PER_PLAYER = 12

local services
local info: Configuration
local current: string? = nil
local lastEvent: string? = nil
local rng = Random.new()
local gemCount = {} -- [Player] = gemas cogidas en este evento
local pickups: Folder

function EventService.Active(): string?
	return current
end

local function lobbyArea()
	local lobby = services.ArenaService.Lobby()
	return if lobby then lobby.Origin else Vector3.new(-3000, 0, 0)
end

-- Objeto que se coge al tocarlo (espíritu maldito o cristal de gema)
local function spawnPickup(kind: string)
	local origin = lobbyArea()
	local pos = origin + Vector3.new(rng:NextNumber(-110, 110), rng:NextNumber(3, 5), rng:NextNumber(-90, 95))
	local orb = Instance.new("Part")
	orb.Name = kind
	orb.Anchored = true
	orb.CanCollide = false
	orb.CanQuery = false
	orb.CastShadow = false
	orb.Material = Enum.Material.Neon
	if kind == "Gem" then
		orb.Size = Vector3.new(1.4, 2.6, 1.4)
		orb.Color = C(90, 220, 255)
		orb.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(45))
	else
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.one * 2.2
		orb.Color = C(150, 60, 230)
		orb.Position = pos
	end
	local fx = Instance.new("ParticleEmitter")
	fx.Texture = if kind == "Gem" then "rbxasset://textures/particles/sparkles_main.dds" else "rbxasset://textures/particles/fire_main.dds"
	fx.Color = ColorSequence.new(orb.Color:Lerp(Color3.new(1, 1, 1), 0.4), orb.Color)
	fx.LightEmission = 1
	fx.Size = NumberSequence.new(1.2, 0)
	fx.Lifetime = NumberRange.new(0.5, 0.9)
	fx.Rate = 18
	fx.Speed = NumberRange.new(1, 3)
	fx.Parent = orb
	local light = Instance.new("PointLight")
	light.Color = orb.Color
	light.Range = 10
	light.Brightness = 2
	light.Parent = orb
	CollectionService:AddTag(orb, "EventPickup")
	local taken = false
	orb.Touched:Connect(function(hit)
		if taken then
			return
		end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or player:GetAttribute("ArenaId") ~= "Lobby" then
			return
		end
		if kind == "Gem" then
			if (gemCount[player] or 0) >= GEMS_PER_PLAYER then
				return
			end
			taken = true
			gemCount[player] = (gemCount[player] or 0) + 2
			services.EconomyService.AddCurrency(player, "Gems", 2, "Evento:GemFall")
			services.EconomyFeedback:FireClient(player, "Reward", { Gems = 2, Reason = "Gemas Caídas" })
		else
			taken = true
			services.EconomyService.AddCurrency(player, "Coins", 40, "Evento:CurseRain")
			services.EconomyFeedback:FireClient(player, "Reward", { Coins = 40, Reason = "Espíritu maldito" })
		end
		orb:Destroy()
	end)
	orb.Parent = pickups
	task.delay(25, function()
		if orb.Parent then
			orb:Destroy()
		end
	end)
end

local function startEvent(id: string)
	local event = EVENTS[id]
	if not event or current then
		return
	end
	current = id
	lastEvent = id
	gemCount = {}
	local endsAt = os.time() + event.Duration
	info:SetAttribute("Id", id)
	info:SetAttribute("Name", event.Name)
	info:SetAttribute("Description", event.Description)
	info:SetAttribute("Color", event.Color)
	info:SetAttribute("EndsAt", endsAt)
	-- Objetos que caen en el patio
	if id == "CurseRain" or id == "GemFall" then
		task.spawn(function()
			while current == id and os.time() < endsAt do
				if #pickups:GetChildren() < (if id == "GemFall" then 14 else 28) then
					spawnPickup(if id == "GemFall" then "Gem" else "Curse")
				end
				task.wait(if id == "GemFall" then 2.5 else 1.2)
			end
		end)
	end
	task.delay(event.Duration, function()
		if current == id then
			current = nil
			info:SetAttribute("Id", nil)
			info:SetAttribute("EndsAt", 0)
			pickups:ClearAllChildren()
		end
	end)
end

local function pickNext(): string
	local total = 0
	for id, e in EVENTS do
		if id ~= lastEvent then
			total += e.Weight
		end
	end
	local roll = rng:NextNumber() * total
	for id, e in EVENTS do
		if id ~= lastEvent then
			roll -= e.Weight
			if roll <= 0 then
				return id
			end
		end
	end
	return "BloodMoon"
end

function EventService.Start(s)
	services = s
	info = Instance.new("Configuration")
	info.Name = "EventInfo"
	info:SetAttribute("EndsAt", 0)
	info.Parent = ReplicatedStorage
	pickups = Instance.new("Folder")
	pickups.Name = "EventPickups"
	pickups.Parent = workspace

	-- x2 Monedas / x2 XP mientras dura su evento
	services.EconomyService.RegisterMultiplier(function(_player, kind)
		if current == "BloodMoon" and kind == "Coins" then
			return 2
		elseif current == "XPRush" and kind == "XP" then
			return 2
		end
		return 1
	end)
	Players.PlayerRemoving:Connect(function(player)
		gemCount[player] = nil
	end)

	task.spawn(function()
		task.wait(FIRST_DELAY)
		while true do
			startEvent(pickNext())
			task.wait(rng:NextInteger(GAP_MIN, GAP_MAX))
		end
	end)
end

-- SOLO EN STUDIO: lanzar un evento para probarlo
-- game.ReplicatedStorage.Remotes.ShopRequest:InvokeServer("DevEvent", "CurseRain")
if game:GetService("RunService"):IsStudio() then
	EventService.Handlers.DevEvent = function(_player: Player, id: any)
		if type(id) ~= "string" or not EVENTS[id] then
			return { ok = false, msg = "Eventos: BloodMoon, XPRush, CurseRain, GemFall, Fortune" }
		end
		current = nil
		startEvent(id)
		return { ok = true, msg = `[Studio] Evento {EVENTS[id].Name}` }
	end
end

return EventService
