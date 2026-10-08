-- LobbyController: el Lobby 3D en el cliente.
--   * Puestos del patio (ProximityPrompt, tecla E): Historia, Pase, Tienda, fichas de personaje, Dojo
--   * Barra "Estás en el Dojo" con botón para volver al Lobby
--   * Guía de bienvenida al llegar al patio
--   * Pétalos de cerezo cayendo de los árboles (solo en este cliente, sin coste de red)
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local StateController = require(script.Parent:WaitForChild("StateController"))
local CurrencyController = require(script.Parent:WaitForChild("CurrencyController"))

local player = Players.LocalPlayer

local LobbyController = {}

local function request(action: string, ...)
	local response = StateController.Request(action, ...)
	if response.msg and response.msg ~= "" then
		CurrencyController.Toast(response.msg, if response.ok then UI.Colors.Green else UI.Colors.Red)
	end
	return response.ok
end

local function controller(name: string)
	return require(script.Parent:WaitForChild(name))
end

local ACTIONS = {
	OpenStory = function()
		controller("StoryController").Open()
	end,
	OpenPass = function()
		controller("BattlePassController").Open()
	end,
	OpenStore = function()
		controller("StoreController").Open()
	end,
	OpenCharacter = function(prompt: ProximityPrompt)
		controller("CharacterShopController").Open(prompt:GetAttribute("CharacterId"))
	end,
	Practice = function()
		request("GoPractice")
	end,
}

-- ===== Pétalos de cerezo
local PETAL_COUNT = 140
local PETAL_RANGE = 160 -- solo caen de los árboles cercanos a la cámara
local PETAL_COLORS = { Color3.fromRGB(255, 190, 215), Color3.fromRGB(255, 160, 195), Color3.fromRGB(255, 220, 235) }

local function startPetals()
	local folder = Instance.new("Folder")
	folder.Name = "SakuraPetals"
	folder.Parent = workspace
	local rng = Random.new()
	local petals = {}
	for i = 1, PETAL_COUNT do
		local p = Instance.new("Part")
		p.Name = "Petal"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.Size = Vector3.new(0.45, 0.05, 0.3)
		p.Color = PETAL_COLORS[(i % #PETAL_COLORS) + 1]
		p.Transparency = 1
		p.Parent = folder
		petals[i] = { Part = p, Alive = false, Wait = rng:NextNumber(0, 6) }
	end

	local nearby: { BasePart } = {}
	task.spawn(function()
		while true do
			local camPos = workspace.CurrentCamera.CFrame.Position
			local list = {}
			for _, canopy in CollectionService:GetTagged("SakuraCanopy") do
				if canopy:IsDescendantOf(workspace) and (canopy.Position - camPos).Magnitude < PETAL_RANGE then
					table.insert(list, canopy)
				end
			end
			nearby = list
			task.wait(1)
		end
	end)

	local wind = Vector3.new(1.6, 0, 0.8)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { folder }
	rayParams.RespectCanCollide = true -- atraviesa las copas (no colisionan), se posa en el suelo
	RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()
		for _, petal in petals do
			local p = petal.Part
			if not petal.Alive then
				petal.Wait -= dt
				if petal.Wait <= 0 and #nearby > 0 then
					local canopy = nearby[rng:NextInteger(1, #nearby)]
					local r = canopy.Size.X * 0.45
					petal.Pos = canopy.Position + Vector3.new(rng:NextNumber(-r, r), rng:NextNumber(-r * 0.5, 0), rng:NextNumber(-r, r))
					local hit = workspace:Raycast(petal.Pos, Vector3.new(0, -60, 0), rayParams)
					petal.Floor = if hit then hit.Position.Y + 0.05 else petal.Pos.Y - 30
					petal.Landed = nil
					petal.Fall = rng:NextNumber(2.2, 3.6)
					petal.Seed = rng:NextNumber(0, 100)
					petal.Life = 0
					petal.Alive = true
					p.Transparency = 0.05
				else
					continue
				end
			end
			petal.Life += dt
			local seed = petal.Seed
			if petal.Landed then
				-- posado en el suelo un momento y se desvanece
				petal.Landed += dt
				p.Transparency = math.clamp(petal.Landed / 2, 0.05, 1)
			else
				local sway = Vector3.new(math.sin(t * 1.7 + seed) * 1.4, 0, math.cos(t * 1.3 + seed) * 1.1)
				petal.Pos += (wind + sway) * dt + Vector3.new(0, -petal.Fall * dt, 0)
				if petal.Pos.Y <= petal.Floor then
					petal.Pos = Vector3.new(petal.Pos.X, petal.Floor, petal.Pos.Z)
					petal.Landed = 0
					p.CFrame = CFrame.new(petal.Pos) * CFrame.Angles(0, seed, 0)
				else
					p.CFrame = CFrame.new(petal.Pos) * CFrame.Angles(t * 2.1 + seed, t * 1.4 + seed, math.sin(t * 3 + seed) * 1.2)
				end
			end
			if petal.Life > 16 or (petal.Landed and petal.Landed > 2) then
				petal.Alive = false
				petal.Wait = rng:NextNumber(0, 2)
				p.Transparency = 1
			end
		end
	end)
end

-- Remolinos de los portales: giran suavemente (solo visual, en el cliente)
local function startPortals()
	local swirls = {}
	local function add(part: Instance)
		if part:IsA("BasePart") then
			swirls[part] = part.CFrame
		end
	end
	CollectionService:GetInstanceAddedSignal("PortalSwirl"):Connect(add)
	for _, p in CollectionService:GetTagged("PortalSwirl") do
		add(p)
	end
	local angle = 0
	RunService.RenderStepped:Connect(function(dt)
		angle += dt * 1.6
		for part, base in swirls do
			if part.Parent then
				part.CFrame = base * CFrame.Angles(0, 0, angle)
			else
				swirls[part] = nil
			end
		end
	end)
end

function LobbyController.Start()
	task.spawn(startPetals)
	task.spawn(startPortals)

	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
		local action = ACTIONS[prompt:GetAttribute("Action") or ""]
		if action then
			action(prompt)
		end
	end)

	local gui = UI.screenGui("LobbyHUD", 5)

	-- Barra del Dojo
	local dojoBar = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 58), Size = UDim2.fromOffset(360, 40),
		BackgroundColor3 = UI.Colors.Panel, BackgroundTransparency = 0.1, Visible = false,
	}, gui)
	UI.corner(dojoBar, 10)
	UI.stroke(dojoBar, Color3.fromRGB(60, 160, 220), 2)
	UI.autoScale(dojoBar)
	UI.label(dojoBar, { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -150, 1, 0), Text = "Dojo de práctica", TextSize = 15 })
	local back = UI.button(dojoBar, "Volver al Lobby", Color3.fromRGB(60, 160, 220), {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(136, 28), TextSize = 13,
	})
	back.Activated:Connect(function()
		request("ReturnToLobby")
	end)

	-- Guía de bienvenida
	local guide = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -150), Size = UDim2.fromOffset(560, 74),
		BackgroundColor3 = UI.Colors.Panel, BackgroundTransparency = 0.15, Visible = false,
	}, gui)
	UI.corner(guide, 12)
	UI.stroke(guide, UI.Colors.Gold, 2)
	UI.autoScale(guide)
	UI.label(guide, {
		Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -28, 0, 24), TextSize = 17, Font = Enum.Font.GothamBlack,
		Text = "Escuela de Hechicería", TextColor3 = UI.Colors.Gold,
	})
	UI.label(guide, {
		Position = UDim2.fromOffset(14, 32), Size = UDim2.new(1, -28, 0, 36), TextSize = 13, TextWrapped = true,
		TextColor3 = UI.Colors.Text,
		Text = "Derecha: Sala de Combate (pisa un círculo para buscar rivales) · Dentro de la Escuela: Personajes · Izquierda: Historia · Pase y Tienda delante · Pulsa E en cada puesto",
	})

	local lastZone = nil
	local guideShown = 0
	task.spawn(function()
		while true do
			task.wait(0.4)
			local arenaId = player:GetAttribute("ArenaId")
			local activity = player:GetAttribute("Activity")
			dojoBar.Visible = arenaId == "Hub" and (activity == "Hub" or activity == "Queue")
			if arenaId ~= lastZone then
				lastZone = arenaId
				if arenaId == "Lobby" and guideShown < 3 then
					guideShown += 1
					guide.Visible = true
					task.delay(14, function()
						guide.Visible = false
					end)
				else
					guide.Visible = false
				end
			end
		end
	end)
end

return LobbyController
