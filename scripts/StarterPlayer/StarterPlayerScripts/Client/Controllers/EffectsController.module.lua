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

function EffectsController.Start()
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "ClientFX"
	fxFolder.Parent = workspace

	RunService.RenderStepped:Connect(function()
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
			floatingText(d, `{b}%`, Color3.fromRGB(255, 230, 90))
			burst(d, Color3.fromRGB(255, 240, 200), 1, 3 + c / 25, 0.15)
			if c > 60 then
				CameraController.Shake(math.clamp(c / 120, 0.3, 1.5), 0.15)
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
