-- EffectsController: feedback visual (game feel).
--   golpes, KOs (con el efecto de KO equipado por quien lo consigue), escudo, esquivas,
--   rotura de escudo, agarres, intercambio e invulnerabilidad.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("CombatConfig"))
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))
local ArenaInfo = require(Shared:WaitForChild("ArenaInfo"))
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))
local CameraController = require(script.Parent:WaitForChild("CameraController"))

local EffectsController = {}

local fxFolder: Folder
local bubbles = {} -- [Model] = Part

local function fxPart(props): Part
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
	p.Parent = fxFolder
	return p
end

local function flash(model: Model, color: Color3?)
	local h = Instance.new("Highlight")
	h.FillColor = color or Color3.new(1, 1, 1)
	h.FillTransparency = 0.2
	h.OutlineTransparency = 1
	h.Parent = model
	Debris:AddItem(h, 0.08)
end

local function floatingText(position: Vector3, text: string, color: Color3, size: number?)
	local anchor = fxPart({ Transparency = 1, Size = Vector3.one * 0.2, Position = position + Vector3.new(0, 3, 0) })
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 44)
	gui.AlwaysOnTop = true
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.PermanentMarker
	label.TextSize = size or 26
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = gui
	TweenService:Create(anchor, TweenInfo.new(0.7), { Position = anchor.Position + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.7), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 0.75)
end

local function burst(position: Vector3, color: Color3, startSize: number, endSize: number, duration: number, transparency: number?)
	local p = fxPart({ Shape = Enum.PartType.Ball, Color = color, Size = Vector3.one * startSize, Position = position, Transparency = transparency or 0 })
	TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.one * endSize,
		Transparency = 1,
	}):Play()
	Debris:AddItem(p, duration)
end

local function scatter(position: Vector3, color: Color3, count: number, spread: number)
	for _ = 1, count do
		local p = fxPart({ Size = Vector3.one * math.random(6, 14) / 10, Position = position, Color = color })
		local target = position + Vector3.new(math.random(-spread, spread), math.random(-spread, spread), math.random(-4, 4))
		TweenService:Create(p, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = target, Transparency = 1, Orientation = Vector3.new(math.random(0, 360), math.random(0, 360), 0),
		}):Play()
		Debris:AddItem(p, 0.7)
	end
end

local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_FIRE = "rbxasset://textures/particles/fire_main.dds"
local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"

-- Anillo de impacto mirando a la cámara
local function impactRing(position: Vector3, color: Color3, size: number, duration: number)
	local look = workspace.CurrentCamera.CFrame.LookVector
	local ring = fxPart({
		Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.15, size * 0.3, size * 0.3), Color = color, Transparency = 0.05,
		CFrame = CFrame.lookAt(position, position + look) * CFrame.Angles(0, math.rad(90), 0),
	})
	TweenService:Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.05, size, size), Transparency = 1,
	}):Play()
	Debris:AddItem(ring, duration)
end

-- Ráfaga de partículas puntual (chispas, llamas, humo)
local function emitAt(position: Vector3, count: number, props)
	local holder = fxPart({ Size = Vector3.one * 0.2, Position = position, Transparency = 1 })
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	e.LightEmission = 1
	e.LightInfluence = 0
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = holder
	e:Emit(count)
	Debris:AddItem(holder, 1.5)
end

-- "Impact frame" de anime: un instante en blanco y negro con mucho contraste
local impactCC: ColorCorrectionEffect? = nil
local function impactFrame(duration: number)
	if impactCC then
		return
	end
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation = -1
	cc.Contrast = 0.9
	cc.Brightness = 0.12
	cc.Parent = game:GetService("Lighting")
	impactCC = cc
	task.delay(duration, function()
		cc:Destroy()
		impactCC = nil
	end)
end

-- Aura maldita al lanzar una técnica: llamas del color del personaje + humo negro + anillo en el suelo
local function cursedAura(model: Model)
	local torso = model:FindFirstChild("Torso") :: BasePart?
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not torso or not hrp then
		return
	end
	local data = CharacterRegistry.Get(model:GetAttribute("CharacterId"))
	local color = if data and data.Color then data.Color else Color3.fromRGB(150, 70, 220)
	local flames = Instance.new("ParticleEmitter")
	flames.Texture = TEX_FIRE
	flames.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.25), color:Lerp(Color3.new(0, 0, 0), 0.5))
	flames.LightEmission = 1
	flames.LightInfluence = 0
	flames.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.8), NumberSequenceKeypoint.new(1, 0.2) })
	flames.Transparency = NumberSequence.new(0.15, 1)
	flames.Lifetime = NumberRange.new(0.35, 0.6)
	flames.Rate = 90
	flames.Speed = NumberRange.new(2, 5)
	flames.Acceleration = Vector3.new(0, 14, 0)
	flames.SpreadAngle = Vector2.new(30, 30)
	flames.EmissionDirection = Enum.NormalId.Top
	flames.RotSpeed = NumberRange.new(-150, 150)
	flames.Rotation = NumberRange.new(0, 360)
	flames.Parent = torso
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = TEX_SMOKE
	smoke.Color = ColorSequence.new(Color3.fromRGB(12, 6, 18))
	smoke.LightInfluence = 0
	smoke.Size = NumberSequence.new(1.5, 3.5)
	smoke.Transparency = NumberSequence.new(0.5, 1)
	smoke.Lifetime = NumberRange.new(0.4, 0.7)
	smoke.Rate = 30
	smoke.Speed = NumberRange.new(1, 3)
	smoke.Acceleration = Vector3.new(0, 6, 0)
	smoke.Parent = torso
	task.delay(0.55, function()
		flames.Enabled = false
		smoke.Enabled = false
		Debris:AddItem(flames, 1)
		Debris:AddItem(smoke, 1)
	end)
	local ring = fxPart({
		Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 2, 2), Color = color, Transparency = 0.2,
		CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2.9, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	})
	TweenService:Create(ring, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Size = Vector3.new(0.05, 14, 14), Transparency = 1 }):Play()
	Debris:AddItem(ring, 0.45)
end

-- KO con el efecto equipado por quien lo consigue
local function koEffect(pos: Vector3, killer: Model?)
	local effectId = killer and killer:GetAttribute("KOEffect")
	local item = effectId and CatalogConfig.StoreItems[effectId]
	if not item then
		burst(pos, Color3.fromRGB(255, 90, 60), 4, 45, 0.6)
		return
	end
	if effectId == "Effect_Sakura" then
		burst(pos, item.Color, 4, 30, 0.6, 0.3)
		scatter(pos, item.Color, 30, 25)
	elseif effectId == "Effect_Gold" then
		burst(pos, item.Color, 6, 55, 0.7)
		scatter(pos, Color3.fromRGB(255, 240, 150), 20, 30)
	elseif effectId == "Effect_Domain" then
		burst(pos, item.Color, 10, 90, 1, 0.2)
		burst(pos, Color3.new(1, 1, 1), 2, 30, 0.4)
	elseif effectId == "Effect_BlackFlash" then
		burst(pos, item.Color, 6, 40, 0.5)
		burst(pos, item.Accent, 3, 60, 0.7, 0.3)
		scatter(pos, item.Accent, 24, 28)
	else
		burst(pos, item.Color, 4, 45, 0.6)
	end
	floatingText(pos, "¡K.O.!", item.Accent or item.Color, 40)
end

local function setTransparency(model: Model, value: number)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.LocalTransparencyModifier = value
		end
	end
end

local function watchFighter(model: Model)
	local highlight: Highlight? = nil
	local function updateInvulnerable()
		if model:GetAttribute("Invulnerable") then
			if not highlight then
				highlight = Instance.new("Highlight")
				highlight.FillTransparency = 0.7
				highlight.OutlineColor = Color3.new(1, 1, 1)
				highlight.Parent = model
			end
		elseif highlight then
			highlight:Destroy()
			highlight = nil
		end
	end
	model:GetAttributeChangedSignal("Invulnerable"):Connect(updateInvulnerable)
	updateInvulnerable()

	-- Esquiva: semitransparente mientras es intangible
	model:GetAttributeChangedSignal("Intangible"):Connect(function()
		setTransparency(model, if model:GetAttribute("Intangible") then 0.6 else 0)
	end)

	-- Escudo: burbuja que encoge y se pone roja al gastarse
	model:GetAttributeChangedSignal("Shielding"):Connect(function()
		local on = model:GetAttribute("Shielding")
		if on and not bubbles[model] then
			bubbles[model] = fxPart({
				Shape = Enum.PartType.Ball, Size = Vector3.one * 7, Transparency = 0.55,
				Material = Enum.Material.ForceField, Color = Color3.fromRGB(120, 200, 255),
			})
		elseif not on and bubbles[model] then
			bubbles[model]:Destroy()
			bubbles[model] = nil
		end
	end)
end

-- ===== Efecto de correr: polvareda en los pies + estela de velocidad + "fantasmas" a tope de velocidad
-- Se calcula por la velocidad real, así se ve en TODOS los luchadores sin replicar nada.
local runFx = {} -- [Model] = { Dust, Trail, LastGhost }
local RUN_THRESHOLD = 27

local function ensureRunFx(model: Model)
	local fx = runFx[model]
	if fx then
		return fx
	end
	local torso = model:FindFirstChild("Torso") :: BasePart?
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not torso or not hrp then
		return nil
	end
	local feet = Instance.new("Attachment")
	feet.Name = "RunFeet"
	feet.Position = Vector3.new(0, -2.9, 0)
	feet.Parent = hrp
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(Color3.fromRGB(235, 225, 210))
	dust.LightInfluence = 0.6
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 2.6) })
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
	dust.Lifetime = NumberRange.new(0.35, 0.6)
	dust.Speed = NumberRange.new(2, 5)
	dust.SpreadAngle = Vector2.new(35, 35)
	dust.Acceleration = Vector3.new(0, 3, 0)
	dust.RotSpeed = NumberRange.new(-90, 90)
	dust.Rotation = NumberRange.new(0, 360)
	dust.Rate = 0
	dust.Parent = feet
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.9, 0)
	a0.Parent = torso
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.9, 0)
	a1.Parent = torso
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(Color3.new(1, 1, 1))
	trail.LightEmission = 0.6
	trail.Transparency = NumberSequence.new(0.55, 1)
	trail.Lifetime = 0.18
	trail.MinLength = 0.2
	trail.Enabled = false
	trail.Parent = torso
	fx = { Dust = dust, Trail = trail, LastGhost = 0 }
	runFx[model] = fx
	return fx
end

-- Silueta translúcida que se queda atrás (afterimage)
local function ghost(model: Model, color: Color3)
	for _, name in { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" } do
		local p = model:FindFirstChild(name) :: BasePart?
		if p then
			local g = fxPart({ Size = p.Size, CFrame = p.CFrame, Color = color, Transparency = 0.55 })
			g.Material = Enum.Material.ForceField
			TweenService:Create(g, TweenInfo.new(0.3), { Transparency = 1 }):Play()
			Debris:AddItem(g, 0.32)
		end
	end
end

local function updateRunFx()
	local now = os.clock()
	for _, model in CollectionService:GetTagged("Fighter") do
		local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if hrp and humanoid and model:GetAttribute("MoveMode") ~= "Free" then
			local fx = ensureRunFx(model)
			if fx then
				local speed = math.abs(hrp.AssemblyLinearVelocity.X)
				local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
				local fast = speed > RUN_THRESHOLD
				fx.Dust.Rate = if fast and grounded then 40 else 0
				fx.Trail.Enabled = fast
				if fast and grounded and now - fx.LastGhost > 0.09 then
					fx.LastGhost = now
					local data = CharacterRegistry.Get(model:GetAttribute("CharacterId"))
					ghost(model, if data and data.Color then data.Color else Color3.new(1, 1, 1))
				end
			end
		end
	end
	for model in runFx do
		if not model.Parent then
			runFx[model] = nil
		end
	end
end

function EffectsController.Start()
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "ClientFX"
	fxFolder.Parent = workspace

	RunService.RenderStepped:Connect(function()
		updateRunFx()
		for model, bubble in bubbles do
			local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not model.Parent or not hrp then
				bubble:Destroy()
				bubbles[model] = nil
			else
				local ratio = math.clamp((model:GetAttribute("ShieldHP") or 50) / Config.Defense.ShieldMax, 0, 1)
				bubble.Size = Vector3.one * (3.5 + 4 * ratio)
				bubble.Color = Color3.fromRGB(255, 70, 70):Lerp(Color3.fromRGB(120, 200, 255), ratio)
				bubble.Position = hrp.Position
			end
		end
	end)

	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CombatFeedback").OnClientEvent:Connect(function(kind, a, b, c, d)
		if kind == "Hit" then
			-- a = víctima, b = daño, c = knockback, d = posición
			flash(a)
			floatingText(d, `{b}%`, Color3.fromRGB(255, 230, 90), if c > 80 then 34 else 26)
			burst(d, Color3.fromRGB(255, 240, 200), 1, 3 + c / 25, 0.15)
			-- Anillo + chispas: más grandes cuanto más fuerte es el golpe
			local strength = math.clamp(c / 100, 0.3, 2)
			impactRing(d, Color3.new(1, 1, 1), 6 + strength * 10, 0.2 + strength * 0.08)
			emitAt(d, math.floor(8 + strength * 14), {
				Texture = TEX_SPARK, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(255, 200, 90)),
				Size = NumberSequence.new(0.9, 0), Lifetime = NumberRange.new(0.15, 0.35), Speed = NumberRange.new(20, 45),
				SpreadAngle = Vector2.new(180, 180), Drag = 5,
			})
			if c > 60 then
				CameraController.Shake(math.clamp(c / 120, 0.3, 1.5), 0.15)
			end
			if c > 95 then
				impactFrame(0.06) -- golpes que mandan a volar: fotograma de impacto
				impactRing(d, Color3.fromRGB(255, 90, 60), 30, 0.35)
			end
		elseif kind == "KO" then
			-- a = modelo, b = posición donde cruzó la blast zone, c = quien lo consiguió
			local left, right, bottom, top = ArenaInfo.Bounds(a:GetAttribute("ArenaId"))
			local pos = b
			if left then
				pos = Vector3.new(math.clamp(b.X, left + 10, right - 10), math.clamp(b.Y, bottom + 10, top - 10), Config.PlaneZ)
			end
			koEffect(pos, c)
			CameraController.Shake(2, 0.4)
		elseif kind == "MoveStarted" and typeof(a) == "Instance" and typeof(b) == "string" and b:find("Special") then
			cursedAura(a)
		elseif kind == "ShieldHit" then
			burst(b, Color3.fromRGB(150, 220, 255), 3, 8, 0.15, 0.4)
		elseif kind == "ShieldBreak" then
			burst(b, Color3.fromRGB(120, 200, 255), 4, 22, 0.5)
			scatter(b, Color3.fromRGB(160, 220, 255), 16, 10)
			floatingText(b, "¡ESCUDO ROTO!", Color3.fromRGB(255, 90, 90), 30)
			CameraController.Shake(1, 0.3)
		elseif kind == "Grabbed" then
			local hrp = b and b:FindFirstChild("HumanoidRootPart")
			if hrp then
				floatingText(hrp.Position, "¡AGARRE!", Color3.fromRGB(120, 255, 150), 24)
			end
		elseif kind == "Swap" then
			for _, model in { a, b } do
				local hrp = model and model:FindFirstChild("HumanoidRootPart")
				if hrp then
					burst(hrp.Position, Color3.new(1, 1, 1), 2, 12, 0.25)
				end
			end
			CameraController.Shake(0.6, 0.15)
		end
	end)

	CollectionService:GetInstanceAddedSignal("Fighter"):Connect(watchFighter)
	for _, model in CollectionService:GetTagged("Fighter") do
		watchFighter(model)
	end
end

return EffectsController
