-- LobbyBuilder: el LOBBY 3D, patio de la Escuela de Hechicería (Jujutsu).
-- Zonas (coordenadas relativas al centro del patio):
--   Centro: estatua del campeón · Fondo: escuela + tablas de clasificación + puerta de la Historia
--   Izquierda: Sala de Personajes (pedestales) · Derecha: Sala de Combate (portales con cola)
--   Delante: puesto del Pase y Tienda · Entrada: torii y punto de aparición
-- Piezas que usa LobbyService: SpawnPoint, ChampionPedestal, LeaderboardWins, LeaderboardLevel,
-- HallSpot (atributo Index), QueuePad (atributo Mode) y ProximityPrompts (atributo Action).
local CollectionService = game:GetService("CollectionService")

local LobbyBuilder = {}

local C = Color3.fromRGB
local M = Enum.Material

LobbyBuilder.HallSlots = 24

-- require "fresco" (el instalador corre en la Command Bar, que cachea los módulos)
local function freshRequire(name: string)
	local m = game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Builders"):WaitForChild(name)
	local c = m:Clone()
	c.Parent = m.Parent
	local ok, result = pcall(require, c)
	c:Destroy()
	return if ok then result else nil
end

function LobbyBuilder.Build(): Model
	local model = Instance.new("Model")
	model.Name = "Lobby"
	local rng = Random.new(11)
	local Env = freshRequire("EnvMeshes")
	local useMeshes = Env ~= nil and Env.Available()

	local function part(props): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Material = M.SmoothPlastic
		for k, v in props do
			(p :: any)[k] = v
		end
		p.Parent = model
		return p
	end
	local function cylY(pos: Vector3, height: number, diameter: number, color: Color3, material, collide: boolean?)
		return part({
			Shape = Enum.PartType.Cylinder, Size = Vector3.new(height, diameter, diameter),
			CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = material or M.SmoothPlastic,
			CanCollide = collide ~= false,
		})
	end
	local function sign(pos: Vector3, text: string, color: Color3, width: number?)
		local anchor = part({ Size = Vector3.one, Position = pos, Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
		local gui = Instance.new("BillboardGui")
		gui.Name = "Sign"
		gui.Size = UDim2.new(width or 18, 0, 3, 0)
		gui.LightInfluence = 0
		gui.MaxDistance = 220
		gui.Parent = anchor
		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.PermanentMarker -- pincel, estilo Jujutsu
		label.TextScaled = true
		label.TextColor3 = color
		label.TextStrokeTransparency = 0.15
		label.Text = text
		label.Parent = gui
		return anchor, label
	end
	local function prompt(parent: BasePart, action: string, text: string, object: string)
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = text
		pp.ObjectText = object
		pp.MaxActivationDistance = 12
		pp.HoldDuration = 0
		pp.RequiresLineOfSight = false
		pp:SetAttribute("Action", action)
		pp.Parent = parent
		return pp
	end
	-- Torii: por defecto se cruza en dirección Z; sideways = true para cruzarlo en dirección X
	local function torii(pos: Vector3, width: number, height: number, red: Color3, sideways: boolean?)
		if useMeshes and Env.Torii(model, pos, width, height, red, sideways) then
			return
		end
		local black = C(30, 25, 25)
		local base = CFrame.new(pos) * CFrame.Angles(0, if sideways then math.rad(90) else 0, 0)
		for _, side in { -1, 1 } do
			cylY((base * CFrame.new(side * width / 2, height / 2, 0)).Position, height, 1.6, red)
		end
		part({ Size = Vector3.new(width + 6, 1.6, 2.2), CFrame = base * CFrame.new(0, height + 0.8, 0), Color = black })
		part({ Size = Vector3.new(width + 3, 1, 1.6), CFrame = base * CFrame.new(0, height - 0.6, 0), Color = red })
		part({ Size = Vector3.new(width, 0.8, 1.2), CFrame = base * CFrame.new(0, height - 4, 0), Color = red })
	end
	local function tree(pos: Vector3, scale: number)
		if useMeshes and Env.Tree(model, pos, scale * 1.55, rng:NextNumber(0, 6.28)) then
			return
		end
		cylY(pos + Vector3.new(0, 7 * scale, 0), 14 * scale, 1.6 * scale, C(90, 60, 45), M.Wood)
		for _ = 1, 5 do
			local leaves = part({
				Shape = Enum.PartType.Ball, Size = Vector3.one * rng:NextNumber(7, 11) * scale, CanCollide = false,
				Position = pos + Vector3.new(rng:NextNumber(-4, 4), 15 * scale + rng:NextNumber(-1, 3), rng:NextNumber(-4, 4)),
				Color = C(255, 170 + rng:NextInteger(0, 30), 200), Material = M.Grass,
			})
			CollectionService:AddTag(leaves, "SakuraCanopy") -- de aquí caen los pétalos (cliente)
		end
	end
	local function lantern(pos: Vector3)
		if useMeshes and Env.Lantern(model, pos, 0.85) then
			return
		end
		part({ Size = Vector3.new(1.4, 3, 1.4), Position = pos + Vector3.new(0, 1.5, 0), Color = C(150, 145, 140), Material = M.Slate })
		local light = part({ Size = Vector3.new(2.2, 1.4, 2.2), Position = pos + Vector3.new(0, 3.7, 0), Color = C(255, 200, 120), Material = M.Neon })
		local pl = Instance.new("PointLight")
		pl.Color = C(255, 190, 120)
		pl.Range = 16
		pl.Brightness = 1.5
		pl.Parent = light
		part({ Size = Vector3.new(2.8, 0.6, 2.8), Position = pos + Vector3.new(0, 4.7, 0), Color = C(120, 115, 110), Material = M.Slate })
	end

	-- ===== Suelo, caminos y muros
	part({ Name = "Ground", Size = Vector3.new(280, 2, 220), Position = Vector3.new(0, -1, 0), Color = C(120, 115, 110), Material = M.Slate })
	part({ Size = Vector3.new(16, 0.2, 200), Position = Vector3.new(0, 0.1, 0), Color = C(165, 160, 150), Material = M.Cobblestone })
	part({ Size = Vector3.new(260, 0.2, 14), Position = Vector3.new(0, 0.1, 0), Color = C(165, 160, 150), Material = M.Cobblestone })
	for _, x in { -140, 140 } do
		part({ Size = Vector3.new(4, 8, 220), Position = Vector3.new(x, 4, 0), Color = C(220, 210, 190) })
		part({ Size = Vector3.new(6, 1.2, 222), Position = Vector3.new(x, 8.6, 0), Color = C(60, 50, 55) })
	end
	part({ Size = Vector3.new(284, 8, 4), Position = Vector3.new(0, 4, 110), Color = C(220, 210, 190) })
	part({ Size = Vector3.new(284, 1.2, 6), Position = Vector3.new(0, 8.6, 110), Color = C(60, 50, 55) })
	-- Límites invisibles (altos: no se pueden saltar) para no salirse del patio
	for _, b in {
		{ Vector3.new(4, 120, 270), Vector3.new(-139, 60, -18) }, { Vector3.new(4, 120, 270), Vector3.new(139, 60, -18) },
		{ Vector3.new(282, 120, 4), Vector3.new(0, 60, 109) }, { Vector3.new(282, 120, 4), Vector3.new(0, 60, -147) },
		{ Vector3.new(282, 4, 260), Vector3.new(0, 122, -18) },
	} do
		part({ Name = "Boundary", Size = b[1], Position = b[2], Transparency = 1, CanQuery = false, CastShadow = false })
	end
	-- Hierba fuera de los muros
	part({ Size = Vector3.new(900, 1, 900), Position = Vector3.new(0, -2.5, 0), Color = C(90, 130, 80), Material = M.Grass })

	-- ===== Entrada: torii + aparición
	torii(Vector3.new(0, 0, 92), 22, 22, C(200, 40, 35))
	local spawn = part({ Name = "SpawnPoint", Size = Vector3.new(10, 0.4, 10), Position = Vector3.new(0, 0.2, 64), Color = C(200, 180, 255), Material = M.Neon, CanCollide = false, Transparency = 0.6 })
	spawn:SetAttribute("Facing", Vector3.new(0, 0, -1))
	sign(Vector3.new(0, 30, 92), "呪術高専 · ESCUELA DE HECHICERÍA", C(255, 230, 200), 34)

	-- ===== Escuela al fondo (hueca: dentro está la Sala de Personajes)
	local WALL = C(235, 225, 205)
	local DARK_WOOD = C(60, 40, 35)
	local SCHOOL_Z = -128
	-- Planta alta maciza (exterior) y tejado
	part({ Size = Vector3.new(200, 28, 36), Position = Vector3.new(0, 36, SCHOOL_Z), Color = WALL })
	part({ Size = Vector3.new(210, 4, 42), Position = Vector3.new(0, 52, SCHOOL_Z), Color = C(60, 50, 55) })
	part({ Shape = Enum.PartType.Wedge, Size = Vector3.new(210, 14, 22), CFrame = CFrame.new(0, 61, -118), Color = C(70, 55, 60) })
	part({ Shape = Enum.PartType.Wedge, Size = Vector3.new(210, 14, 22), CFrame = CFrame.new(0, 61, -138) * CFrame.Angles(0, math.rad(180), 0), Color = C(70, 55, 60) })
	if useMeshes then
		-- Tejados japoneses curvos (sustituyen a las cuñas) + alero entre plantas + entramado de madera
		for _, d in model:GetChildren() do
			if d:IsA("Part") and (d.Shape == Enum.PartType.Wedge or d.Size == Vector3.new(210, 4, 42)) and math.abs(d.Position.Z - SCHOOL_Z) < 15 and d.Position.Y > 45 then
				d:Destroy()
			end
		end
		Env.Roof(model, CFrame.new(0, 50, SCHOOL_Z), 216, 48, 20, C(55, 58, 72))
		Env.Roof(model, CFrame.new(0, 21.5, SCHOOL_Z + 18), 208, 10, 3.5, C(55, 58, 72))
		for x = -97.75, 97.75, 11.5 do
			-- las vigas no pueden caer delante de la puerta (antes tapaban la entrada)
			if math.abs(x) > 10 then
				part({ Size = Vector3.new(1.2, 48, 1.2), Position = Vector3.new(x, 24, -109.4), Color = DARK_WOOD, Material = M.Wood, CanCollide = false })
			end
		end
		for _, y in { 23, 49.4 } do
			part({ Size = Vector3.new(202, 1.2, 1.4), Position = Vector3.new(0, y, -109.4), Color = DARK_WOOD, Material = M.Wood, CanCollide = false })
		end
		-- zócalo de madera a ras de suelo, partido en dos para dejar libre la puerta
		for _, x in { -54.5, 54.5 } do
			part({ Size = Vector3.new(91, 1.2, 1.4), Position = Vector3.new(x, 0.6, -109.4), Color = DARK_WOOD, Material = M.Wood, CanCollide = false })
		end
	end
	-- Planta baja: muros con la puerta en el centro
	part({ Size = Vector3.new(92, 22, 2), Position = Vector3.new(-54, 11, -111), Color = WALL })
	part({ Size = Vector3.new(92, 22, 2), Position = Vector3.new(54, 11, -111), Color = WALL })
	part({ Size = Vector3.new(16, 6, 2), Position = Vector3.new(0, 19, -111), Color = WALL })
	part({ Size = Vector3.new(200, 22, 2), Position = Vector3.new(0, 11, -145), Color = WALL })
	for _, x in { -99, 99 } do
		part({ Size = Vector3.new(2, 22, 32), Position = Vector3.new(x, 11, SCHOOL_Z), Color = WALL })
	end
	-- Marco de la puerta, escalón y cartel
	for _, x in { -8.6, 8.6 } do
		part({ Size = Vector3.new(1.4, 16, 3), Position = Vector3.new(x, 8, -110.5), Color = DARK_WOOD })
	end
	part({ Size = Vector3.new(20, 1.6, 3.2), Position = Vector3.new(0, 16.6, -110.5), Color = DARK_WOOD })
	part({ Size = Vector3.new(22, 0.6, 6), Position = Vector3.new(0, 0.3, -107), Color = C(150, 145, 140), Material = M.Slate })
	sign(Vector3.new(0, 20.5, -108), "SALA DE PERSONAJES", C(255, 170, 210), 22)
	-- Tejadillo sobre la entrada
	part({ Size = Vector3.new(26, 0.8, 6), CFrame = CFrame.new(0, 18.2, -106.5) * CFrame.Angles(math.rad(-12), 0, 0), Color = C(55, 58, 72), Material = M.Slate })
	for _, x in { -11, 11 } do
		part({ Size = Vector3.new(0.8, 18, 0.8), Position = Vector3.new(x, 9, -104.2), Color = DARK_WOOD, Material = M.Wood })
	end
	-- Ventanas de la fachada (las de la puerta no)
	for row = 0, 2 do
		for col = -8, 8 do
			if row == 0 and math.abs(col) <= 1 then
				continue
			end
			part({
				Size = Vector3.new(6, 6, 1), Position = Vector3.new(col * 11.5, 10 + row * 13, -109.6), CanCollide = false,
				Color = if (row + col) % 3 == 0 then C(255, 220, 150) else C(90, 110, 140), Material = if (row + col) % 3 == 0 then M.Neon else M.Glass,
			})
		end
	end

	-- ===== Interior: Sala de Personajes
	part({ Size = Vector3.new(196, 0.4, 32), Position = Vector3.new(0, 0.2, SCHOOL_Z), Color = C(95, 65, 50), Material = M.WoodPlanks })
	part({ Size = Vector3.new(190, 0.1, 7), Position = Vector3.new(0, 0.45, SCHOOL_Z), Color = C(150, 25, 35), Material = M.Fabric })
	part({ Size = Vector3.new(190, 0.12, 0.5), Position = Vector3.new(0, 0.46, SCHOOL_Z - 3.7), Color = C(220, 180, 70), Material = M.Metal })
	part({ Size = Vector3.new(190, 0.12, 0.5), Position = Vector3.new(0, 0.46, SCHOOL_Z + 3.7), Color = C(220, 180, 70), Material = M.Metal })
	part({ Size = Vector3.new(7, 0.1, 18), Position = Vector3.new(0, 0.45, -116), Color = C(150, 25, 35), Material = M.Fabric })
	-- Techo de madera (antes se veía el bloque de la planta alta) y decoración de las paredes
	part({ Size = Vector3.new(196, 0.4, 32), Position = Vector3.new(0, 21.9, SCHOOL_Z), Color = C(120, 85, 60), Material = M.WoodPlanks, CanCollide = false })
	local WAINSCOT = C(70, 45, 35)
	local PAPER = C(250, 238, 215)
	-- zócalo de madera + moldura dorada en la pared del fondo y en la de la entrada (dejando libre la puerta)
	part({ Size = Vector3.new(196, 4, 0.4), Position = Vector3.new(0, 2, -143.8), Color = WAINSCOT, Material = M.Wood })
	part({ Size = Vector3.new(196, 0.4, 0.5), Position = Vector3.new(0, 4.2, -143.7), Color = C(220, 180, 70), Material = M.Metal })
	for _, x in { -53.5, 53.5 } do
		part({ Size = Vector3.new(91, 4, 0.4), Position = Vector3.new(x, 2, -112.2), Color = WAINSCOT, Material = M.Wood })
		part({ Size = Vector3.new(91, 0.4, 0.5), Position = Vector3.new(x, 4.2, -112.3), Color = C(220, 180, 70), Material = M.Metal })
	end
	for _, x in { -98.8, 98.8 } do
		part({ Size = Vector3.new(0.4, 4, 32), Position = Vector3.new(x, 2, SCHOOL_Z), Color = WAINSCOT, Material = M.Wood })
	end
	-- Paneles shoji (papel con celosía de madera) en la pared de la entrada, por dentro
	local function shoji(center: Vector3, width: number, height: number, z: number)
		part({ Size = Vector3.new(width, height, 0.2), Position = Vector3.new(center.X, center.Y, z), Color = PAPER, Material = M.SmoothPlastic, CanCollide = false })
		local function bar(size: Vector3, pos: Vector3)
			part({ Size = size, Position = pos, Color = DARK_WOOD, Material = M.Wood, CanCollide = false })
		end
		local zb = z + (if z < SCHOOL_Z then 0.15 else -0.15)
		bar(Vector3.new(width + 0.6, 0.5, 0.3), Vector3.new(center.X, center.Y + height / 2, zb))
		bar(Vector3.new(width + 0.6, 0.5, 0.3), Vector3.new(center.X, center.Y - height / 2, zb))
		bar(Vector3.new(0.5, height, 0.3), Vector3.new(center.X - width / 2, center.Y, zb))
		bar(Vector3.new(0.5, height, 0.3), Vector3.new(center.X + width / 2, center.Y, zb))
		for i = 1, 2 do
			bar(Vector3.new(0.18, height, 0.25), Vector3.new(center.X - width / 2 + width * i / 3, center.Y, zb))
			bar(Vector3.new(width, 0.18, 0.25), Vector3.new(center.X, center.Y - height / 2 + height * i / 3, zb))
		end
	end
	for _, x in { -82.5, -67.5, -52.5, -37.5, -22.5, 22.5, 37.5, 52.5, 67.5, 82.5 } do
		shoji(Vector3.new(x, 11, 0), 9, 9, -112.3)
	end
	-- Por dentro de la puerta: marco de madera y noren (cortina partida con el kanji 術)
	for _, x in { -8.6, 8.6 } do
		part({ Size = Vector3.new(1.4, 16, 1.2), Position = Vector3.new(x, 8, -112.6), Color = DARK_WOOD, Material = M.Wood })
	end
	part({ Size = Vector3.new(20, 1.6, 1.2), Position = Vector3.new(0, 16.6, -112.6), Color = DARK_WOOD, Material = M.Wood })
	for i, x in { -5.2, 0, 5.2 } do
		local strip = part({ Size = Vector3.new(4.9, 4.5, 0.1), Position = Vector3.new(x, 13.4, -112.8), Color = C(150, 25, 35), Material = M.Fabric, CanCollide = false })
		if i == 2 then
			local g = Instance.new("SurfaceGui")
			g.Face = Enum.NormalId.Back
			g.LightInfluence = 0.5
			g.CanvasSize = Vector2.new(100, 90)
			g.Parent = strip
			local t = Instance.new("TextLabel")
			t.Size = UDim2.fromScale(1, 1)
			t.BackgroundTransparency = 1
			t.Text = "術"
			t.Font = Enum.Font.GothamBlack
			t.TextScaled = true
			t.TextColor3 = C(250, 238, 215)
			t.Parent = g
		end
	end

	-- Vigas del techo y farolillos de papel sobre el pasillo
	for x = -90, 90, 15 do
		part({ Size = Vector3.new(1.6, 1.6, 34), Position = Vector3.new(x, 21, SCHOOL_Z), Color = DARK_WOOD, Material = M.Wood })
		if x < 90 then
			local lamp = part({
				Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 3.2, 2.6), Position = Vector3.new(x + 7.5, 15, SCHOOL_Z),
				Color = if (x // 15) % 2 == 0 then C(255, 120, 90) else C(255, 210, 140), Material = M.Neon, CanCollide = false,
			})
			part({ Size = Vector3.new(0.15, 4.5, 0.15), Position = Vector3.new(x + 7.5, 18.8, SCHOOL_Z), Color = C(30, 25, 25), CanCollide = false })
			local light = Instance.new("PointLight")
			light.Color = C(255, 190, 140)
			light.Range = 18
			light.Brightness = 1.2
			light.Shadows = true
			light.Parent = lamp
		end
	end
	-- Pedestales: 12 delante (miran al fondo) y 12 al fondo (miran a la puerta), con foco y anillo de rareza
	local slot = 0
	for _, rowInfo in { { Z = -116.5, Facing = Vector3.new(0, 0, -1) }, { Z = -139.5, Facing = Vector3.new(0, 0, 1) } } do
		for _, x in { -90, -75, -60, -45, -30, -15, 15, 30, 45, 60, 75, 90 } do
			slot += 1
			local base = Vector3.new(x, 0.4, rowInfo.Z)
			local pedestal = part({
				Name = "HallSpot", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.6, 6.4, 6.4),
				CFrame = CFrame.new(base + Vector3.new(0, 1.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = C(40, 35, 55), Material = M.Marble,
			})
			pedestal:SetAttribute("Index", slot)
			pedestal:SetAttribute("Facing", rowInfo.Facing)
			local ring = part({
				Name = "HallRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 7.4, 7.4), CanCollide = false,
				CFrame = CFrame.new(base + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = C(200, 200, 220), Material = M.Neon,
			})
			ring:SetAttribute("Index", slot)
			local lightPart = part({ Size = Vector3.one, Position = base + Vector3.new(0, 19.5, 0), Transparency = 1, CanCollide = false, CanQuery = false })
			local spot = Instance.new("SpotLight")
			spot.Face = Enum.NormalId.Bottom
			spot.Angle = 50
			spot.Range = 24
			spot.Brightness = 3
			spot.Color = C(255, 240, 225)
			spot.Shadows = true
			spot.Parent = lightPart
			-- Pilares entre pedestales y estandartes en la pared del fondo
			if x ~= 90 and x ~= -15 then
				cylY(Vector3.new(x + 7.5, 11, rowInfo.Z + (if rowInfo.Facing.Z < 0 then 3 else -3)), 22, 1.6, DARK_WOOD, M.Wood)
			end
			if rowInfo.Facing.Z > 0 then
				local banner = part({ Size = Vector3.new(5, 12, 0.3), Position = Vector3.new(x, 12, -143.7), Color = C(140, 20, 30), Material = M.Fabric, CanCollide = false })
				local gui = Instance.new("SurfaceGui")
				gui.Face = Enum.NormalId.Back
				gui.CanvasSize = Vector2.new(100, 240)
				gui.LightInfluence = 0.4
				gui.Parent = banner
				local glyph = Instance.new("TextLabel")
				glyph.Size = UDim2.fromScale(1, 1)
				glyph.BackgroundTransparency = 1
				glyph.Font = Enum.Font.GothamBlack
				glyph.TextScaled = true
				glyph.TextColor3 = C(255, 215, 120)
				glyph.Text = if slot % 2 == 0 then "呪" else "術"
				glyph.Parent = gui
			end
		end
	end

	-- ===== Tablas de clasificación (a los lados de la escuela)
	for _, info in { { "LeaderboardWins", -62, "MURO DE LEYENDAS" }, { "LeaderboardLevel", 62, "TOP NIVELES" } } do
		local board = part({ Name = info[1], Size = Vector3.new(34, 26, 1), Position = Vector3.new(info[2], 17, -90), Color = C(20, 16, 34) })
		part({ Size = Vector3.new(35, 27, 0.6), Position = Vector3.new(info[2], 17, -90.6), Color = C(150, 70, 220), Material = M.Neon })
		cylY(Vector3.new(info[2] - 16, 2, -90), 4, 1.4, C(60, 50, 55))
		cylY(Vector3.new(info[2] + 16, 2, -90), 4, 1.4, C(60, 50, 55))
		board:SetAttribute("Title", info[3])
	end

	-- ===== Centro: estatua del campeón
	cylY(Vector3.new(0, 0.6, 0), 1.2, 30, C(90, 85, 80), M.Slate)
	cylY(Vector3.new(0, 1.3, 0), 0.4, 26, C(80, 140, 200), M.Glass)
	part({ Name = "ChampionPedestal", Size = Vector3.new(8, 4, 8), Position = Vector3.new(0, 2, 0), Color = C(60, 45, 90), Material = M.Marble })
	part({ Size = Vector3.new(8.4, 0.3, 8.4), Position = Vector3.new(0, 4.1, 0), Color = C(255, 200, 60), Material = M.Neon })

	-- ===== Izquierda: Santuario del Modo Historia
	part({ Size = Vector3.new(60, 1, 60), Position = Vector3.new(-96, 0.5, -10), Color = C(85, 80, 90), Material = M.Slate })
	cylY(Vector3.new(-104, 1.2, -10), 1.4, 30, C(60, 45, 80), M.Marble)
	torii(Vector3.new(-80, 0, -10), 16, 18, C(120, 40, 160), true)
	-- Portal del Modo Historia: el mismo arco de piedra con remolino que los de combate (antes era un bloque morado)
	local storyColor = C(150, 60, 230)
	local storyMesh = nil
	if useMeshes then
		local base = CFrame.new(-106, 0, -10) * CFrame.Angles(0, math.rad(90), 0)
		storyMesh = Env.Place(model, "PortalStone", base, 1.15, { CanCollide = true })
		Env.Place(model, "PortalCharms", base, 1.15)
		local vortex = Env.Place(model, "PortalSwirl", base, 1.15, { Color = storyColor, CanQuery = false })
		if vortex then
			CollectionService:AddTag(vortex, "PortalSwirl")
		end
	end
	if not storyMesh then
		-- Sin las mallas: anillo de piedra con talismanes y un disco de energía
		local center = Vector3.new(-104, 9, -10)
		for i = 0, 19 do
			local a = i / 20 * math.pi * 2
			part({
				Size = Vector3.new(2.4, 2.6, 2.6), CFrame = CFrame.new(center + Vector3.new(0, math.sin(a) * 8, math.cos(a) * 8)) * CFrame.Angles(-a, 0, 0),
				Color = C(70, 65, 75), Material = M.Slate,
			})
			if i % 4 == 0 then
				part({ Size = Vector3.new(0.2, 2.4, 1.2), CFrame = CFrame.new(center + Vector3.new(1.4, math.sin(a) * 8 - 1.6, math.cos(a) * 8)),
					Color = C(250, 238, 215), CanCollide = false })
			end
		end
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 14.5, 14.5), Position = center, Color = storyColor, Material = M.ForceField, CanCollide = false })
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 13, 13), Position = center + Vector3.new(0.3, 0, 0), Color = C(40, 10, 70), Material = M.Neon, Transparency = 0.25, CanCollide = false })
	end
	local storyLight = Instance.new("PointLight")
	storyLight.Color = storyColor
	storyLight.Range = 28
	storyLight.Brightness = 2.5
	local storyGate = part({ Name = "StoryGate", Size = Vector3.new(0.6, 15, 14), Position = Vector3.new(-104, 9, -10), Color = storyColor, Material = M.Neon, Transparency = 1, CanCollide = false })
	storyLight.Parent = storyGate
	local veil = Instance.new("ParticleEmitter")
	veil.Color = ColorSequence.new(C(170, 80, 255), C(40, 0, 80))
	veil.LightEmission = 0.8
	veil.Size = NumberSequence.new(1.5, 0)
	veil.Lifetime = NumberRange.new(1, 2)
	veil.Rate = 25
	veil.Speed = NumberRange.new(1, 3)
	veil.SpreadAngle = Vector2.new(180, 180)
	veil.Parent = storyGate
	prompt(storyGate, "OpenStory", "Abrir", "Modo Historia")
	sign(Vector3.new(-96, 24, -10), "MODO HISTORIA", C(210, 170, 255), 22)
	for _, z in { -26, 6 } do
		lantern(Vector3.new(-86, 1, z))
	end

	-- ===== Delante a la izquierda: portal de la OBBY "Ascenso Maldito"
	do
		local obbyColor = C(255, 170, 60)
		local base = CFrame.new(-112, 0, 72) * CFrame.Angles(0, math.rad(90), 0)
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 26, 26), CFrame = CFrame.new(-106, 0.5, 72) * CFrame.Angles(0, 0, math.rad(90)), Color = C(85, 80, 90), Material = M.Slate })
		local mesh = nil
		if useMeshes then
			mesh = Env.Place(model, "PortalStone", base, 1.05, { CanCollide = true })
			Env.Place(model, "PortalCharms", base, 1.05)
			local vortex = Env.Place(model, "PortalSwirl", base, 1.05, { Color = obbyColor, CanQuery = false })
			if vortex then
				CollectionService:AddTag(vortex, "PortalSwirl")
			end
		end
		if not mesh then
			torii(Vector3.new(-110, 0, 72), 12, 16, obbyColor, true)
		end
		local gate = part({ Name = "ObbyGate", Size = Vector3.new(0.6, 13, 11), Position = Vector3.new(-110, 7.5, 72), Color = obbyColor, Material = M.Neon,
			Transparency = if mesh then 1 else 0.3, CanCollide = false })
		local gl = Instance.new("PointLight")
		gl.Color = obbyColor
		gl.Range = 26
		gl.Brightness = 2.5
		gl.Parent = gate
		prompt(gate, "Obby", "Entrar", "Obby · Ascenso Maldito")
		sign(Vector3.new(-106, 22, 72), "OBBY · ASCENSO MALDITO", obbyColor, 20)
		sign(Vector3.new(-104, 4, 72), "Parkour con premio diario", C(255, 255, 255), 13)
		for _, z in { 60, 84 } do
			lantern(Vector3.new(-100, 1, z))
		end
	end

	-- ===== Derecha: Sala de Combate (portales + plataformas de cola)
	part({ Size = Vector3.new(72, 1, 100), Position = Vector3.new(92, 0.5, -10), Color = C(50, 45, 60), Material = M.Slate })
	sign(Vector3.new(92, 24, -60), "SALA DE COMBATE", C(255, 120, 120), 26)
	local portals = {
		{ Mode = "FFA", Z = -40, Color = C(220, 60, 70), Title = "PARTIDA RÁPIDA" },
		{ Mode = "Duel", Z = -10, Color = C(230, 140, 30), Title = "DUELO 1V1" },
		{ Mode = "Dojo", Z = 20, Color = C(60, 160, 220), Title = "DOJO · PRÁCTICA" },
	}
	for _, p in portals do
		local portalMesh = nil
		if useMeshes then
			-- Arco de piedra con talismanes y remolino de energía (gira en el cliente)
			local base = CFrame.new(118, 0, p.Z) * CFrame.Angles(0, math.rad(-90), 0)
			portalMesh = Env.Place(model, "PortalStone", base, 1.05, { CanCollide = true })
			Env.Place(model, "PortalCharms", base, 1.05)
			local vortex = Env.Place(model, "PortalSwirl", base, 1.05, { Color = p.Color, CanQuery = false })
			if vortex then
				CollectionService:AddTag(vortex, "PortalSwirl")
				local light = Instance.new("PointLight")
				light.Color = p.Color
				light.Range = 26
				light.Brightness = 2.5
				light.Parent = vortex
			end
		end
		if not portalMesh then
			torii(Vector3.new(116, 0, p.Z), 12, 16, p.Color, true)
		end
		local swirl = part({
			Name = "Portal", Size = Vector3.new(0.6, 13, 11), Position = Vector3.new(116, 7.5, p.Z),
			Color = p.Color, Material = M.Neon, Transparency = if portalMesh then 1 else 0.3, CanCollide = false,
		})
		local fx = Instance.new("ParticleEmitter")
		fx.Color = ColorSequence.new(p.Color)
		fx.LightEmission = 1
		fx.Size = NumberSequence.new(1.2, 0)
		fx.Lifetime = NumberRange.new(0.6, 1.2)
		fx.Rate = 30
		fx.Speed = NumberRange.new(2, 5)
		fx.SpreadAngle = Vector2.new(30, 30)
		fx.Parent = swirl
		local _, label = sign(Vector3.new(112, 21, p.Z), p.Title, p.Color, 20)
		label.Name = "QueueText"
		label.Parent.Parent.Name = `QueueSign_{p.Mode}`
		if p.Mode == "Dojo" then
			prompt(swirl, "Practice", "Entrar", "Dojo de práctica")
		else
			-- Súbete al círculo para entrar en la cola
			local pad = part({
				Name = `QueuePad_{p.Mode}`, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 16, 16),
				CFrame = CFrame.new(100, 1.2, p.Z) * CFrame.Angles(0, 0, math.rad(90)), Color = p.Color, Material = M.Neon,
				Transparency = 0.35, CanCollide = false,
			})
			pad:SetAttribute("Mode", p.Mode)
			CollectionService:AddTag(pad, "QueuePad")
			sign(Vector3.new(100, 4, p.Z), "Súbete aquí para buscar partida", C(255, 255, 255), 14)
		end
	end

	-- ===== Delante: Pase de Batalla y Tienda
	local stalls = {
		{ X = -40, Color = C(255, 190, 40), Cloth = C(150, 30, 35), Title = "PASE DE BATALLA", Action = "OpenPass", Prompt = "Ver el pase" },
		{ X = 40, Color = C(90, 220, 255), Cloth = C(30, 50, 120), Title = "TIENDA", Action = "OpenStore", Prompt = "Comprar" },
	}
	for _, s in stalls do
		if useMeshes then
			local rot = if s.X < 0 then math.rad(90) else math.rad(-90) -- mirando al camino central
			local counter = Env.Shop(model, CFrame.new(s.X, 0, 52) * CFrame.Angles(0, rot, 0), 1.35, s.Cloth)
			if counter then
				prompt(counter, s.Action, s.Prompt, s.Title)
				sign(Vector3.new(s.X, 21, 52), s.Title, s.Color, 18)
				continue
			end
		end
		local counter = part({ Size = Vector3.new(16, 4, 5), Position = Vector3.new(s.X, 2, 52), Color = C(110, 70, 45), Material = M.Wood })
		part({ Size = Vector3.new(17, 0.5, 6), Position = Vector3.new(s.X, 4.25, 52), Color = s.Color, Material = M.Neon })
		for _, dx in { -7.5, 7.5 } do
			cylY(Vector3.new(s.X + dx, 6, 50), 12, 0.8, C(90, 60, 45), M.Wood)
		end
		part({ Shape = Enum.PartType.Wedge, Size = Vector3.new(19, 3, 8), CFrame = CFrame.new(s.X, 13.5, 51) * CFrame.Angles(0, math.rad(180), 0), Color = s.Color })
		prompt(counter, s.Action, s.Prompt, s.Title)
		sign(Vector3.new(s.X, 18, 52), s.Title, s.Color, 18)
	end

	-- ===== Ambiente
	if useMeshes then
		local function prop(name: string, x: number, z: number, rotDeg: number, scale, props)
			return Env.Place(model, name, CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(rotDeg), 0), scale, props)
		end
		-- Estanque de carpas con puente rojo (delante a la izquierda)
		part({ Size = Vector3.new(34, 1, 22), Position = Vector3.new(-92, -0.3, 74), Color = C(40, 90, 110), Material = M.Glass, Transparency = 0.25, Reflectance = 0.2, CanCollide = false })
		part({ Size = Vector3.new(36, 0.8, 24), Position = Vector3.new(-92, -0.9, 74), Color = C(30, 50, 60), CanCollide = true })
		for i = 0, 7 do -- borde de piedras
			local a = i / 8 * math.pi * 2
			Env.Rock(model, CFrame.new(-92 + math.cos(a) * 18, 0.3, 74 + math.sin(a) * 12) * CFrame.Angles(0, a, 0), 0.45)
		end
		prop("Bridge", -92, 74, 90, 1.25, { CanCollide = true })
		for k = 1, 6 do -- carpas koi
			part({ Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 0.5, 0.8), Position = Vector3.new(-104 + k * 4, -0.5, 70 + (k % 3) * 3),
				Color = if k % 2 == 0 then C(255, 120, 40) else C(250, 250, 250), Material = M.SmoothPlastic, CanCollide = false })
		end
		-- Rincón de entrenamiento (delante a la derecha): postes makiwara y bancos
		for i, x in { 80, 90, 100 } do
			prop("Makiwara", x, 70 + (i % 2) * 6, 0, 1, { CanCollide = true })
			prop("MakiwaraRope", x, 70 + (i % 2) * 6, 0, 1)
		end
		prop("Bench", 92, 86, 180, 1)
		-- Bancos alrededor de la estatua del campeón
		for _, b in { { -16, 0, 90 }, { 16, 0, -90 }, { 0, 16, 180 } } do
			prop("Bench", b[1], b[2], b[3], 1)
		end
		-- Máquinas expendedoras junto a la entrada (muy de Tokio)
		for _, x in { -16, -12, 12, 16 } do
			local m = prop("Vending", x, 104, 180, 1, { CanCollide = true, Color = if x < 0 then C(200, 40, 45) else C(40, 110, 200) })
			local f = prop("VendingFront", x, 104, 180, 1)
			if f then
				local light = Instance.new("PointLight")
				light.Color = C(200, 230, 255)
				light.Range = 10
				light.Parent = f
			end
		end
		-- Pagodas en las esquinas del fondo y bambú junto a los muros
		prop("PagodaBody", -122, -128, 0, 1.4, { CanCollide = true })
		prop("PagodaRoofs", -122, -128, 0, 1.4)
		prop("PagodaBody", 122, -128, 45, 1.4, { CanCollide = true })
		prop("PagodaRoofs", 122, -128, 45, 1.4)
		for z = -80, 100, 30 do
			for _, x in { -132, 132 } do
				prop("Bamboo", x, z, z * 7, 1)
				prop("BambooLeaves", x, z, z * 7, 1)
			end
		end
	end
	for _, pos in { Vector3.new(-128, 0, 96), Vector3.new(128, 0, 96), Vector3.new(-128, 0, -100), Vector3.new(128, 0, -100), Vector3.new(-40, 0, 80), Vector3.new(40, 0, 80), Vector3.new(-128, 0, 60), Vector3.new(128, 0, 60),
		Vector3.new(-34, 0, 30), Vector3.new(34, 0, 30), Vector3.new(-34, 0, -40), Vector3.new(34, 0, -40),
		Vector3.new(-128, 0, 20), Vector3.new(128, 0, 20), Vector3.new(-100, 0, 96), Vector3.new(100, 0, 96) } do
		tree(pos, 1.2)
	end
	for _, x in { -24, 24 } do
		for _, z in { 70, 40, 10, -20, -50 } do
			lantern(Vector3.new(x, 0, z))
		end
	end
	for _, z in { -55, -25, 5, 35 } do -- Sala de Combate iluminada
		lantern(Vector3.new(76, 0, z))
		lantern(Vector3.new(130, 0, z))
	end
	-- Montañas lejanas
	for i, x in { -360, -200, -40, 140, 300 } do
		for _, rot in { 90, -90 } do
			part({
				Shape = Enum.PartType.Wedge, Size = Vector3.new(80, 120 + i * 15, 160), CanCollide = false,
				CFrame = CFrame.new(x, 40, -380) * CFrame.Angles(0, math.rad(rot), 0), Color = C(55, 50, 85), CastShadow = false,
			})
		end
	end

	-- ===== Horizonte Jujutsu: Tokio de noche, el Velo (Tobari) sobre Shibuya y la luna maldita
	local skylineRng = Random.new(23)
	for i = 0, 34 do
		local x = -520 + i * 30 + skylineRng:NextNumber(-6, 6)
		local h = skylineRng:NextNumber(50, 170)
		local z = -470 - skylineRng:NextNumber(0, 60)
		local w = skylineRng:NextNumber(18, 28)
		part({ Size = Vector3.new(w, h, 20), Position = Vector3.new(x, h / 2 - 5, z), Color = C(28, 24, 44), CanCollide = false, CastShadow = false })
		for _ = 1, skylineRng:NextInteger(2, 5) do
			part({
				Size = Vector3.new(w * 0.7, 1.2, 0.4), Position = Vector3.new(x, skylineRng:NextNumber(8, h - 6), z + 10.3),
				Color = if skylineRng:NextNumber() < 0.7 then C(255, 210, 140) else C(140, 200, 255), Material = M.Neon,
				CanCollide = false, CastShadow = false,
			})
		end
		if skylineRng:NextNumber() < 0.3 then
			-- luz roja de aviso en lo alto
			part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 2, Position = Vector3.new(x, h - 4, z), Color = C(255, 40, 40), Material = M.Neon, CanCollide = false })
		end
	end
	-- El Velo: una cúpula negra que cubre parte de la ciudad
	local veilDome = part({
		Name = "Tobari", Shape = Enum.PartType.Ball, Size = Vector3.one * 360, Position = Vector3.new(-260, -40, -560),
		Color = C(8, 4, 16), Material = M.SmoothPlastic, Transparency = 0.12, CanCollide = false, CastShadow = false,
	})
	local veilEdge = part({
		Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 330, 330), CFrame = CFrame.new(-260, 4, -560) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C(140, 40, 255), Material = M.Neon, Transparency = 0.25, CanCollide = false, CastShadow = false,
	})
	veilEdge.Name = "TobariEdge"
	local veilFx = Instance.new("ParticleEmitter")
	veilFx.Color = ColorSequence.new(C(150, 60, 255), C(20, 0, 40))
	veilFx.LightEmission = 1
	veilFx.Size = NumberSequence.new(14, 0)
	veilFx.Lifetime = NumberRange.new(3, 6)
	veilFx.Rate = 8
	veilFx.Speed = NumberRange.new(4, 10)
	veilFx.SpreadAngle = Vector2.new(180, 180)
	veilFx.Parent = veilDome
	-- Luna maldita
	part({
		Name = "CursedMoon", Shape = Enum.PartType.Ball, Size = Vector3.one * 70, Position = Vector3.new(280, 300, -900),
		Color = C(255, 120, 110), Material = M.Neon, Transparency = 0.05, CanCollide = false, CastShadow = false,
	})
	part({
		Shape = Enum.PartType.Ball, Size = Vector3.one * 95, Position = Vector3.new(280, 300, -905),
		Color = C(255, 60, 90), Material = M.Neon, Transparency = 0.85, CanCollide = false, CastShadow = false,
	})
	-- Energía maldita flotando por el patio
	for _, pos in { Vector3.new(-60, 3, 40), Vector3.new(60, 3, 40), Vector3.new(0, 3, -60), Vector3.new(-80, 3, -60), Vector3.new(80, 3, -60), Vector3.new(0, 3, 30) } do
		local emitterPart = part({ Size = Vector3.new(40, 1, 30), Position = pos, Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
		local wisps = Instance.new("ParticleEmitter")
		wisps.Color = ColorSequence.new(C(120, 160, 255), C(170, 90, 255))
		wisps.LightEmission = 1
		wisps.LightInfluence = 0
		wisps.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.35), NumberSequenceKeypoint.new(1, 0) })
		wisps.Transparency = NumberSequence.new(0.2, 1)
		wisps.Lifetime = NumberRange.new(4, 7)
		wisps.Rate = 6
		wisps.Speed = NumberRange.new(0.5, 1.5)
		wisps.Acceleration = Vector3.new(0, 0.6, 0)
		wisps.SpreadAngle = Vector2.new(60, 60)
		wisps.Parent = emitterPart
	end

	-- Texturas propias (MaterialVariants CC_*): piedra, madera, revoque y tejas
	local WALL_COLOR, ROOF_COLOR = C(235, 225, 205), C(70, 55, 60)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			if p.Material == M.Slate and p.Size.X >= 20 and p.Size.Z >= 20 then
				p.MaterialVariant = "CC_Stone"
			elseif p.Material == M.WoodPlanks then
				p.MaterialVariant = "CC_Wood"
			elseif p.Material == M.SmoothPlastic and p.Color == WALL_COLOR then
				p.Material = M.Concrete
				p.MaterialVariant = "CC_Plaster"
			elseif p.Color == ROOF_COLOR and p:IsA("Part") and p.Shape == Enum.PartType.Wedge then
				p.Material = M.Slate
				p.MaterialVariant = "CC_Roof"
			end
		end
	end

	model.WorldPivot = CFrame.new()
	return model
end

function LobbyBuilder.BuildTemplate()
	local ServerStorage = game:GetService("ServerStorage")
	local templates = ServerStorage:FindFirstChild("Templates") or Instance.new("Folder")
	templates.Name = "Templates"
	templates.Parent = ServerStorage
	for _, name in { "Lobby", "Obby" } do
		local old = templates:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	LobbyBuilder.Build().Parent = templates
end

return LobbyBuilder
