-- TutorialController: tutorial guiado OPCIONAL y largo, contado por personajes (estilo anime).
--   * Al entrar por primera vez te pregunta si quieres hacerlo; se puede saltar en cualquier momento
--     y empezar o repetir con el botón "Tutorial" del menú.
--   * Antes de cada paso hablan Shiro (el profesor), Kaito (tu compañero) o Mika, con retrato 3D,
--     texto que se escribe solo y clic para continuar.
--   * Guía hacia el objetivo:
--       - cristal de energía maldita girando sobre el destino, con un pilar de luz y la distancia
--       - sello que gira en el suelo del destino
--       - camino de talismanes (ofuda) que se iluminan en oleada desde ti hasta el destino
--       - flecha en el borde de la pantalla cuando el destino no se ve
--       - marco dorado + "¡AQUÍ!" alrededor del botón cuando el paso es de interfaz
-- Al terminar, el servidor da la recompensa (una sola vez).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local Sfx = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Sfx"))
local Portrait = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Portrait"))
local StateController = require(script.Parent:WaitForChild("StateController"))
local CurrencyController = require(script.Parent:WaitForChild("CurrencyController"))
local MovementController = require(script.Parent:WaitForChild("MovementController"))

local player = Players.LocalPlayer

local TutorialController = {}

local GOLD = Color3.fromRGB(255, 210, 90)
local CURSED = Color3.fromRGB(170, 80, 255)

-- ===================================================================
-- Personajes que hablan
-- ===================================================================
local SPEAKERS = {
	Shiro = { Name = "Shiro Tenma · Profesor", Character = "Sorcerer", Color = Color3.fromRGB(120, 190, 255) },
	Kaito = { Name = "Kaito Hayami", Character = "Brawler", Color = Color3.fromRGB(255, 110, 140) },
	Mika = { Name = "Mika Zenra", Character = "WeaponMaster", Color = Color3.fromRGB(90, 220, 130) },
}

-- ===================================================================
-- Utilidades
-- ===================================================================
local function lobbyPos(x: number, y: number, z: number): Vector3?
	local lobby = workspace:FindFirstChild("Lobby")
	return lobby and (lobby:GetPivot().Position + Vector3.new(x, y, z))
end

local function myRoot(): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function near(target: Vector3?, dist: number): boolean
	local root = myRoot()
	return root ~= nil and target ~= nil and (root.Position - target).Magnitude < dist
end

local function modalOpen(guiName: string): boolean
	local pg = player:FindFirstChildOfClass("PlayerGui")
	local g = pg and pg:FindFirstChild(guiName)
	for _, f in (g and g:GetChildren() or {}) do
		if f:IsA("Frame") and f.Visible and f.ZIndex == 10 then
			return true
		end
	end
	return false
end

local function dummy(): Model?
	return workspace:FindFirstChild("TrainingDummy") :: Model?
end

local function dummyGround(): Vector3?
	local d = dummy()
	local root = d and d:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root and root.Position - Vector3.new(0, 3, 0)
end

-- Señales que rellenan los pasos
local lastMoveKey: string? = nil
local runTime = 0
local cancelled = false

-- ===================================================================
-- Pasos: Talk (diálogo antes), Text (objetivo), Target (3D), Button (botón a señalar), Done()
-- ===================================================================
local STEPS = {
	{
		Talk = {
			{ "Shiro", "¡Bienvenido a la Escuela de Hechicería! Soy Shiro, tu profesor. Desde hoy eres uno de los nuestros." },
			{ "Kaito", "¡Eh, novato! Yo soy Kaito. Tranquilo, el profe parece serio pero es un buenazo... casi siempre." },
			{ "Shiro", "Lo primero: cada día que vengas te espera un premio. Ve a por él." },
		},
		Text = "Reclama tu [premio diario]", Button = "PREMIOS",
		Done = function()
			local st = StateController.Get()
			local login = st and st.Login
			return login ~= nil and login.LastDay == math.floor(StateController.Now() / 86400)
		end,
	},
	{
		Talk = {
			{ "Kaito", "¡Bien! Con eso ya tienes tus primeras Monedas Malditas." },
			{ "Shiro", "Delante de la entrada están los puestos del patio. El de la izquierda es el del Pase de Batalla." },
		},
		Text = "Ve al puesto del [Pase de Batalla] y ábrelo (E)",
		Target = function()
			return lobbyPos(-40, 0, 52)
		end,
		Done = function()
			return modalOpen("BattlePass")
		end,
	},
	{
		Talk = {
			{ "Mika", "Cada partida te da XP del pase. Sube niveles y te llevas monedas, gemas y skins." },
			{ "Mika", "Al otro lado está la tienda. Échale un ojo, que hay efectos de KO preciosos." },
		},
		Text = "Visita la [Tienda] (E en el puesto)",
		Target = function()
			return lobbyPos(40, 0, 52)
		end,
		Done = function()
			return modalOpen("Store")
		end,
	},
	{
		Talk = {
			{ "Kaito", "¿Ves la estatua del centro? Ahí sale el mejor jugador del servidor." },
			{ "Kaito", "Algún día serás tú... después de mí, claro." },
		},
		Text = "Acércate a la [Estatua del Campeón]",
		Target = function()
			return lobbyPos(0, 0, 8)
		end,
		Done = function()
			return near(lobbyPos(0, 0, 0), 16)
		end,
	},
	{
		Talk = {
			{ "Shiro", "Dentro de la Escuela está la Sala de Personajes: todos los hechiceros que puedes ser." },
		},
		Text = "Entra en la [Sala de Personajes]",
		Target = function()
			return lobbyPos(0, 0, -112)
		end,
		Done = function()
			return near(lobbyPos(0, 0, -118), 18)
		end,
	},
	{
		Talk = {
			{ "Shiro", "Cada personaje tiene sus técnicas y su ulti: Expansiones de Dominio, transformaciones..." },
			{ "Mika", "¡Y puedes PROBARLOS gratis en el Dojo antes de comprarlos! Abre la ventana de personajes." },
		},
		Text = "Abre la ventana de [Personajes]", Button = "PERSONAJES",
		Done = function()
			return modalOpen("CharacterShop")
		end,
	},
	{
		Talk = {
			{ "Kaito", "A la izquierda del patio está el Santuario. Ahí empieza el Modo Historia." },
			{ "Shiro", "Crónicas del Sello Maldito... Cuando estés listo, ve. De momento, solo echa un vistazo." },
		},
		Text = "Visita el [Santuario del Modo Historia]",
		Target = function()
			return lobbyPos(-80, 0, -10)
		end,
		Done = function()
			return near(lobbyPos(-80, 0, -10), 18)
		end,
	},
	{
		Talk = {
			{ "Shiro", "Bien. Ahora a entrenar. A la derecha está la Sala de Combate." },
			{ "Kaito", "¡El portal azul es el Dojo! Ahí hay un muñeco que no se queja por mucho que le pegues." },
		},
		Text = "Entra al [Dojo de práctica]: pulsa E en el portal azul",
		Target = function()
			return lobbyPos(114, 0, 20)
		end,
		Done = function()
			return player:GetAttribute("ArenaId") == "Hub"
		end,
	},
	{
		Talk = {
			{ "Shiro", "En combate todo es velocidad. Mantén Shift, toca dos veces la dirección o empuja el joystick a tope." },
		},
		Text = "[Corre] un poco  (Shift · doble toque · joystick a tope)",
		Done = function()
			return runTime > 0.8
		end,
	},
	{
		Talk = {
			{ "Kaito", "Y en el aire puedes saltar otra vez. ¡Es lo que te salva cuando te mandan a volar!" },
		},
		Text = "Haz un [doble salto]  (salta y vuelve a saltar en el aire)",
		Done = function()
			return MovementController.AirJumpsUsed() >= 1
		end,
	},
	{
		Talk = {
			{ "Mika", "El muñeco te espera. Golpe rápido con clic o J, golpe fuerte con clic derecho o K." },
			{ "Shiro", "Aquí no hay barra de vida: cuanto más porcentaje tiene, más lejos sale volando." },
		},
		Text = "Golpea al muñeco hasta el [30%]  (Clic / J · Clic derecho / K)",
		Target = dummyGround,
		Done = function()
			local d = dummy()
			return d ~= nil and (d:GetAttribute("Percent") or 0) >= 30
		end,
	},
	{
		Talk = {
			{ "Kaito", "Truco: mantén arriba (W) mientras atacas y el golpe sale hacia arriba. Igual con los lados y abajo." },
		},
		Text = "Haz un [ataque hacia arriba]  (W + ataque)",
		Done = function()
			return lastMoveKey ~= nil and lastMoveKey:find("_Up") ~= nil
		end,
	},
	{
		Talk = {
			{ "Shiro", "Ahora lo importante: tus TÉCNICAS. Cada hechicero tiene las suyas, con E o L." },
			{ "Shiro", "Arriba + técnica te sirve para volver al escenario si te caes. No lo olvides." },
		},
		Text = "Usa una [técnica especial]  (E / L)",
		Done = function()
			return lastMoveKey ~= nil and lastMoveKey:find("Special") ~= nil
		end,
	},
	{
		Talk = {
			{ "Mika", "Para defenderte, mantén el escudo. Si te mueves con él puesto, esquivas." },
		},
		Text = "Mantén el [escudo]  (Q · L1 · botón Escudo)",
		Done = function()
			local c = player.Character
			return c ~= nil and c:GetAttribute("Shielding") == true
		end,
	},
	{
		Talk = {
			{ "Kaito", "Contra los que solo se cubren con escudo: ¡agárralos! Acércate y pulsa G. Luego lánzalos con una dirección." },
		},
		Text = "[Agarra] al muñeco  (G · R1 · botón Agarre)",
		Target = dummyGround,
		Done = function()
			return lastMoveKey ~= nil and (lastMoveKey == "Grab" or lastMoveKey:find("Throw") ~= nil)
		end,
	},
	{
		Talk = {
			{ "Kaito", "¡Ahora dale con todo! Si lo subes mucho, sale volando como un cohete." },
			{ "Shiro", "Peleando se carga tu barra de ULTI. Cuando esté llena, pulsa R... y verás algo especial." },
		},
		Text = "Sube al muñeco hasta el [80%]",
		Target = dummyGround,
		Done = function()
			local d = dummy()
			return d ~= nil and (d:GetAttribute("Percent") or 0) >= 80
		end,
	},
	{
		Talk = {
			{ "Shiro", "Excelente. Ya estás listo para pelear de verdad. Vuelve al patio." },
		},
		Text = "¡Bien! Vuelve al [Lobby]", Button = "VOLVER AL LOBBY",
		Done = function()
			return player:GetAttribute("ArenaId") == "Lobby"
		end,
	},
	{
		Talk = {
			{ "Kaito", "¿Te atreves con rivales de verdad? Pisa el círculo de Partida Rápida en la Sala de Combate." },
			{ "Shiro", "Antes de cada partida podréis votar el escenario. Suerte, hechicero." },
		},
		Text = "Busca rivales: pisa el círculo de [Partida Rápida]",
		Target = function()
			return lobbyPos(100, 0, -40)
		end,
		Done = function()
			local a = player:GetAttribute("Activity")
			return a == "Queue" or a == "Match"
		end,
	},
}

local OUTRO = {
	{ "Shiro", "Has terminado el tutorial. Toma, un pequeño regalo de bienvenida." },
	{ "Kaito", "¡Nos vemos en la arena! Y no llores cuando te gane." },
}

-- ===================================================================
-- Interfaz
-- ===================================================================
local gui: ScreenGui
local banner: Frame
local bannerText: TextLabel
local bannerStep: TextLabel
local bannerBar: Frame
local distanceLabel: TextLabel
local buttonFrame: Frame
local edgeArrow: Frame
local dialogue: Frame
local dlgName: TextLabel
local dlgText: TextLabel
local dlgPortrait: Frame
local dlgHint: TextLabel
local clickCatcher: TextButton
local advance = Instance.new("BindableEvent")

-- Guías 3D (solo existen en tu cliente)
local guideFolder: Folder
local crystal: Part
local crystalShell: Part
local pillar: Part
local seal: Part
local sealRing: Part
local markerDistance: TextLabel
local talismans: { Part } = {}
local TALISMAN_COUNT = 24
local TALISMAN_GAP = 5

local active = false

local function rich(text: string): string
	return (text:gsub("%[(.-)%]", '<font color="#FFD25A">%1</font>'))
end

local function findButton(text: string): GuiObject?
	local pg = player:FindFirstChildOfClass("PlayerGui")
	for _, g in (pg and pg:GetChildren() or {}) do
		if g:IsA("ScreenGui") and g.Enabled and g ~= gui then
			for _, d in g:GetDescendants() do
				if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Visible and string.upper(d.Text) == text then
					local target = if d:IsA("TextButton") then d else d.Parent
					if target and target:IsA("GuiObject") and target.Visible and target.AbsoluteSize.X > 0 then
						return target
					end
				end
			end
		end
	end
	return nil
end

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

local function buildGuides()
	guideFolder = Instance.new("Folder")
	guideFolder.Name = "TutorialGuides"

	-- Cristal de energía maldita (rombo alargado) con capa de energía
	crystal = part({ Size = Vector3.new(2.2, 2.2, 2.2), Color = GOLD, Parent = guideFolder })
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(0.7, 1.6, 0.7)
	mesh.Parent = crystal
	crystalShell = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 4.2, Color = CURSED, Material = Enum.Material.ForceField, Parent = guideFolder })
	local fx = Instance.new("ParticleEmitter")
	fx.Texture = "rbxasset://textures/particles/fire_main.dds"
	fx.Color = ColorSequence.new(Color3.fromRGB(255, 230, 150), CURSED)
	fx.LightEmission = 1
	fx.LightInfluence = 0
	fx.Size = NumberSequence.new(1.2, 0)
	fx.Transparency = NumberSequence.new(0.2, 1)
	fx.Lifetime = NumberRange.new(0.4, 0.7)
	fx.Rate = 40
	fx.Speed = NumberRange.new(1, 3)
	fx.Acceleration = Vector3.new(0, 6, 0)
	fx.Parent = crystal
	local light = Instance.new("PointLight")
	light.Color = GOLD
	light.Range = 16
	light.Brightness = 2
	light.Parent = crystal

	-- Pilar de luz que se ve desde lejos
	pillar = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(120, 3, 3), Color = GOLD, Transparency = 0.82, Parent = guideFolder })

	-- Sello en el suelo: círculo con el kanji 呪 que gira + anillo exterior que late
	seal = part({ Size = Vector3.new(9, 0.2, 9), Transparency = 1, Parent = guideFolder })
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Top
	sg.LightInfluence = 0
	sg.Brightness = 2
	sg.CanvasSize = Vector2.new(400, 400)
	sg.Parent = seal
	local circle = Instance.new("Frame")
	circle.Size = UDim2.fromScale(1, 1)
	circle.BackgroundTransparency = 1
	circle.Parent = sg
	Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
	local stroke = Instance.new("UIStroke")
	stroke.Color = GOLD
	stroke.Thickness = 12
	stroke.Parent = circle
	local kanji = Instance.new("TextLabel")
	kanji.Size = UDim2.fromScale(0.75, 0.75)
	kanji.Position = UDim2.fromScale(0.125, 0.125)
	kanji.BackgroundTransparency = 1
	kanji.Text = "呪"
	kanji.TextScaled = true
	kanji.Font = Enum.Font.GothamBlack
	kanji.TextColor3 = GOLD
	kanji.TextTransparency = 0.15
	kanji.Parent = sg
	sealRing = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.15, 12, 12), Color = CURSED, Transparency = 0.3, Parent = guideFolder })

	-- Cartel flotante con la distancia
	local markerGui = Instance.new("BillboardGui")
	markerGui.Size = UDim2.fromOffset(180, 60)
	markerGui.StudsOffset = Vector3.new(0, 3.2, 0)
	markerGui.AlwaysOnTop = true
	markerGui.LightInfluence = 0
	markerGui.Parent = crystal
	local tag = Instance.new("TextLabel")
	tag.Size = UDim2.new(1, 0, 0.55, 0)
	tag.BackgroundTransparency = 1
	tag.Text = "¡AQUÍ!"
	tag.Font = Enum.Font.PermanentMarker
	tag.TextScaled = true
	tag.TextColor3 = GOLD
	tag.TextStrokeTransparency = 0
	tag.Parent = markerGui
	markerDistance = Instance.new("TextLabel")
	markerDistance.Position = UDim2.fromScale(0, 0.55)
	markerDistance.Size = UDim2.new(1, 0, 0.45, 0)
	markerDistance.BackgroundTransparency = 1
	markerDistance.Font = Enum.Font.GothamBlack
	markerDistance.TextScaled = true
	markerDistance.TextColor3 = Color3.new(1, 1, 1)
	markerDistance.TextStrokeTransparency = 0
	markerDistance.Parent = markerGui

	-- Talismanes (ofuda) del camino: papel blanco con franja roja
	for i = 1, TALISMAN_COUNT do
		local t = part({ Size = Vector3.new(1.1, 0.12, 2.2), Color = Color3.fromRGB(250, 240, 220), Material = Enum.Material.SmoothPlastic, Parent = guideFolder })
		local stripe = part({ Name = "Stripe", Size = Vector3.new(0.35, 0.14, 1.6), Color = Color3.fromRGB(220, 40, 50), Parent = t })
		stripe.Name = "Stripe"
		local glow = Instance.new("PointLight")
		glow.Color = GOLD
		glow.Range = 5
		glow.Brightness = 0
		glow.Parent = t
		talismans[i] = t
	end
end

local function groundY(position: Vector3): number?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { guideFolder, player.Character }
	local hit = workspace:Raycast(position + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), params)
	return hit and hit.Position.Y
end

local function hideGuides()
	guideFolder.Parent = nil
	buttonFrame.Visible = false
	edgeArrow.Visible = false
	distanceLabel.Text = ""
end

-- Coloca todas las guías hacia el objetivo (se llama cada fotograma)
local function updateGuides(target: Vector3?, button: GuiObject?)
	local t = os.clock()
	if target then
		guideFolder.Parent = workspace
		local bob = math.sin(t * 3) * 0.6
		local top = target + Vector3.new(0, 7 + bob, 0)
		crystal.CFrame = CFrame.new(top) * CFrame.Angles(0, t * 2, 0)
		crystalShell.CFrame = CFrame.new(top) * CFrame.Angles(t, t * 1.5, 0)
		pillar.CFrame = CFrame.new(target + Vector3.new(0, 60, 0)) * CFrame.Angles(0, 0, math.rad(90))
		local gy = groundY(target) or target.Y
		seal.CFrame = CFrame.new(target.X, gy + 0.15, target.Z) * CFrame.Angles(0, t * 0.8, 0)
		local k = (t * 0.8) % 1
		sealRing.Size = Vector3.new(0.15, 9 + k * 8, 9 + k * 8)
		sealRing.Transparency = 0.2 + k * 0.8
		sealRing.CFrame = CFrame.new(target.X, gy + 0.2, target.Z) * CFrame.Angles(0, 0, math.rad(90))

		-- Camino de talismanes desde tus pies hasta el objetivo, iluminándose en oleada
		local root = myRoot()
		if root then
			local from = Vector3.new(root.Position.X, 0, root.Position.Z)
			local to = Vector3.new(target.X, 0, target.Z)
			local delta = to - from
			local dist = delta.Magnitude
			markerDistance.Text = `{math.floor(dist)} m`
			distanceLabel.Text = `{math.floor(dist)} m`
			local dir = if dist > 0.1 then delta.Unit else Vector3.zAxis
			for i, tal in talismans do
				local along = i * TALISMAN_GAP
				local stripe = tal:FindFirstChild("Stripe") :: BasePart
				local glow = tal:FindFirstChildOfClass("PointLight") :: PointLight
				if along < dist - 3 then
					local p = from + dir * along
					local y = groundY(Vector3.new(p.X, root.Position.Y, p.Z)) or (root.Position.Y - 3)
					local at = Vector3.new(p.X, y + 0.1, p.Z)
					tal.CFrame = CFrame.lookAt(at, at + dir)
					local wave = (math.sin(t * 6 - i * 0.6) + 1) / 2
					tal.Transparency = 0.05
					tal.Color = Color3.fromRGB(250, 240, 220):Lerp(GOLD, wave)
					stripe.CFrame = tal.CFrame * CFrame.new(0, 0.01, 0)
					stripe.Transparency = 0
					glow.Brightness = wave * 2
				else
					tal.Transparency = 1
					stripe.Transparency = 1
					glow.Brightness = 0
				end
			end
		end

		-- Flecha en el borde de la pantalla si el objetivo no se ve
		local cam = workspace.CurrentCamera
		-- WorldToScreenPoint ya descuenta la barra de Roblox (misma zona que esta interfaz)
		local sp, onScreen = cam:WorldToScreenPoint(top)
		local vs = gui.AbsoluteSize
		if onScreen and sp.X > 40 and sp.X < vs.X - 40 and sp.Y > 40 and sp.Y < vs.Y - 40 then
			edgeArrow.Visible = false
		else
			local center = vs / 2
			local dir2 = Vector2.new(sp.X, sp.Y) - center
			if sp.Z < 0 then
				dir2 = -dir2 -- detrás de la cámara
			end
			if dir2.Magnitude < 1 then
				dir2 = Vector2.new(0, -1)
			end
			dir2 = dir2.Unit
			local margin = 60
			local scaleX = (center.X - margin) / math.max(math.abs(dir2.X), 0.001)
			local scaleY = (center.Y - margin) / math.max(math.abs(dir2.Y), 0.001)
			local p = center + dir2 * math.min(scaleX, scaleY)
			edgeArrow.Position = UDim2.fromOffset(p.X, p.Y)
			edgeArrow.Rotation = math.deg(math.atan2(dir2.Y, dir2.X)) + 90
			edgeArrow.Visible = true
		end
	else
		guideFolder.Parent = nil
		edgeArrow.Visible = false
		distanceLabel.Text = ""
	end

	if button then
		local p, s = button.AbsolutePosition, button.AbsoluteSize
		buttonFrame.Position = UDim2.fromOffset(p.X - 8, p.Y - 8)
		buttonFrame.Size = UDim2.fromOffset(s.X + 16, s.Y + 16)
		local sc = buttonFrame:FindFirstChildOfClass("UIScale") :: UIScale
		sc.Scale = 1 + math.sin(t * 6) * 0.04
		buttonFrame.Visible = true
	else
		buttonFrame.Visible = false
	end
end

local function build()
	gui = UI.screenGui("Tutorial", 30)
	buildGuides()

	-- Cartel de misión (talismán dorado arriba)
	banner = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 150), Size = UDim2.fromOffset(640, 74),
		BackgroundColor3 = Color3.new(1, 1, 1), Visible = false,
	}, gui)
	UI.autoScale(banner)
	UI.corner(banner, 14)
	UI.gradient(banner, Color3.fromRGB(46, 32, 70), Color3.fromRGB(14, 12, 22))
	UI.animatedStroke(banner, GOLD, 2)
	UI.glow(banner, CURSED, 14)
	local sealIcon = UI.make("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(54, 54),
		BackgroundColor3 = Color3.fromRGB(190, 30, 45), Text = "呪", TextSize = 30, Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.fromRGB(255, 235, 200),
	}, banner)
	UI.corner(sealIcon, 999)
	UI.stroke(sealIcon, GOLD, 2)
	bannerStep = UI.make("TextLabel", {
		Position = UDim2.fromOffset(76, 8), Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = CURSED, Text = "", TextSize = 11, Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1),
	}, banner)
	UI.make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, bannerStep)
	UI.corner(bannerStep, 999)
	bannerText = UI.label(banner, {
		Position = UDim2.fromOffset(76, 28), Size = UDim2.new(1, -170, 0, 26), TextSize = 20, Font = Enum.Font.GothamBlack,
		RichText = true, Text = "", TextTruncate = Enum.TextTruncate.AtEnd,
	})
	distanceLabel = UI.label(banner, {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -84, 0, 8), Size = UDim2.fromOffset(80, 18), TextSize = 12,
		TextColor3 = GOLD, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Right, Text = "",
	})
	local barBack = UI.make("Frame", {
		Position = UDim2.new(0, 76, 1, -14), Size = UDim2.new(1, -170, 0, 6), BackgroundColor3 = Color3.fromRGB(40, 34, 60), BorderSizePixel = 0,
	}, banner)
	UI.corner(barBack, 999)
	bannerBar = UI.make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0 }, barBack)
	UI.corner(bannerBar, 999)
	local skip = UI.button(banner, "Saltar", Color3.fromRGB(70, 60, 95), {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(70, 28), TextSize = 12,
	})
	skip.Activated:Connect(function()
		cancelled = true
		advance:Fire()
	end)

	-- Marco dorado alrededor del botón que hay que pulsar
	buttonFrame = UI.make("Frame", { BackgroundTransparency = 1, Visible = false, ZIndex = 50 }, gui)
	UI.make("UIScale", {}, buttonFrame)
	UI.corner(buttonFrame, 12)
	UI.animatedStroke(buttonFrame, GOLD, 4)
	local here = UI.make("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 10, 0.5, 0), Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(190, 30, 45), Text = "◀ ¡AQUÍ!", TextSize = 16, Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.new(1, 1, 1), ZIndex = 51,
	}, buttonFrame)
	UI.make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, here)
	UI.corner(here, 8)
	UI.stroke(here, GOLD, 2)

	-- Flecha del borde de pantalla (rombo + punta)
	edgeArrow = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(64, 64), BackgroundTransparency = 1, Visible = false, ZIndex = 50,
	}, gui)
	local diamond = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromOffset(34, 34), Rotation = 45,
		BackgroundColor3 = Color3.fromRGB(190, 30, 45), ZIndex = 50,
	}, edgeArrow)
	UI.corner(diamond, 6)
	UI.stroke(diamond, GOLD, 3)
	UI.label(edgeArrow, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.18), Size = UDim2.fromOffset(40, 30), Text = "▲",
		TextSize = 30, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0, ZIndex = 51,
	})

	-- Cuadro de diálogo (abajo, estilo anime)
	clickCatcher = UI.make("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Visible = false, ZIndex = 60, AutoButtonColor = false,
	}, gui)
	clickCatcher.Activated:Connect(function()
		advance:Fire()
	end)
	dialogue = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(720, 150),
		BackgroundColor3 = Color3.new(1, 1, 1), Visible = false, ZIndex = 61,
	}, gui)
	UI.autoScale(dialogue)
	UI.corner(dialogue, 16)
	UI.gradient(dialogue, Color3.fromRGB(40, 30, 60), Color3.fromRGB(12, 10, 20))
	UI.animatedStroke(dialogue, CURSED, 2.5)
	UI.glow(dialogue, CURSED, 16)
	dlgPortrait = UI.make("Frame", {
		Position = UDim2.fromOffset(16, -40), Size = UDim2.fromOffset(130, 130), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 62,
	}, dialogue)
	UI.corner(dlgPortrait, 999)
	UI.gradient(dlgPortrait, Color3.new(1, 1, 1), Color3.fromRGB(70, 70, 80))
	UI.stroke(dlgPortrait, Color3.new(1, 1, 1), 3)
	dlgName = UI.make("TextLabel", {
		Position = UDim2.fromOffset(160, -16), Size = UDim2.fromOffset(0, 32), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = CURSED, Text = "", TextSize = 20, Font = UI.TitleFont, TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.4, ZIndex = 63, Rotation = -2,
	}, dialogue)
	UI.make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, dlgName)
	UI.corner(dlgName, 8)
	UI.stroke(dlgName, Color3.new(1, 1, 1), 2)
	dlgText = UI.label(dialogue, {
		Position = UDim2.fromOffset(160, 26), Size = UDim2.new(1, -180, 1, -56), TextSize = 18, TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.GothamBold, ZIndex = 62, Text = "",
	})
	dlgHint = UI.label(dialogue, {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -8), Size = UDim2.fromOffset(260, 18),
		Text = "Clic / toca para continuar ▸", TextSize = 12, TextColor3 = UI.Colors.Muted, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 62,
	})
	local skipTalk = UI.button(dialogue, "Saltar tutorial", Color3.fromRGB(70, 60, 95), {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(120, 26), TextSize = 12, ZIndex = 64,
	})
	skipTalk.Activated:Connect(function()
		cancelled = true
		advance:Fire()
	end)
	-- Espacio / Enter / A del mando también avanzan el diálogo
	UserInputService.InputBegan:Connect(function(input)
		if dialogue.Visible and (input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA or input.KeyCode == Enum.KeyCode.Return) then
			advance:Fire()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			dlgHint.TextTransparency = if dlgHint.TextTransparency < 0.5 then 0.6 else 0
		end
	end)
end

-- Muestra una conversación completa (lista de { quién, texto })
local function talk(lines)
	if not lines or #lines == 0 then
		return
	end
	hideGuides()
	dialogue.Visible = true
	clickCatcher.Visible = true
	local s = dialogue:FindFirstChildOfClass("UIScale") :: UIScale
	local base = s.Scale
	s.Scale = base * 0.9
	TweenService:Create(s, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = base }):Play()
	local currentSpeaker = nil
	for _, line in lines do
		if cancelled then
			break
		end
		local who = SPEAKERS[line[1]] or SPEAKERS.Shiro
		if who ~= currentSpeaker then
			currentSpeaker = who
			for _, c in dlgPortrait:GetChildren() do
				if c:IsA("ViewportFrame") then
					c:Destroy()
				end
			end
			dlgPortrait.BackgroundColor3 = who.Color
			local vp = Portrait.Create(dlgPortrait, who.Character, "Bust", { Size = UDim2.fromScale(1, 1), ZIndex = 63 })
			UI.corner(vp, 999)
			dlgName.Text = who.Name
			dlgName.BackgroundColor3 = who.Color:Lerp(Color3.new(0, 0, 0), 0.25)
			-- pequeño salto del retrato al cambiar de personaje
			dlgPortrait.Position = UDim2.fromOffset(16, -30)
			TweenService:Create(dlgPortrait, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Position = UDim2.fromOffset(16, -40) }):Play()
		end
		dlgText.Text = line[2]
		dlgText.MaxVisibleGraphemes = 0
		local total = utf8.len(line[2]) or #line[2]
		local typing = true
		local conn = advance.Event:Connect(function()
			typing = false
		end)
		for i = 1, total do
			if not typing or cancelled then
				break
			end
			dlgText.MaxVisibleGraphemes = i
			if i % 3 == 0 then
				Sfx.Play("Click", nil, 0.15, 1.6)
			end
			task.wait(0.022)
		end
		conn:Disconnect()
		dlgText.MaxVisibleGraphemes = -1
		if not cancelled then
			advance.Event:Wait()
		end
	end
	dialogue.Visible = false
	clickCatcher.Visible = false
end

-- Celebración al terminar
local function celebrate()
	Sfx.Play("LevelUp", nil, 1)
	local title = UI.label(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.35), Size = UDim2.fromOffset(700, 90),
		Text = "¡TUTORIAL COMPLETADO!", TextSize = 56, Font = UI.TitleFont, TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0, ZIndex = 70,
	})
	UI.gradient(title, Color3.new(1, 1, 1), GOLD)
	local s = UI.make("UIScale", { Scale = 2 }, title)
	TweenService:Create(s, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(2.2, function()
		TweenService:Create(title, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.wait(0.45)
		title:Destroy()
	end)
end

local function run(fromStep: number)
	if active then
		return
	end
	active = true
	cancelled = false
	lastMoveKey = nil
	runTime = 0
	for i = fromStep, #STEPS do
		local step = STEPS[i]
		talk(step.Talk)
		if cancelled then
			break
		end
		banner.Visible = true
		bannerStep.Text = `PASO {i} / {#STEPS}`
		bannerText.Text = rich(step.Text)
		TweenService:Create(bannerBar, TweenInfo.new(0.4), { Size = UDim2.fromScale((i - 1) / #STEPS, 1) }):Play()
		banner.Position = UDim2.new(0.5, 0, 0, 118)
		TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0, 150) }):Play()
		lastMoveKey = nil
		runTime = 0
		while not step.Done() and not cancelled do
			local dt = task.wait()
			if MovementController.IsRunning() then
				runTime += dt
			end
			local target = step.Target and step.Target()
			local button = step.Button and findButton(step.Button)
			updateGuides(target, button)
		end
		hideGuides()
		if cancelled then
			break
		end
		Sfx.Play("LevelUp", nil, 0.6)
		bannerText.Text = rich("¡Hecho!  [" .. step.Text:gsub("[%[%]]", "") .. "]")
		TweenService:Create(bannerBar, TweenInfo.new(0.4), { Size = UDim2.fromScale(i / #STEPS, 1) }):Play()
		task.wait(1)
		banner.Visible = false
	end
	banner.Visible = false
	hideGuides()
	if cancelled then
		dialogue.Visible = false
		clickCatcher.Visible = false
		active = false
		cancelled = false
		CurrencyController.Toast("Tutorial saltado · puedes repetirlo con el botón Tutorial", UI.Colors.Muted)
		return
	end
	talk(OUTRO)
	active = false
	celebrate()
	local response = StateController.Request("CompleteTutorial")
	if response.msg and response.msg ~= "" then
		CurrencyController.Toast(response.msg, if response.ok then UI.Colors.Gold else UI.Colors.Muted)
	end
end

-- Ventana que pregunta si quieres hacer el tutorial (no es obligatorio)
local function offer(onAccept: () -> ())
	local offerGui = UI.screenGui("TutorialOffer", 40)
	local card = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(460, 240),
		BackgroundColor3 = Color3.new(1, 1, 1),
	}, offerGui)
	UI.autoScale(card)
	UI.corner(card, 18)
	UI.gradient(card, Color3.fromRGB(44, 32, 68), Color3.fromRGB(14, 12, 22))
	UI.animatedStroke(card, GOLD, 2.5)
	UI.glow(card, GOLD, 18)
	local bust = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -50), Size = UDim2.fromOffset(96, 96),
		BackgroundColor3 = SPEAKERS.Shiro.Color,
	}, card)
	UI.corner(bust, 999)
	UI.stroke(bust, Color3.new(1, 1, 1), 3)
	local vp = Portrait.Create(bust, SPEAKERS.Shiro.Character, "Bust", { Size = UDim2.fromScale(1, 1) })
	UI.corner(vp, 999)
	local title = UI.label(card, {
		Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, 0, 0, 34), Text = "¿Quieres hacer el tutorial?", TextSize = 26,
		Font = UI.TitleFont, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.5,
	})
	UI.gradient(title, Color3.new(1, 1, 1), GOLD)
	UI.label(card, {
		Position = UDim2.fromOffset(24, 90), Size = UDim2.new(1, -48, 0, 60), TextWrapped = true, TextSize = 14,
		TextColor3 = UI.Colors.Muted, TextXAlignment = Enum.TextXAlignment.Center,
		Text = "El profesor Shiro y Kaito te enseñarán la Escuela, el combate y tu primera partida. Al terminar te llevas una recompensa.",
	})
	local yes = UI.button(card, "¡VAMOS!", UI.Colors.Green, {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(0.5, -8, 1, -20), Size = UDim2.fromOffset(170, 44), TextSize = 17,
	})
	UI.shine(yes, 1.5)
	local no = UI.button(card, "Ahora no", Color3.fromRGB(70, 60, 95), {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0.5, 8, 1, -20), Size = UDim2.fromOffset(170, 44), TextSize = 15,
	})
	local scale = card:FindFirstChildOfClass("UIScale") :: UIScale
	local target = scale.Scale
	scale.Scale = target * 0.8
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = target }):Play()
	yes.Activated:Connect(function()
		offerGui:Destroy()
		onAccept()
	end)
	no.Activated:Connect(function()
		offerGui:Destroy()
		CurrencyController.Toast("Puedes empezar el tutorial cuando quieras con el botón Tutorial", UI.Colors.Muted)
	end)
end

function TutorialController.Start()
	build()
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CombatFeedback").OnClientEvent:Connect(function(kind, model, key)
		if kind == "MoveStarted" and model == player.Character and typeof(key) == "string" then
			lastMoveKey = key
		end
	end)
	-- Solo la primera vez (lo dice el servidor) y después de la intro
	task.spawn(function()
		local deadline = os.clock() + 30
		while not StateController.Get() and os.clock() < deadline do
			task.wait(0.5)
		end
		local st = StateController.Get()
		if st and not (st.Tutorial and st.Tutorial.Done) then
			while not player:GetAttribute("TitleDone") do
				task.wait(0.3)
			end
			task.wait(if player:GetAttribute("TitleStart") then 12 else 3)
			offer(function()
				run(1)
			end)
		end
	end)
end

function TutorialController.Restart()
	task.spawn(run, 1)
end

return TutorialController
