-- ObbyBuilder: la OBBY "Ascenso Maldito", un recorrido de parkour flotante sobre el vacío.
-- Se entra por el portal del Lobby. 5 secciones con 4 checkpoints:
--   1. Puente de Talismanes  · plataformas de madera con talismanes
--   2. Mar de Lava Maldita   · piedras sobre lava (tocarla = volver al checkpoint), plataformas que se mueven
--   3. Molinos Malditos      · barras giratorias que te tiran
--   4. Escalera al Cielo     · subida en espiral con trampolines
--   5. Velo Final            · plataformas que aparecen y desaparecen + santuario de meta
-- Los obstáculos que se mueven los anima el cliente (ObbyController) para que sean suaves y te lleven encima.
-- Etiquetas (CollectionService): ObbyCheckpoint (Index), ObbyKill, ObbyMover (Offset, Period),
-- ObbySpinner (Speed), ObbyFade (Offset, On, Off), ObbyBounce (Power), ObbyFinish, ObbyStart.
local CollectionService = game:GetService("CollectionService")

local ObbyBuilder = {}

local C = Color3.fromRGB
local M = Enum.Material

ObbyBuilder.Checkpoints = 4

function ObbyBuilder.Build(origin: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Obby"

	local function part(props): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Material = M.SmoothPlastic
		for k, v in props do
			(p :: any)[k] = v
		end
		if p.Position ~= nil and props.CFrame == nil and props.Position ~= nil then
			p.Position = origin + props.Position
		elseif props.CFrame ~= nil then
			p.CFrame = CFrame.new(origin) * props.CFrame
		end
		p.Parent = model
		return p
	end
	local function tag(p: Instance, name: string, attrs)
		CollectionService:AddTag(p, name)
		for k, v in attrs or {} do
			p:SetAttribute(k, v)
		end
		return p
	end
	local function sign(pos: Vector3, text: string, color: Color3, size: number)
		local anchor = part({ Size = Vector3.one, Position = pos, Transparency = 1, CanCollide = false, CanQuery = false })
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromScale(size, size / 6)
		gui.LightInfluence = 0
		gui.MaxDistance = 260
		gui.Parent = anchor
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.PermanentMarker
		label.TextScaled = true
		label.TextColor3 = color
		label.TextStrokeTransparency = 0.1
		label.Text = text
		label.Parent = gui
	end
	local function torii(pos: Vector3, width: number, height: number, color: Color3)
		for _, side in { -1, 1 } do
			part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(height, 1.4, 1.4), CFrame = CFrame.new(pos + Vector3.new(0, height / 2, side * width / 2)) * CFrame.Angles(0, 0, math.rad(90)), Color = color })
		end
		part({ Size = Vector3.new(2, 1.4, width + 5), Position = pos + Vector3.new(0, height + 0.7, 0), Color = C(30, 25, 25) })
		part({ Size = Vector3.new(1.4, 0.9, width + 2.5), Position = pos + Vector3.new(0, height - 0.6, 0), Color = color })
		part({ Size = Vector3.new(1, 0.7, width), Position = pos + Vector3.new(0, height - 3.5, 0), Color = color })
	end
	local function lanternAt(pos: Vector3)
		part({ Size = Vector3.new(1.2, 2.6, 1.2), Position = pos + Vector3.new(0, 1.3, 0), Color = C(150, 145, 140), Material = M.Slate })
		local l = part({ Size = Vector3.new(1.8, 1.2, 1.8), Position = pos + Vector3.new(0, 3.2, 0), Color = C(255, 200, 120), Material = M.Neon, CanCollide = false })
		local pl = Instance.new("PointLight")
		pl.Color = C(255, 190, 120)
		pl.Range = 14
		pl.Brightness = 1.4
		pl.Parent = l
	end
	-- Plataforma flotante con borde de color (se lee bien dónde acaba)
	-- bare = sin borde ni raíces (para las que se mueven o desaparecen: las piezas extra se quedarían atrás)
	local function plat(pos: Vector3, size: Vector3, color: Color3, material: Enum.Material?, trim: Color3?, bare: boolean?)
		local p = part({ Size = size, Position = pos, Color = color, Material = material or M.Slate })
		if bare then
			return p
		end
		if trim then
			part({ Size = Vector3.new(size.X + 0.3, 0.3, size.Z + 0.3), Position = pos + Vector3.new(0, size.Y / 2 - 0.1, 0), Color = trim, Material = M.Neon, CanCollide = false })
		end
		-- raíces de roca colgando (que se vea que flota)
		part({ Size = Vector3.new(size.X * 0.6, size.Y * 2, size.Z * 0.6), Position = pos - Vector3.new(0, size.Y * 1.4, 0), Color = C(60, 55, 60), Material = M.Rock, CanCollide = false })
		return p
	end
	local function checkpoint(pos: Vector3, index: number, title: string, color: Color3)
		plat(pos, Vector3.new(16, 2, 16), C(70, 60, 80), M.Slate, color)
		torii(pos + Vector3.new(-6, 1, 0), 10, 11, color)
		local pad = part({
			Name = `Checkpoint{index}`, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 9, 9),
			CFrame = CFrame.new(pos + Vector3.new(1, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = M.Neon,
			Transparency = 0.3, CanCollide = false,
		})
		tag(pad, "ObbyCheckpoint", { Index = index })
		local fx = Instance.new("ParticleEmitter")
		fx.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		fx.Color = ColorSequence.new(color)
		fx.LightEmission = 1
		fx.Size = NumberSequence.new(0.8, 0)
		fx.Lifetime = NumberRange.new(0.8, 1.4)
		fx.Rate = 18
		fx.Speed = NumberRange.new(2, 4)
		fx.EmissionDirection = Enum.NormalId.Right -- el cilindro está tumbado: "Right" apunta hacia arriba
		fx.Parent = pad
		sign(pos + Vector3.new(0, 15, 0), title, color, 20)
		lanternAt(pos + Vector3.new(5, 1, -6))
		lanternAt(pos + Vector3.new(5, 1, 6))
	end

	-- ===== Salida
	local startPlat = plat(Vector3.new(0, 0, 0), Vector3.new(30, 2, 30), C(80, 70, 90), M.Slate, C(200, 120, 255))
	startPlat.Name = "ObbyStartPlatform"
	local spawn = part({ Name = "ObbyStart", Size = Vector3.new(6, 0.3, 6), Position = Vector3.new(-6, 1.2, 0), Color = C(200, 160, 255), Material = M.Neon, Transparency = 0.5, CanCollide = false })
	tag(spawn, "ObbyStart")
	torii(Vector3.new(10, 1, 0), 12, 14, C(200, 40, 50))
	sign(Vector3.new(0, 22, 0), "OBBY · ASCENSO MALDITO", C(255, 210, 120), 34)
	sign(Vector3.new(0, 17, 0), "Si te caes, vuelves al último checkpoint", C(230, 220, 255), 18)
	for _, z in { -12, 12 } do
		lanternAt(Vector3.new(-12, 1, z))
	end
	-- Portal de vuelta al Lobby
	local back = part({ Name = "ObbyExit", Size = Vector3.new(0.6, 10, 8), Position = Vector3.new(-14.5, 6, 0), Color = C(255, 190, 40), Material = M.Neon, Transparency = 0.35, CanCollide = false })
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Volver"
	pp.ObjectText = "Lobby"
	pp.MaxActivationDistance = 10
	pp.HoldDuration = 0
	pp.RequiresLineOfSight = false
	pp:SetAttribute("Action", "LeaveObby")
	pp.Parent = back

	-- ===== 1. Puente de Talismanes (madera con talismanes, va subiendo y zigzaguea)
	local x, y, z = 22, 0, 0
	for i = 1, 9 do
		x += 9
		y += if i % 3 == 0 then 3 else 1
		z = if i % 2 == 0 then 4 else -4
		local p = plat(Vector3.new(x, y, z), Vector3.new(6, 1.2, 6), C(120, 80, 55), M.WoodPlanks, C(255, 210, 120))
		-- talismán pegado encima
		part({ Size = Vector3.new(1.2, 0.1, 2.4), CFrame = CFrame.new(p.Position - origin + Vector3.new(0, 0.66, 0)) * CFrame.Angles(0, math.rad(i * 20), 0), Color = C(250, 238, 215), CanCollide = false })
	end
	x += 12
	checkpoint(Vector3.new(x, y, 0), 1, "CHECKPOINT 1 · PUENTE DE TALISMANES", C(255, 210, 120))

	-- ===== 2. Mar de Lava Maldita
	local lavaY = y - 8
	local lavaStart = x + 8
	local lava = part({ Name = "Lava", Size = Vector3.new(130, 1, 50), Position = Vector3.new(lavaStart + 65, lavaY, 0), Color = C(255, 80, 20), Material = M.Neon, Transparency = 0.1 })
	tag(lava, "ObbyKill")
	local glow = Instance.new("ParticleEmitter")
	glow.Texture = "rbxasset://textures/particles/fire_main.dds"
	glow.Color = ColorSequence.new(C(255, 220, 120), C(255, 60, 0))
	glow.LightEmission = 1
	glow.Size = NumberSequence.new(2, 0)
	glow.Lifetime = NumberRange.new(0.5, 1)
	glow.Rate = 60
	glow.Speed = NumberRange.new(3, 8)
	glow.EmissionDirection = Enum.NormalId.Top
	glow.Parent = lava
	x = lavaStart
	local layout = {
		{ "stone", 6 }, { "stone", 8 }, { "mover", 10 }, { "stone", 9 }, { "beam", 14 }, { "stone", 9 },
		{ "mover", 11 }, { "stone", 9 }, { "stone", 8 }, { "beam", 14 }, { "stone", 9 },
	}
	for i, item in layout do
		x += item[2]
		if item[1] == "stone" then
			plat(Vector3.new(x, y, (i % 3 - 1) * 4), Vector3.new(5, 1.4, 5), C(50, 40, 40), M.Basalt, C(255, 120, 40))
		elseif item[1] == "beam" then
			plat(Vector3.new(x - 4, y, 0), Vector3.new(14, 1.2, 2), C(60, 45, 45), M.Basalt, C(255, 120, 40))
			x += 4
		else
			local mover = plat(Vector3.new(x, y, 0), Vector3.new(6, 1.2, 6), C(150, 90, 230), M.Neon, nil, true)
			tag(mover, "ObbyMover", { Offset = Vector3.new(0, 0, 12), Period = 3.2, Origin = mover.CFrame })
		end
	end
	x += 12
	checkpoint(Vector3.new(x, y, 0), 2, "CHECKPOINT 2 · MAR DE LAVA", C(255, 120, 40))

	-- ===== 3. Molinos Malditos: pasarela con barras que giran (te tiran al vacío)
	x += 14
	local walkway = plat(Vector3.new(x + 30, y, 0), Vector3.new(66, 2, 10), C(70, 60, 85), M.Slate, C(150, 70, 230))
	walkway.Name = "Walkway"
	for i = 0, 2 do
		local cx = x + 12 + i * 20
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 2.4, 2.4), CFrame = CFrame.new(cx, y + 2.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = C(40, 30, 50) })
		local bar = part({ Name = "Spinner", Size = Vector3.new(1.2, 1.2, 15), Position = Vector3.new(cx, y + 2.3, 0), Color = C(200, 40, 60), Material = M.Neon })
		tag(bar, "ObbyKill")
		tag(bar, "ObbySpinner", { Speed = (if i % 2 == 0 then 1 else -1) * (1.6 + i * 0.4), Origin = bar.CFrame })
	end
	x += 66
	-- pilares para saltar
	for i = 1, 4 do
		x += 8
		plat(Vector3.new(x, y + i * 1.5, if i % 2 == 0 then 3 else -3), Vector3.new(4, 1.2, 4), C(80, 70, 95), M.Marble, C(150, 70, 230))
	end
	y += 6
	x += 12
	checkpoint(Vector3.new(x, y, 0), 3, "CHECKPOINT 3 · MOLINOS MALDITOS", C(170, 90, 255))

	-- ===== 4. Escalera al Cielo: espiral alrededor de una torre + trampolines
	local towerX = x + 22
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(70, 10, 10), CFrame = CFrame.new(towerX, y + 30, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = C(60, 50, 70), Material = M.Slate })
	local stepY = y
	for i = 1, 12 do
		local a = i * 0.75
		stepY += 3.2
		local pos = Vector3.new(towerX + math.cos(a) * 12, stepY, math.sin(a) * 12)
		if i == 5 or i == 10 then
			local pad = plat(pos, Vector3.new(6, 1.2, 6), C(60, 200, 255), M.Neon, nil, true)
			tag(pad, "ObbyBounce", { Power = 95 })
			stepY += 8
		else
			plat(pos, Vector3.new(5.5, 1.2, 5.5), C(110, 100, 130), M.Marble, C(120, 200, 255))
		end
	end
	y = stepY + 2
	x = towerX + 22
	checkpoint(Vector3.new(x, y, 0), 4, "CHECKPOINT 4 · ESCALERA AL CIELO", C(120, 200, 255))

	-- ===== 5. Velo Final: plataformas que aparecen y desaparecen
	for i = 1, 10 do
		x += 8
		local p = plat(Vector3.new(x, y + (i % 2), if i % 3 == 0 then 0 else (if i % 2 == 0 then 4 else -4)), Vector3.new(5, 1, 5), C(255, 80, 200), M.Neon, nil, true)
		tag(p, "ObbyFade", { Offset = i * 0.45, On = 2.2, Off = 1.2 })
	end
	x += 16
	-- ===== Meta
	plat(Vector3.new(x, y, 0), Vector3.new(26, 2, 26), C(90, 75, 50), M.Marble, C(255, 215, 80))
	torii(Vector3.new(x - 9, y + 1, 0), 14, 16, C(255, 200, 60))
	local chest = part({ Name = "ObbyChest", Size = Vector3.new(5, 3.5, 3.5), Position = Vector3.new(x + 6, y + 2.75, 0), Color = C(150, 90, 40), Material = M.Wood })
	part({ Size = Vector3.new(5.2, 0.6, 3.7), Position = Vector3.new(x + 6, y + 4.6, 0), Color = C(255, 210, 70), Material = M.Neon, CanCollide = false })
	local finish = part({
		Name = "ObbyFinish", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 14, 14),
		CFrame = CFrame.new(x, y + 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = C(255, 215, 80), Material = M.Neon, Transparency = 0.25, CanCollide = false,
	})
	tag(finish, "ObbyFinish")
	local light = Instance.new("PointLight")
	light.Color = C(255, 215, 80)
	light.Range = 30
	light.Brightness = 3
	light.Parent = chest
	sign(Vector3.new(x, y + 22, 0), "¡META! · 完", C(255, 215, 80), 30)
	for _, zz in { -10, 10 } do
		lanternAt(Vector3.new(x + 9, y + 1, zz))
	end

	model:SetAttribute("BaseY", origin.Y - 30) -- por debajo = caída -> último checkpoint
	model:SetAttribute("Checkpoints", ObbyBuilder.Checkpoints)
	return model
end

return ObbyBuilder
