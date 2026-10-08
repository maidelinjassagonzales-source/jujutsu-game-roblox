-- StageBuilder: construye los escenarios (centrados en el origen, combate en el plano Z = 0).
-- La cámara mira hacia -Z: todo lo decorativo va detrás (Z negativa) o por debajo.
-- Usa MaterialVariants propios (CC_Stone, CC_Wood...) y carteles que brillan (SurfaceGui).
-- El instalador los genera como plantillas en ServerStorage.Templates.Stages.
-- Solo usa rutas absolutas (game:GetService) para poder ejecutarse desde la Command Bar.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StageAssets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StageAssets"))

local StageBuilder = {}

-- Modelos de Blender (EnvMeshes) con require "fresco": el instalador corre en la Command Bar, que cachea módulos
local envCache = nil
local function Env()
	if envCache == nil then
		local m = game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Builders"):WaitForChild("EnvMeshes")
		local c = m:Clone()
		c.Parent = m.Parent
		local ok, result = pcall(require, c)
		c:Destroy()
		envCache = if ok and result.Available() then result else false
	end
	return envCache or nil
end

local C = Color3.fromRGB
local M = Enum.Material

-- ===================================================================== utilidades
local function part(parent: Instance, props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = M.SmoothPlastic
	local variant = props.Mat
	props.Mat = nil
	for k, v in props do
		(p :: any)[k] = v
	end
	if variant then
		local m = StageAssets.Materials[variant]
		p.Material = m.Base
		p.MaterialVariant = StageAssets.VariantName(variant)
	end
	p.Parent = parent
	return p
end

-- Decoración: no colisiona ni bloquea hitboxes
local function deco(parent: Instance, props): Part
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	if props.CastShadow == nil then
		props.CastShadow = false
	end
	return part(parent, props)
end

-- Plataforma atravesable desde abajo (como en Smash). La lógica está en el cliente.
local function soft(parent: Instance, props): Part
	local p = part(parent, props)
	CollectionService:AddTag(p, "SoftPlatform")
	return p
end

local function cylY(parent, pos: Vector3, height: number, diameter: number, color: Color3, material, mat: string?)
	return deco(parent, {
		Shape = Enum.PartType.Cylinder, Size = Vector3.new(height, diameter, diameter),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = material or M.SmoothPlastic, Mat = mat,
	})
end

local function cylX(parent, pos: Vector3, length: number, diameter: number, color: Color3, material)
	return deco(parent, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(length, diameter, diameter), CFrame = CFrame.new(pos), Color = color, Material = material or M.SmoothPlastic })
end

local function ball(parent, pos: Vector3, size, color: Color3, material, transparency: number?)
	return deco(parent, {
		Shape = Enum.PartType.Ball, Size = if typeof(size) == "Vector3" then size else Vector3.one * size, Position = pos,
		Color = color, Material = material or M.SmoothPlastic, Transparency = transparency or 0,
	})
end

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function newModel(name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	return model
end

-- Imagen que brilla en una cara (neones, pantallas, fachadas). La cara visible desde la cámara es Back (+Z).
-- tileStuds: repetir la imagen cada N studs (fachadas) en vez de estirarla.
local function glowImage(target: BasePart, signName: string, face: Enum.NormalId?, brightness: number?, tileStuds: Vector2?)
	face = face or Enum.NormalId.Back
	local size = target.Size
	local w, h
	if face == Enum.NormalId.Top or face == Enum.NormalId.Bottom then
		w, h = size.X, size.Z
	elseif face == Enum.NormalId.Left or face == Enum.NormalId.Right then
		w, h = size.Z, size.Y
	else
		w, h = size.X, size.Y
	end
	local pps = math.min(20, 1024 / math.max(w, h)) -- lienzo de como mucho ~1024 px
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.LightInfluence = 0
	gui.Brightness = brightness or 1.6
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pps
	gui.Parent = target
	local image = Instance.new("ImageLabel")
	image.Size = UDim2.fromScale(1, 1)
	image.BackgroundTransparency = 1
	image.Image = `rbxassetid://{StageAssets.Signs[signName]}`
	if tileStuds then
		image.ScaleType = Enum.ScaleType.Tile
		image.TileSize = UDim2.fromOffset(tileStuds.X * pps, tileStuds.Y * pps)
	else
		image.ScaleType = Enum.ScaleType.Stretch
	end
	image.Parent = gui
	return gui
end

local function light(target: BasePart, color: Color3, range: number, brightness: number?)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness or 1.5
	l.Parent = target
	return l
end

local function emitter(target: BasePart, props)
	local e = Instance.new("ParticleEmitter")
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = target
	return e
end

-- Tejado japonés a dos aguas con alero y cumbrera. cf = centro de la base del tejado.
local function roof(parent, cf: CFrame, width: number, depth: number, height: number, color: Color3?)
	local env = Env()
	if env and env.Roof(parent, cf, width + 4, depth + 4, height + 2, color) then
		return
	end
	local col = color or C(70, 72, 85)
	deco(parent, { Shape = Enum.PartType.Wedge, Size = Vector3.new(width, height, depth / 2), CFrame = cf * CFrame.new(0, height / 2, depth / 4), Color = col, Mat = "Roof", CastShadow = true })
	deco(parent, { Shape = Enum.PartType.Wedge, Size = Vector3.new(width, height, depth / 2), CFrame = cf * CFrame.new(0, height / 2, -depth / 4) * CFrame.Angles(0, math.rad(180), 0), Color = col, Mat = "Roof", CastShadow = true })
	deco(parent, { Size = Vector3.new(width + 3, 0.8, depth + 3), CFrame = cf * CFrame.new(0, -0.2, 0), Color = C(40, 30, 28), Material = M.Wood })
	deco(parent, { Size = Vector3.new(width + 1, 1.2, 1.4), CFrame = cf * CFrame.new(0, height + 0.3, 0), Color = C(30, 30, 36) })
	for _, side in { -1, 1 } do -- adornos dorados en los extremos de la cumbrera
		deco(parent, { Shape = Enum.PartType.Wedge, Size = Vector3.new(1, 2.4, 1.6), CFrame = cf * CFrame.new(side * (width / 2 + 0.2), height + 1.4, 0), Color = C(230, 180, 60), Material = M.Metal })
	end
end

local function torii(parent, pos: Vector3, width: number, height: number, red: Color3, withRope: boolean?)
	local env = Env()
	if env and env.Torii(parent, pos, width, height, red) then
		return
	end
	local black = C(28, 22, 22)
	for _, side in { -1, 1 } do
		cylY(parent, pos + Vector3.new(side * width / 2, height / 2, 0), height, 2.2, red)
		cylY(parent, pos + Vector3.new(side * width / 2, 1, 0), 2, 3, black)
	end
	deco(parent, { Size = Vector3.new(width + 8, 2, 3), Position = pos + Vector3.new(0, height + 1, 0), Color = black, CastShadow = true })
	deco(parent, { Size = Vector3.new(width + 4, 1.4, 2.2), Position = pos + Vector3.new(0, height - 0.8, 0), Color = red })
	deco(parent, { Size = Vector3.new(width, 1.2, 1.8), Position = pos + Vector3.new(0, height - 5, 0), Color = red })
	deco(parent, { Size = Vector3.new(1.8, 4, 0.6), Position = pos + Vector3.new(0, height - 2.8, 1), Color = black })
	if withRope then
		-- shimenawa (cuerda sagrada) con tiras de papel shide
		cylX(parent, pos + Vector3.new(0, height - 7, 0.6), width - 2, 1.2, C(200, 170, 110), M.Fabric)
		for i = -2, 2 do
			deco(parent, { Size = Vector3.new(0.8, 2.6, 0.1), Position = pos + Vector3.new(i * width / 6, height - 9, 1.3), Color = C(250, 250, 250), Material = M.SmoothPlastic })
		end
	end
end

local function stoneLantern(parent, pos: Vector3, glow: Color3?)
	local env = Env()
	if env and env.Lantern(parent, pos, 1) then
		return
	end
	local stone = C(140, 136, 130)
	deco(parent, { Size = Vector3.new(3, 0.8, 3), Position = pos + Vector3.new(0, 0.4, 0), Color = stone, Mat = "Stone" })
	cylY(parent, pos + Vector3.new(0, 2.4, 0), 3.2, 1.1, stone, M.Slate)
	deco(parent, { Size = Vector3.new(2.6, 0.6, 2.6), Position = pos + Vector3.new(0, 4.3, 0), Color = stone, Mat = "Stone" })
	local fire = deco(parent, { Size = Vector3.new(1.8, 1.6, 1.8), Position = pos + Vector3.new(0, 5.4, 0), Color = glow or C(255, 190, 110), Material = M.Neon })
	light(fire, glow or C(255, 180, 100), 14, 1.4)
	deco(parent, { Shape = Enum.PartType.Wedge, Size = Vector3.new(3.4, 1.2, 1.7), CFrame = CFrame.new(pos + Vector3.new(0, 6.8, 0.85)), Color = stone, Material = M.Slate })
	deco(parent, { Shape = Enum.PartType.Wedge, Size = Vector3.new(3.4, 1.2, 1.7), CFrame = CFrame.new(pos + Vector3.new(0, 6.8, -0.85)) * CFrame.Angles(0, math.rad(180), 0), Color = stone, Material = M.Slate })
end

local function sakura(parent, pos: Vector3, scale: number, rng: Random)
	local env = Env()
	if env and env.Tree(parent, pos, scale * 1.4, rng:NextNumber(0, 6.28)) then
		return
	end
	cylY(parent, pos + Vector3.new(0, 7 * scale, 0), 14 * scale, 1.8 * scale, C(80, 55, 45), M.Wood)
	for _, dir in { -1, 1 } do -- ramas
		deco(parent, {
			Size = Vector3.new(0.9 * scale, 7 * scale, 0.9 * scale), Color = C(80, 55, 45), Material = M.Wood,
			CFrame = CFrame.new(pos + Vector3.new(dir * 2.2 * scale, 14 * scale, 0)) * CFrame.Angles(0, 0, math.rad(-dir * 40)),
		})
	end
	for _ = 1, 6 do
		local leaves = ball(parent, pos + Vector3.new(rng:NextNumber(-5, 5), 15 * scale + rng:NextNumber(-1, 4), rng:NextNumber(-4, 4)) * Vector3.new(scale, 1, scale),
			rng:NextNumber(7, 11) * scale, C(255, 165 + rng:NextInteger(0, 35), 200), M.Grass)
		CollectionService:AddTag(leaves, "SakuraCanopy")
	end
end

-- Base flotante de roca bajo el suelo de combate (para que no parezca una caja)
local function floatingRock(parent, width: number, color: Color3)
	deco(parent, { Size = Vector3.new(width - 4, 14, 20), Position = Vector3.new(0, -12, 0), Color = color, Material = M.Rock })
	for _, side in { -1, 1 } do
		deco(parent, { Shape = Enum.PartType.Wedge, Size = Vector3.new(20, 18, width / 2 - 4), CFrame = CFrame.new(side * width / 4, -28, 0) * CFrame.Angles(0, math.rad(90 * side), math.rad(180)), Color = color, Material = M.Rock })
	end
	deco(parent, { Shape = Enum.PartType.Wedge, Size = Vector3.new(14, 14, 10), CFrame = CFrame.new(0, -42, 0) * CFrame.Angles(0, math.rad(90), math.rad(180)), Color = color, Material = M.Rock })
end

-- ===================================================================== ACADEMY · Dojo de la Escuela
function StageBuilder.Academy(): Model
	local model = newModel("Academy")
	local combat = folder(model, "Combat")
	local decor = folder(model, "Decor")
	local rng = Random.new(7)

	-- Suelo de losas de piedra con borde de madera
	part(combat, { Name = "Ground", Size = Vector3.new(110, 6, 24), Position = Vector3.new(0, -3, 0), Color = C(165, 160, 150), Mat = "Stone" })
	for _, z in { 12.2, -12.2 } do
		deco(decor, { Size = Vector3.new(111, 1.4, 0.8), Position = Vector3.new(0, -0.5, z), Color = C(70, 45, 32), Mat = "Wood" })
	end
	for _, x in { -55.4, 55.4 } do
		deco(decor, { Size = Vector3.new(0.8, 1.4, 25), Position = Vector3.new(x, -0.5, 0), Color = C(70, 45, 32), Mat = "Wood" })
	end
	floatingRock(decor, 110, C(95, 88, 82))
	deco(decor, { Size = Vector3.new(112, 1.5, 26), Position = Vector3.new(0, -6.2, 0), Color = C(80, 120, 60), Material = M.Grass })

	-- Plataformas de madera con farolillos colgando
	local platforms = { Vector3.new(-30, 14, 0), Vector3.new(30, 14, 0), Vector3.new(0, 27, 0) }
	for i, pos in platforms do
		soft(combat, { Name = "Platform", Size = Vector3.new(if i == 3 then 22 else 24, 1.2, 10), Position = pos, Color = C(160, 110, 70), Mat = "Wood" })
		deco(decor, { Size = Vector3.new(if i == 3 then 22.4 else 24.4, 0.6, 10.4), Position = pos - Vector3.new(0, 0.9, 0), Color = C(60, 38, 28), Material = M.Wood })
		for _, dx in { -9, 9 } do
			deco(decor, { Size = Vector3.new(0.12, 2, 0.12), Position = pos + Vector3.new(dx, -2, -3), Color = C(30, 25, 25) })
			local lamp = ball(decor, pos + Vector3.new(dx, -3.6, -3), Vector3.new(1.6, 2, 1.6), C(255, 110, 80), M.Neon)
			light(lamp, C(255, 150, 100), 10, 1)
		end
	end

	-- Sala del dojo al fondo: tarima, paredes shoji, pilares y gran tejado
	local hallZ = -46
	deco(decor, { Size = Vector3.new(96, 3, 26), Position = Vector3.new(0, 1.5, hallZ), Color = C(120, 80, 55), Mat = "Wood" })
	for i = 0, 2 do -- escalones
		deco(decor, { Size = Vector3.new(30, 1, 2), Position = Vector3.new(0, 0.5 + i, hallZ + 14 - i * 2), Color = C(150, 145, 138), Mat = "Stone" })
	end
	deco(decor, { Size = Vector3.new(86, 18, 1), Position = Vector3.new(0, 12, hallZ - 6), Color = C(240, 232, 214), Mat = "Shoji" })
	for x = -42, 42, 12 do
		cylY(decor, Vector3.new(x, 12, hallZ + 6), 18, 1.6, C(70, 30, 25), M.Wood)
	end
	deco(decor, { Size = Vector3.new(90, 1.6, 1.2), Position = Vector3.new(0, 20.5, hallZ + 6), Color = C(55, 30, 25), Material = M.Wood })
	roof(decor, CFrame.new(0, 22, hallZ), 104, 34, 12)
	local plaque = deco(decor, { Size = Vector3.new(6, 14, 0.6), Position = Vector3.new(0, 12, hallZ + 6.8), Color = C(20, 15, 25) })
	glowImage(plaque, "Jujutsu", Enum.NormalId.Back, 1.2)

	-- Torii con cuerda sagrada y faroles de piedra
	torii(decor, Vector3.new(0, 0, -20), 40, 32, C(200, 40, 35), true)
	for _, x in { -44, -16, 16, 44 } do
		stoneLantern(decor, Vector3.new(x, 0, -10), nil)
	end

	-- Cerezos y bambú
	for _, x in { -62, -48, 50, 64 } do
		sakura(decor, Vector3.new(x, -6, -26 - rng:NextNumber(0, 8)), 1.15, rng)
	end
	for _ = 1, 26 do
		local x = rng:NextNumber(70, 110) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local h = rng:NextNumber(26, 40)
		cylY(decor, Vector3.new(x, h / 2 - 6, rng:NextNumber(-70, -40)), h, rng:NextNumber(0.8, 1.3), C(70 + rng:NextInteger(0, 30), 140, 60), M.SmoothPlastic)
	end

	-- La Escuela al fondo y montañas
	deco(decor, { Size = Vector3.new(170, 40, 30), Position = Vector3.new(0, 10, -130), Color = C(235, 228, 212), Mat = "Plaster" })
	roof(decor, CFrame.new(0, 30, -130), 176, 36, 14)
	for row = 0, 2 do
		for col = -7, 7 do
			deco(decor, {
				Size = Vector3.new(6, 6, 1), Position = Vector3.new(col * 11, -1 + row * 11, -114.6),
				Color = if (row + col) % 3 == 0 then C(255, 220, 150) else C(80, 100, 130), Material = if (row + col) % 3 == 0 then M.Neon else M.Glass,
			})
		end
	end
	for i, x in { -320, -180, -40, 120, 280 } do
		for _, rot in { 90, -90 } do
			deco(decor, { Shape = Enum.PartType.Wedge, Size = Vector3.new(60, 90 + i * 12, 120), CFrame = CFrame.new(x, 20, -330) * CFrame.Angles(0, math.rad(rot), 0), Color = C(95, 90, 135) })
		end
	end
	deco(decor, { Size = Vector3.new(900, 2, 700), Position = Vector3.new(0, -72, -200), Color = C(80, 120, 70), Material = M.Grass })

	model.WorldPivot = CFrame.new()
	return model
end

-- ===================================================================== SHIBUYA · Incidente de Shibuya
function StageBuilder.Shibuya(): Model
	local model = newModel("Shibuya")
	local combat = folder(model, "Combat")
	local decor = folder(model, "Decor")
	local rng = Random.new(21)
	local neons = { C(0, 230, 255), C(255, 40, 160), C(255, 220, 60), C(140, 80, 255), C(60, 255, 150) }

	-- Paso elevado: asfalto con barandillas y farolas, sobre pilares de hormigón
	part(combat, { Name = "Ground", Size = Vector3.new(100, 6, 24), Position = Vector3.new(0, -3, 0), Color = C(70, 70, 78), Mat = "Asphalt" })
	for _, z in { 11.5, -11.5 } do
		deco(decor, { Size = Vector3.new(100, 1.6, 1), Position = Vector3.new(0, 0.8, z), Color = C(170, 170, 175), Material = M.Concrete })
	end
	for x = -45, 45, 15 do -- líneas de carril
		deco(decor, { Size = Vector3.new(6, 0.05, 0.5), Position = Vector3.new(x, 0.03, 4), Color = C(240, 240, 230) })
		deco(decor, { Size = Vector3.new(6, 0.05, 0.5), Position = Vector3.new(x, 0.03, -4), Color = C(240, 220, 90) })
	end
	deco(decor, { Size = Vector3.new(96, 4, 22), Position = Vector3.new(0, -8, 0), Color = C(110, 110, 115), Material = M.Concrete })
	for _, x in { -32, 0, 32 } do
		deco(decor, { Size = Vector3.new(8, 60, 10), Position = Vector3.new(x, -40, 0), Color = C(120, 120, 125), Material = M.Concrete })
	end
	for _, x in { -40, -12, 16, 44 } do -- farolas
		deco(decor, { Size = Vector3.new(0.6, 14, 0.6), Position = Vector3.new(x, 7, -12.5), Color = C(60, 60, 70), Material = M.Metal })
		deco(decor, { Size = Vector3.new(4, 0.5, 0.6), Position = Vector3.new(x + 1.7, 14, -12.5), Color = C(60, 60, 70), Material = M.Metal })
		local bulb = deco(decor, { Size = Vector3.new(1.6, 0.4, 1), Position = Vector3.new(x + 3.2, 13.6, -12.5), Color = C(255, 240, 200), Material = M.Neon })
		light(bulb, C(255, 230, 180), 22, 2)
	end

	-- Pórticos de señales (plataformas) con el cartel de la estación
	for _, x in { -28, 28 } do
		soft(combat, { Name = "Platform", Size = Vector3.new(24, 1.2, 10), Position = Vector3.new(x, 14, 0), Color = C(90, 95, 105), Material = M.DiamondPlate })
		for _, dx in { -11, 11 } do
			deco(decor, { Size = Vector3.new(0.9, 14, 0.9), Position = Vector3.new(x + dx, 7, -4), Color = C(80, 85, 95), Material = M.Metal })
		end
		local board = deco(decor, { Size = Vector3.new(14, 6, 0.4), Position = Vector3.new(x, 10.2, -4.6), Color = C(20, 70, 50) })
		glowImage(board, "Shibuya", Enum.NormalId.Back, 1)
	end
	soft(combat, { Name = "Platform", Size = Vector3.new(22, 1.2, 10), Position = Vector3.new(0, 27, 0), Color = C(40, 40, 50), Material = M.Metal })
	deco(decor, { Size = Vector3.new(22, 0.4, 10.4), Position = Vector3.new(0, 27.7, 0), Color = C(255, 40, 160), Material = M.Neon })

	-- El cruce de Shibuya abajo, con coches
	deco(decor, { Size = Vector3.new(700, 2, 220), Position = Vector3.new(0, -70, -80), Color = C(60, 60, 66), Mat = "Asphalt" })
	for _, x in { -60, 60 } do
		deco(decor, { Size = Vector3.new(30, 0.2, 160), Position = Vector3.new(x, -68.9, -80), Color = C(80, 80, 88), Mat = "Crosswalk" })
	end
	deco(decor, { Size = Vector3.new(160, 0.2, 30), Position = Vector3.new(0, -68.9, -80), Color = C(80, 80, 88), Mat = "Crosswalk" })
	for _ = 1, 14 do
		local pos = Vector3.new(rng:NextNumber(-250, 250), -67, rng:NextNumber(-150, -20))
		local col = neons[rng:NextInteger(1, #neons)]:Lerp(C(40, 40, 50), 0.6)
		deco(decor, { Size = Vector3.new(9, 2.4, 4.4), Position = pos, Color = col, Material = M.Metal })
		deco(decor, { Size = Vector3.new(5, 1.8, 4), Position = pos + Vector3.new(-0.5, 2, 0), Color = C(30, 35, 45), Material = M.Glass })
		deco(decor, { Size = Vector3.new(0.2, 0.6, 3.6), Position = pos + Vector3.new(4.6, 0.2, 0), Color = C(255, 250, 220), Material = M.Neon })
		deco(decor, { Size = Vector3.new(0.2, 0.6, 3.6), Position = pos + Vector3.new(-4.6, 0.2, 0), Color = C(255, 40, 40), Material = M.Neon })
	end

	-- Edificios con fachadas iluminadas, neones en japonés y pantallas gigantes
	local signs = { "Ramen", "Karaoke", "Hotel", "Jujutsu" }
	for x = -330, 330, 42 do
		local h = rng:NextNumber(80, 210)
		local z = rng:NextNumber(-70, -110)
		local w = rng:NextNumber(30, 38)
		local building = deco(decor, { Size = Vector3.new(w, h, 30), Position = Vector3.new(x, h / 2 - 70, z), Color = C(30, 30, 42), Material = M.Concrete })
		glowImage(building, "Facade", Enum.NormalId.Back, 0.9, Vector2.new(34, 68))
		deco(decor, { Size = Vector3.new(w + 1, 2, 31), Position = Vector3.new(x, h - 69, z), Color = neons[rng:NextInteger(1, #neons)], Material = M.Neon })
		if rng:NextNumber() < 0.75 then
			local signName = signs[rng:NextInteger(1, #signs)]
			local vertical = signName == "Hotel" or signName == "Jujutsu"
			local size = if vertical then Vector3.new(7, 18, 0.6) else Vector3.new(18, 9, 0.6)
			local sign = deco(decor, { Size = size, Position = Vector3.new(x + rng:NextNumber(-6, 6), rng:NextNumber(-40, h - 90), z + 15.6), Color = C(10, 8, 16) })
			glowImage(sign, signName, Enum.NormalId.Back, 2)
		end
	end
	for _, info in { { -90, 10, -64 }, { 110, 30, -72 } } do
		local frame = deco(decor, { Size = Vector3.new(52, 30, 2), Position = Vector3.new(info[1], info[2], info[3]), Color = C(15, 15, 20) })
		local screen = deco(decor, { Size = Vector3.new(48, 27, 0.2), Position = Vector3.new(info[1], info[2], info[3] + 1.1), Color = C(0, 0, 0) })
		glowImage(screen, "Poster", Enum.NormalId.Back, 2.2)
		light(frame, C(200, 100, 255), 40, 1)
	end

	-- El Velo (Tobari) sobre la ciudad y la luna
	local veil = ball(decor, Vector3.new(60, -60, -420), 520, C(8, 4, 16), M.SmoothPlastic, 0.1)
	emitter(veil, { Color = ColorSequence.new(C(150, 60, 255)), LightEmission = 1, Size = NumberSequence.new(20, 0), Lifetime = NumberRange.new(4, 7), Rate = 6, Speed = NumberRange.new(5, 12), SpreadAngle = Vector2.new(180, 180) })
	ball(decor, Vector3.new(-200, 200, -560), 46, C(240, 235, 255), M.Neon)

	model.WorldPivot = CFrame.new()
	return model
end

-- ===================================================================== INFINITY · Vacío Infinito
function StageBuilder.Infinity(): Model
	local model = newModel("Infinity")
	local combat = folder(model, "Combat")
	local decor = folder(model, "Decor")
	local rng = Random.new(99)

	-- Suelo de cristal con la galaxia dentro (brilla) y bordes de energía
	local ground = part(combat, { Name = "Ground", Size = Vector3.new(90, 4, 22), Position = Vector3.new(0, -2, 0), Color = C(20, 25, 60), Material = M.Glass, Reflectance = 0.25 })
	glowImage(ground, "Cosmic", Enum.NormalId.Top, 1.4)
	glowImage(ground, "Cosmic", Enum.NormalId.Back, 1.2)
	deco(decor, { Size = Vector3.new(91, 0.15, 0.25), Position = Vector3.new(0, 0.02, 10.9), Color = C(80, 220, 255), Material = M.Neon, Transparency = 0.3 })
	deco(decor, { Size = Vector3.new(91, 0.4, 0.6), Position = Vector3.new(0, 0.05, -11), Color = C(80, 220, 255), Material = M.Neon })
	for _, side in { -1, 1 } do
		deco(decor, { Shape = Enum.PartType.Wedge, Size = Vector3.new(20, 26, 44), CFrame = CFrame.new(side * 22, -17, 0) * CFrame.Angles(0, math.rad(90 * side), math.rad(180)), Color = C(25, 25, 70), Material = M.Glass, Transparency = 0.3 })
	end

	for _, pos in { Vector3.new(-28, 13, 0), Vector3.new(28, 13, 0), Vector3.new(0, 25, 0) } do
		local p = soft(combat, { Name = "Platform", Size = Vector3.new(20, 1, 9), Position = pos, Color = C(25, 25, 60), Material = M.Glass, Transparency = 0.1 })
		glowImage(p, "Cosmic", Enum.NormalId.Top, 1)
		deco(decor, { Size = Vector3.new(20.4, 0.3, 9.4), Position = pos + Vector3.new(0, -0.6, 0), Color = C(170, 90, 255), Material = M.Neon })
	end

	-- Muro de galaxia gigante al fondo y "información infinita" que fluye hacia ti
	local sky = deco(decor, { Size = Vector3.new(1400, 800, 2), Position = Vector3.new(0, 80, -420), Color = C(5, 5, 20) })
	glowImage(sky, "Cosmic", Enum.NormalId.Back, 1.3)
	for _, x in { -200, 0, 200 } do
		local source = deco(decor, { Size = Vector3.new(160, 120, 1), Position = Vector3.new(x, 40, -300), Transparency = 1 })
		emitter(source, {
			Color = ColorSequence.new(C(200, 230, 255), C(120, 80, 255)), LightEmission = 1, LightInfluence = 0,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) }),
			Squash = NumberSequence.new(-3), Lifetime = NumberRange.new(2, 3), Rate = 60, Speed = NumberRange.new(80, 140),
			EmissionDirection = Enum.NormalId.Back, SpreadAngle = Vector2.new(5, 5),
		})
	end

	-- Orbes: azul (atrae), rojo (repele), púrpura (vacío) con halos
	for _, o in { { Vector3.new(-120, 60, -230), 44, C(60, 140, 255) }, { Vector3.new(120, 45, -240), 38, C(255, 50, 60) }, { Vector3.new(0, 110, -320), 80, C(150, 60, 255) } } do
		ball(decor, o[1], o[2], o[3], M.Neon, if o[2] > 60 then 0.3 else 0)
		ball(decor, o[1], o[2] * 1.5, o[3], M.Neon, 0.85)
	end

	-- Anillos de energía
	local function ring(center: Vector3, radius: number, count: number, color: Color3, tilt: number)
		for i = 0, count - 1 do
			local a = (i / count) * math.pi * 2
			local cf = CFrame.new(center) * CFrame.Angles(math.rad(tilt), 0, 0) * CFrame.Angles(0, 0, a) * CFrame.new(radius, 0, 0)
			deco(decor, { Size = Vector3.new(2, radius * 0.27, 2), CFrame = cf, Color = color, Material = M.Neon, Transparency = 0.2 })
		end
	end
	ring(Vector3.new(0, 15, -140), 95, 44, C(80, 200, 255), 0)
	ring(Vector3.new(0, 15, -170), 60, 30, C(180, 80, 255), 25)
	ring(Vector3.new(0, 15, -200), 130, 50, C(255, 255, 255), -15)

	-- Cristales flotantes que reflejan
	for _ = 1, 22 do
		local s = rng:NextNumber(4, 12)
		deco(decor, {
			Size = Vector3.new(s, s * 1.8, s), Reflectance = 0.4,
			CFrame = CFrame.new(rng:NextNumber(-200, 200), rng:NextNumber(-60, 80), rng:NextNumber(-60, -160)) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6)),
			Color = C(90, 120, 255), Material = M.Glass, Transparency = 0.25,
		})
	end
	-- Polvo estelar alrededor del escenario
	local dust = deco(decor, { Size = Vector3.new(160, 60, 40), Position = Vector3.new(0, 10, -20), Transparency = 1 })
	emitter(dust, {
		Color = ColorSequence.new(C(180, 220, 255)), LightEmission = 1, LightInfluence = 0, Size = NumberSequence.new(0.25, 0),
		Lifetime = NumberRange.new(4, 8), Rate = 25, Speed = NumberRange.new(0.5, 2), SpreadAngle = Vector2.new(180, 180),
	})

	model.WorldPivot = CFrame.new()
	return model
end

-- ===================================================================== TEMPLE · Santuario Maldito
local function skull(parent, pos: Vector3, size: number, facing: number?)
	local bone = C(225, 215, 195)
	local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(facing or 0), 0)
	ball(parent, pos, Vector3.new(size, size * 0.9, size), bone, M.SmoothPlastic)
	deco(parent, { Size = Vector3.new(size * 0.7, size * 0.35, size * 0.6), CFrame = cf * CFrame.new(0, -size * 0.42, size * 0.12), Color = bone })
	for _, side in { -1, 1 } do
		deco(parent, { Shape = Enum.PartType.Ball, Size = Vector3.one * size * 0.28, CFrame = cf * CFrame.new(side * size * 0.2, 0, size * 0.42), Color = C(15, 8, 8) })
	end
	deco(parent, { Size = Vector3.new(size * 0.12, size * 0.18, size * 0.1), CFrame = cf * CFrame.new(0, -size * 0.15, size * 0.47), Color = C(15, 8, 8) })
end

local function boneArc(parent, base: Vector3, height: number, lean: number, segments: number)
	local bone = C(230, 220, 200)
	local prev = base
	for i = 1, segments do
		local t = i / segments
		local p = base + Vector3.new(math.sin(t * math.pi * 0.5) * lean, t * height, 0)
		local mid = (prev + p) / 2
		deco(parent, { Size = Vector3.new(2.2 - t, (p - prev).Magnitude + 0.5, 2.2 - t), CFrame = CFrame.lookAt(mid, p) * CFrame.Angles(math.rad(90), 0, 0), Color = bone, CastShadow = true })
		prev = p
	end
end

function StageBuilder.Temple(): Model
	local model = newModel("Temple")
	local combat = folder(model, "Combat")
	local decor = folder(model, "Decor")
	local rng = Random.new(5)
	local red, dark = C(150, 25, 25), C(30, 18, 18)

	-- Muelle de piedra maldita sobre un estanque de sangre
	part(combat, { Name = "Ground", Size = Vector3.new(104, 4, 24), Position = Vector3.new(0, -2, 0), Color = C(200, 170, 165), Mat = "Shrine" })
	for _, z in { 12.2, -12.2 } do
		deco(decor, { Size = Vector3.new(105, 1, 0.8), Position = Vector3.new(0, -0.3, z), Color = red, Material = M.Wood })
	end
	for _, x in { -36, 0, 36 } do -- luz cálida sobre el muelle para que se lea la piedra
		local glow = deco(decor, { Size = Vector3.one, Position = Vector3.new(x, 16, 6), Transparency = 1 })
		light(glow, C(255, 170, 140), 40, 1.6)
	end
	for x = -48, 48, 16 do -- pilotes
		cylY(decor, Vector3.new(x, -14, 9), 24, 2.4, dark, M.Wood)
		cylY(decor, Vector3.new(x, -14, -9), 24, 2.4, dark, M.Wood)
	end
	local pond = deco(decor, { Size = Vector3.new(900, 1, 600), Position = Vector3.new(0, -20, -200), Color = C(90, 5, 10), Material = M.Glass, Reflectance = 0.35, Transparency = 0.05 })
	emitter(pond, { Color = ColorSequence.new(C(255, 80, 40)), LightEmission = 1, Size = NumberSequence.new(0.5, 0), Lifetime = NumberRange.new(3, 6), Rate = 40, Speed = NumberRange.new(2, 6), SpreadAngle = Vector2.new(20, 20), Acceleration = Vector3.new(0, 2, 0) })

	-- Puentes de hueso (plataformas)
	for _, x in { -26, 26 } do
		soft(combat, { Name = "Platform", Size = Vector3.new(22, 1.2, 10), Position = Vector3.new(x, 13, 0), Color = C(220, 210, 190) })
		for _, dx in { -11, 11 } do
			ball(decor, Vector3.new(x + dx, 13, 0), Vector3.new(2.6, 2.2, 10.4), C(225, 215, 195))
		end
	end
	soft(combat, { Name = "Platform", Size = Vector3.new(22, 1.2, 10), Position = Vector3.new(0, 26, 0), Color = C(70, 55, 55), Mat = "Shrine" })
	skull(decor, Vector3.new(0, 24, -3), 3, 0)

	-- Faroles rojos sobre pilares y costillas gigantes saliendo de la sangre
	for _, x in { -46, -20, 20, 46 } do
		cylY(decor, Vector3.new(x, 8, -10), 18, 1.8, red)
		local lamp = ball(decor, Vector3.new(x, 18, -10), Vector3.new(2.4, 3, 2.4), C(255, 70, 40), M.Neon)
		light(lamp, C(255, 60, 30), 18, 2)
		emitter(lamp, { Color = ColorSequence.new(C(255, 120, 40)), LightEmission = 1, Size = NumberSequence.new(0.6, 0), Lifetime = NumberRange.new(0.6, 1), Rate = 12, Speed = NumberRange.new(2, 4), Acceleration = Vector3.new(0, 4, 0) })
	end
	for i = 0, 5 do
		local x = -110 + i * 44
		boneArc(decor, Vector3.new(x, -20, -40 - (i % 2) * 20), 50 + (i % 3) * 10, if x < 0 then 18 else -18, 7)
	end

	-- El Santuario: base de calaveras, salón rojo, tejado y fauces en la entrada
	local shrineZ = -150
	deco(decor, { Size = Vector3.new(120, 22, 70), Position = Vector3.new(0, -9, shrineZ), Color = dark, Mat = "Shrine" })
	for i = 1, 70 do -- montaña de calaveras
		local x = rng:NextNumber(-62, 62)
		skull(decor, Vector3.new(x, rng:NextNumber(-16, 2), shrineZ + 35 + rng:NextNumber(-3, 4)), rng:NextNumber(3, 6), rng:NextNumber(-30, 30))
	end
	deco(decor, { Size = Vector3.new(90, 34, 46), Position = Vector3.new(0, 19, shrineZ - 4), Color = C(110, 20, 20), Material = M.Wood })
	for x = -42, 42, 12 do
		cylY(decor, Vector3.new(x, 19, shrineZ + 20), 34, 2.4, dark, M.Wood)
	end
	roof(decor, CFrame.new(0, 37, shrineZ - 4), 104, 60, 22, C(45, 30, 35))
	roof(decor, CFrame.new(0, 64, shrineZ - 4), 66, 40, 16, C(45, 30, 35))
	-- fauces: dientes en la entrada
	for i = -4, 4 do
		deco(decor, { Shape = Enum.PartType.Wedge, Size = Vector3.new(4, 7, 3), CFrame = CFrame.new(i * 5, 31, shrineZ + 22) * CFrame.Angles(math.rad(180), 0, 0), Color = C(235, 228, 210) })
		deco(decor, { Shape = Enum.PartType.Wedge, Size = Vector3.new(4, 6, 3), CFrame = CFrame.new(i * 5 + 2.5, 6.5, shrineZ + 22), Color = C(235, 228, 210) })
	end
	local maw = deco(decor, { Size = Vector3.new(46, 22, 1), Position = Vector3.new(0, 17, shrineZ + 21.6), Color = C(10, 0, 0), Material = M.Neon })
	light(maw, C(255, 30, 30), 60, 3)
	-- cuernos de buey en las esquinas del tejado
	for _, side in { -1, 1 } do
		for k = 1, 4 do
			deco(decor, { Size = Vector3.new(2.4 - k * 0.4, 4, 2.4 - k * 0.4), CFrame = CFrame.new(side * (52 + k * 1.5), 40 + k * 3.2, shrineZ + 22) * CFrame.Angles(0, 0, math.rad(side * (30 + k * 12))), Color = C(235, 228, 210) })
		end
	end

	torii(decor, Vector3.new(0, -20, -60), 46, 44, C(20, 10, 10), true)

	-- Luna roja y montañas
	ball(decor, Vector3.new(140, 160, -480), 90, C(255, 60, 40), M.Neon)
	ball(decor, Vector3.new(140, 160, -485), 130, C(255, 40, 30), M.Neon, 0.85)
	for i, x in { -300, -140, 160, 320 } do
		for _, rot in { 90, -90 } do
			deco(decor, { Shape = Enum.PartType.Wedge, Size = Vector3.new(80, 120 + i * 15, 140), CFrame = CFrame.new(x, 0, -400) * CFrame.Angles(0, math.rad(rot), 0), Color = C(35, 12, 12) })
		end
	end
	-- Ascuas en el aire
	local embers = deco(decor, { Size = Vector3.new(200, 4, 60), Position = Vector3.new(0, -16, -30), Transparency = 1 })
	emitter(embers, { Color = ColorSequence.new(C(255, 140, 40), C(255, 40, 20)), LightEmission = 1, Size = NumberSequence.new(0.35, 0), Lifetime = NumberRange.new(5, 9), Rate = 30, Speed = NumberRange.new(2, 5), Acceleration = Vector3.new(0, 3, 0), SpreadAngle = Vector2.new(30, 30) })

	model.WorldPivot = CFrame.new()
	return model
end

function StageBuilder.Build(stageId: string): Model?
	local fn = (StageBuilder :: any)[stageId]
	if type(fn) == "function" and stageId ~= "Build" and stageId ~= "BuildTemplates" then
		return fn()
	end
	return nil
end

-- Usado por el instalador: genera ServerStorage.Templates.Stages.<Id>
function StageBuilder.BuildTemplates(ids: { string })
	local ServerStorage = game:GetService("ServerStorage")
	local templates = ServerStorage:FindFirstChild("Templates") or Instance.new("Folder")
	templates.Name = "Templates"
	templates.Parent = ServerStorage
	local stages = templates:FindFirstChild("Stages") or Instance.new("Folder")
	stages.Name = "Stages"
	stages.Parent = templates
	for _, id in ids do
		local old = stages:FindFirstChild(id)
		if old then
			old:Destroy()
		end
		local m = StageBuilder.Build(id)
		if m then
			m.Parent = stages
		end
	end
end

return StageBuilder
