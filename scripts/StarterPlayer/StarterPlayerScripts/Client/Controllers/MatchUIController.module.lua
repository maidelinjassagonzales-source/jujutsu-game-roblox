-- MatchUIController: cuenta atrás, temporizador, eliminaciones y pantalla de victoria (Fase 5).
-- La pantalla de resultados es una zona de "flexeo": muestra al ganador con su skin
-- en grande, su racha y lo que ganó cada uno.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))
local ArenaInfo = require(Shared:WaitForChild("ArenaInfo"))
local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local CharacterShopController = require(script.Parent:WaitForChild("CharacterShopController"))

local player = Players.LocalPlayer

local MatchUIController = {}

local gui: ScreenGui
local bigText: TextLabel
local timerLabel: TextLabel
local results: Frame

local function flash(text: string, color: Color3, duration: number)
	bigText.Text = text
	bigText.TextColor3 = color
	bigText.TextTransparency = 0
	bigText.TextStrokeTransparency = 0.2
	local scale = bigText:FindFirstChildOfClass("UIScale") :: UIScale
	scale.Scale = 1.6
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(duration, function()
		if bigText.Text == text then
			TweenService:Create(bigText, TweenInfo.new(0.3), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

local function showResults(data)
	for _, child in results:GetChildren() do
		child:Destroy()
	end
	results.Visible = true

	-- Escenario de 700x500 que se encoge en pantallas pequeñas
	local stage = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(700, 500),
		BackgroundTransparency = 1,
	}, results)
	UI.autoScale(stage, 560)

	-- En equipos gana todo el equipo (data.Winners = UserIds de los ganadores)
	local won = data.WinnerUserId == player.UserId or (data.Winners ~= nil and table.find(data.Winners, player.UserId) ~= nil)
	UI.label(stage, {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 30), Size = UDim2.new(1, 0, 0, 70),
		Text = if won then "VICTORY!" else "MATCH OVER", TextSize = 60, Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = if won then UI.Colors.Gold else UI.Colors.Text,
		TextStrokeTransparency = 0.3,
	})

	-- Ganador en 3D girando (con su skin y aura): el escaparate de cosméticos
	local viewport = UI.make("ViewportFrame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, -170, 0, 110), Size = UDim2.fromOffset(300, 320),
		BackgroundColor3 = UI.Colors.Panel, BackgroundTransparency = 0.2, Ambient = Color3.fromRGB(200, 200, 200),
		LightColor = Color3.new(1, 1, 1), LightDirection = Vector3.new(-1, -1, -1),
	}, stage)
	UI.corner(viewport, 16)
	UI.stroke(viewport, UI.Colors.Gold, 3)
	local winnerModel: Model? = data.WinnerModel
	if winnerModel and winnerModel.Parent then
		winnerModel.Archivable = true
		local ok, clone = pcall(winnerModel.Clone, winnerModel)
		if ok and clone then
			-- Sin etiquetas: si no, el HUD y la cámara lo tratarían como otro luchador
			for _, tag in CollectionService:GetTags(clone) do
				CollectionService:RemoveTag(clone, tag)
			end
			for _, d in clone:GetDescendants() do
				if d:IsA("BaseScript") then
					d:Destroy()
				elseif d:IsA("BasePart") then
					d.Anchored = true
				end
			end
			local worldModel = UI.make("WorldModel", {}, viewport)
			clone:PivotTo(CFrame.new())
			clone.Parent = worldModel
			local camera = UI.make("Camera", { FieldOfView = 40 }, viewport)
			viewport.CurrentCamera = camera
			local angle = 0
			local conn
			conn = RunService.RenderStepped:Connect(function(dt)
				if not viewport.Parent or not results.Visible then
					conn:Disconnect()
					return
				end
				angle += dt * 0.8
				camera.CFrame = CFrame.lookAt(Vector3.new(math.sin(angle) * 12, 0.5, math.cos(angle) * 12), Vector3.new(0, -0.5, 0))
			end)
		end
	end

	if data.WinnerUserId then
		UI.avatar(viewport, data.WinnerUserId, { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(72, 72), ZIndex = 5 })
	end

	-- Ficha del ganador
	local info = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 170, 0, 110), Size = UDim2.fromOffset(320, 320),
		BackgroundColor3 = UI.Colors.Panel, BackgroundTransparency = 0.15,
	}, stage)
	UI.corner(info, 16)
	UI.make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingTop = UDim.new(0, 12), PaddingRight = UDim.new(0, 14) }, info)
	UI.make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, info)

	local character = CharacterRegistry.Get(data.WinnerCharacterId)
	local skin = data.WinnerSkinId and CatalogConfig.Skins[data.WinnerSkinId]
	local order = 0
	local function line(text: string, size: number, color: Color3?)
		order += 1
		return UI.label(info, {
			Size = UDim2.new(1, 0, 0, size + 6), Text = text, TextSize = size, LayoutOrder = order,
			TextColor3 = color or UI.Colors.Text, TextWrapped = true,
		})
	end
	line(`{data.WinnerName or "?"}`, 22, UI.Colors.Gold)
	line(if character then character.DisplayName else "", 15)
	if skin then
		line(`Skin: {skin.Name}`, 14, if skin.Premium then UI.Colors.Gold else UI.Colors.Muted)
	end
	if (data.Streak or 0) > 1 then
		line(`{data.Streak}-win streak`, 14, Color3.fromRGB(255, 140, 60))
	end
	line(" ", 6)
	line("RANKING", 13, UI.Colors.Muted)
	for _, entry in data.Ranking or {} do
		local c = CharacterRegistry.Get(entry.CharacterId)
		line(`{entry.Place}. {entry.Name}  ·  {if c then c.DisplayName else ""}  ·  {entry.KOs} KO`, 13,
			if entry.UserId == player.UserId then UI.Colors.Gold else UI.Colors.Text)
	end

	-- Llamada a la acción: el momento de máxima emoción es cuando más apetece mejorar
	local cta = UI.button(stage, "View characters and skins", UI.Colors.Accent, {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 446), Size = UDim2.fromOffset(280, 40),
	})
	cta.Activated:Connect(function()
		results.Visible = false
		CharacterShopController.Open(data.WinnerCharacterId)
	end)
end

function MatchUIController.Start()
	gui = UI.screenGui("MatchUI", 8)

	bigText = UI.label(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.new(1, 0, 0, 100),
		TextSize = 72, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center,
		TextTransparency = 1, TextStrokeTransparency = 1,
	})
	UI.make("UIScale", {}, bigText)

	-- Temporizador grande arriba en el centro (estilo Smash) y el logo arriba a la izquierda
	timerLabel = UI.label(gui, {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(240, 64),
		TextSize = 58, Font = Enum.Font.LuckiestGuy, TextXAlignment = Enum.TextXAlignment.Center, Visible = false,
	})
	UI.make("UIStroke", { Thickness = 4, Color = Color3.fromRGB(10, 8, 16) }, timerLabel)
	UI.make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 220)) }, timerLabel)
	UI.autoScale(timerLabel)
	local logo = UI.icon(gui, "Logo", { Position = UDim2.fromOffset(14, 62), Size = UDim2.fromOffset(150, 81), Visible = false })
	UI.autoScale(logo)

	results = UI.make("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35,
		Visible = false, ZIndex = 5,
	}, gui)

	-- Temporizador de la partida (de TU arena)
	task.spawn(function()
		while true do
			task.wait(0.25)
			local character = player.Character
			local info = ArenaInfo.Get(character and character:GetAttribute("ArenaId"))
			local matchState = info and info:GetAttribute("MatchState")
			local endsAt = info and info:GetAttribute("EndsAt") or 0
			timerLabel.Visible = matchState == "Fighting"
			logo.Visible = character ~= nil and (character:GetAttribute("ArenaId") or "Lobby") ~= "Lobby" and not results.Visible
			if matchState == "Fighting" then
				local left = math.max(0, endsAt - workspace:GetServerTimeNow())
				timerLabel.Text = string.format("%d:%02d", left // 60, left % 60)
				timerLabel.TextColor3 = if left <= 30 then UI.Colors.Red else UI.Colors.Text
				if left <= 10 and left > 0 then
					local tick = math.floor(left)
					if timerLabel:GetAttribute("LastTick") ~= tick then
						timerLabel:SetAttribute("LastTick", tick)
						local scale = timerLabel:FindFirstChildOfClass("UIScale") :: UIScale
						local base = scale.Scale
						scale.Scale = base * 1.25
						TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = base }):Play()
					end
				end
			end
			if results.Visible and player:GetAttribute("Activity") ~= "Match" then
				results.Visible = false
			end
		end
	end)

	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MatchFeedback").OnClientEvent:Connect(function(kind, payload, stageName, modeName, roster)
		if kind == "Countdown" then
			results.Visible = false
			task.spawn(function()
				if roster then
					task.wait(2.2) -- la presentación VS (CinematicController) ya muestra modo y escenario
				elseif stageName then
					flash(`{modeName or ""}\n{stageName}`, UI.Colors.Gold, 1.6)
					task.wait(1.4)
				end
				for i = math.max(1, payload - 2), 1, -1 do
					flash(tostring(i), UI.Colors.Text, 0.8)
					task.wait(1)
				end
			end)
		elseif kind == "Start" then
			flash("FIGHT!", UI.Colors.Gold, 1)
		elseif kind == "Eliminated" and typeof(payload) == "Instance" then
			local name = payload:GetAttribute("DisplayName") or payload.Name
			local info = ArenaInfo.Get(player.Character and player.Character:GetAttribute("ArenaId"))
			if info and info:GetAttribute("MatchState") ~= "Fighting" then
				return -- última eliminación: ya sale el ¡GAME!
			end
			flash(if payload == player.Character then "ELIMINATED!" else `{name} eliminated!`, UI.Colors.Red, 1.5)
		elseif kind == "Finish" then
			bigText.TextTransparency = 1 -- el ¡GAME! de la cinemática manda
			bigText.TextStrokeTransparency = 1
		elseif kind == "Results" then
			showResults(payload)
		end
	end)
end

return MatchUIController
