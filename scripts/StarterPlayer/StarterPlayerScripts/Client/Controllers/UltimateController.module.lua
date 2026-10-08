-- UltimateController: lo visual de las ultis y de las pasivas de firma (todo en el cliente).
--   Ultimate  -> cinemática (zoom + franjas + nombre a pincel), y según el tipo:
--                Domain = esfera gigante del dominio + tinte de color · Transform = aura + brillo · Burst = destello
--   BlackFlash (Itadori) -> relámpagos negros/rojos + "黒閃"  ·  Infinity (Gojo) -> onda azul + "∞"
--   Stunned / Burn -> efectos sobre la víctima
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaInfo = require(Shared:WaitForChild("ArenaInfo"))
local UltimateConfig = require(Shared:WaitForChild("UltimateConfig"))
local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local Sfx = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Sfx"))
local DomainThemes = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("DomainThemes"))

-- Color del "cielo" de cada dominio
local DOMAIN_SKY = {
	Void = Color3.fromRGB(4, 8, 28), Shrine = Color3.fromRGB(95, 0, 0), Shadow = Color3.fromRGB(4, 2, 10), Hands = Color3.fromRGB(40, 50, 62),
	Volcano = Color3.fromRGB(70, 18, 0), Swords = Color3.fromRGB(36, 22, 62), Womb = Color3.fromRGB(55, 22, 20), Pachinko = Color3.fromRGB(16, 6, 28),
	BlackFlash = Color3.fromRGB(12, 0, 0), Ratio = Color3.fromRGB(32, 26, 10), Blood = Color3.fromRGB(55, 0, 6), Clap = Color3.fromRGB(32, 10, 10),
	Nails = Color3.fromRGB(42, 26, 14),
}

-- Altura del suelo bajo un punto (para que el escenario del dominio salga del suelo)
local function groundBelow(position: Vector3): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { workspace:FindFirstChild("UltimateFX") }
	for _, m in game:GetService("CollectionService"):GetTagged("Fighter") do
		table.insert(ignore, m)
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -200, 0), params)
	return if hit then hit.Position.Y else position.Y - 3
end
local CameraController = require(script.Parent:WaitForChild("CameraController"))

local player = Players.LocalPlayer

local UltimateController = {}

local gui: ScreenGui
local titleFrame: Frame
local kindLabel: TextLabel
local nameLabel: TextLabel
local jpLabel: TextLabel
local flash: Frame
local fxFolder: Folder
local barTop: Frame
local barBottom: Frame
local bigFrame: Frame
local bigKanji: TextLabel
local bigSub: TextLabel
local lightning -- se define más abajo

local function root(model: Instance?): BasePart?
	return model and model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") :: BasePart? or nil
end

local function myArena(): string?
	local c = player.Character
	return c and c:GetAttribute("ArenaId")
end

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = fxFolder
	return p
end

local function screenFlash(color: Color3, strength: number)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 1 - strength
	TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
end

local KIND_TEXT = { Domain = "領域展開 · EXPANSIÓN DE DOMINIO", Transform = "変身 · TRANSFORMACIÓN", Burst = "奥義 · TÉCNICA DEFINITIVA" }

local function showTitle(info)
	kindLabel.Text = KIND_TEXT[info.Kind] or ""
	nameLabel.Text = info.Name
	nameLabel.TextColor3 = info.Color:Lerp(Color3.new(1, 1, 1), 0.35)
	jpLabel.Text = info.Japanese or ""
	titleFrame.Visible = true
	titleFrame.Position = UDim2.fromScale(0.5, 0.62)
	local s = titleFrame:FindFirstChildOfClass("UIScale") :: UIScale
	s.Scale = 1.4
	TweenService:Create(s, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	for _, l in { kindLabel, nameLabel, jpLabel } do
		l.TextTransparency = 0
		l.TextStrokeTransparency = 0.1
	end
	task.delay(2.4, function()
		for _, l in { kindLabel, nameLabel, jpLabel } do
			TweenService:Create(l, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
		task.wait(0.45)
		titleFrame.Visible = false
	end)
end

-- Bandas negras de cine (arriba y abajo)
local function letterbox(on: boolean)
	local h = if on then 0.12 else 0
	TweenService:Create(barTop, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(1, h) }):Play()
	TweenService:Create(barBottom, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(1, h) }):Play()
end

-- Kanji gigante que "golpea" la pantalla
local function slamText(text: string, sub: string, color: Color3, hold: number)
	bigKanji.Text = text
	bigSub.Text = sub
	bigKanji.TextColor3 = Color3.new(1, 1, 1)
	local stroke = bigKanji:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = color:Lerp(Color3.new(0, 0, 0), 0.4)
	end
	bigFrame.Visible = true
	local s = bigFrame:FindFirstChildOfClass("UIScale") :: UIScale
	s.Scale = 2.4
	for _, l in { bigKanji, bigSub } do
		l.TextTransparency = 0
	end
	TweenService:Create(s, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(0.22, function()
		CameraController.Shake(1.4, 0.25)
		TweenService:Create(s, TweenInfo.new(hold, Enum.EasingStyle.Linear), { Scale = 1.08 }):Play()
	end)
	task.delay(hold, function()
		for _, l in { bigKanji, bigSub } do
			TweenService:Create(l, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
		end
		task.wait(0.3)
		bigFrame.Visible = false
	end)
end

-- Remolino de energía maldita alrededor del lanzador (llamas + humo negro + anillos + rayos)
local function vortex(model: Model, color: Color3, duration: number)
	local hrp = root(model)
	if not hrp then
		return
	end
	local holder = part({ Size = Vector3.new(4, 6, 4), CFrame = hrp.CFrame, Transparency = 1 })
	local flames = Instance.new("ParticleEmitter")
	flames.Texture = "rbxasset://textures/particles/fire_main.dds"
	flames.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.3), color:Lerp(Color3.new(0, 0, 0), 0.4))
	flames.LightEmission = 1
	flames.LightInfluence = 0
	flames.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 0.5) })
	flames.Transparency = NumberSequence.new(0.2, 1)
	flames.Lifetime = NumberRange.new(0.6, 1)
	flames.Rate = 140
	flames.Speed = NumberRange.new(2, 6)
	flames.Acceleration = Vector3.new(0, 18, 0)
	flames.SpreadAngle = Vector2.new(20, 20)
	flames.EmissionDirection = Enum.NormalId.Top
	flames.RotSpeed = NumberRange.new(-180, 180)
	flames.Rotation = NumberRange.new(0, 360)
	flames.Parent = holder
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(10, 5, 15))
	smoke.LightInfluence = 0
	smoke.Size = NumberSequence.new(3, 7)
	smoke.Transparency = NumberSequence.new(0.35, 1)
	smoke.Lifetime = NumberRange.new(0.8, 1.4)
	smoke.Rate = 50
	smoke.Speed = NumberRange.new(4, 9)
	smoke.SpreadAngle = Vector2.new(180, 20)
	smoke.RotSpeed = NumberRange.new(-60, 60)
	smoke.Rotation = NumberRange.new(0, 360)
	smoke.Parent = holder
	-- Anillos de energía en el suelo que se expanden
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < duration and hrp.Parent do
			local ring = part({
				Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 3, 3), Color = color, Material = Enum.Material.Neon, Transparency = 0.2,
				CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2.8, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			})
			TweenService:Create(ring, TweenInfo.new(0.7, Enum.EasingStyle.Quad), { Size = Vector3.new(0.1, 26, 26), Transparency = 1 }):Play()
			Debris:AddItem(ring, 0.75)
			task.wait(0.28)
		end
	end)
	-- Rayos alrededor del lanzador
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < duration and hrp.Parent do
			lightning(hrp.Position, { color, Color3.new(1, 1, 1), color:Lerp(Color3.new(0, 0, 0), 0.6) }, 3, 7)
			task.wait(0.12)
		end
	end)
	task.delay(duration, function()
		flames.Enabled = false
		smoke.Enabled = false
		Debris:AddItem(holder, 1.5)
	end)
end

-- Cinemática de la ulti.
--   Dominio: el tiempo se para (blanco y negro) -> primer plano -> la cámara gira -> "領域展開" -> se abre el dominio
--   Transformación: subida de poder con remolino y rayos · Resto: acercamiento rápido
local function cinematic(model: Model, info)
	local hrp = root(model)
	local head = model:FindFirstChild("Head") :: BasePart?
	if not hrp or not head then
		return
	end
	local camera = workspace.CurrentCamera
	local start = camera.CFrame
	local windup = info.Windup or UltimateConfig.WindupFor(info.Kind)
	local t = 0
	local side = if (start.Position - hrp.Position).Z >= 0 then 1 else -1
	info.CamSide = side -- el dominio pone su telón al otro lado de la cámara
	letterbox(true)

	if info.Kind == "Domain" then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "CinematicGray"
		cc.Parent = Lighting
		TweenService:Create(cc, TweenInfo.new(0.25), { Saturation = -0.85, Contrast = 0.25 }):Play()
		vortex(model, info.Color, windup)
		task.delay(0.35, slamText, "領域展開", "EXPANSIÓN DE DOMINIO", info.Color, 1.05)
		task.delay(1.45, showTitle, info)
		task.delay(windup - 0.55, function()
			-- Fogonazo del color del dominio: vuelve el color
			screenFlash(info.Color, 0.9)
			TweenService:Create(cc, TweenInfo.new(0.4), { Saturation = 0, Contrast = 0 }):Play()
			Debris:AddItem(cc, 0.5)
			CameraController.Shake(2, 0.5)
		end)
	elseif info.Kind == "Transform" then
		vortex(model, info.Color, windup * 0.9)
		task.delay(0.15, showTitle, info)
	else
		task.delay(0.1, showTitle, info)
	end

	local orbitTurns = math.pi * 1.2
	CameraController.SetOverride(function(dt)
		t += dt
		if t > windup or not hrp.Parent then
			return nil
		end
		local look = hrp.CFrame.LookVector
		local focus = head.Position
		if info.Kind == "Domain" then
			if t < 1.1 then
				-- 1) primer plano de la cara, acercándose despacio
				local a = math.clamp(t / 0.3, 0, 1)
				local dist = 6 - t * 1.6
				local close = CFrame.lookAt(focus + look * dist + Vector3.new(0, 0.4, side * 2), focus)
				return start:Lerp(close, 1 - (1 - a) ^ 3)
			end
			local orbitTime = windup - 1.7
			local k = math.clamp((t - 1.1) / orbitTime, 0, 1)
			local angle = k * orbitTurns
			local orbit = CFrame.lookAt(
				hrp.Position + Vector3.new(math.sin(angle) * 11, 3 + k * 4, math.cos(angle) * 11 * side),
				hrp.Position + Vector3.new(0, 1.5, 0)
			)
			if t < windup - 0.6 then
				-- 2) la cámara gira alrededor mientras la energía se arremolina
				return orbit
			end
			-- 3) vuelta a la vista de la arena justo cuando se abre el dominio
			local back = math.clamp((t - (windup - 0.6)) / 0.6, 0, 1)
			return orbit:Lerp(start, 1 - (1 - back) ^ 2)
		end
		local target = CFrame.lookAt(hrp.Position + look * 9 + Vector3.new(0, 2.5, side * 6), hrp.Position + Vector3.new(0, 1.5, 0))
		if t > windup - 0.3 then
			return target:Lerp(start, (t - (windup - 0.3)) / 0.3)
		end
		local a = math.clamp(t / 0.35, 0, 1)
		return start:Lerp(target, 1 - (1 - a) ^ 3)
	end)
	task.delay(windup, function()
		CameraController.SetOverride(nil)
		letterbox(false)
	end)
end

local function aura(model: Model, color: Color3, duration: number)
	local torso = model:FindFirstChild("Torso") :: BasePart?
	if not torso then
		return
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "UltAura"
	emitter.Color = ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), 0.5))
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Rate = 70
	emitter.Speed = NumberRange.new(3, 8)
	emitter.Acceleration = Vector3.new(0, 12, 0)
	emitter.SpreadAngle = Vector2.new(25, 25)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = torso
	local highlight = Instance.new("Highlight")
	highlight.FillColor = color
	highlight.FillTransparency = 0.75
	highlight.OutlineColor = color
	highlight.OutlineTransparency = 0.1
	highlight.Parent = model
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 16
	light.Brightness = 3
	light.Parent = torso
	Debris:AddItem(emitter, duration)
	Debris:AddItem(highlight, duration)
	Debris:AddItem(light, duration)
end

-- Expansión de dominio: esfera que se expande desde el lanzador y cubre la arena + tinte de color
local function domain(model: Model, info)
	local hrp = root(model)
	if not hrp then
		return
	end
	local info2 = ArenaInfo.Get(model:GetAttribute("ArenaId"))
	local center = if info2 then Vector3.new(info2:GetAttribute("CenterX") or hrp.Position.X, hrp.Position.Y, 0) else hrp.Position
	local inner = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 4, Position = hrp.Position, Color = info.Color,
		Material = Enum.Material.ForceField, Transparency = 0 })
	local shell = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 4, Position = hrp.Position, Color = info.Color:Lerp(Color3.new(0, 0, 0), 0.6),
		Material = Enum.Material.Neon, Transparency = 0.85 })
	local dur = info.Duration + 0.5
	TweenService:Create(inner, TweenInfo.new(0.9, Enum.EasingStyle.Quart), { Size = Vector3.one * 110, Position = center }):Play()
	TweenService:Create(shell, TweenInfo.new(1.1, Enum.EasingStyle.Quart), { Size = Vector3.one * 130, Position = center }):Play()
	-- Telón del dominio: tapa el escenario de fondo con el color de la técnica (desde la cámara se ve "dentro")
	local look = workspace.CurrentCamera.CFrame.LookVector
	local back = if info.CamSide then Vector3.new(0, 0, -info.CamSide) else Vector3.new(0, 0, if look.Z < 0 then -1 else 1)
	DomainThemes.Build(info.Theme, { Center = center, Back = back, Ground = groundBelow(hrp.Position), Color = info.Color, Duration = dur })
	local backdrop = part({ Size = Vector3.new(700, 400, 1), CFrame = CFrame.lookAt(center + back * 70, center), Color = DOMAIN_SKY[info.Theme or ""] or info.Color:Lerp(Color3.new(0, 0, 0), 0.75),
		Material = Enum.Material.Neon, Transparency = 1 })
	local glow = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 4, 4), CFrame = CFrame.new(center - Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = info.Color, Material = Enum.Material.Neon, Transparency = 0.35 })
	TweenService:Create(backdrop, TweenInfo.new(0.7), { Transparency = 0.08 }):Play()
	TweenService:Create(glow, TweenInfo.new(1, Enum.EasingStyle.Quart), { Size = Vector3.new(0.4, 120, 120) }):Play()
	local stars = Instance.new("ParticleEmitter")
	stars.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	stars.Color = ColorSequence.new(info.Color:Lerp(Color3.new(1, 1, 1), 0.5))
	stars.Size = NumberSequence.new(1.5, 0)
	stars.Lifetime = NumberRange.new(1.5, 3)
	stars.Rate = 120
	stars.Speed = NumberRange.new(2, 6)
	stars.SpreadAngle = Vector2.new(180, 180)
	stars.LightEmission = 1
	stars.Parent = backdrop
	task.delay(dur, function()
		stars.Enabled = false
		TweenService:Create(backdrop, TweenInfo.new(0.6), { Transparency = 1 }):Play()
		TweenService:Create(glow, TweenInfo.new(0.6), { Transparency = 1 }):Play()
		Debris:AddItem(backdrop, 1)
		Debris:AddItem(glow, 1)
	end)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "DomainTint"
	cc.TintColor = Color3.new(1, 1, 1)
	cc.Parent = Lighting
	TweenService:Create(cc, TweenInfo.new(0.8), { TintColor = info.Color:Lerp(Color3.new(1, 1, 1), 0.35), Contrast = 0.3, Saturation = -0.1, Brightness = -0.05 }):Play()
	task.delay(dur, function()
		TweenService:Create(inner, TweenInfo.new(0.6), { Transparency = 1 }):Play()
		TweenService:Create(shell, TweenInfo.new(0.6), { Transparency = 1 }):Play()
		TweenService:Create(cc, TweenInfo.new(0.6), { TintColor = Color3.new(1, 1, 1), Contrast = 0, Saturation = 0, Brightness = 0 }):Play()
		task.wait(0.7)
		inner:Destroy()
		shell:Destroy()
		cc:Destroy()
	end)
end

function lightning(pos: Vector3, colors: { Color3 }, count: number, size: number)
	for i = 1, count do
		local color = colors[(i % #colors) + 1]
		local a = math.random() * math.pi * 2
		local len = size * (0.6 + math.random() * 0.8)
		local dir = Vector3.new(math.cos(a), math.sin(a), 0)
		local bolt = part({ Size = Vector3.new(0.35, 0.35, len), CFrame = CFrame.lookAt(pos + dir * len / 2, pos + dir * len), Color = color, Material = Enum.Material.Neon })
		TweenService:Create(bolt, TweenInfo.new(0.35), { Transparency = 1, Size = Vector3.new(0.05, 0.05, len * 1.3) }):Play()
		Debris:AddItem(bolt, 0.4)
	end
end

local function floating(pos: Vector3, text: string, color: Color3, size: number)
	local anchor = part({ Size = Vector3.one, Position = pos, Transparency = 1 })
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(300, 80)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Parent = anchor
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color
	l.TextSize = size
	l.Font = UI.TitleFont
	l.TextStrokeTransparency = 0
	l.Parent = bb
	TweenService:Create(anchor, TweenInfo.new(1), { Position = pos + Vector3.new(0, 5, 0) }):Play()
	TweenService:Create(l, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1.1)
end

function UltimateController.Start()
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "UltimateFX"
	fxFolder.Parent = workspace
	DomainThemes.Init(fxFolder)

	gui = UI.screenGui("UltimateFX", 45, true)
	gui.IgnoreGuiInset = true
	flash = UI.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1 }, gui)
	barTop = UI.make("Frame", { Size = UDim2.fromScale(1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 8 }, gui)
	barBottom = UI.make("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 8,
	}, gui)
	bigFrame = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.9, 0.42),
		BackgroundTransparency = 1, Visible = false, ZIndex = 9,
	}, gui)
	UI.make("UIScale", {}, bigFrame)
	bigKanji = UI.label(bigFrame, {
		Size = UDim2.fromScale(1, 0.78), TextScaled = true, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 10,
	})
	UI.make("UIStroke", { Thickness = 6, Color = Color3.new(0, 0, 0) }, bigKanji)
	bigSub = UI.label(bigFrame, {
		Position = UDim2.fromScale(0, 0.78), Size = UDim2.fromScale(1, 0.22), TextScaled = true, Font = UI.TitleFont,
		TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Color3.new(1, 1, 1), ZIndex = 10,
	})
	UI.make("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, bigSub)
	titleFrame = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.62), Size = UDim2.fromOffset(900, 170),
		BackgroundTransparency = 1, Visible = false, ZIndex = 5,
	}, gui)
	UI.make("UIScale", {}, titleFrame)
	kindLabel = UI.label(titleFrame, {
		Size = UDim2.new(1, 0, 0, 30), TextSize = 26, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Color3.fromRGB(230, 220, 255), ZIndex = 6,
	})
	nameLabel = UI.label(titleFrame, {
		Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 90), TextScaled = true, Font = UI.TitleFont,
		TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 6,
	})
	UI.make("UITextSizeConstraint", { MaxTextSize = 84 }, nameLabel)
	jpLabel = UI.label(titleFrame, {
		Position = UDim2.fromOffset(0, 120), Size = UDim2.new(1, 0, 0, 44), TextSize = 40, Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Color3.new(1, 1, 1), ZIndex = 6,
	})

	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CombatFeedback").OnClientEvent:Connect(function(kind, a, b, c, d)
		if kind == "Ultimate" and typeof(a) == "Instance" and type(b) == "table" then
			local inMyArena = a:GetAttribute("ArenaId") == myArena()
			if not inMyArena then
				return
			end
			local windup = b.Windup or UltimateConfig.WindupFor(b.Kind)
			b.Windup = windup
			Sfx.Play("Domain", nil, 1)
			screenFlash(b.Color, 0.55)
			cinematic(a, b)
			CameraController.Shake(1.2, 0.6)
			if b.Kind == "Domain" then
				task.delay(windup - 0.5, domain, a, b)
			elseif b.Kind == "Transform" then
				aura(a, b.Color, (b.Duration or 10) + windup)
				DomainThemes.Aura(b.Theme, a, (b.Duration or 10) + windup)
				task.delay(windup * 0.85, function()
					screenFlash(b.Color, 0.7)
					CameraController.Shake(1.6, 0.4)
				end)
			else
				DomainThemes.Burst(b.Theme, a, windup)
				task.delay(windup, screenFlash, b.Color, 0.4)
			end
		elseif kind == "DomainTick" and typeof(a) == "Instance" and a:GetAttribute("ArenaId") == myArena() then
			DomainThemes.Tick(c, b, d)
		elseif kind == "Jackpot" and typeof(a) == "Instance" and a:GetAttribute("ArenaId") == myArena() then
			DomainThemes.Jackpot(a, b == true)
			screenFlash(if b then Color3.fromRGB(255, 225, 60) else Color3.fromRGB(80, 80, 90), 0.6)
		elseif kind == "BlackFlash" and typeof(b) == "Vector3" then
			lightning(b, { Color3.fromRGB(10, 0, 0), Color3.fromRGB(230, 20, 40), Color3.fromRGB(20, 0, 10) }, 14, 9)
			floating(b + Vector3.new(0, 3, 0), "黒閃 ¡DESTELLO NEGRO!", Color3.fromRGB(255, 50, 60), 34)
			screenFlash(Color3.fromRGB(0, 0, 0), 0.35)
			CameraController.Shake(1.6, 0.3)
			Sfx.Play("HitHeavy", nil, 1, 0.7)
		elseif kind == "Infinity" and typeof(b) == "Vector3" then
			local ring = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 2, Position = b, Color = Color3.fromRGB(120, 200, 255), Material = Enum.Material.ForceField })
			TweenService:Create(ring, TweenInfo.new(0.5), { Size = Vector3.one * 10, Transparency = 1 }):Play()
			Debris:AddItem(ring, 0.55)
			floating(b + Vector3.new(0, 3, 0), "∞ INFINITO", Color3.fromRGB(150, 210, 255), 28)
			Sfx.Play("Shield", nil, 1, 1.4)
		elseif kind == "Stunned" and typeof(a) == "Instance" then
			local hrp = root(a)
			if hrp then
				floating(hrp.Position + Vector3.new(0, 4, 0), "¡PARALIZADO!", Color3.fromRGB(200, 230, 255), 24)
			end
		elseif kind == "Burn" and typeof(a) == "Instance" then
			local torso = a:FindFirstChild("Torso")
			if torso then
				local fire = Instance.new("Fire")
				fire.Heat = 6
				fire.Size = 5
				fire.Parent = torso
				Debris:AddItem(fire, 0.6)
			end
		end
	end)
end

return UltimateController
