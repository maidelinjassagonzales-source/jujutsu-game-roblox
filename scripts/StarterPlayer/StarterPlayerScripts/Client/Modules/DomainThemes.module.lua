-- DomainThemes: el aspecto PROPIO de cada Expansión de Dominio y de cada transformación.
--   Build(theme, ctx)  -> escenario del dominio (aparece del suelo y se va al terminar)
--   Tick(theme, ...)   -> efecto de cada golpe del dominio sobre la víctima
--   Aura(theme, ...)   -> aura de las transformaciones (Super Saiyan, Gear 5, Modo Kurama...)
--   Burst(theme, ...)  -> preparación de las técnicas definitivas (Púrpura Hueco, Asura)
-- Todo es local (solo en el cliente) y se hace con piezas básicas + texturas que trae Roblox.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local DomainThemes = {}

local TEX_FIRE = "rbxasset://textures/particles/fire_main.dds"
local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)

local folder: Folder

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = folder
	return p
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

local function fadeOut(p: BasePart, t: number)
	TweenService:Create(p, TweenInfo.new(t), { Transparency = 1 }):Play()
	Debris:AddItem(p, t + 0.05)
end

-- Sale del suelo con un rebote y se va al acabar el dominio
local function rise(p: BasePart, duration: number, delayIn: number?)
	local final = p.CFrame
	local finalT = p.Transparency
	p.CFrame = final - Vector3.new(0, p.Size.Y + 2, 0)
	p.Transparency = 1
	task.delay(delayIn or 0, function()
		TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Back), { CFrame = final, Transparency = finalT }):Play()
	end)
	task.delay(duration, fadeOut, p, 0.5)
end

local function floatText(position: Vector3, text: string, color: Color3, size: number, life: number?)
	local anchor = part({ Size = Vector3.one, Position = position, Transparency = 1 })
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(320, 90)
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
	life = life or 0.9
	TweenService:Create(anchor, TweenInfo.new(life), { Position = position + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(l, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, life + 0.1)
end

local function bolt(from: Vector3, to: Vector3, color: Color3, width: number?)
	-- rayo en zigzag (3 tramos)
	local points = { from }
	for i = 1, 2 do
		local p = from:Lerp(to, i / 3) + Vector3.new(math.random(-15, 15) / 10, math.random(-15, 15) / 10, 0)
		table.insert(points, p)
	end
	table.insert(points, to)
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local seg = part({
			Size = Vector3.new(width or 0.3, width or 0.3, (b - a).Magnitude), CFrame = CFrame.lookAt((a + b) / 2, b),
			Color = color, Material = Enum.Material.Neon,
		})
		TweenService:Create(seg, TweenInfo.new(0.25), { Transparency = 1 }):Play()
		Debris:AddItem(seg, 0.3)
	end
end

local function slash(center: Vector3, color: Color3, length: number, width: number?)
	local angle = math.random() * math.pi
	local dir = Vector3.new(math.cos(angle), math.sin(angle), 0)
	local s = part({
		Size = Vector3.new(width or 0.25, width or 0.25, 0.5), CFrame = CFrame.lookAt(center, center + dir),
		Color = color, Material = Enum.Material.Neon,
	})
	TweenService:Create(s, TweenInfo.new(0.08), { Size = Vector3.new(width or 0.25, width or 0.25, length) }):Play()
	task.delay(0.1, fadeOut, s, 0.25)
end

local function ringAt(position: Vector3, color: Color3, size: number, t: number, flat: boolean?)
	local cf = if flat then CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)) else CFrame.new(position) * CFrame.Angles(0, math.rad(90), 0)
	local r = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, size * 0.2, size * 0.2), CFrame = cf, Color = color, Material = Enum.Material.Neon, Transparency = 0.1 })
	TweenService:Create(r, TweenInfo.new(t, Enum.EasingStyle.Quad), { Size = Vector3.new(0.05, size, size), Transparency = 1 }):Play()
	Debris:AddItem(r, t + 0.05)
end

local function rootOf(model: Instance?): BasePart?
	return model and model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") :: BasePart? or nil
end

-- ===================================================================
-- ESCENARIOS DE DOMINIO
-- ctx = { Center, Back (vector hacia el fondo), Ground (Y del suelo), Color, Duration }
-- ===================================================================
local Scenery = {}

-- Gojo · Vacío Infinito: espacio infinito, galaxia girando, cascada de información
function Scenery.Void(ctx)
	local c, back, dur = ctx.Center, ctx.Back, ctx.Duration
	local holder = part({ Size = Vector3.new(160, 90, 2), CFrame = CFrame.lookAt(c + back * 40, c), Transparency = 1 })
	emitter(holder, {
		Texture = TEX_SPARK, Color = ColorSequence.new(WHITE, Color3.fromRGB(150, 210, 255)), Size = NumberSequence.new(0.8, 0),
		Lifetime = NumberRange.new(1, 2.5), Rate = 400, Speed = NumberRange.new(0.5, 3), SpreadAngle = Vector2.new(180, 180),
	})
	-- Corriente de "información infinita": líneas de luz que pasan a toda velocidad
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < dur do
			local y = ctx.Ground + math.random(2, 50)
			local z = back * math.random(5, 35)
			local line = part({
				Size = Vector3.new(math.random(8, 30), 0.12, 0.12), Position = c + z + Vector3.new(-90, y - c.Y, 0),
				Color = if math.random() < 0.5 then WHITE else Color3.fromRGB(140, 200, 255), Material = Enum.Material.Neon,
			})
			TweenService:Create(line, TweenInfo.new(0.5, Enum.EasingStyle.Linear), { Position = line.Position + Vector3.new(180, 0, 0) }):Play()
			Debris:AddItem(line, 0.55)
			task.wait(0.03)
		end
	end)
	-- Galaxia: anillos girando al fondo
	for i = 1, 3 do
		local ring = part({
			Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 30 + i * 22, 30 + i * 22),
			CFrame = CFrame.lookAt(c + back * (45 + i * 5) + Vector3.new(0, 15, 0), c) * CFrame.Angles(0, math.rad(90), 0),
			Color = Color3.fromRGB(120, 190, 255):Lerp(WHITE, i / 4), Material = Enum.Material.Neon, Transparency = 0.6,
		})
		task.spawn(function()
			local t0 = os.clock()
			local base = ring.CFrame
			while os.clock() - t0 < dur and ring.Parent do
				ring.CFrame = base * CFrame.Angles((os.clock() - t0) * (0.6 + i * 0.3), 0, 0)
				task.wait()
			end
		end)
		task.delay(dur, fadeOut, ring, 0.5)
	end
	task.delay(dur, function()
		holder:Destroy()
	end)
end

-- Sukuna · Santuario Malévolo: el santuario con boca y cuernos sobre un charco de sangre y cráneos
function Scenery.Shrine(ctx)
	local c, back, g, dur = ctx.Center, ctx.Back, ctx.Ground, ctx.Duration
	local base = c + back * 34
	local bone = Color3.fromRGB(230, 220, 200)
	local wood = Color3.fromRGB(70, 20, 20)
	-- charco de sangre
	rise(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 120, 120), CFrame = CFrame.new(c.X, g + 0.15, base.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(110, 0, 10), Material = Enum.Material.Glass, Transparency = 0.1 }), dur)
	-- pilares
	for _, x in { -12, -4, 4, 12 } do
		rise(part({ Size = Vector3.new(2.2, 26, 2.2), CFrame = CFrame.new(base.X + x, g + 13, base.Z), Color = wood }), dur, 0.1)
	end
	-- tejados (dos pisos) + cuernos
	rise(part({ Size = Vector3.new(36, 2, 12), CFrame = CFrame.new(base.X, g + 27, base.Z), Color = Color3.fromRGB(40, 10, 10) }), dur, 0.25)
	rise(part({ Size = Vector3.new(26, 2, 9), CFrame = CFrame.new(base.X, g + 33, base.Z), Color = Color3.fromRGB(40, 10, 10) }), dur, 0.35)
	for _, side in { -1, 1 } do
		rise(part({ Size = Vector3.new(1.4, 9, 1.4), CFrame = CFrame.new(base.X + side * 15, g + 32, base.Z) * CFrame.Angles(0, 0, math.rad(-side * 25)), Color = bone }), dur, 0.45)
	end
	-- boca con dientes
	rise(part({ Size = Vector3.new(16, 9, 1), CFrame = CFrame.new(base.X, g + 20, base.Z - back.Z * 1.2), Color = Color3.fromRGB(15, 0, 0), Material = Enum.Material.Neon, Transparency = 0.2 }), dur, 0.3)
	for i = -3, 3 do
		rise(part({ Size = Vector3.new(1.1, 2, 0.6), CFrame = CFrame.new(base.X + i * 2.1, g + 24, base.Z - back.Z * 1.6) * CFrame.Angles(0, 0, math.rad(180)), Color = bone }), dur, 0.4)
		rise(part({ Size = Vector3.new(1.1, 2, 0.6), CFrame = CFrame.new(base.X + i * 2.1, g + 16, base.Z - back.Z * 1.6), Color = bone }), dur, 0.4)
	end
	-- montones de cráneos
	for _ = 1, 26 do
		local x = math.random(-50, 50)
		rise(part({ Shape = Enum.PartType.Ball, Size = Vector3.one * math.random(14, 24) / 10, Position = Vector3.new(c.X + x, g + 0.8, base.Z + back.Z * math.random(-8, 10)), Color = bone }), dur, math.random() * 0.4)
	end
	-- cielo rojo con cortes por todas partes
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < dur do
			slash(c + back * math.random(5, 30) + Vector3.new(math.random(-50, 50), math.random(0, 35), 0), if math.random() < 0.5 then WHITE else Color3.fromRGB(255, 60, 60), math.random(8, 20), 0.15)
			task.wait(0.05)
		end
	end)
end

-- Megumi · Jardín de Sombras Quimera: suelo de sombra líquida y tentáculos negros
function Scenery.Shadow(ctx)
	local c, back, g, dur = ctx.Center, ctx.Back, ctx.Ground, ctx.Duration
	rise(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 140, 140), CFrame = CFrame.new(c.X, g + 0.15, c.Z + back.Z * 20) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(5, 5, 12), Material = Enum.Material.Glass, Transparency = 0 }), dur)
	for _ = 1, 22 do
		local h = math.random(8, 22)
		local p = part({ Size = Vector3.new(1.2, h, 1.2), CFrame = CFrame.new(c.X + math.random(-55, 55), g + h / 2, c.Z + back.Z * math.random(4, 30)) * CFrame.Angles(0, 0, math.rad(math.random(-15, 15))),
			Color = Color3.fromRGB(8, 6, 16), Material = Enum.Material.Neon, Transparency = 0.1 })
		rise(p, dur, math.random() * 0.6)
		emitter(p, { Texture = TEX_SMOKE, LightEmission = 0, Color = ColorSequence.new(Color3.fromRGB(20, 10, 35)), Size = NumberSequence.new(1.5, 3),
			Transparency = NumberSequence.new(0.4, 1), Lifetime = NumberRange.new(0.6, 1), Rate = 6, Speed = NumberRange.new(1, 2) })
	end
	-- ojos de shikigami en la oscuridad
	for _ = 1, 8 do
		local pos = c + back * math.random(15, 35) + Vector3.new(math.random(-45, 45), math.random(2, 18), 0)
		for _, dx in { -0.6, 0.6 } do
			rise(part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.6, Position = pos + Vector3.new(dx, 0, 0), Color = Color3.fromRGB(200, 220, 255), Material = Enum.Material.Neon }), dur, 0.5)
		end
	end
end

-- Mahito · Autoencarnación de la Perfección: manos gigantes por todas partes
local function hand(position: Vector3, scale: number, color: Color3, dur: number, delayIn: number)
	local rot = CFrame.Angles(0, 0, math.rad(math.random(-40, 40)))
	local palm = part({ Size = Vector3.new(2.4, 2.6, 0.8) * scale, CFrame = CFrame.new(position) * rot, Color = color })
	rise(palm, dur, delayIn)
	for i = 0, 3 do
		local f = part({ Size = Vector3.new(0.5, 2, 0.6) * scale, CFrame = palm.CFrame * CFrame.new((-0.9 + i * 0.6) * scale, 2.2 * scale, 0), Color = color })
		rise(f, dur, delayIn)
	end
	local thumb = part({ Size = Vector3.new(0.5, 1.6, 0.6) * scale, CFrame = palm.CFrame * CFrame.new(1.5 * scale, 0.4 * scale, 0) * CFrame.Angles(0, 0, math.rad(-40)), Color = color })
	rise(thumb, dur, delayIn)
end
function Scenery.Hands(ctx)
	local c, back, g, dur = ctx.Center, ctx.Back, ctx.Ground, ctx.Duration
	for _ = 1, 16 do
		hand(c + back * math.random(10, 35) + Vector3.new(math.random(-50, 50), g - c.Y + math.random(3, 25), 0), math.random(15, 35) / 10, Color3.fromRGB(150, 175, 200), dur, math.random() * 0.5)
	end
	rise(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 130, 130), CFrame = CFrame.new(c.X, g + 0.15, c.Z + back.Z * 20) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(70, 90, 110), Material = Enum.Material.Slate }), dur)
end

-- Jogo · Ataúd de la Montaña de Hierro: interior de un volcán con suelo de lava y erupciones
function Scenery.Volcano(ctx)
	local c, back, g, dur = ctx.Center, ctx.Back, ctx.Ground, ctx.Duration
	rise(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 140, 140), CFrame = CFrame.new(c.X, g + 0.2, c.Z + back.Z * 20) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 90, 10), Material = Enum.Material.Neon, Transparency = 0.15 }), dur)
	for i = 1, 5 do
		local r = 40 - i * 6
		rise(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(8, r, r), CFrame = CFrame.new(c.X, g + i * 7, c.Z + back.Z * 50) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(45, 25, 20), Material = Enum.Material.Basalt }), dur, i * 0.08)
	end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < dur do
			local p = part({ Size = Vector3.one, Position = c + back * math.random(5, 40) + Vector3.new(math.random(-55, 55), g - c.Y, 0), Transparency = 1 })
			local e = emitter(p, { Texture = TEX_FIRE, Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 60, 0)), Size = NumberSequence.new(4, 1),
				Transparency = NumberSequence.new(0.1, 1), Lifetime = NumberRange.new(0.6, 1), Speed = NumberRange.new(25, 40), SpreadAngle = Vector2.new(12, 12),
				EmissionDirection = Enum.NormalId.Top, Rate = 0, Acceleration = Vector3.new(0, -20, 0) })
			e:Emit(30)
			Debris:AddItem(p, 1.2)
			task.wait(0.25)
		end
	end)
end

-- Yuta · Amor Mutuo Auténtico: campo infinito de katanas clavadas y cruces
function Scenery.Swords(ctx)
	local c, back, g, dur = ctx.Center, ctx.Back, ctx.Ground, ctx.Duration
	rise(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 140, 140), CFrame = CFrame.new(c.X, g + 0.15, c.Z + back.Z * 20) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(60, 50, 80), Material = Enum.Material.Sand }), dur)
	for _ = 1, 40 do
		local pos = Vector3.new(c.X + math.random(-60, 60), g, c.Z + back.Z * math.random(3, 40))
		local tilt = CFrame.Angles(math.rad(math.random(-15, 15)), 0, math.rad(math.random(-15, 15)))
		local blade = part({ Size = Vector3.new(0.25, 5, 0.6), CFrame = CFrame.new(pos + Vector3.new(0, 2.5, 0)) * tilt, Color = Color3.fromRGB(220, 225, 240), Material = Enum.Material.Metal })
		local guard = part({ Size = Vector3.new(0.4, 0.25, 1.4), CFrame = blade.CFrame * CFrame.new(0, 2.6, 0), Color = Color3.fromRGB(40, 30, 20) })
		local handle = part({ Size = Vector3.new(0.35, 1.6, 0.4), CFrame = blade.CFrame * CFrame.new(0, 3.5, 0), Color = Color3.fromRGB(80, 30, 120) })
		local d = math.random() * 0.6
		rise(blade, dur, d)
		rise(guard, dur, d)
		rise(handle, dur, d)
	end
	for _ = 1, 5 do
		local pos = c + back * math.random(25, 40) + Vector3.new(math.random(-40, 40), g - c.Y, 0)
		rise(part({ Size = Vector3.new(1, 14, 1), Position = pos + Vector3.new(0, 7, 0), Color = Color3.fromRGB(230, 230, 245), Material = Enum.Material.Neon, Transparency = 0.3 }), dur, 0.3)
		rise(part({ Size = Vector3.new(7, 1, 1), Position = pos + Vector3.new(0, 10, 0), Color = Color3.fromRGB(230, 230, 245), Material = Enum.Material.Neon, Transparency = 0.3 }), dur, 0.3)
	end
end

-- Kenjaku · Útero Profuso: paisaje orgánico del que brotan espíritus malditos
function Scenery.Womb(ctx)
	local c, back, g, dur = ctx.Center, ctx.Back, ctx.Ground, ctx.Duration
	rise(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 140, 140), CFrame = CFrame.new(c.X, g + 0.15, c.Z + back.Z * 20) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(90, 45, 40), Material = Enum.Material.Pebble }), dur)
	for _ = 1, 14 do
		local s = math.random(30, 70) / 10
		local p = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * s, Position = c + back * math.random(8, 35) + Vector3.new(math.random(-50, 50), g - c.Y + s * 0.3, 0),
			Color = Color3.fromRGB(120, 60, 55), Material = Enum.Material.Pebble })
		rise(p, dur, math.random() * 0.5)
		emitter(p, { Texture = TEX_SMOKE, LightEmission = 0, Color = ColorSequence.new(Color3.fromRGB(30, 10, 25)), Size = NumberSequence.new(1, 4),
			Transparency = NumberSequence.new(0.3, 1), Lifetime = NumberRange.new(1, 1.6), Rate = 5, Speed = NumberRange.new(2, 4),
			EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(20, 20) })
	end
end

-- Hakari · Juego de Muerte Ociosa: escenario de pachinko con luces, bolas y el marcador
function Scenery.Pachinko(ctx)
	local c, back, g, dur = ctx.Center, ctx.Back, ctx.Ground, ctx.Duration
	local colors = { Color3.fromRGB(255, 60, 120), Color3.fromRGB(60, 220, 255), Color3.fromRGB(255, 220, 60), Color3.fromRGB(90, 255, 140) }
	local bars = {}
	for i = -6, 6 do
		local bar = part({ Size = Vector3.new(1.2, 40, 0.6), Position = c + back * 32 + Vector3.new(i * 9, g - c.Y + 20, 0), Color = colors[(i % 4) + 1], Material = Enum.Material.Neon, Transparency = 0.25 })
		rise(bar, dur, 0.05 * (i + 6))
		table.insert(bars, bar)
	end
	-- marcador con los tres números
	local board = part({ Size = Vector3.new(24, 9, 1), Position = c + back * 30 + Vector3.new(0, g - c.Y + 30, 0), Color = Color3.fromRGB(20, 10, 30), Material = Enum.Material.SmoothPlastic })
	rise(board, dur, 0.2)
	local sg = Instance.new("SurfaceGui")
	sg.Face = if back.Z < 0 then Enum.NormalId.Back else Enum.NormalId.Front
	sg.LightInfluence = 0
	sg.Parent = board
	local digits = Instance.new("TextLabel")
	digits.Size = UDim2.fromScale(1, 1)
	digits.BackgroundTransparency = 1
	digits.TextScaled = true
	digits.Font = Enum.Font.GothamBlack
	digits.TextColor3 = Color3.fromRGB(255, 230, 90)
	digits.Text = "7 7 7"
	digits.Parent = sg
	task.spawn(function()
		local t0 = os.clock()
		local k = 0
		while os.clock() - t0 < dur do
			k += 1
			for i, bar in bars do
				bar.Color = colors[((i + k) % 4) + 1]
			end
			digits.Text = `{math.random(1, 9)} {math.random(1, 9)} {math.random(1, 9)}`
			-- lluvia de bolas de pachinko
			local ball = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.8, Position = c + back * math.random(3, 25) + Vector3.new(math.random(-50, 50), 45, 0),
				Color = Color3.fromRGB(210, 210, 220), Material = Enum.Material.Metal })
			TweenService:Create(ball, TweenInfo.new(0.9, Enum.EasingStyle.Bounce), { Position = Vector3.new(ball.Position.X, g + 0.4, ball.Position.Z) }):Play()
			Debris:AddItem(ball, 1)
			task.wait(0.08)
		end
		digits.Text = "? ? ?"
	end)
end

-- Dominios inventados -------------------------------------------------
-- Itadori · Dominio del Destello Negro: tormenta de rayos negros y rojos
function Scenery.BlackFlash(ctx)
	local c, back, g, dur = ctx.Center, ctx.Back, ctx.Ground, ctx.Duration
	rise(part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 140, 140), CFrame = CFrame.new(c.X, g + 0.15, c.Z + back.Z * 20) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(10, 0, 0), Material = Enum.Material.Glass }), dur)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < dur do
			local top = c + back * math.random(5, 35) + Vector3.new(math.random(-55, 55), 40, 0)
			bolt(top, Vector3.new(top.X + math.random(-6, 6), g, top.Z), if math.random() < 0.5 then BLACK else Color3.fromRGB(230, 20, 40), 0.5)
			task.wait(0.06)
		end
	end)
end

-- Nanami · Proporción 7:3: rejilla de líneas doradas que marca los puntos débiles
function Scenery.Ratio(ctx)
	local c, back, g, dur = ctx.Center, ctx.Back, ctx.Ground, ctx.Duration
	for i = -8, 8 do
		rise(part({ Size = Vector3.new(0.2, 50, 0.2), Position = c + back * 25 + Vector3.new(i * 7, g - c.Y + 25, 0), Color = Color3.fromRGB(240, 210, 120), Material = Enum.Material.Neon, Transparency = 0.4 }), dur, 0.02 * (i + 8))
	end
	for j = 0, 6 do
		rise(part({ Size = Vector3.new(120, 0.2, 0.2), Position = c + back * 25 + Vector3.new(0, g - c.Y + 3 + j * 7, 0), Color = Color3.fromRGB(240, 210, 120), Material = Enum.Material.Neon, Transparency = 0.5 }), dur, 0.3)
	end
end

-- Choso · Río Carmesí: río de sangre con pilares de sangre que caen
function Scenery.Blood(ctx)
	local c, back, g, dur = ctx.Center, ctx.Back, ctx.Ground, ctx.Duration
	local river = part({ Size = Vector3.new(160, 0.4, 30), Position = Vector3.new(c.X, g + 0.2, c.Z + back.Z * 18), Color = Color3.fromRGB(150, 0, 20), Material = Enum.Material.Glass, Transparency = 0.1 })
	rise(river, dur)
	emitter(river, { Texture = TEX_SPARK, Color = ColorSequence.new(Color3.fromRGB(255, 60, 80)), Size = NumberSequence.new(0.6, 0), Lifetime = NumberRange.new(0.5, 1),
		Rate = 80, Speed = NumberRange.new(10, 20), EmissionDirection = Enum.NormalId.Right, SpreadAngle = Vector2.new(5, 5) })
	for _ = 1, 10 do
		rise(part({ Size = Vector3.new(1.5, 30, 1.5), Position = c + back * math.random(20, 40) + Vector3.new(math.random(-50, 50), g - c.Y + 15, 0), Color = Color3.fromRGB(120, 0, 20), Material = Enum.Material.Neon, Transparency = 0.3 }), dur, math.random() * 0.5)
	end
end

-- Todo · Escenario del Mejor Amigo: escenario con focos y aplausos
function Scenery.Clap(ctx)
	local c, back, g, dur = ctx.Center, ctx.Back, ctx.Ground, ctx.Duration
	rise(part({ Size = Vector3.new(120, 1, 40), Position = Vector3.new(c.X, g + 0.5, c.Z + back.Z * 20), Color = Color3.fromRGB(90, 50, 30), Material = Enum.Material.WoodPlanks }), dur)
	rise(part({ Size = Vector3.new(120, 40, 1), Position = c + back * 40 + Vector3.new(0, g - c.Y + 20, 0), Color = Color3.fromRGB(140, 20, 30), Material = Enum.Material.Fabric }), dur, 0.2)
	for _, x in { -30, -10, 10, 30 } do
		local beam = part({ Size = Vector3.new(6, 45, 6), CFrame = CFrame.new(c.X + x, g + 22, c.Z + back.Z * 15) * CFrame.Angles(0, 0, math.rad(x / 3)),
			Color = Color3.fromRGB(255, 240, 200), Material = Enum.Material.Neon, Transparency = 0.8 })
		rise(beam, dur, 0.3)
	end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < dur do
			floatText(c + back * math.random(5, 20) + Vector3.new(math.random(-40, 40), math.random(5, 25), 0), "¡CLAP!", Color3.fromRGB(255, 220, 160), 30, 0.6)
			task.wait(0.3)
		end
	end)
end

-- Nobara · Bosque de Clavos: clavos gigantes clavados y muñecos de paja
function Scenery.Nails(ctx)
	local c, back, g, dur = ctx.Center, ctx.Back, ctx.Ground, ctx.Duration
	for _ = 1, 18 do
		local h = math.random(8, 18)
		local pos = Vector3.new(c.X + math.random(-55, 55), g + h / 2, c.Z + back.Z * math.random(5, 35))
		local tilt = CFrame.Angles(math.rad(math.random(-20, 20)), 0, math.rad(math.random(-20, 20)))
		local d = math.random() * 0.5
		local shaft = part({ Size = Vector3.new(0.8, h, 0.8), CFrame = CFrame.new(pos) * tilt, Color = Color3.fromRGB(150, 150, 160), Material = Enum.Material.Metal })
		local head = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 3, 3), CFrame = shaft.CFrame * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(170, 170, 180), Material = Enum.Material.Metal })
		rise(shaft, dur, d)
		rise(head, dur, d)
	end
	for _ = 1, 4 do
		local pos = c + back * math.random(10, 25) + Vector3.new(math.random(-35, 35), g - c.Y + 3, 0)
		rise(part({ Size = Vector3.new(2, 4, 1), Position = pos, Color = Color3.fromRGB(200, 170, 100), Material = Enum.Material.Fabric }), dur, 0.4)
		rise(part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 1.8, Position = pos + Vector3.new(0, 2.8, 0), Color = Color3.fromRGB(200, 170, 100), Material = Enum.Material.Fabric }), dur, 0.4)
	end
end

function DomainThemes.Build(theme: string?, ctx)
	local f = theme and Scenery[theme]
	if f then
		local ok, err = pcall(f, ctx)
		if not ok then
			warn("[DomainThemes]", theme, err)
		end
	end
end

-- ===================================================================
-- GOLPES DEL DOMINIO (cada tick sobre cada víctima)
-- ===================================================================
local Ticks = {}
function Ticks.Void(pos)
	ringAt(pos, Color3.fromRGB(150, 210, 255), 10, 0.4)
	floatText(pos + Vector3.new(0, 2, 0), "∞", WHITE, 40, 0.6)
end
function Ticks.Shrine(pos)
	for _ = 1, 6 do
		slash(pos + Vector3.new(math.random(-2, 2), math.random(-2, 2), 0), if math.random() < 0.5 then WHITE else Color3.fromRGB(255, 40, 40), 9, 0.2)
	end
end
function Ticks.Shadow(pos)
	for _ = 1, 3 do
		local base = pos + Vector3.new(math.random(-3, 3), -4, 0)
		local spike = part({ Size = Vector3.new(0.8, 0.5, 0.8), CFrame = CFrame.new(base), Color = Color3.fromRGB(10, 6, 20), Material = Enum.Material.Neon })
		TweenService:Create(spike, TweenInfo.new(0.12), { Size = Vector3.new(0.8, 9, 0.8), CFrame = CFrame.new(base + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, 0, math.rad(math.random(-25, 25))) }):Play()
		task.delay(0.2, fadeOut, spike, 0.3)
	end
end
function Ticks.Hands(pos)
	hand(pos + Vector3.new(0, 1, -1), 1.6, Color3.fromRGB(170, 190, 210), 0.5, 0)
	floatText(pos, "手", WHITE, 30, 0.5)
end
function Ticks.Volcano(pos)
	local p = part({ Size = Vector3.one, Position = pos - Vector3.new(0, 3, 0), Transparency = 1 })
	emitter(p, { Texture = TEX_FIRE, Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 60, 0)), Size = NumberSequence.new(3, 0.5),
		Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.4, 0.7), Speed = NumberRange.new(20, 30), SpreadAngle = Vector2.new(10, 10),
		EmissionDirection = Enum.NormalId.Top, Rate = 0 }):Emit(25)
	Debris:AddItem(p, 1)
end
function Ticks.Swords(pos)
	local blade = part({ Size = Vector3.new(0.3, 6, 0.7), CFrame = CFrame.new(pos + Vector3.new(math.random(-2, 2), 18, 0)) * CFrame.Angles(0, 0, math.rad(180)),
		Color = Color3.fromRGB(230, 230, 250), Material = Enum.Material.Neon })
	TweenService:Create(blade, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(180)) }):Play()
	task.delay(0.2, fadeOut, blade, 0.3)
end
function Ticks.Womb(pos)
	for i = 1, 3 do
		ringAt(pos, Color3.fromRGB(90, 50, 70):Lerp(BLACK, i / 4), 6 + i * 3, 0.3 + i * 0.1)
	end
end
function Ticks.Pachinko(pos)
	for _ = 1, 8 do
		local ball = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.7, Position = pos, Color = Color3.fromRGB(220, 220, 230), Material = Enum.Material.Metal })
		TweenService:Create(ball, TweenInfo.new(0.4), { Position = pos + Vector3.new(math.random(-6, 6), math.random(-2, 6), 0), Transparency = 1 }):Play()
		Debris:AddItem(ball, 0.45)
	end
	floatText(pos + Vector3.new(0, 2, 0), tostring(math.random(1, 9)), Color3.fromRGB(255, 230, 90), 34, 0.5)
end
function Ticks.BlackFlash(pos)
	for _ = 1, 5 do
		local a = math.random() * math.pi * 2
		bolt(pos, pos + Vector3.new(math.cos(a), math.sin(a), 0) * 7, if math.random() < 0.5 then BLACK else Color3.fromRGB(230, 20, 40), 0.35)
	end
	floatText(pos + Vector3.new(0, 2, 0), "黒閃", Color3.fromRGB(255, 50, 60), 34, 0.6)
end
function Ticks.Ratio(pos)
	local line = part({ Size = Vector3.new(10, 0.25, 0.25), Position = pos + Vector3.new(0, 0.6, 0), Color = Color3.fromRGB(255, 220, 120), Material = Enum.Material.Neon })
	task.delay(0.15, fadeOut, line, 0.2)
	floatText(pos + Vector3.new(0, 2.5, 0), "7:3", Color3.fromRGB(255, 220, 120), 28, 0.5)
end
function Ticks.Blood(pos)
	local from = pos + Vector3.new(math.random(-12, 12), 14, 0)
	local spear = part({ Size = Vector3.new(0.4, 0.4, (pos - from).Magnitude), CFrame = CFrame.lookAt((from + pos) / 2, pos), Color = Color3.fromRGB(200, 0, 30), Material = Enum.Material.Neon })
	task.delay(0.1, fadeOut, spear, 0.25)
end
function Ticks.Clap(pos)
	ringAt(pos, Color3.fromRGB(255, 220, 160), 12, 0.3)
	floatText(pos + Vector3.new(0, 2, 0), "¡CLAP!", Color3.fromRGB(255, 220, 160), 30, 0.5)
end
function Ticks.Nails(pos)
	local from = pos + Vector3.new(math.random(-10, 10), math.random(4, 10), 0)
	local nail = part({ Size = Vector3.new(0.3, 0.3, 2.5), CFrame = CFrame.lookAt(from, pos), Color = Color3.fromRGB(180, 180, 190), Material = Enum.Material.Metal })
	TweenService:Create(nail, TweenInfo.new(0.1), { CFrame = CFrame.lookAt(pos, pos + (pos - from).Unit) }):Play()
	task.delay(0.15, fadeOut, nail, 0.3)
	ringAt(pos, Color3.fromRGB(255, 140, 60), 7, 0.25)
end

function DomainThemes.Tick(theme: string?, victim: Instance?, final: boolean?)
	local r = rootOf(victim)
	local f = theme and Ticks[theme]
	if not r or not f then
		return
	end
	f(r.Position)
	if final then
		f(r.Position + Vector3.new(1, 1, 0))
		ringAt(r.Position, WHITE, 26, 0.4)
	end
end

-- ===================================================================
-- AURAS DE TRANSFORMACIÓN
-- ===================================================================
local Auras = {}
local function flames(parent: Instance, c1: Color3, c2: Color3, size: number, rate: number)
	return emitter(parent, {
		Texture = TEX_FIRE, Color = ColorSequence.new(c1, c2), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 0.2) }),
		Transparency = NumberSequence.new(0.15, 1), Lifetime = NumberRange.new(0.4, 0.8), Rate = rate, Speed = NumberRange.new(3, 7),
		Acceleration = Vector3.new(0, 16, 0), SpreadAngle = Vector2.new(25, 25), EmissionDirection = Enum.NormalId.Top,
		RotSpeed = NumberRange.new(-120, 120), Rotation = NumberRange.new(0, 360),
	})
end
local function loop(model: Model, duration: number, every: number, fn: (BasePart) -> ())
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < duration and model.Parent do
			local r = rootOf(model)
			if r then
				fn(r)
			end
			task.wait(every)
		end
	end)
end

-- Super Saiyan: llamarada dorada con chispas eléctricas
function Auras.Saiyan(model, torso, duration)
	local list = { flames(torso, Color3.fromRGB(255, 250, 200), Color3.fromRGB(255, 200, 30), 2.4, 110) }
	loop(model, duration, 0.18, function(r)
		local a = math.random() * math.pi * 2
		bolt(r.Position + Vector3.new(math.cos(a), math.sin(a), 0) * 1.5, r.Position + Vector3.new(math.cos(a), math.sin(a), 0) * 4, Color3.fromRGB(160, 230, 255), 0.12)
	end)
	return list
end
-- Gear 5: nubes blancas, risa y latido del "tambor de la liberación"
function Auras.Gear5(model, torso, duration)
	local list = { emitter(torso, { Texture = TEX_SMOKE, Color = ColorSequence.new(WHITE), LightEmission = 0.4, Size = NumberSequence.new(1.5, 4),
		Transparency = NumberSequence.new(0.2, 1), Lifetime = NumberRange.new(0.6, 1), Rate = 40, Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(180, 180) }) }
	loop(model, duration, 0.6, function(r)
		ringAt(r.Position, WHITE, 10, 0.45)
		if math.random() < 0.5 then
			floatText(r.Position + Vector3.new(0, 4, 0), "¡JAJAJA!", WHITE, 26, 0.7)
		else
			floatText(r.Position + Vector3.new(0, 4, 0), "DON DON", Color3.fromRGB(255, 240, 200), 24, 0.6)
		end
	end)
	return list
end
-- Modo Kurama: manto de chakra naranja
function Auras.Kurama(model, torso, duration)
	return { flames(torso, Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 100, 0), 2.2, 120),
		emitter(torso, { Texture = TEX_SPARK, Color = ColorSequence.new(Color3.fromRGB(255, 200, 80)), Size = NumberSequence.new(0.6, 0),
			Lifetime = NumberRange.new(0.3, 0.6), Rate = 30, Speed = NumberRange.new(2, 6), SpreadAngle = Vector2.new(180, 180) }) }
end
-- Respiración del Sol: estela de fuego y halo solar
function Auras.SunBreath(model, torso, duration)
	local list = {}
	for _, name in { "Right Arm", "Left Arm" } do
		local arm = model:FindFirstChild(name)
		if arm then
			table.insert(list, flames(arm, Color3.fromRGB(255, 230, 140), Color3.fromRGB(255, 70, 10), 1.4, 60))
		end
	end
	loop(model, duration, 0.8, function(r)
		ringAt(r.Position + Vector3.new(0, 2, 0), Color3.fromRGB(255, 160, 40), 9, 0.6)
	end)
	return list
end
-- Furia del Guerrero: vapor rojo
function Auras.Berserk(model, torso, duration)
	return { emitter(torso, { Texture = TEX_SMOKE, LightEmission = 0.3, Color = ColorSequence.new(Color3.fromRGB(200, 30, 20), Color3.fromRGB(60, 0, 0)),
		Size = NumberSequence.new(1.5, 3.5), Transparency = NumberSequence.new(0.3, 1), Lifetime = NumberRange.new(0.5, 0.9), Rate = 45,
		Speed = NumberRange.new(2, 5), Acceleration = Vector3.new(0, 8, 0) }) }
end
-- Restricción Celestial: sin energía maldita, solo físico -> siluetas verdes que se quedan atrás
function Auras.Celestial(model, torso, duration)
	loop(model, duration, 0.12, function()
		for _, name in { "Torso", "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg" } do
			local p = model:FindFirstChild(name) :: BasePart?
			if p then
				local g = part({ Size = p.Size, CFrame = p.CFrame, Color = Color3.fromRGB(90, 230, 140), Material = Enum.Material.ForceField, Transparency = 0.5 })
				fadeOut(g, 0.25)
			end
		end
	end)
	return {}
end
-- JACKPOT de Hakari: lluvia de monedas doradas y energía infinita
function Auras.Jackpot(model, torso, duration)
	return { flames(torso, Color3.fromRGB(180, 255, 200), Color3.fromRGB(60, 220, 120), 2, 90),
		emitter(torso, { Texture = TEX_SPARK, Color = ColorSequence.new(Color3.fromRGB(255, 230, 90)), Size = NumberSequence.new(0.9, 0),
			Lifetime = NumberRange.new(0.6, 1), Rate = 40, Speed = NumberRange.new(4, 8), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -15, 0) }) }
end

function DomainThemes.Aura(theme: string?, model: Model, duration: number)
	local torso = model:FindFirstChild("Torso")
	local f = theme and Auras[theme]
	if not torso or not f then
		return
	end
	local list = f(model, torso, duration)
	task.delay(duration, function()
		for _, e in list do
			e.Enabled = false
			Debris:AddItem(e, 1)
		end
	end)
end

-- ===================================================================
-- PREPARACIÓN DE TÉCNICAS DEFINITIVAS
-- ===================================================================
function DomainThemes.Burst(theme: string?, model: Model, windup: number)
	local r = rootOf(model)
	if not r then
		return
	end
	if theme == "Purple" then
		-- Azul (atracción) + Rojo (repulsión) se juntan = Púrpura Hueco
		local look = r.CFrame.LookVector
		local blue = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 2.5, Position = r.Position + Vector3.new(-3, 2, 0), Color = Color3.fromRGB(60, 140, 255), Material = Enum.Material.Neon })
		local red = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 2.5, Position = r.Position + Vector3.new(3, 2, 0), Color = Color3.fromRGB(255, 40, 60), Material = Enum.Material.Neon })
		local meet = r.Position + look * 3 + Vector3.new(0, 1.5, 0)
		TweenService:Create(blue, TweenInfo.new(windup * 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = meet }):Play()
		TweenService:Create(red, TweenInfo.new(windup * 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = meet }):Play()
		task.delay(windup * 0.8, function()
			blue:Destroy()
			red:Destroy()
			local purple = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 3, Position = meet, Color = Color3.fromRGB(170, 60, 255), Material = Enum.Material.Neon })
			TweenService:Create(purple, TweenInfo.new(0.25), { Size = Vector3.one * 9, Transparency = 1 }):Play()
			Debris:AddItem(purple, 0.3)
			ringAt(meet, Color3.fromRGB(200, 120, 255), 30, 0.4)
		end)
	elseif theme == "Asura" then
		-- Tres cabezas y nueve espadas: siluetas fantasma a los lados
		for _, dx in { -2.5, 2.5 } do
			for _, name in { "Torso", "Head", "Left Arm", "Right Arm" } do
				local p = model:FindFirstChild(name) :: BasePart?
				if p then
					local g = part({ Size = p.Size, CFrame = p.CFrame + Vector3.new(dx, 0, -1), Color = Color3.fromRGB(90, 220, 120), Material = Enum.Material.ForceField, Transparency = 0.3 })
					task.delay(windup, fadeOut, g, 0.4)
				end
			end
		end
		for i = 1, 9 do
			local a = math.rad(-60 + i * 13)
			local pos = r.Position + Vector3.new(math.cos(a) * 4, math.sin(a) * 4 + 1, 0)
			local blade = part({ Size = Vector3.new(0.2, 3.2, 0.5), CFrame = CFrame.lookAt(pos, pos + Vector3.new(0, 0, 1)) * CFrame.Angles(0, 0, a), Color = Color3.fromRGB(220, 255, 230), Material = Enum.Material.Neon })
			task.delay(windup, fadeOut, blade, 0.3)
		end
	end
end

-- Resultado del pachinko de Hakari
function DomainThemes.Jackpot(model: Model, won: boolean)
	local r = rootOf(model)
	if not r then
		return
	end
	if won then
		floatText(r.Position + Vector3.new(0, 6, 0), "¡¡JACKPOT!!", Color3.fromRGB(255, 225, 60), 60, 1.6)
		ringAt(r.Position, Color3.fromRGB(255, 225, 60), 40, 0.6)
		ringAt(r.Position, Color3.fromRGB(90, 255, 140), 28, 0.8)
	else
		floatText(r.Position + Vector3.new(0, 6, 0), "Fallo...", Color3.fromRGB(160, 160, 170), 40, 1.2)
	end
end

function DomainThemes.Init(fx: Folder)
	folder = fx
end

return DomainThemes
