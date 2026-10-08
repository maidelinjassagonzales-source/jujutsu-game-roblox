-- LightingController: cada escenario tiene su ambiente (hora, niebla, atmósfera).
-- Los cambios de Lighting en el cliente son locales: cada jugador ve el de SU arena.
-- "Shaders": Bloom, ColorCorrection, SunRays y DepthOfField (solo Lobby) + nubes volumétricas y cielo.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StageConfig = require(Shared:WaitForChild("StageConfig"))
local ArenaInfo = require(Shared:WaitForChild("ArenaInfo"))

local player = Players.LocalPlayer

local LightingController = {}

local atmosphere: Atmosphere
local bloom: BloomEffect
local color: ColorCorrectionEffect
local sunRays: SunRaysEffect
local dof: DepthOfFieldEffect
local sky: Sky
local clouds: Clouds
local applied: string? = nil
local defaultSky = nil -- texturas del cielo por defecto (para volver a él)

local function apply(preset)
	local tween = TweenInfo.new(0.8)
	TweenService:Create(Lighting, tween, {
		ClockTime = preset.ClockTime, Brightness = preset.Brightness, Ambient = preset.Ambient,
		OutdoorAmbient = preset.OutdoorAmbient, FogColor = preset.FogColor, FogStart = preset.FogStart, FogEnd = preset.FogEnd,
	}):Play()
	TweenService:Create(atmosphere, tween, {
		Color = preset.AtmosphereColor, Decay = preset.AtmosphereDecay, Density = preset.AtmosphereDensity, Haze = preset.Haze,
	}):Play()
	TweenService:Create(color, tween, {
		TintColor = preset.Tint or Color3.new(1, 1, 1), Saturation = preset.Saturation or 0.1, Contrast = preset.Contrast or 0.08,
	}):Play()
	sunRays.Intensity = preset.SunRays or 0.08
	dof.Enabled = preset.Blur == true
	sky.StarCount = preset.Stars or 0
	local box = preset.Skybox
	if box then
		local side = `rbxassetid://{box.Side}`
		sky.SkyboxBk, sky.SkyboxFt, sky.SkyboxLf, sky.SkyboxRt = side, side, side, side
		sky.SkyboxUp = `rbxassetid://{box.Up}`
		sky.SkyboxDn = `rbxassetid://{box.Down}`
		sky.CelestialBodiesShown = false
	elseif defaultSky then
		for k, v in defaultSky do
			(sky :: any)[k] = v
		end
		sky.CelestialBodiesShown = true
	end
	local c = preset.Clouds
	clouds.Enabled = c ~= nil
	if c then
		TweenService:Create(clouds, tween, { Cover = c.Cover, Density = c.Density, Color = c.Color }):Play()
	end
end

local function ensure(className: string, parent: Instance): any
	local inst = parent:FindFirstChildOfClass(className)
	if not inst then
		inst = Instance.new(className)
		inst.Parent = parent
	end
	return inst
end

local function refresh()
	local character = player.Character
	local key, preset
	if character and character:GetAttribute("MoveMode") == "Free" then
		key, preset = "Lobby", StageConfig.LobbyLighting
	else
		local arenaId = if character then character:GetAttribute("ArenaId") else "Hub"
		local info = ArenaInfo.Get(arenaId)
		local stageId = if info then info:GetAttribute("StageId") else StageConfig.HubStage
		key, preset = stageId, StageConfig.Stages[stageId] and StageConfig.Stages[stageId].Lighting
	end
	if preset and key ~= applied then
		applied = key
		apply(preset)
	end
end

function LightingController.Start()
	atmosphere = ensure("Atmosphere", Lighting)
	atmosphere.Offset = 0.15
	atmosphere.Glare = 0.4
	bloom = ensure("BloomEffect", Lighting)
	bloom.Intensity = 0.7
	bloom.Size = 28
	bloom.Threshold = 1.4
	color = ensure("ColorCorrectionEffect", Lighting)
	sunRays = ensure("SunRaysEffect", Lighting)
	sunRays.Spread = 0.6
	dof = ensure("DepthOfFieldEffect", Lighting)
	dof.FarIntensity = 0.25
	dof.FocusDistance = 40
	dof.InFocusRadius = 60
	dof.NearIntensity = 0
	sky = ensure("Sky", Lighting)
	sky.SunAngularSize = 14
	sky.MoonAngularSize = 9
	sky.CelestialBodiesShown = true
	defaultSky = {
		SkyboxBk = sky.SkyboxBk, SkyboxFt = sky.SkyboxFt, SkyboxLf = sky.SkyboxLf,
		SkyboxRt = sky.SkyboxRt, SkyboxUp = sky.SkyboxUp, SkyboxDn = sky.SkyboxDn,
	}
	clouds = ensure("Clouds", workspace:WaitForChild("Terrain"))
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true

	local function hook(character: Model)
		character:GetAttributeChangedSignal("ArenaId"):Connect(refresh)
		character:GetAttributeChangedSignal("MoveMode"):Connect(refresh)
		refresh()
	end
	player.CharacterAdded:Connect(hook)
	if player.Character then
		hook(player.Character)
	end
	task.spawn(function()
		while true do
			task.wait(2)
			refresh()
		end
	end)
end

return LightingController
