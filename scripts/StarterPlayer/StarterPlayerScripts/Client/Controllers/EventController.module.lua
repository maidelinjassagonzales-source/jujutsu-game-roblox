-- EventController: lo visual de los EVENTOS ALEATORIOS.
--   * Anuncio a pantalla completa cuando empieza (kanji + nombre a pincel)
--   * Marcador con el evento activo, qué da y la cuenta atrás
--   * Luna de Sangre: el cielo se tiñe de rojo · objetos del evento que giran y flotan
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local Sfx = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Sfx"))

local EventController = {}

local KANJI = { BloodMoon = "血月", XPRush = "修行", CurseRain = "呪雨", GemFall = "晶雨", Fortune = "幸運" }

local info: Configuration
local banner: Frame
local bannerName: TextLabel
local bannerDesc: TextLabel
local bannerTime: TextLabel
local bannerKanji: TextLabel
local announce: Frame
local announceKanji: TextLabel
local announceName: TextLabel
local announceDesc: TextLabel
local tint: ColorCorrectionEffect

local function showAnnouncement(id: string)
	local color = info:GetAttribute("Color") or Color3.new(1, 1, 1)
	announceKanji.Text = KANJI[id] or "祭"
	announceKanji.TextColor3 = color
	announceName.Text = string.upper(info:GetAttribute("Name") or "")
	announceDesc.Text = info:GetAttribute("Description") or ""
	announce.Visible = true
	local s = announce:FindFirstChildOfClass("UIScale") :: UIScale
	s.Scale = 2
	for _, l in { announceKanji, announceName, announceDesc } do
		l.TextTransparency = 0
		l.TextStrokeTransparency = 0.2
	end
	TweenService:Create(s, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	Sfx.Play("Domain", nil, 0.6)
	task.delay(3.2, function()
		for _, l in { announceKanji, announceName, announceDesc } do
			TweenService:Create(l, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
		task.wait(0.55)
		announce.Visible = false
	end)
end

-- En plena batalla (partida o historia) no se enseñan los avisos de eventos: tapan el combate
local function inBattle(): boolean
	local player = game:GetService("Players").LocalPlayer
	local activity = player:GetAttribute("Activity")
	return activity == "Match" or activity == "Story"
end

local function refresh(announceIt: boolean)
	local id = info:GetAttribute("Id")
	local active = id ~= nil and (info:GetAttribute("EndsAt") or 0) > os.time() - 2
	banner.Visible = active and not inBattle()
	if announceIt and inBattle() then
		announceIt = false
	end
	if active then
		local color = info:GetAttribute("Color") or Color3.new(1, 1, 1)
		bannerName.Text = info:GetAttribute("Name") or ""
		bannerDesc.Text = info:GetAttribute("Description") or ""
		bannerKanji.Text = KANJI[id] or "祭"
		bannerKanji.TextColor3 = color
		local stroke = banner:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = color
		end
		if announceIt then
			showAnnouncement(id)
		end
	end
	-- Luna de Sangre: tinte rojo
	TweenService:Create(tint, TweenInfo.new(1.5), {
		TintColor = if active and id == "BloodMoon" then Color3.fromRGB(255, 190, 190) else Color3.new(1, 1, 1),
		Saturation = if active and id == "BloodMoon" then 0.15 else 0,
	}):Play()
end

function EventController.Start()
	info = ReplicatedStorage:WaitForChild("EventInfo", 30) :: Configuration
	if not info then
		return
	end
	tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "EventTint"
	tint.Parent = Lighting

	local gui = UI.screenGui("EventHUD", 7)
	-- Marcador del evento (arriba a la izquierda, debajo de los botones de Roblox)
	banner = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 104), Size = UDim2.fromOffset(380, 54),
		BackgroundColor3 = Color3.new(1, 1, 1), Visible = false,
	}, gui)
	UI.autoScale(banner)
	UI.corner(banner, 12)
	UI.gradient(banner, Color3.fromRGB(50, 20, 40), Color3.fromRGB(14, 10, 18))
	UI.stroke(banner, Color3.new(1, 1, 1), 2)
	bannerKanji = UI.label(banner, {
		Position = UDim2.fromOffset(8, 4), Size = UDim2.fromOffset(60, 46), TextScaled = true, Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3,
	})
	local evTag = UI.label(banner, {
		Position = UDim2.fromOffset(76, 4), Size = UDim2.fromOffset(60, 14), Text = "EVENT", TextSize = 10, Font = Enum.Font.GothamBlack,
		TextColor3 = UI.Colors.Gold,
	})
	evTag.TextXAlignment = Enum.TextXAlignment.Left
	bannerName = UI.label(banner, { Position = UDim2.fromOffset(76, 16), Size = UDim2.new(1, -170, 0, 20), TextSize = 17, Font = UI.TitleFont, TextStrokeTransparency = 0.5 })
	bannerDesc = UI.label(banner, { Position = UDim2.fromOffset(76, 35), Size = UDim2.new(1, -90, 0, 14), TextSize = 11, TextColor3 = UI.Colors.Muted, TextTruncate = Enum.TextTruncate.AtEnd })
	bannerTime = UI.label(banner, {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), Size = UDim2.fromOffset(80, 24), TextSize = 20,
		Font = Enum.Font.GothamBlack, TextColor3 = UI.Colors.Gold, TextXAlignment = Enum.TextXAlignment.Right,
	})

	-- Anuncio grande al empezar
	announce = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.fromOffset(800, 230), BackgroundTransparency = 1,
		Visible = false, ZIndex = 20,
	}, gui)
	UI.make("UIScale", {}, announce)
	announceKanji = UI.label(announce, { Size = UDim2.new(1, 0, 0, 120), TextScaled = true, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 21 })
	UI.make("UIStroke", { Thickness = 5, Color = Color3.new(0, 0, 0) }, announceKanji)
	announceName = UI.label(announce, {
		Position = UDim2.fromOffset(0, 120), Size = UDim2.new(1, 0, 0, 60), TextScaled = true, Font = UI.TitleFont,
		TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 21,
	})
	UI.make("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, announceName)
	announceDesc = UI.label(announce, {
		Position = UDim2.fromOffset(0, 184), Size = UDim2.new(1, 0, 0, 30), TextSize = 22, Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 21, TextColor3 = UI.Colors.Gold,
	})

	info:GetAttributeChangedSignal("Id"):Connect(function()
		refresh(info:GetAttribute("Id") ~= nil)
	end)
	refresh(false)

	-- Cuenta atrás + objetos del evento flotando y girando (solo visual, en tu cliente)
	RunService.RenderStepped:Connect(function()
		if banner.Visible and inBattle() then
			banner.Visible = false
			announce.Visible = false
		elseif not banner.Visible and not inBattle() and info:GetAttribute("Id") ~= nil
			and (info:GetAttribute("EndsAt") or 0) > os.time() then
			banner.Visible = true -- al volver de la batalla, vuelve el marcador (sin el anuncio grande)
		end
		if banner.Visible then
			local left = math.max(0, (info:GetAttribute("EndsAt") or 0) - os.time())
			bannerTime.Text = string.format("%d:%02d", left // 60, left % 60)
			if left <= 0 then
				banner.Visible = false
			end
		end
		local t = os.clock()
		for _, p in CollectionService:GetTagged("EventPickup") do
			if p:IsA("BasePart") then
				local base = p:GetAttribute("BaseCF") :: CFrame?
				if not base then
					base = p.CFrame
					p:SetAttribute("BaseCF", base)
				end
				p.CFrame = base * CFrame.new(0, math.sin(t * 3 + base.Position.X) * 0.6, 0) * CFrame.Angles(0, t * 2, 0)
			end
		end
	end)
end

return EventController
