-- BattlePassController: ventana del Pase de Batalla con ruta gratuita y premium (Fase 4).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BattlePassConfig = require(Shared:WaitForChild("BattlePassConfig"))
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))
local EconomyConfig = require(Shared:WaitForChild("EconomyConfig"))
local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local StateController = require(script.Parent:WaitForChild("StateController"))
local CurrencyController = require(script.Parent:WaitForChild("CurrencyController"))
local Portrait = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Portrait"))

local player = Players.LocalPlayer

local BattlePassController = {}

local frame: Frame
local header: Frame
local track: ScrollingFrame
local claimableChanged = Instance.new("BindableEvent")
BattlePassController.ClaimableChanged = claimableChanged.Event

local PREMIUM_COLOR = Color3.fromRGB(255, 190, 40)

local function currentTier(): number
	return BattlePassConfig.TierFromXP(player:GetAttribute("BPXP") or 0)
end

local function isClaimed(track: string, tier: number): boolean
	local state = StateController.Get()
	if not state then
		return false
	end
	local bp = state.BattlePass
	local claimed = if track == "Free" then bp.ClaimedFree else bp.ClaimedPremium
	return claimed[tostring(tier)] == true
end

function BattlePassController.ClaimableCount(): number
	local tier = currentTier()
	local premium = player:GetAttribute("BPPremium") == true
	local count = 0
	for t = 1, tier do
		if not isClaimed("Free", t) then
			count += 1
		end
		if premium and not isClaimed("Premium", t) then
			count += 1
		end
	end
	return count
end

local function claim(tier: number, trackName: string)
	local response = StateController.Request("ClaimTier", tier, trackName)
	if not response.ok then
		CurrencyController.Toast(response.msg, UI.Colors.Red)
	end
end

local function rewardIcon(parent: Instance, reward, zIndex: number)
	if reward.Skin then
		local skin = CatalogConfig.Skins[reward.Skin]
		local holder = UI.make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(58, 58),
			BackgroundColor3 = (skin and skin.Aura) or PREMIUM_COLOR, BackgroundTransparency = 0.55, ZIndex = zIndex,
		}, parent)
		UI.corner(holder, 999)
		UI.stroke(holder, (skin and skin.Aura) or PREMIUM_COLOR, 2)
		if skin then
			Portrait.Create(holder, skin.Character, "Bust", { Size = UDim2.fromScale(1, 1), ZIndex = zIndex })
		end
		return
	end
	local iconName = if reward.Gems then "Gems" else "Coins"
	-- Las recompensas grandes usan el arte grande (montón de monedas / gema grande)
	if reward.Gems and reward.Gems >= 100 then
		iconName = "GemBig"
	elseif reward.Coins and reward.Coins >= 400 then
		iconName = "CoinPile"
	end
	UI.icon(parent, iconName, {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(56, 56), ZIndex = zIndex,
	})
end

local function rewardCaption(reward): string
	if reward.Coins then
		return UI.formatNumber(reward.Coins)
	elseif reward.Gems then
		return UI.formatNumber(reward.Gems)
	elseif reward.Skin then
		local skin = CatalogConfig.Skins[reward.Skin]
		return if skin then skin.Name else reward.Skin
	end
	return "?"
end

local function rewardBox(parent: Instance, tier: number, trackName: string, y: number)
	local reward = BattlePassConfig.Tiers[tier][trackName]
	local premiumTrack = trackName == "Premium"
	local premiumOwned = player:GetAttribute("BPPremium") == true
	local reached = tier <= currentTier()
	local unlocked = reached and (not premiumTrack or premiumOwned)
	local claimed = isClaimed(trackName, tier)
	local accent = if premiumTrack then PREMIUM_COLOR else Color3.fromRGB(150, 110, 255)

	local box = UI.make("Frame", {
		Position = UDim2.fromOffset(5, y), Size = UDim2.new(1, -10, 0, 118), BackgroundColor3 = Color3.new(1, 1, 1),
	}, parent)
	UI.corner(box, 10)
	if premiumTrack then
		UI.gradient(box, Color3.fromRGB(92, 66, 22), Color3.fromRGB(40, 28, 12))
	else
		UI.gradient(box, Color3.fromRGB(58, 46, 92), Color3.fromRGB(28, 24, 44))
	end
	if unlocked and not claimed then
		UI.animatedStroke(box, Color3.fromRGB(80, 255, 140), 2.5)
	else
		UI.stroke(box, accent, if premiumTrack then 1.5 else 1).Transparency = 0.35
	end
	if reward.Skin then
		UI.ribbon(box, "SKIN", Color3.fromRGB(230, 60, 120))
	end

	rewardIcon(box, reward, 2)
	UI.label(box, {
		Position = UDim2.fromOffset(2, 64), Size = UDim2.new(1, -4, 0, 20), Text = rewardCaption(reward), TextWrapped = true,
		TextScaled = reward.Skin ~= nil, TextSize = 15, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = if reward.Skin then PREMIUM_COLOR elseif reward.Gems then EconomyConfig.Currencies.Gems.Color else UI.Colors.Text,
		TextStrokeTransparency = 0.5, ZIndex = 3,
	})

	local btnProps = { Position = UDim2.new(0, 6, 1, -28), Size = UDim2.new(1, -12, 0, 22), TextSize = 11, ZIndex = 4 }
	if claimed then
		-- Velo oscuro + sello de "reclamado"
		local veil = UI.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, ZIndex = 5 }, box)
		UI.corner(veil, 10)
		local stamp = UI.label(veil, {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.new(1, -8, 0, 22),
			Text = "CLAIMED", TextSize = 13, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(90, 230, 130),
			TextXAlignment = Enum.TextXAlignment.Center, Rotation = -12, ZIndex = 6, BackgroundColor3 = Color3.fromRGB(10, 40, 20),
			BackgroundTransparency = 0.2,
		})
		UI.corner(stamp, 4)
		UI.stroke(stamp, Color3.fromRGB(90, 230, 130), 1.5)
	elseif unlocked then
		local b = UI.button(box, "CLAIM", UI.Colors.Green, btnProps)
		UI.shine(b, 1.2)
		b.Activated:Connect(function()
			claim(tier, trackName)
		end)
	else
		local veil = UI.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.6, ZIndex = 5 }, box)
		UI.corner(veil, 10)
		UI.label(veil, {
			Position = UDim2.new(0, 0, 1, -26), Size = UDim2.new(1, 0, 0, 20), ZIndex = 6, TextSize = 10,
			Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center,
			Text = if premiumTrack and reached then "PREMIUM ONLY" else `TIER {tier}`,
			TextColor3 = if premiumTrack then PREMIUM_COLOR else UI.Colors.Muted,
		})
	end
end

local function refreshHeader()
	for _, child in header:GetChildren() do
		child:Destroy()
	end
	local season = BattlePassConfig.Season
	local xp = player:GetAttribute("BPXP") or 0
	local tier = currentTier()
	local premium = player:GetAttribute("BPPremium") == true
	local remaining = season.End - StateController.Now()

	-- Insignia de nivel (rombo dorado con el número)
	local badge = UI.make("Frame", {
		Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(56, 56), Rotation = 45, BackgroundColor3 = Color3.new(1, 1, 1),
	}, header)
	UI.corner(badge, 10)
	UI.gradient(badge, Color3.fromRGB(255, 220, 110), Color3.fromRGB(190, 120, 20), 45)
	UI.stroke(badge, Color3.fromRGB(255, 245, 200), 2)
	UI.label(header, {
		Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(56, 56), Text = tostring(tier), TextSize = 26,
		Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3,
		TextStrokeColor3 = Color3.fromRGB(90, 50, 0),
	})

	local x = 84
	local title = UI.label(header, { Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x - 260, 0, 26), Text = season.Name, TextSize = 20, Font = UI.TitleFont, TextStrokeTransparency = 0.5 })
	UI.gradient(title, Color3.fromRGB(255, 245, 210), PREMIUM_COLOR)
	UI.label(header, {
		Position = UDim2.fromOffset(x, 26), Size = UDim2.new(1, -x - 260, 0, 16), TextSize = 12, TextColor3 = UI.Colors.Muted,
		Text = if remaining > 0 then `Ends in {UI.formatDuration(remaining)}` else "Season over",
	})

	local inTier = if tier >= BattlePassConfig.MaxTier then BattlePassConfig.XPPerTier else xp % BattlePassConfig.XPPerTier
	local bar = UI.progressBar(header, inTier / BattlePassConfig.XPPerTier, UI.Colors.Gold, {
		Position = UDim2.fromOffset(x, 48), Size = UDim2.new(1, -x - 260, 0, 18),
	})
	UI.label(bar, {
		Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 12, Font = Enum.Font.GothamBlack,
		Text = `{UI.formatNumber(inTier)} / {UI.formatNumber(BattlePassConfig.XPPerTier)} XP`, TextStrokeTransparency = 0.3, ZIndex = 3,
	})

	local right = { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(240, 40), TextSize = 15 }
	if premium then
		local b = UI.button(header, "PREMIUM ACTIVE", Color3.fromRGB(190, 140, 25), right)
		b.AutoButtonColor = false
		UI.shine(b, 3)
	else
		-- El Premium se paga con Robux (Developer Product): Roblox ya pide confirmación en su ventana
		local b = UI.priceButton(header, "Robux", BattlePassConfig.PremiumRobuxHint, Color3.fromRGB(235, 165, 20), right)
		UI.ribbon(b, "PREMIUM", Color3.fromRGB(230, 60, 120))
		UI.shine(b, 1.6)
		b.Activated:Connect(function()
			if BattlePassConfig.PremiumProductId == 0 then
				CurrencyController.Toast("Premium Pass not set up (put its ID in BattlePassConfig)", UI.Colors.Red)
			else
				MarketplaceService:PromptProductPurchase(player, BattlePassConfig.PremiumProductId)
			end
		end)
		UI.label(header, {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 42), Size = UDim2.fromOffset(240, 16),
			Text = "Includes 500 gems and 2 exclusive skins", TextSize = 11, TextColor3 = PREMIUM_COLOR, Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
	end

	local claimAll = UI.button(header, `Claim all ({BattlePassController.ClaimableCount()})`, UI.Colors.Green, {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 60), Size = UDim2.fromOffset(240, 24), TextSize = 12,
		Visible = BattlePassController.ClaimableCount() > 0,
	})
	UI.shine(claimAll, 1.5)
	claimAll.Activated:Connect(function()
		claimAll.Visible = false
		for t = 1, tier do
			for _, trackName in { "Free", "Premium" } do
				if not isClaimed(trackName, t) and (trackName == "Free" or premium) then
					claim(t, trackName)
					task.wait(0.15)
				end
			end
		end
	end)
end

local function refreshTrack()
	for _, child in track:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	local tier = currentTier()
	for t = 1, BattlePassConfig.MaxTier do
		local reached = t <= tier
		local column = UI.make("Frame", {
			Size = UDim2.new(0, 104, 1, -12), LayoutOrder = t, BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = if reached then 0.2 else 0.5,
		}, track)
		UI.corner(column, 12)
		UI.gradient(column, if reached then Color3.fromRGB(56, 44, 84) else Color3.fromRGB(30, 26, 44), Color3.fromRGB(18, 16, 28))
		if t == tier then
			UI.stroke(column, UI.Colors.Gold, 2)
		end
		-- Número del nivel en una pastilla
		local pill = UI.make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(44, 20),
			Text = tostring(t), TextSize = 13, Font = Enum.Font.GothamBlack,
			BackgroundColor3 = if reached then UI.Colors.Gold else Color3.fromRGB(60, 55, 80),
			TextColor3 = if reached then Color3.fromRGB(60, 35, 0) else UI.Colors.Muted,
		}, column)
		UI.corner(pill, 999)
		rewardBox(column, t, "Free", 30)
		rewardBox(column, t, "Premium", 154)
	end
end

local function refresh()
	claimableChanged:Fire(BattlePassController.ClaimableCount())
	if frame.Visible and StateController.Get() then
		refreshHeader()
		refreshTrack()
	end
end

function BattlePassController.Open()
	if not frame.Visible then
		BattlePassController.Toggle()
	end
end

function BattlePassController.Toggle()
	if frame.Visible then
		frame.Visible = false
	else
		UI.show(frame)
		refresh()
		-- saltar al nivel actual
		local tier = currentTier()
		track.CanvasPosition = Vector2.new(math.max(0, (tier - 2) * 112), 0)
	end
end

function BattlePassController.Start()
	local gui = UI.screenGui("BattlePass", 10)
	local content
	frame, content = UI.modal(gui, "🎫 Battle Pass", UDim2.fromOffset(860, 500), PREMIUM_COLOR)

	header = UI.make("Frame", { Size = UDim2.new(1, 0, 0, 86), BackgroundTransparency = 1 }, content)

	-- Etiquetas fijas de las dos rutas (a la izquierda del carril)
	local rails = UI.make("Frame", { Position = UDim2.fromOffset(0, 120), Size = UDim2.new(0, 34, 1, -120), BackgroundTransparency = 1 }, content)
	for i, info in { { "FREE", Color3.fromRGB(150, 110, 255), 30 }, { "PREMIUM", PREMIUM_COLOR, 154 } } do
		local tag = UI.make("Frame", {
			Position = UDim2.fromOffset(0, info[3]), Size = UDim2.fromOffset(30, 118), BackgroundColor3 = info[2], BackgroundTransparency = 0.15,
		}, rails)
		UI.corner(tag, 8)
		UI.gradient(tag, Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150))
		UI.label(tag, {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(118, 30), Rotation = -90,
			Text = info[1], TextSize = 13, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center,
			TextStrokeTransparency = 0.4,
		})
		if i == 2 then
			UI.icon(tag, "Pass", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -14), Size = UDim2.fromOffset(28, 28) })
		end
	end

	local skip = UI.priceButton(content, "Gems", CatalogConfig.TierSkipGems, UI.Colors.Gems, {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 90), Size = UDim2.fromOffset(150, 24), TextSize = 12,
	})
	UI.label(content, {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -156, 0, 90), Size = UDim2.fromOffset(120, 24),
		Text = "Skip tier", TextSize = 12, Font = Enum.Font.GothamBlack, TextColor3 = UI.Colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	UI.confirmButton(skip, function()
		local response = StateController.Request("SkipTier")
		CurrencyController.Toast(response.msg, if response.ok then UI.Colors.Green else UI.Colors.Red)
	end)

	track = UI.make("ScrollingFrame", {
		Position = UDim2.fromOffset(40, 120), Size = UDim2.new(1, -40, 1, -120), BackgroundTransparency = 1,
		ScrollBarThickness = 6, ScrollingDirection = Enum.ScrollingDirection.X, BorderSizePixel = 0,
		ScrollBarImageColor3 = PREMIUM_COLOR, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
	}, content)
	UI.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
	}, track)
	UI.make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, track)

	StateController.Changed:Connect(refresh)
	for _, attr in { "BPXP", "BPPremium" } do
		player:GetAttributeChangedSignal(attr):Connect(refresh)
	end
end

return BattlePassController
