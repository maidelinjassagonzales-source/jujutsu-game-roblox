-- SpecialFX: el aspecto PROPIO de cada técnica especial (todo se dibuja en el cliente).
--   * Proyectiles: el servidor avisa (ProjectileSpawn/Hit/End) y aquí se dibuja cada uno con su estilo:
--     Azul que atrae, Rojo que repele, Púrpura Hueco, cortes de Sukuna, Flecha de Fuego, Perros Divinos,
--     sangre de Choso, Rasengan, kunais, clavos, magma, insectos de fuego, Kamehameha, Rika...
--   * Golpes especiales cuerpo a cuerpo: cortes en arco, estocadas, ondas en el suelo, columnas, siluetas...
-- El estilo se elige por el NOMBRE de la técnica (el mismo que sale en la tienda); si no tiene uno propio,
-- se usa uno genérico según la pose y el color del personaje.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local SpecialFX = {}

local TEX_FIRE = "rbxasset://textures/particles/fire_main.dds"
local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local C = Color3.fromRGB

local folder: Folder

-- ===================================================================
-- Piezas básicas
-- ===================================================================
local function part(props, className: string?): BasePart
	local p = Instance.new(className or "Part") :: BasePart
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = folder
	return p
end

local function ball(size: number, color: Color3, props): BasePart
	local t = { Shape = Enum.PartType.Ball, Size = Vector3.one * size, Color = color }
	for k, v in props or {} do
		t[k] = v
	end
	return part(t)
end

local function emitter(parent: Instance, props): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.LightEmission = 1
	e.LightInfluence = 0
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

local function fade(p: BasePart, t: number, props)
	local goal = { Transparency = 1 }
	for k, v in props or {} do
		goal[k] = v
	end
	TweenService:Create(p, TweenInfo.new(t, Enum.EasingStyle.Quad), goal):Play()
	Debris:AddItem(p, t + 0.05)
end

local function light(parent: Instance, color: Color3, range: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = 3
	l.Parent = parent
	return l
end

local function trail(p: BasePart, c1: Color3, c2: Color3, width: number, life: number?)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, width / 2, 0)
	a0.Parent = p
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -width / 2, 0)
	a1.Parent = p
	local t = Instance.new("Trail")
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Color = ColorSequence.new(c1, c2)
	t.LightEmission = 1
	t.LightInfluence = 0
	t.Lifetime = life or 0.3
	t.WidthScale = NumberSequence.new(1, 0.1)
	t.Transparency = NumberSequence.new(0.1, 1)
	t.FaceCamera = true
	t.Parent = p
	return t
end

-- Anillo (mirando a la cámara o plano en el suelo)
local function ring(position: Vector3, color: Color3, size: number, t: number, flat: boolean?)
	local cf = if flat then CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)) else CFrame.lookAt(position, position + workspace.CurrentCamera.CFrame.LookVector) * CFrame.Angles(0, math.rad(90), 0)
	local r = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, size * 0.2, size * 0.2), CFrame = cf, Color = color, Transparency = 0.05 })
	fade(r, t, { Size = Vector3.new(0.05, size, size) })
end

local function burstAt(position: Vector3, count: number, props)
	local holder = part({ Size = Vector3.one * 0.2, Position = position, Transparency = 1 })
	local e = emitter(holder, props)
	e.Rate = 0
	e:Emit(count)
	Debris:AddItem(holder, 2)
end

local function sparks(position: Vector3, color: Color3, count: number, speed: number?)
	burstAt(position, count, {
		Texture = TEX_SPARK, Color = ColorSequence.new(WHITE, color), Size = NumberSequence.new(0.9, 0),
		Lifetime = NumberRange.new(0.2, 0.45), Speed = NumberRange.new((speed or 30) * 0.5, speed or 30), SpreadAngle = Vector2.new(180, 180), Drag = 5,
	})
end

local function smokePuff(position: Vector3, color: Color3, count: number, size: number)
	burstAt(position, count, {
		Texture = TEX_SMOKE, LightEmission = 0, Color = ColorSequence.new(color), Size = NumberSequence.new(size, size * 2.5),
		Transparency = NumberSequence.new(0.3, 1), Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(4, 10),
		SpreadAngle = Vector2.new(180, 180), RotSpeed = NumberRange.new(-90, 90), Rotation = NumberRange.new(0, 360),
	})
end

local function fireBurst(position: Vector3, c1: Color3, c2: Color3, count: number, size: number)
	burstAt(position, count, {
		Texture = TEX_FIRE, Color = ColorSequence.new(c1, c2), Size = NumberSequence.new(size, 0),
		Transparency = NumberSequence.new(0.1, 1), Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(10, 25),
		SpreadAngle = Vector2.new(180, 180), RotSpeed = NumberRange.new(-180, 180), Rotation = NumberRange.new(0, 360), Drag = 3,
	})
end

local function bolt(from: Vector3, to: Vector3, color: Color3, width: number?)
	local points = { from }
	for i = 1, 2 do
		table.insert(points, from:Lerp(to, i / 3) + Vector3.new(math.random(-12, 12) / 10, math.random(-12, 12) / 10, 0))
	end
	table.insert(points, to)
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local seg = part({ Size = Vector3.new(width or 0.25, width or 0.25, (b - a).Magnitude), CFrame = CFrame.lookAt((a + b) / 2, b), Color = color })
		fade(seg, 0.22)
	end
end

local function floatText(position: Vector3, text: string, color: Color3, size: number)
	local anchor = part({ Size = Vector3.one, Position = position, Transparency = 1 })
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(260, 70)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Parent = anchor
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color
	l.TextSize = size
	l.Font = Enum.Font.PermanentMarker
	l.TextStrokeTransparency = 0
	l.Parent = bb
	TweenService:Create(anchor, TweenInfo.new(0.8), { Position = position + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(l, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 0.85)
end

-- Arco de corte: segmentos de luz que aparecen uno tras otro (barrido)
local function slashArc(center: Vector3, facing: number, color: Color3, radius: number, fromDeg: number, toDeg: number, thickness: number?, edge: Color3?)
	local steps = 12
	for i = 0, steps - 1 do
		local a1 = math.rad(fromDeg + (toDeg - fromDeg) * i / steps)
		local a2 = math.rad(fromDeg + (toDeg - fromDeg) * (i + 1) / steps)
		local p1 = center + Vector3.new(math.cos(a1) * radius * facing, math.sin(a1) * radius, 0)
		local p2 = center + Vector3.new(math.cos(a2) * radius * facing, math.sin(a2) * radius, 0)
		local w = (thickness or 0.5) * math.sin(math.pi * (i + 0.5) / steps) + 0.08 -- más grueso en el centro, como una media luna
		task.delay(i * 0.008, function()
			local seg = part({ Size = Vector3.new(w, w, (p2 - p1).Magnitude + 0.15), CFrame = CFrame.lookAt((p1 + p2) / 2, p2), Color = if edge and i % 2 == 0 then edge else color })
			fade(seg, 0.28)
		end)
	end
end

-- Onda en el suelo + rocas que saltan + polvo
local function groundShock(position: Vector3, color: Color3, size: number)
	local ground = position - Vector3.new(0, 2.8, 0)
	ring(ground, color, size, 0.45, true)
	ring(ground, WHITE, size * 0.6, 0.3, true)
	smokePuff(ground, C(200, 190, 175), 10, 1.5)
	for _ = 1, 8 do
		local rock = part({ Size = Vector3.one * (math.random(4, 9) / 10), CFrame = CFrame.new(ground) * CFrame.Angles(math.random(), math.random(), math.random()),
			Color = C(90, 80, 75), Material = Enum.Material.Slate })
		local target = ground + Vector3.new(math.random(-size, size) / 2, math.random(3, 7), math.random(-2, 2))
		TweenService:Create(rock, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = target }):Play()
		task.delay(0.35, function()
			TweenService:Create(rock, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = target - Vector3.new(0, 6, 0), Transparency = 1 }):Play()
		end)
		Debris:AddItem(rock, 0.75)
	end
end

-- Columna vertical (géiser, pilar de fuego, corriente de agua...)
local function column(position: Vector3, color: Color3, height: number, width: number, material: Enum.Material?)
	local base = position - Vector3.new(0, 2.8, 0)
	local col = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, width, width), CFrame = CFrame.new(base) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color, Material = material or Enum.Material.Neon, Transparency = 0.15 })
	TweenService:Create(col, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
		Size = Vector3.new(height, width, width), CFrame = CFrame.new(base + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	}):Play()
	task.delay(0.25, fade, col, 0.35)
end

-- Siluetas que se quedan atrás (velocidad)
local function afterimages(model: Model, color: Color3, duration: number, every: number?)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < duration and model.Parent do
			for _, name in { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" } do
				local p = model:FindFirstChild(name) :: BasePart?
				if p then
					fade(part({ Size = p.Size, CFrame = p.CFrame, Color = color, Material = Enum.Material.ForceField, Transparency = 0.35 }), 0.25)
				end
			end
			task.wait(every or 0.05)
		end
	end)
end

local function handPos(model: Model, side: string?): Vector3?
	local arm = model:FindFirstChild(if side == "Left" then "Left Arm" else "Right Arm") :: BasePart?
	return arm and (arm.CFrame * CFrame.new(0, -1.1, 0)).Position
end

local function rootPos(model: Model): Vector3?
	local r = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	return r and r.Position
end

-- ===================================================================
-- PROYECTILES: cada estilo crea sus piezas y devuelve update(pos, t)
-- ctx = { Color, D (tamaño), Facing, Start }
-- ===================================================================
local Projectiles = {}

-- Genérico: núcleo + capa de energía + anillos + llamas del color de la técnica
function Projectiles.Energy(ctx, add)
	local d, col = ctx.D, ctx.Color
	local core = add(ball(d * 0.5, col:Lerp(WHITE, 0.6)))
	local shell = add(ball(d, col, { Material = Enum.Material.ForceField }))
	local glow = add(ball(d * 0.9, col, { Transparency = 0.55 }))
	local r1 = add(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.15, d * 1.4, d * 1.4), Color = col:Lerp(WHITE, 0.3), Transparency = 0.35 }))
	trail(core, col:Lerp(WHITE, 0.5), col, d * 0.8)
	light(core, col, d * 3)
	emitter(core, { Texture = TEX_FIRE, Color = ColorSequence.new(col:Lerp(WHITE, 0.4), col), Size = NumberSequence.new(d * 0.6, 0),
		Transparency = NumberSequence.new(0.2, 1), Lifetime = NumberRange.new(0.2, 0.4), Rate = 60, Speed = NumberRange.new(1, 4),
		SpreadAngle = Vector2.new(180, 180), RotSpeed = NumberRange.new(-200, 200), Rotation = NumberRange.new(0, 360) })
	return function(pos, t)
		core.CFrame = CFrame.new(pos)
		shell.CFrame = CFrame.new(pos) * CFrame.Angles(t * 3, t * 2, 0)
		glow.CFrame = CFrame.new(pos)
		glow.Size = Vector3.one * d * 0.9 * (1 + math.sin(t * 25) * 0.08)
		r1.CFrame = CFrame.new(pos) * CFrame.Angles(t * 9, t * 4, 0)
	end
end

-- Gojo · Azul: esfera que ATRAE (partículas y anillos que se cierran hacia el centro)
function Projectiles.Blue(ctx, add)
	local d = ctx.D
	local blue = C(60, 140, 255)
	local core = add(ball(d * 0.45, C(200, 230, 255)))
	local shell = add(ball(d * 0.9, blue, { Material = Enum.Material.ForceField }))
	local field = add(ball(d * 3, blue, { Transparency = 1 }))
	emitter(field, { Texture = TEX_SPARK, Color = ColorSequence.new(C(150, 210, 255), blue), Size = NumberSequence.new(0.5, 0.1),
		Lifetime = NumberRange.new(0.3, 0.5), Rate = 120, Speed = NumberRange.new(6, 10), Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward })
	local rings = {}
	for i = 1, 3 do
		rings[i] = add(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, d * 1.6, d * 1.6), Color = blue, Transparency = 0.3 }))
	end
	trail(core, C(180, 220, 255), blue, d * 0.7)
	light(core, blue, d * 4)
	return function(pos, t)
		core.CFrame = CFrame.new(pos)
		shell.CFrame = CFrame.new(pos) * CFrame.Angles(t * 5, t * 3, 0)
		field.CFrame = CFrame.new(pos)
		for i, r in rings do
			-- anillos que se encogen hacia el centro una y otra vez
			local k = ((t * 2 + i / 3) % 1)
			local s = d * (2.4 - k * 2)
			r.Size = Vector3.new(0.1, s, s)
			r.Transparency = 0.2 + k * 0.7
			r.CFrame = CFrame.new(pos) * CFrame.Angles(i, t * 4 + i, 0)
		end
	end
end

-- Gojo · Rojo: energía inestable que REPELE (pinchos de luz que laten y chispas hacia fuera)
function Projectiles.Red(ctx, add)
	local d = ctx.D
	local red = C(255, 50, 60)
	local core = add(ball(d * 0.5, C(255, 220, 220)))
	local glow = add(ball(d, red, { Transparency = 0.45 }))
	local spikes = {}
	for i = 1, 8 do
		spikes[i] = add(part({ Size = Vector3.new(0.18, 0.18, d * 1.4), Color = C(255, 120, 120) }))
	end
	emitter(core, { Texture = TEX_SPARK, Color = ColorSequence.new(WHITE, red), Size = NumberSequence.new(0.6, 0), Lifetime = NumberRange.new(0.2, 0.35),
		Rate = 90, Speed = NumberRange.new(12, 20), SpreadAngle = Vector2.new(180, 180) })
	trail(core, C(255, 160, 160), red, d * 0.8)
	light(core, red, d * 4)
	return function(pos, t)
		core.CFrame = CFrame.new(pos)
		local pulse = 1 + math.abs(math.sin(t * 30)) * 0.25
		glow.CFrame = CFrame.new(pos)
		glow.Size = Vector3.one * d * pulse
		for i, s in spikes do
			local a = i / 8 * math.pi * 2 + t * 6
			s.CFrame = CFrame.lookAt(pos, pos + Vector3.new(math.cos(a), math.sin(a), 0)) * CFrame.new(0, 0, -d * 0.7 * pulse)
		end
	end
end

-- Púrpura Hueco: esfera enorme que lo borra todo, con Azul y Rojo girando y rayos
function Projectiles.Purple(ctx, add)
	local d = ctx.D
	local purple = C(170, 60, 255)
	local core = add(ball(d * 0.75, C(235, 210, 255)))
	local body = add(ball(d, purple, { Transparency = 0.25 }))
	local shell = add(ball(d * 1.2, purple, { Material = Enum.Material.ForceField }))
	local blue = add(ball(d * 0.25, C(60, 140, 255)))
	local red = add(ball(d * 0.25, C(255, 50, 60)))
	trail(core, C(220, 180, 255), purple, d, 0.5)
	light(core, purple, d * 3)
	emitter(body, { Texture = TEX_SMOKE, LightEmission = 0.5, Color = ColorSequence.new(C(60, 20, 90)), Size = NumberSequence.new(d * 0.5, d),
		Transparency = NumberSequence.new(0.3, 1), Lifetime = NumberRange.new(0.4, 0.7), Rate = 40, Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(180, 180) })
	local lastBolt = 0
	return function(pos, t)
		core.CFrame = CFrame.new(pos)
		body.CFrame = CFrame.new(pos)
		shell.CFrame = CFrame.new(pos) * CFrame.Angles(t * 2, t * 3, 0)
		blue.CFrame = CFrame.new(pos + Vector3.new(math.cos(t * 8), math.sin(t * 8), 0) * d * 0.7)
		red.CFrame = CFrame.new(pos + Vector3.new(math.cos(t * 8 + math.pi), math.sin(t * 8 + math.pi), 0) * d * 0.7)
		if t - lastBolt > 0.08 then
			lastBolt = t
			local a = math.random() * math.pi * 2
			bolt(pos, pos + Vector3.new(math.cos(a), math.sin(a), 0) * d * 1.3, if math.random() < 0.5 then WHITE else purple, 0.2)
		end
	end
end

-- Media luna de corte (Desmantelar, Tajo Maldito, Corte Volador): sin bola, solo el filo con ecos detrás
local function crescent(ctx, add, color: Color3, edge: Color3, echoes: number)
	local d, f = ctx.D, ctx.Facing
	local sets = {}
	for e = 0, echoes do
		local segs = {}
		for i = 1, 9 do
			segs[i] = add(part({ Size = Vector3.new(0.2, 0.2, 0.2), Color = if e == 0 then (if i % 3 == 0 then edge else color) else color, Transparency = e * 0.25 }))
		end
		sets[e] = segs
	end
	local radius = d * 0.9
	return function(pos, t)
		for e, segs in sets do
			local center = pos - Vector3.new(f * e * d * 0.35, 0, 0)
			for i, s in segs do
				local a1 = math.rad(-70 + 140 * (i - 1) / 9)
				local a2 = math.rad(-70 + 140 * i / 9)
				local p1 = center + Vector3.new(math.cos(a1) * radius * f, math.sin(a1) * radius * 1.4, 0)
				local p2 = center + Vector3.new(math.cos(a2) * radius * f, math.sin(a2) * radius * 1.4, 0)
				local w = 0.12 + 0.55 * math.sin(math.pi * (i - 0.5) / 9)
				s.Size = Vector3.new(w, w, (p2 - p1).Magnitude + 0.1)
				s.CFrame = CFrame.lookAt((p1 + p2) / 2, p2)
			end
		end
	end
end
function Projectiles.Dismantle(ctx, add)
	return crescent(ctx, add, WHITE, C(255, 60, 60), 2)
end
function Projectiles.CrescentWhite(ctx, add)
	return crescent(ctx, add, C(240, 240, 255), C(180, 120, 255), 2)
end
function Projectiles.CrescentGreen(ctx, add)
	return crescent(ctx, add, C(170, 255, 190), C(60, 200, 100), 3)
end

-- Sukuna · Flecha de Fuego (Fuga): flecha de fuego con punta y llamas
function Projectiles.FireArrow(ctx, add)
	local d, f = ctx.D, ctx.Facing
	local orange = C(255, 120, 30)
	local shaft = add(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(d * 2.2, d * 0.25, d * 0.25), Color = C(255, 200, 120) }))
	local tipA = add(part({ Size = Vector3.new(d * 0.7, d * 0.15, d * 0.15), Color = C(255, 240, 200) }))
	local tipB = add(part({ Size = Vector3.new(d * 0.7, d * 0.15, d * 0.15), Color = C(255, 240, 200) }))
	local flame = add(part({ Size = Vector3.new(d * 2, d * 0.6, d * 0.6), Transparency = 1 }))
	emitter(flame, { Texture = TEX_FIRE, Color = ColorSequence.new(C(255, 230, 150), orange), Size = NumberSequence.new(d * 0.7, 0),
		Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.15, 0.3), Rate = 160, Speed = NumberRange.new(2, 6),
		SpreadAngle = Vector2.new(180, 180), RotSpeed = NumberRange.new(-200, 200), Rotation = NumberRange.new(0, 360) })
	emitter(flame, { Texture = TEX_SMOKE, LightEmission = 0, Color = ColorSequence.new(C(60, 30, 20)), Size = NumberSequence.new(d * 0.4, d),
		Transparency = NumberSequence.new(0.5, 1), Lifetime = NumberRange.new(0.4, 0.7), Rate = 25, Speed = NumberRange.new(1, 3) })
	trail(shaft, C(255, 220, 120), orange, d * 0.5, 0.4)
	light(shaft, orange, d * 4)
	return function(pos, t)
		shaft.CFrame = CFrame.new(pos - Vector3.new(f * d * 0.6, 0, 0))
		local tip = pos + Vector3.new(f * d * 0.5, 0, 0)
		tipA.CFrame = CFrame.new(tip) * CFrame.Angles(0, 0, math.rad(f * 30))
		tipB.CFrame = CFrame.new(tip) * CFrame.Angles(0, 0, math.rad(-f * 30))
		flame.CFrame = shaft.CFrame
	end
end

-- Megumi · Perros Divinos: lobo de sombra corriendo con ojos brillantes
function Projectiles.Dogs(ctx, add)
	local d, f = ctx.D, ctx.Facing
	local fur = C(15, 15, 22)
	local body = add(part({ Size = Vector3.new(d * 1.1, d * 0.5, d * 0.45), Color = fur, Material = Enum.Material.SmoothPlastic }))
	local head = add(part({ Size = Vector3.new(d * 0.45, d * 0.4, d * 0.38), Color = fur, Material = Enum.Material.SmoothPlastic }))
	local snout = add(part({ Size = Vector3.new(d * 0.3, d * 0.18, d * 0.2), Color = fur, Material = Enum.Material.SmoothPlastic }))
	local ears = { add(part({ Size = Vector3.new(d * 0.1, d * 0.25, d * 0.1), Color = fur, Material = Enum.Material.SmoothPlastic })),
		add(part({ Size = Vector3.new(d * 0.1, d * 0.25, d * 0.1), Color = fur, Material = Enum.Material.SmoothPlastic })) }
	local eye = add(part({ Size = Vector3.new(d * 0.08, d * 0.06, d * 0.4), Color = C(230, 240, 255) }))
	local legs = {}
	for i = 1, 4 do
		legs[i] = add(part({ Size = Vector3.new(d * 0.12, d * 0.45, d * 0.12), Color = fur, Material = Enum.Material.SmoothPlastic }))
	end
	local tail = add(part({ Size = Vector3.new(d * 0.45, d * 0.1, d * 0.1), Color = fur, Material = Enum.Material.SmoothPlastic }))
	emitter(body, { Texture = TEX_SMOKE, LightEmission = 0, Color = ColorSequence.new(C(10, 8, 20)), Size = NumberSequence.new(d * 0.3, d * 0.8),
		Transparency = NumberSequence.new(0.3, 1), Lifetime = NumberRange.new(0.3, 0.6), Rate = 50, Speed = NumberRange.new(0.5, 2) })
	return function(pos, t)
		local bob = math.abs(math.sin(t * 22)) * d * 0.12
		local base = CFrame.new(pos + Vector3.new(0, bob, 0)) * CFrame.Angles(0, if f > 0 then 0 else math.pi, 0)
		body.CFrame = base
		head.CFrame = base * CFrame.new(d * 0.65, d * 0.25, 0)
		snout.CFrame = head.CFrame * CFrame.new(d * 0.3, -d * 0.06, 0)
		ears[1].CFrame = head.CFrame * CFrame.new(-d * 0.05, d * 0.28, d * 0.12)
		ears[2].CFrame = head.CFrame * CFrame.new(-d * 0.05, d * 0.28, -d * 0.12)
		eye.CFrame = head.CFrame * CFrame.new(d * 0.12, d * 0.07, 0)
		tail.CFrame = base * CFrame.new(-d * 0.7, d * 0.2, 0) * CFrame.Angles(0, 0, math.rad(25 + math.sin(t * 20) * 15))
		for i, leg in legs do
			local x = if i <= 2 then d * 0.4 else -d * 0.4
			local z = if i % 2 == 0 then d * 0.15 else -d * 0.15
			local swing = math.sin(t * 22 + (if i % 2 == 0 then 0 else math.pi)) * 0.7
			leg.CFrame = base * CFrame.new(x, -d * 0.3, z) * CFrame.Angles(0, 0, swing) * CFrame.new(0, -d * 0.15, 0)
		end
	end
end

-- Choso · Perforación de Sangre: rayo fino de sangre comprimida que se alarga desde la mano
function Projectiles.BloodBeam(ctx, add)
	local d, start = ctx.D, ctx.Start
	local red = C(200, 0, 30)
	local beam = add(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, d * 0.3, d * 0.3), Color = C(255, 60, 80) }))
	local outer = add(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, d * 0.6, d * 0.6), Color = red, Transparency = 0.6 }))
	local tip = add(ball(d * 0.45, C(255, 120, 130)))
	emitter(tip, { Texture = TEX_SPARK, Color = ColorSequence.new(C(255, 80, 90)), Size = NumberSequence.new(0.5, 0), Lifetime = NumberRange.new(0.2, 0.4),
		Rate = 70, Speed = NumberRange.new(5, 12), SpreadAngle = Vector2.new(60, 60) })
	light(tip, red, d * 3)
	return function(pos, t)
		local len = math.max(0.5, (pos - start).Magnitude)
		local mid = (pos + start) / 2
		beam.Size = Vector3.new(len, d * 0.3, d * 0.3)
		beam.CFrame = CFrame.new(mid)
		outer.Size = Vector3.new(len, d * 0.6 * (1 + math.sin(t * 40) * 0.1), d * 0.6)
		outer.CFrame = CFrame.new(mid)
		tip.CFrame = CFrame.new(pos)
	end
end

-- Choso · Bala de Sangre: gota roja con anillo de presión
function Projectiles.BloodBullet(ctx, add)
	local d = ctx.D
	local drop = add(ball(d * 0.6, C(180, 0, 25), { Material = Enum.Material.Glass, Transparency = 0.05 }))
	local ringP = add(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, d, d), Color = C(255, 80, 90), Transparency = 0.4 }))
	trail(drop, C(255, 60, 70), C(120, 0, 10), d * 0.5, 0.25)
	return function(pos, t)
		drop.CFrame = CFrame.new(pos)
		ringP.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(t * 10, 0, 0)
	end
end

-- Maldición · Escupitajo: masa verde viscosa que gotea
function Projectiles.Spit(ctx, add)
	local d = ctx.D
	local goo = add(ball(d * 0.8, C(100, 230, 90), { Material = Enum.Material.Glass, Transparency = 0.15 }))
	local inner = add(ball(d * 0.45, C(60, 140, 50)))
	emitter(goo, { Texture = TEX_SMOKE, LightEmission = 0.2, Color = ColorSequence.new(C(120, 255, 100)), Size = NumberSequence.new(d * 0.25, 0),
		Lifetime = NumberRange.new(0.4, 0.6), Rate = 30, Speed = NumberRange.new(0, 1), Acceleration = Vector3.new(0, -40, 0) })
	return function(pos, t)
		local wob = 1 + math.sin(t * 18) * 0.12
		goo.Size = Vector3.new(d * 0.8 * wob, d * 0.8 / wob, d * 0.8)
		goo.CFrame = CFrame.new(pos)
		inner.CFrame = CFrame.new(pos)
	end
end

-- Kenjaku · Maldición Invocada: espíritu maldito con ojos y boca
function Projectiles.CurseSpirit(ctx, add)
	local d, f = ctx.D, ctx.Facing
	local bodyP = add(ball(d * 0.9, C(80, 50, 110), { Material = Enum.Material.SmoothPlastic }))
	local aura = add(ball(d * 1.1, C(120, 60, 160), { Material = Enum.Material.ForceField }))
	local eyes = { add(ball(d * 0.15, C(255, 240, 120))), add(ball(d * 0.15, C(255, 240, 120))) }
	local mouth = add(part({ Size = Vector3.new(d * 0.08, d * 0.12, d * 0.4), Color = C(20, 0, 10) }))
	emitter(bodyP, { Texture = TEX_SMOKE, LightEmission = 0, Color = ColorSequence.new(C(40, 20, 50)), Size = NumberSequence.new(d * 0.4, d),
		Transparency = NumberSequence.new(0.3, 1), Lifetime = NumberRange.new(0.4, 0.7), Rate = 35, Speed = NumberRange.new(0.5, 2) })
	return function(pos, t)
		local p = pos + Vector3.new(0, math.sin(t * 8) * d * 0.15, 0)
		bodyP.CFrame = CFrame.new(p)
		aura.CFrame = CFrame.new(p)
		local front = p + Vector3.new(f * d * 0.42, 0, 0)
		eyes[1].CFrame = CFrame.new(front + Vector3.new(0, d * 0.15, d * 0.18))
		eyes[2].CFrame = CFrame.new(front + Vector3.new(0, d * 0.15, -d * 0.18))
		mouth.CFrame = CFrame.new(front - Vector3.new(0, d * 0.15, 0))
	end
end

-- Kenjaku · Enjambre Maldito: nube de bichos negros zumbando
function Projectiles.Swarm(ctx, add)
	local d = ctx.D
	local bugs = {}
	for i = 1, 12 do
		bugs[i] = add(part({ Size = Vector3.new(0.35, 0.25, 0.25), Color = if i % 4 == 0 then C(255, 40, 40) else C(20, 15, 25), Material = Enum.Material.SmoothPlastic }))
	end
	return function(pos, t)
		for i, b in bugs do
			local a = t * (8 + i) + i
			b.CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * d * 0.6, math.sin(a * 1.3) * d * 0.5, math.sin(a) * d * 0.3)) * CFrame.Angles(a, a, 0)
		end
	end
end

-- Kenjaku · Vórtice Maldito (Uzumaki): espiral oscura que gira
function Projectiles.Vortex(ctx, add)
	local d = ctx.D
	local segs = {}
	for i = 1, 18 do
		segs[i] = add(part({ Size = Vector3.new(0.3, 0.3, d * 0.3), Color = C(70, 30, 100):Lerp(BLACK, (i % 3) / 4) }))
	end
	local core = add(ball(d * 0.35, C(20, 0, 30)))
	return function(pos, t)
		core.CFrame = CFrame.new(pos)
		for i, s in segs do
			local a = i * 0.7 - t * 10
			local r = d * (0.2 + i / 18 * 0.8)
			local p = pos + Vector3.new(math.cos(a) * r, math.sin(a) * r, 0)
			s.CFrame = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), math.cos(a), 0))
		end
	end
end

-- Naruto · Esfera Espiral (Rasengan): núcleo blanco con anillos de viento girando muy rápido
function Projectiles.Rasengan(ctx, add)
	local d = ctx.D
	local blue = C(120, 200, 255)
	local core = add(ball(d * 0.45, WHITE))
	local shell = add(ball(d * 0.85, blue, { Transparency = 0.35 }))
	local rings = {}
	for i = 1, 4 do
		rings[i] = add(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, d * (0.9 + i * 0.12), d * (0.9 + i * 0.12)), Color = blue:Lerp(WHITE, i / 5), Transparency = 0.25 }))
	end
	emitter(shell, { Texture = TEX_SMOKE, LightEmission = 0.8, Color = ColorSequence.new(C(200, 235, 255)), Size = NumberSequence.new(d * 0.3, d * 0.6),
		Transparency = NumberSequence.new(0.4, 1), Lifetime = NumberRange.new(0.15, 0.25), Rate = 60, Speed = NumberRange.new(3, 6), SpreadAngle = Vector2.new(180, 180) })
	light(core, blue, d * 3)
	return function(pos, t)
		core.CFrame = CFrame.new(pos)
		shell.CFrame = CFrame.new(pos)
		for i, r in rings do
			r.CFrame = CFrame.new(pos) * CFrame.Angles(i * 0.8, t * (20 + i * 4), i)
		end
	end
end

-- Kunai / daga arrojadiza: hoja girando
local function spinningBlade(ctx, add, bladeColor: Color3, handleColor: Color3, withRing: boolean)
	local d = ctx.D
	local blade = add(part({ Size = Vector3.new(d * 0.9, d * 0.25, d * 0.06), Color = bladeColor, Material = Enum.Material.Metal }))
	local handle = add(part({ Size = Vector3.new(d * 0.5, d * 0.12, d * 0.12), Color = handleColor, Material = Enum.Material.Fabric }))
	local r = withRing and add(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.05, d * 0.25, d * 0.25), Color = handleColor, Material = Enum.Material.Metal })) or nil
	trail(blade, C(230, 230, 240), C(150, 150, 160), d * 0.2, 0.15)
	return function(pos, t)
		local spin = CFrame.new(pos) * CFrame.Angles(0, 0, -t * 25 * ctx.Facing)
		blade.CFrame = spin * CFrame.new(d * 0.3, 0, 0)
		handle.CFrame = spin * CFrame.new(-d * 0.35, 0, 0)
		if r then
			r.CFrame = spin * CFrame.new(-d * 0.65, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
		end
	end
end
function Projectiles.Kunai(ctx, add)
	return spinningBlade(ctx, add, C(170, 175, 185), C(40, 40, 50), true)
end
function Projectiles.Dagger(ctx, add)
	return spinningBlade(ctx, add, C(210, 210, 220), C(110, 70, 40), false)
end

-- Hakari · Puertas Corredizas: puertas shoji brillantes que se cierran sobre el rival
function Projectiles.Doors(ctx, add)
	local d, f = ctx.D, ctx.Facing
	local green = C(120, 255, 140)
	local panels = {}
	for i = 1, 2 do
		local frame = add(part({ Size = Vector3.new(d * 0.1, d * 1.6, d * 0.8), Color = green }))
		local paper = add(part({ Size = Vector3.new(d * 0.06, d * 1.4, d * 0.65), Color = C(240, 250, 230), Material = Enum.Material.SmoothPlastic, Transparency = 0.2 }))
		panels[i] = { frame, paper }
	end
	return function(pos, t)
		local gap = d * 0.5 * math.abs(math.cos(t * 6))
		for i, pair in panels do
			local z = (if i == 1 then -1 else 1) * (d * 0.35 + gap)
			pair[1].CFrame = CFrame.new(pos + Vector3.new(0, 0, z))
			pair[2].CFrame = CFrame.new(pos + Vector3.new(f * 0.05, 0, z))
		end
	end
end

-- Goku · Onda Celestial (Kamehameha): rayo azul que sale de las manos con una esfera al frente
function Projectiles.Kamehameha(ctx, add)
	local d, start = ctx.D, ctx.Start
	local blue = C(90, 200, 255)
	local core = add(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, d * 0.45, d * 0.45), Color = C(220, 245, 255) }))
	local outer = add(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, d * 0.85, d * 0.85), Color = blue, Transparency = 0.45 }))
	local head = add(ball(d * 1.1, blue, { Transparency = 0.25 }))
	local headCore = add(ball(d * 0.7, WHITE))
	emitter(head, { Texture = TEX_SPARK, Color = ColorSequence.new(WHITE, blue), Size = NumberSequence.new(0.8, 0), Lifetime = NumberRange.new(0.2, 0.4),
		Rate = 100, Speed = NumberRange.new(10, 20), SpreadAngle = Vector2.new(180, 180) })
	light(head, blue, d * 5)
	return function(pos, t)
		local len = math.max(0.5, (pos - start).Magnitude)
		local mid = (pos + start) / 2
		local pulse = 1 + math.sin(t * 35) * 0.08
		core.Size = Vector3.new(len, d * 0.45 * pulse, d * 0.45 * pulse)
		core.CFrame = CFrame.new(mid)
		outer.Size = Vector3.new(len, d * 0.85 * pulse, d * 0.85 * pulse)
		outer.CFrame = CFrame.new(mid)
		head.CFrame = CFrame.new(pos)
		headCore.CFrame = CFrame.new(pos)
	end
end

-- Nobara · Clavos: tres clavos que vuelan en abanico
local function nails(ctx, add, glow: Color3?)
	local d, f = ctx.D, ctx.Facing
	local list = {}
	for i = 1, 3 do
		local shaft = add(part({ Size = Vector3.new(d * 0.7, d * 0.08, d * 0.08), Color = C(170, 170, 180), Material = Enum.Material.Metal }))
		local head = add(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(d * 0.05, d * 0.25, d * 0.25), Color = C(190, 190, 200), Material = Enum.Material.Metal }))
		if glow then
			emitter(shaft, { Texture = TEX_SPARK, Color = ColorSequence.new(glow), Size = NumberSequence.new(0.5, 0), Lifetime = NumberRange.new(0.15, 0.3), Rate = 40, Speed = NumberRange.new(1, 3) })
		end
		trail(shaft, C(220, 220, 230), C(120, 120, 130), d * 0.08, 0.12)
		list[i] = { shaft, head, (i - 2) * d * 0.35 }
	end
	return function(pos, t)
		for _, n in list do
			local p = pos + Vector3.new(0, n[3], 0)
			n[1].CFrame = CFrame.new(p)
			n[2].CFrame = CFrame.new(p - Vector3.new(f * d * 0.35, 0, 0))
		end
	end
end
function Projectiles.Nails(ctx, add)
	return nails(ctx, add, nil)
end
function Projectiles.Hairpin(ctx, add)
	return nails(ctx, add, C(255, 150, 60))
end

-- Mahito · Alma Disparada: alma pálida cosida con cara deformada
function Projectiles.Soul(ctx, add)
	local d = ctx.D
	local soul = add(ball(d * 0.8, C(170, 190, 215), { Material = Enum.Material.SmoothPlastic }))
	local glowP = add(ball(d, C(150, 170, 210), { Material = Enum.Material.ForceField }))
	local stitches = {}
	for i = 1, 4 do
		stitches[i] = add(part({ Size = Vector3.new(d * 0.6, d * 0.04, d * 0.04), Color = C(40, 40, 50), Material = Enum.Material.SmoothPlastic }))
	end
	return function(pos, t)
		local p = pos + Vector3.new(0, math.sin(t * 10) * d * 0.1, 0)
		soul.CFrame = CFrame.new(p)
		glowP.CFrame = CFrame.new(p)
		for i, s in stitches do
			s.CFrame = CFrame.new(p + Vector3.new(0, (i - 2.5) * d * 0.15, -d * 0.38)) * CFrame.Angles(0, 0, math.rad(if i % 2 == 0 then 25 else -25))
		end
	end
end

-- Yuta · ¡Ven, Reina Maldita!: Rika gigante (cabeza, ojos y brazo) que embiste
function Projectiles.Rika(ctx, add)
	local d, f = ctx.D, ctx.Facing
	local purple = C(140, 60, 200)
	local head = add(ball(d * 1.2, C(40, 20, 60), { Material = Enum.Material.SmoothPlastic }))
	local aura = add(ball(d * 1.6, purple, { Material = Enum.Material.ForceField }))
	local eyes = { add(ball(d * 0.18, WHITE)), add(ball(d * 0.18, WHITE)) }
	local arm = add(part({ Size = Vector3.new(d * 1.4, d * 0.35, d * 0.35), Color = C(40, 20, 60), Material = Enum.Material.SmoothPlastic }))
	local claw = add(part({ Size = Vector3.new(d * 0.4, d * 0.6, d * 0.45), Color = C(230, 220, 240), Material = Enum.Material.SmoothPlastic }))
	emitter(head, { Texture = TEX_SMOKE, LightEmission = 0.3, Color = ColorSequence.new(purple), Size = NumberSequence.new(d * 0.5, d * 1.2),
		Transparency = NumberSequence.new(0.4, 1), Lifetime = NumberRange.new(0.4, 0.7), Rate = 40, Speed = NumberRange.new(1, 3) })
	light(head, purple, d * 4)
	return function(pos, t)
		local p = pos + Vector3.new(0, d * 0.3, 0)
		head.CFrame = CFrame.new(p)
		aura.CFrame = CFrame.new(p)
		eyes[1].CFrame = CFrame.new(p + Vector3.new(f * d * 0.55, d * 0.15, d * 0.25))
		eyes[2].CFrame = CFrame.new(p + Vector3.new(f * d * 0.55, d * 0.15, -d * 0.25))
		local reach = d * (0.9 + math.abs(math.sin(t * 6)) * 0.4)
		arm.CFrame = CFrame.new(p + Vector3.new(f * reach, -d * 0.4, 0))
		claw.CFrame = CFrame.new(p + Vector3.new(f * (reach + d * 0.8), -d * 0.4, 0))
	end
end

-- Jogo · Bola de Magma: roca negra con grietas de lava, fuego y humo
function Projectiles.Magma(ctx, add)
	local d = ctx.D
	local rock = add(ball(d * 0.8, C(40, 25, 20), { Material = Enum.Material.Basalt }))
	local lava = add(ball(d * 0.85, C(255, 100, 10), { Transparency = 0.45 }))
	emitter(rock, { Texture = TEX_FIRE, Color = ColorSequence.new(C(255, 220, 120), C(255, 60, 0)), Size = NumberSequence.new(d * 0.7, 0),
		Transparency = NumberSequence.new(0.1, 1), Lifetime = NumberRange.new(0.2, 0.4), Rate = 90, Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(180, 180),
		RotSpeed = NumberRange.new(-200, 200), Rotation = NumberRange.new(0, 360) })
	emitter(rock, { Texture = TEX_SMOKE, LightEmission = 0, Color = ColorSequence.new(C(40, 30, 30)), Size = NumberSequence.new(d * 0.5, d * 1.4),
		Transparency = NumberSequence.new(0.3, 1), Lifetime = NumberRange.new(0.5, 0.9), Rate = 30, Speed = NumberRange.new(1, 3), Acceleration = Vector3.new(0, 6, 0) })
	light(rock, C(255, 120, 30), d * 4)
	return function(pos, t)
		rock.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, -t * 8 * ctx.Facing)
		lava.CFrame = CFrame.new(pos)
		lava.Transparency = 0.35 + math.abs(math.sin(t * 12)) * 0.25
	end
end

-- Jogo · Insectos de Fuego: varios bichos de fuego en zigzag
function Projectiles.FireBugs(ctx, add)
	local d = ctx.D
	local bugs = {}
	for i = 1, 5 do
		local b = add(ball(d * 0.25, C(255, 200, 80)))
		emitter(b, { Texture = TEX_FIRE, Color = ColorSequence.new(C(255, 220, 120), C(255, 80, 0)), Size = NumberSequence.new(d * 0.35, 0),
			Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.15, 0.3), Rate = 40, Speed = NumberRange.new(0, 1) })
		bugs[i] = b
	end
	return function(pos, t)
		for i, b in bugs do
			b.CFrame = CFrame.new(pos + Vector3.new(-(i - 1) * d * 0.4 * ctx.Facing, math.sin(t * 14 + i) * d * 0.6, math.cos(t * 9 + i) * d * 0.3))
		end
	end
end

-- Qué estilo usa cada técnica (por su nombre)
local PROJECTILE_STYLE = {
	["Azul: Atracción"] = "Blue", ["Rojo: Repulsión"] = "Red", ["Púrpura Hueco"] = "Purple", ["Técnica Inversa: Púrpura Hueco"] = "Purple",
	["Desmantelar"] = "Dismantle", ["Flecha de Fuego"] = "FireArrow", ["Perros Divinos"] = "Dogs",
	["Perforación de Sangre"] = "BloodBeam", ["Sangre Perforante"] = "BloodBeam", ["Bala de Sangre"] = "BloodBullet",
	["Escupitajo Maldito"] = "Spit", ["Maldición Invocada"] = "CurseSpirit", ["Enjambre Maldito"] = "Swarm", ["Vórtice Maldito"] = "Vortex",
	["Uzumaki Máximo"] = "Vortex", ["Esfera Espiral"] = "Rasengan", ["Kunai"] = "Kunai", ["Puertas Corredizas"] = "Doors",
	["Onda Celestial"] = "Kamehameha", ["Clavos"] = "Nails", ["Horquilla"] = "Hairpin", ["Alma Disparada"] = "Soul",
	["Tajo Maldito"] = "CrescentWhite", ["¡Ven, Reina Maldita!"] = "Rika", ["Corte Volador"] = "CrescentGreen", ["Asura: Ichibugin"] = "CrescentGreen",
	["Daga Arrojadiza"] = "Dagger", ["Bola de Magma"] = "Magma", ["Insectos de Fuego"] = "FireBugs",
}

-- Explosión final de cada estilo
local IMPACT = {
	Blue = function(pos, d)
		local r = ball(d * 4, C(60, 140, 255), { Position = pos, Transparency = 0.5, Material = Enum.Material.ForceField })
		fade(r, 0.35, { Size = Vector3.one * 0.5 }) -- implosión
		sparks(pos, C(120, 190, 255), 20, 25)
	end,
	Red = function(pos, d)
		ring(pos, C(255, 60, 60), d * 6, 0.4)
		fade(ball(d, WHITE, { Position = pos }), 0.3, { Size = Vector3.one * d * 4 })
		sparks(pos, C(255, 80, 80), 35, 50)
	end,
	Purple = function(pos, d)
		fade(ball(d, C(200, 120, 255), { Position = pos }), 0.5, { Size = Vector3.one * d * 3 })
		ring(pos, C(170, 60, 255), d * 5, 0.5)
		sparks(pos, C(200, 120, 255), 40, 60)
	end,
	Magma = function(pos, d)
		fireBurst(pos, C(255, 220, 120), C(255, 60, 0), 30, d)
		smokePuff(pos, C(50, 35, 30), 12, d * 0.6)
		ring(pos, C(255, 120, 30), d * 4, 0.4)
	end,
	Hairpin = function(pos, d)
		fireBurst(pos, C(255, 230, 150), C(255, 120, 40), 35, d * 1.2)
		ring(pos, C(255, 150, 60), d * 6, 0.45)
		floatText(pos + Vector3.new(0, 2, 0), "¡BOOM!", C(255, 180, 80), 34)
	end,
	FireArrow = function(pos, d)
		fireBurst(pos, C(255, 230, 150), C(255, 80, 10), 45, d * 1.4)
		ring(pos, C(255, 120, 30), d * 6, 0.5)
	end,
	Kamehameha = function(pos, d)
		fade(ball(d, WHITE, { Position = pos }), 0.35, { Size = Vector3.one * d * 3.5 })
		ring(pos, C(90, 200, 255), d * 6, 0.45)
		sparks(pos, C(150, 220, 255), 40, 55)
	end,
	Spit = function(pos, d)
		burstAt(pos, 20, { Texture = TEX_SMOKE, LightEmission = 0.2, Color = ColorSequence.new(C(120, 255, 100)), Size = NumberSequence.new(d * 0.3, 0),
			Lifetime = NumberRange.new(0.4, 0.7), Speed = NumberRange.new(8, 16), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -40, 0) })
	end,
	BloodBeam = function(pos, d)
		burstAt(pos, 25, { Texture = TEX_SPARK, Color = ColorSequence.new(C(255, 60, 80), C(120, 0, 10)), Size = NumberSequence.new(0.6, 0),
			Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(10, 25), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -30, 0) })
	end,
}
IMPACT.BloodBullet = IMPACT.BloodBeam

local function defaultImpact(pos: Vector3, d: number, color: Color3)
	ring(pos, color, d * 4, 0.35)
	fade(ball(d * 1.2, WHITE, { Position = pos }), 0.25, { Size = Vector3.one * d * 2.6, Color = color })
	sparks(pos, color, 25, 45)
	smokePuff(pos, color:Lerp(BLACK, 0.7), 8, d * 0.6)
end

-- ===== Gestión de los proyectiles en vuelo
local active = {} -- [id] = { Update, Parts, Start, Facing, Speed, Born, Life, Style, D, Color }

local function stopProjectile(id: number, pos: Vector3?, burst: boolean)
	local p = active[id]
	if not p then
		return
	end
	active[id] = nil
	local at = pos or p.Last
	if burst and at then
		local f = IMPACT[p.Style]
		if f then
			f(at, p.D)
		else
			defaultImpact(at, p.D, p.Color)
		end
	end
	for _, piece in p.Parts do
		-- las estelas y partículas se apagan suaves en vez de cortarse de golpe
		for _, d in piece:GetDescendants() do
			if d:IsA("ParticleEmitter") or d:IsA("Trail") then
				d.Enabled = false
			end
		end
		piece.Transparency = 1
		Debris:AddItem(piece, 0.6)
	end
end

function SpecialFX.ProjectileSpawn(id: number, attacker: Instance?, name: string, color: Color3, d: number, start: Vector3, facing: number, speed: number, life: number)
	local style = PROJECTILE_STYLE[name] or "Energy"
	local parts = {}
	local function add(p)
		table.insert(parts, p)
		return p
	end
	local ok, update = pcall(Projectiles[style], { Color = color, D = d, Facing = facing, Start = start }, add)
	if not ok then
		warn("[SpecialFX]", style, update)
		return
	end
	active[id] = { Update = update, Parts = parts, Start = start, Facing = facing, Speed = speed, Born = os.clock(), Life = life, Style = style, D = d, Color = color }
	update(start, 0)
	-- destello en la mano al lanzarlo
	ring(start, color, d * 2.5, 0.25)
end

function SpecialFX.ProjectileHit(id: number, pos: Vector3)
	local p = active[id]
	if p then
		sparks(pos, p.Color, 18, 35)
		ring(pos, p.Color, p.D * 2.5, 0.25)
	end
end

function SpecialFX.ProjectileEnd(id: number, pos: Vector3, _hit: boolean)
	-- Tanto si choca como si se acaba su vida, termina con la explosión de su estilo
	stopProjectile(id, pos, true)
end

-- ===================================================================
-- TÉCNICAS CUERPO A CUERPO / MOVILIDAD
-- ===================================================================
local Moves = {}

-- Genéricos según la pose de la animación
local POSE_FX = {
	Slash = function(m, color, f, at)
		slashArc(at + Vector3.new(f * 1.5, 0.5, 0), f, color, 4, 70, -60, 0.5, WHITE)
	end,
	SlashHeavy = function(m, color, f, at)
		slashArc(at + Vector3.new(f * 2, 1, 0), f, color, 6, 100, -80, 0.8, WHITE)
		slashArc(at + Vector3.new(f * 2.4, 1, 0), f, WHITE, 5.4, 95, -75, 0.3)
	end,
	SlashUp = function(m, color, f, at)
		slashArc(at + Vector3.new(f * 0.5, 0, 0), f, color, 5, -60, 120, 0.6, WHITE)
	end,
	Spin = function(m, color, f, at)
		slashArc(at, 1, color, 5, 0, 360, 0.5, WHITE)
	end,
	Thrust = function(m, color, f, at)
		local from = at + Vector3.new(f * 1, 0.3, 0)
		local to = from + Vector3.new(f * 9, 0, 0)
		local line = part({ Size = Vector3.new(0.35, 0.35, 0.5), CFrame = CFrame.lookAt(from, to), Color = WHITE })
		TweenService:Create(line, TweenInfo.new(0.08), { Size = Vector3.new(0.35, 0.35, 9), CFrame = CFrame.lookAt((from + to) / 2, to) }):Play()
		task.delay(0.1, fade, line, 0.2)
		ring(to, color, 5, 0.25)
	end,
	Slam = function(m, color, f, at)
		groundShock(at, color, 16)
	end,
	Stomp = function(m, color, f, at)
		groundShock(at, color, 10)
	end,
	Rise = function(m, color, f, at)
		for i = 0, 3 do
			task.delay(i * 0.05, ring, at - Vector3.new(0, 2 - i * 1.5, 0), color, 6 - i, 0.3, true)
		end
		smokePuff(at - Vector3.new(0, 2.8, 0), C(220, 220, 220), 8, 1)
	end,
	Palms = function(m, color, f, at)
		local h = handPos(m) or at
		fade(ball(1, color, { Position = h }), 0.25, { Size = Vector3.one * 5 })
		ring(h, color, 7, 0.3)
	end,
	Haymaker = function(m, color, f, at)
		local h = handPos(m) or at
		fade(ball(1.2, WHITE, { Position = h + Vector3.new(f * 1.5, 0, 0) }), 0.2, { Size = Vector3.one * 4, Color = color })
		ring(h + Vector3.new(f * 2, 0, 0), color, 8, 0.3)
		sparks(h, color, 12, 30)
	end,
	Jab = function(m, color, f, at)
		local h = handPos(m) or at
		ring(h + Vector3.new(f * 1.5, 0, 0), color, 5, 0.2)
	end,
	HighKick = function(m, color, f, at)
		slashArc(at + Vector3.new(f * 0.5, -0.5, 0), f, color, 3.5, -70, 80, 0.4)
	end,
	DoubleUp = function(m, color, f, at)
		slashArc(at, f, color, 4, -30, 150, 0.5, WHITE)
	end,
	Clap = function(m, color, f, at)
		ring(at + Vector3.new(0, 1, 0), WHITE, 14, 0.35)
		floatText(at + Vector3.new(0, 4, 0), "¡CLAP!", C(255, 220, 160), 28)
	end,
}

-- Técnicas con efecto propio (por nombre)
Moves["Puño Divergente"] = function(m, color, f, at)
	POSE_FX.Haymaker(m, color, f, at)
	-- segundo impacto retardado (la energía maldita llega un instante después)
	task.delay(0.25, function()
		local h = (handPos(m) or at) + Vector3.new(f * 2.5, 0, 0)
		ring(h, C(60, 180, 255), 10, 0.35)
		sparks(h, C(60, 180, 255), 18, 35)
	end)
end
Moves["Embestida Maldita"] = function(m, color, f, at)
	afterimages(m, color, 0.35)
end
Moves["Impacto Sísmico"] = function(m, color, f, at)
	task.delay(0.15, function()
		groundShock(rootPos(m) or at, color, 22)
	end)
end
Moves["Puño Destello Negro"] = function(m, color, f, at)
	local h = (handPos(m) or at) + Vector3.new(f * 2, 0, 0)
	for _ = 1, 6 do
		local a = math.random() * math.pi * 2
		bolt(h, h + Vector3.new(math.cos(a), math.sin(a), 0) * 5, if math.random() < 0.5 then BLACK else C(230, 20, 40), 0.3)
	end
	floatText(h + Vector3.new(0, 2, 0), "黒閃", C(255, 50, 60), 30)
end
Moves["Partir"] = function(m, color, f, at)
	-- Cleave: corte enorme en cruz
	slashArc(at + Vector3.new(f * 3, 1, 0), f, WHITE, 7, 110, -70, 0.9, C(255, 40, 40))
	task.delay(0.08, slashArc, at + Vector3.new(f * 3, 1, 0), -f, WHITE, 7, 110, -70, 0.9, C(255, 40, 40))
end
Moves["Ascenso del Rey"] = function(m, color, f, at)
	column(at, C(200, 20, 20), 14, 4)
	fireBurst(at, C(255, 160, 120), C(150, 0, 0), 20, 2)
end
Moves["Nue: Picado"] = function(m, color, f, at)
	afterimages(m, C(255, 240, 150), 0.3)
	for _ = 1, 4 do
		bolt(at, at + Vector3.new(math.random(-4, 4), math.random(-4, 4), 0), C(255, 250, 180), 0.2)
	end
end
Moves["Nue: Ascenso"] = function(m, color, f, at)
	-- alas de Nue + electricidad
	for _, side in { -1, 1 } do
		local wing = part({ Size = Vector3.new(4, 0.2, 1.5), CFrame = CFrame.new(at + Vector3.new(side * 2.5, 1, 0)) * CFrame.Angles(0, 0, math.rad(side * 20)), Color = C(240, 240, 255), Transparency = 0.2 })
		fade(wing, 0.4)
	end
	POSE_FX.Rise(m, C(255, 250, 180), f, at)
end
Moves["Mar de Sombras"] = function(m, color, f, at)
	local ground = at - Vector3.new(0, 2.9, 0)
	local pool = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 2, 2), CFrame = CFrame.new(ground) * CFrame.Angles(0, 0, math.rad(90)), Color = C(5, 5, 12), Material = Enum.Material.Glass })
	TweenService:Create(pool, TweenInfo.new(0.2), { Size = Vector3.new(0.2, 18, 18) }):Play()
	task.delay(0.3, fade, pool, 0.4)
	for i = 1, 6 do
		local base = ground + Vector3.new((i - 3.5) * 2.5, 0, 0)
		local spike = part({ Size = Vector3.new(0.7, 0.5, 0.7), CFrame = CFrame.new(base), Color = C(15, 10, 25) })
		task.delay(0.1 + i * 0.02, function()
			TweenService:Create(spike, TweenInfo.new(0.1), { Size = Vector3.new(0.7, 6, 0.7), CFrame = CFrame.new(base + Vector3.new(0, 3, 0)) }):Play()
			task.delay(0.2, fade, spike, 0.3)
		end)
	end
end
Moves["Paso Infinito"] = function(m, color, f, at)
	local r = ball(3, C(120, 190, 255), { Position = at, Material = Enum.Material.ForceField })
	fade(r, 0.35, { Size = Vector3.one * 9 })
	afterimages(m, C(150, 210, 255), 0.25)
end
Moves["Ratio 7:3"] = function(m, color, f, at)
	local center = at + Vector3.new(f * 3.5, 0, 0)
	local line = part({ Size = Vector3.new(0.15, 7, 0.15), Position = center, Color = C(255, 220, 120) })
	fade(line, 0.35)
	local mark = part({ Size = Vector3.new(2.4, 0.2, 0.2), Position = center + Vector3.new(0, 7 * 0.2, 0), Color = C(255, 240, 180) })
	fade(mark, 0.35)
	floatText(center + Vector3.new(0, 3, 0), "7:3", C(255, 220, 120), 26)
	task.delay(0.15, POSE_FX.Slash, m, color, f, at)
end
Moves["Horas Extra"] = function(m, color, f, at)
	afterimages(m, C(240, 210, 130), 0.3)
end
Moves["Colapso"] = function(m, color, f, at)
	task.delay(0.15, groundShock, at, C(220, 200, 140), 20)
end
Moves["Lluvia de Clones"] = function(m, color, f, at)
	for i = -2, 2 do
		smokePuff(at + Vector3.new(i * 2.5, 3, 0), WHITE, 6, 1.2)
	end
	task.delay(0.2, groundShock, at, color, 14)
end
Moves["Doble o Nada"] = function(m, color, f, at)
	floatText(at + Vector3.new(0, 4, 0), "x2", C(120, 255, 140), 30)
	POSE_FX.Jab(m, C(120, 255, 140), f, at)
end
Moves["¡JACKPOT!"] = function(m, color, f, at)
	floatText(at + Vector3.new(0, 4, 0), "7 7 7", C(255, 225, 60), 34)
	sparks(at, C(255, 225, 60), 30, 40)
	task.delay(0.15, groundShock, at, C(120, 255, 140), 16)
end
Moves["Pistola Elástica"] = function(m, color, f, at)
	-- el brazo se estira como goma
	local shoulder = at + Vector3.new(f * 0.8, 0.6, 0)
	local arm = part({ Size = Vector3.new(0.9, 0.9, 1), CFrame = CFrame.lookAt(shoulder, shoulder + Vector3.new(f, 0, 0)), Color = C(235, 200, 165), Material = Enum.Material.SmoothPlastic })
	local fist = ball(1.4, C(235, 200, 165), { Position = shoulder, Material = Enum.Material.SmoothPlastic })
	local reach = 9
	TweenService:Create(arm, TweenInfo.new(0.1), { Size = Vector3.new(0.9, 0.9, reach), CFrame = CFrame.lookAt(shoulder + Vector3.new(f * reach / 2, 0, 0), shoulder + Vector3.new(f * reach, 0, 0)) }):Play()
	TweenService:Create(fist, TweenInfo.new(0.1), { Position = shoulder + Vector3.new(f * reach, 0, 0) }):Play()
	task.delay(0.12, function()
		ring(shoulder + Vector3.new(f * reach, 0, 0), WHITE, 6, 0.25)
		TweenService:Create(arm, TweenInfo.new(0.12), { Size = Vector3.new(0.9, 0.9, 1), CFrame = CFrame.lookAt(shoulder, shoulder + Vector3.new(f, 0, 0)) }):Play()
		TweenService:Create(fist, TweenInfo.new(0.12), { Position = shoulder }):Play()
		Debris:AddItem(arm, 0.15)
		Debris:AddItem(fist, 0.15)
	end)
end
Moves["Bazuca Elástica"] = function(m, color, f, at)
	Moves["Pistola Elástica"](m, color, f, at + Vector3.new(0, 0.8, 0))
	Moves["Pistola Elástica"](m, color, f, at - Vector3.new(0, 0.6, 0))
	task.delay(0.12, ring, at + Vector3.new(f * 9, 0, 0), C(255, 240, 200), 12, 0.35)
end
Moves["Martillo Elástico"] = function(m, color, f, at)
	task.delay(0.2, groundShock, at + Vector3.new(f * 3, 0, 0), C(255, 220, 200), 16)
end
Moves["Cohete Elástico"] = function(m, color, f, at)
	POSE_FX.Rise(m, WHITE, f, at)
end
local function water(m, f, at, radius: number)
	local blue = C(60, 160, 255)
	slashArc(at, f, blue, radius, 0, 360, 0.7, C(200, 235, 255))
	burstAt(at, 25, { Texture = TEX_SPARK, Color = ColorSequence.new(C(200, 235, 255), blue), Size = NumberSequence.new(0.7, 0),
		Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(8, 18), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -30, 0) })
end
Moves["Rueda de Agua"] = function(m, color, f, at)
	water(m, f, at + Vector3.new(f * 2, 0, 0), 4)
end
Moves["Flujo Torrencial"] = function(m, color, f, at)
	afterimages(m, C(120, 190, 255), 0.3)
	slashArc(at + Vector3.new(f * 2, 0, 0), f, C(60, 160, 255), 5, 60, -60, 0.6, C(200, 235, 255))
end
Moves["Cascada Ascendente"] = function(m, color, f, at)
	column(at, C(80, 170, 255), 12, 3, Enum.Material.Glass)
end
Moves["Danza del Dios del Fuego"] = function(m, color, f, at)
	slashArc(at + Vector3.new(f * 1.5, 0, 0), f, C(255, 120, 30), 5, 120, -120, 0.8, C(255, 230, 150))
	fireBurst(at + Vector3.new(f * 3, 0, 0), C(255, 230, 150), C(255, 70, 0), 25, 2)
end
Moves["Lanza Maldita"] = function(m, color, f, at)
	POSE_FX.Thrust(m, C(150, 255, 170), f, at)
end
Moves["Carga Imparable"] = function(m, color, f, at)
	afterimages(m, C(90, 230, 140), 0.35)
end
Moves["Barrido Giratorio"] = function(m, color, f, at)
	slashArc(at - Vector3.new(0, 1.5, 0), 1, C(150, 255, 170), 5, 0, 360, 0.4)
end
Moves["Cadena Infinita"] = function(m, color, f, at)
	-- cadena que se estira hacia delante
	local from = at + Vector3.new(f, 0.4, 0)
	for i = 1, 10 do
		local link = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.15, 0.6, 0.6), CFrame = CFrame.new(from + Vector3.new(f * i * 0.9, 0, 0)) * CFrame.Angles(i % 2 * math.rad(90), math.rad(90), 0),
			Color = C(170, 170, 180), Material = Enum.Material.Metal, Transparency = 1 })
		task.delay(i * 0.012, function()
			link.Transparency = 0
			task.delay(0.25, fade, link, 0.2)
		end)
	end
end
Moves["Asalto Invisible"] = function(m, color, f, at)
	afterimages(m, C(120, 120, 130), 0.3, 0.04)
end
Moves["Caída del Cazador"] = function(m, color, f, at)
	task.delay(0.15, groundShock, at, C(120, 120, 130), 16)
end
Moves["Erupción"] = function(m, color, f, at)
	for i = -1, 1 do
		task.delay(0.1 + (i + 1) * 0.05, column, at + Vector3.new(i * 4, 0, 0), C(255, 110, 20), 10, 3)
	end
	fireBurst(at, C(255, 220, 120), C(255, 60, 0), 30, 2.5)
end
Moves["Géiser"] = function(m, color, f, at)
	column(at, C(255, 140, 40), 14, 3.5)
	smokePuff(at - Vector3.new(0, 2.5, 0), C(80, 60, 50), 10, 1.5)
end
Moves["Meteoro de Sangre"] = function(m, color, f, at)
	task.delay(0.15, function()
		groundShock(at, C(200, 0, 30), 16)
		IMPACT.BloodBeam(at, 4)
	end)
end
Moves["Impulso Carmesí"] = function(m, color, f, at)
	POSE_FX.Rise(m, C(220, 20, 40), f, at)
end
Moves["Transfiguración: Brazo Largo"] = function(m, color, f, at)
	local shoulder = at + Vector3.new(f * 0.8, 0.6, 0)
	local arm = part({ Size = Vector3.new(1.4, 1.4, 1), CFrame = CFrame.lookAt(shoulder, shoulder + Vector3.new(f, 0, 0)), Color = C(160, 180, 200), Material = Enum.Material.SmoothPlastic })
	TweenService:Create(arm, TweenInfo.new(0.12), { Size = Vector3.new(1.6, 1.6, 10), CFrame = CFrame.lookAt(shoulder + Vector3.new(f * 5, 0, 0), shoulder + Vector3.new(f * 10, 0, 0)) }):Play()
	task.delay(0.25, fade, arm, 0.25)
end
Moves["Púas del Alma"] = function(m, color, f, at)
	local ground = at - Vector3.new(0, 2.9, 0)
	for i = -3, 3 do
		local base = ground + Vector3.new(i * 1.8, 0, 0)
		local spike = part({ Size = Vector3.new(0.6, 0.5, 0.6), CFrame = CFrame.new(base), Color = C(170, 190, 215), Material = Enum.Material.SmoothPlastic })
		task.delay(0.12, function()
			TweenService:Create(spike, TweenInfo.new(0.1), { Size = Vector3.new(0.6, 5, 0.6), CFrame = CFrame.new(base + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(i * 8)) }):Play()
			task.delay(0.25, fade, spike, 0.3)
		end)
	end
end
Moves["Alas Remodeladas"] = function(m, color, f, at)
	Moves["Nue: Ascenso"](m, C(170, 190, 215), f, at)
end
Moves["Estocada Relámpago"] = function(m, color, f, at)
	afterimages(m, C(200, 160, 255), 0.25)
	POSE_FX.Thrust(m, C(200, 160, 255), f, at)
end
Moves["Ogro Cortador"] = function(m, color, f, at)
	afterimages(m, C(120, 230, 150), 0.25)
	slashArc(at + Vector3.new(f * 2, 0.5, 0), f, C(150, 255, 170), 5, 40, -40, 0.7, WHITE)
end
Moves["Tornado de Tres Espadas"] = function(m, color, f, at)
	for i = 0, 3 do
		task.delay(i * 0.06, slashArc, at + Vector3.new(0, -1 + i * 1.2, 0), 1, C(150, 255, 170), 4 + i * 0.5, i * 90, i * 90 + 360, 0.35)
	end
end
Moves["Corte del Dragón"] = function(m, color, f, at)
	slashArc(at, f, C(150, 255, 170), 4, -90, 270, 0.4, WHITE)
	POSE_FX.Rise(m, C(150, 255, 170), f, at)
end
Moves["Torbellino de Dagas"] = function(m, color, f, at)
	for i = 0, 2 do
		task.delay(i * 0.07, slashArc, at, 1, C(230, 210, 150), 4 + i, i * 120, i * 120 + 360, 0.3)
	end
end
Moves["Estocada Vikinga"] = function(m, color, f, at)
	POSE_FX.Thrust(m, C(230, 210, 150), f, at)
end
Moves["Embestida Dorada"] = function(m, color, f, at)
	afterimages(m, C(255, 215, 60), 0.35)
end
Moves["Puño del Dragón"] = function(m, color, f, at)
	-- dragón dorado que sube enroscándose
	for i = 0, 10 do
		task.delay(i * 0.02, function()
			local a = i * 0.9
			local p = at + Vector3.new(math.cos(a) * 2, i * 1.1, math.sin(a))
			fade(ball(1.3 - i * 0.06, C(255, 215, 60), { Position = p }), 0.4)
		end)
	end
end
Moves["Teletransporte"] = function(m, color, f, at)
	fade(ball(1, WHITE, { Position = at }), 0.2, { Size = Vector3.one * 6 })
	floatText(at + Vector3.new(0, 3, 0), "¡ZAS!", WHITE, 24)
end
Moves["Tren de Mercancías"] = function(m, color, f, at)
	afterimages(m, C(220, 170, 110), 0.35)
end
Moves["Resonancia"] = function(m, color, f, at)
	-- muñeco de paja + clavo + onda de resonancia
	local doll = part({ Size = Vector3.new(1.2, 2, 0.6), Position = at + Vector3.new(f * 2.5, 0.5, 0), Color = C(200, 170, 100), Material = Enum.Material.Fabric })
	task.delay(0.4, fade, doll, 0.2)
	task.delay(0.15, function()
		ring(at + Vector3.new(f * 3, 0.5, 0), C(255, 140, 60), 14, 0.4)
		floatText(at + Vector3.new(f * 3, 3, 0), "共鳴り", C(255, 160, 80), 28)
	end)
end
Moves["Martillazo Ascendente"] = function(m, color, f, at)
	slashArc(at, f, C(255, 150, 60), 4, -60, 120, 0.5)
end
Moves["Embestida"] = function(m, color, f, at)
	afterimages(m, color, 0.3)
end
Moves["Mordisco"] = function(m, color, f, at)
	local center = at + Vector3.new(f * 2.5, 0.5, 0)
	for _, s in { 1, -1 } do
		local jaw = part({ Size = Vector3.new(2, 0.4, 1), Position = center + Vector3.new(0, s * 1.2, 0), Color = C(230, 220, 200), Material = Enum.Material.SmoothPlastic })
		TweenService:Create(jaw, TweenInfo.new(0.08), { Position = center }):Play()
		task.delay(0.12, fade, jaw, 0.2)
	end
end

-- Aura maldita al empezar cualquier técnica especial
local function castAura(m: Model, color: Color3)
	local torso = m:FindFirstChild("Torso") :: BasePart?
	local hrp = m:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not torso or not hrp then
		return
	end
	local fl = emitter(torso, { Texture = TEX_FIRE, Color = ColorSequence.new(color:Lerp(WHITE, 0.25), color:Lerp(BLACK, 0.5)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.8), NumberSequenceKeypoint.new(1, 0.2) }), Transparency = NumberSequence.new(0.15, 1),
		Lifetime = NumberRange.new(0.35, 0.6), Rate = 90, Speed = NumberRange.new(2, 5), Acceleration = Vector3.new(0, 14, 0),
		SpreadAngle = Vector2.new(30, 30), EmissionDirection = Enum.NormalId.Top, RotSpeed = NumberRange.new(-150, 150), Rotation = NumberRange.new(0, 360) })
	local sm = emitter(torso, { Texture = TEX_SMOKE, LightEmission = 0, Color = ColorSequence.new(C(12, 6, 18)), Size = NumberSequence.new(1.5, 3.5),
		Transparency = NumberSequence.new(0.5, 1), Lifetime = NumberRange.new(0.4, 0.7), Rate = 30, Speed = NumberRange.new(1, 3), Acceleration = Vector3.new(0, 6, 0) })
	task.delay(0.5, function()
		fl.Enabled = false
		sm.Enabled = false
		Debris:AddItem(fl, 1)
		Debris:AddItem(sm, 1)
	end)
	ring(hrp.Position - Vector3.new(0, 2.9, 0), color, 14, 0.4, true)
end

-- Se llama con cada "MoveStarted" de una técnica especial
function SpecialFX.Move(model: Model, move, color: Color3, facing: number)
	local at = rootPos(model)
	if not at or not move then
		return
	end
	castAura(model, color)
	local f = if facing and facing ~= 0 then facing else 1
	local handler = Moves[move.Name or ""] or (not move.Projectile and POSE_FX[move.Pose or ""]) or nil
	if handler then
		-- el efecto llega en el momento del golpe (tras el arranque del movimiento)
		task.delay(math.clamp(move.Startup or 0, 0, 0.5), function()
			local now = rootPos(model) or at
			local ok, err = pcall(handler, model, color, f, now)
			if not ok then
				warn("[SpecialFX]", move.Name, err)
			end
		end)
	end
end

function SpecialFX.Start(fx: Folder)
	folder = fx
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for id, p in active do
			local t = now - p.Born
			if t > p.Life + 0.35 then
				stopProjectile(id, nil, true)
			else
				local pos = p.Start + Vector3.new(p.Facing * p.Speed * math.min(t, p.Life), 0, 0)
				p.Last = pos
				local ok = pcall(p.Update, pos, t)
				if not ok then
					stopProjectile(id, nil, false)
				end
			end
		end
	end)
end

return SpecialFX
