-- RewardsController: ventana "🎁 Premios" (calendario diario de 7 días + canjear códigos).
-- Se abre sola al entrar si la diaria está disponible y añade un botón con aviso al menú.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local RewardsConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RewardsConfig"))
local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local StateController = require(script.Parent:WaitForChild("StateController"))
local CurrencyController = require(script.Parent:WaitForChild("CurrencyController"))

local player = Players.LocalPlayer

local RewardsController = {}

local frame: Frame
local dayCards = {}
local claimButton: TextButton
local streakLabel: TextLabel
local progressFill: Frame
local progressLabel: TextLabel
local menuBadge: TextLabel

local function status(): (number, boolean)
	local state = StateController.Get()
	local login = state and state.Login or { LastDay = 0, Streak = 0 }
	local today = RewardsConfig.Today(StateController.Now())
	if login.LastDay == today then
		return login.Streak, true
	end
	local streak = if login.LastDay == today - 1 then login.Streak % #RewardsConfig.Daily + 1 else 1
	return streak, false
end

local function rewardText(r): string
	local parts = {}
	if r.Coins then
		table.insert(parts, `{UI.formatNumber(r.Coins)} 呪`)
	end
	if r.Gems then
		table.insert(parts, `{r.Gems} 晶`)
	end
	if r.XP then
		table.insert(parts, `{r.XP} XP`)
	end
	return table.concat(parts, "\n")
end

local function refresh()
	local day, claimed = status()
	local done = if claimed then day else day - 1
	for i, card in dayCards do
		local isDone = i <= done
		local current = i == day and not claimed
		local stroke = card.Frame:FindFirstChildOfClass("UIStroke")
		stroke.Color = if current then Color3.fromRGB(120, 255, 140) elseif isDone then UI.Colors.Green else card.BaseStroke
		stroke.Thickness = if current then 4 else 2
		card.Check.Visible = isDone
		card.Lock.Visible = not isDone and not current
		card.Shade.Visible = not current and not isDone
		card.Glow.Visible = current
	end
	progressFill.Size = UDim2.fromScale(done / #RewardsConfig.Daily, 1)
	progressLabel.Text = `STREAK {done}/{#RewardsConfig.Daily}`
	claimButton.Text = if claimed then "CLAIMED · COME BACK TOMORROW" else `CLAIM DAY {day}!`
	claimButton.BackgroundColor3 = if claimed then UI.Colors.Disabled else Color3.fromRGB(60, 200, 90)
	streakLabel.Text = if player:GetAttribute("VIP")
		then "VIP: +50% Coins on every daily reward"
		else "Get VIP for +50% Coins on the daily reward · Miss a day and the streak resets to day 1"
	if menuBadge then
		menuBadge.Visible = not claimed
	end
end

function RewardsController.Open()
	UI.show(frame)
	refresh()
end

function RewardsController.Toggle()
	if frame.Visible then
		frame.Visible = false
	else
		RewardsController.Open()
	end
end

function RewardsController.Start()
	local gui = UI.screenGui("Rewards", 10)
	local content
	frame, content = UI.modal(gui, "🎁 Daily Rewards", UDim2.fromOffset(680, 500), UI.Colors.Gold)

	-- Progreso de la racha
	local bar = UI.make("Frame", { Position = UDim2.fromOffset(150, 4), Size = UDim2.new(1, -150, 0, 18), BackgroundColor3 = Color3.fromRGB(25, 22, 36) }, content)
	UI.corner(bar, 9)
	progressFill = UI.make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(60, 200, 90) }, bar)
	UI.corner(progressFill, 9)
	progressLabel = UI.label(content, { Size = UDim2.fromOffset(140, 26), Text = "", TextSize = 18, Font = Enum.Font.LuckiestGuy, TextColor3 = UI.Colors.Gold })

	-- Días 1-6 en rejilla 3x2 y el día 7 grande y dorado a la derecha
	local function dayCard(i, reward, pos: UDim2, size: UDim2, big: boolean)
		local base = if big then Color3.fromRGB(255, 190, 40) elseif reward.Gems then Color3.fromRGB(50, 120, 230) else Color3.fromRGB(120, 70, 190)
		local card = UI.make("Frame", { Position = pos, Size = size, BackgroundColor3 = base }, content)
		UI.corner(card, 12)
		local baseStroke = base:Lerp(Color3.new(1, 1, 1), 0.4)
		UI.stroke(card, baseStroke, 2)
		UI.make("UIGradient", { Rotation = 90, Color = ColorSequence.new(base:Lerp(Color3.new(1, 1, 1), 0.2), base:Lerp(Color3.new(0, 0, 0), 0.45)) }, card)
		local glow = UI.make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 30, 1, 30), BackgroundTransparency = 1,
			Image = "rbxasset://textures/ui/LuaApp/graphic/shimmer.png", ImageColor3 = Color3.fromRGB(150, 255, 160), ImageTransparency = 0.6, ZIndex = 0, Visible = false,
		}, card)
		local title = UI.label(card, {
			Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, if big then 34 else 22), Text = `DAY {i}`,
			TextSize = if big then 30 else 18, Font = Enum.Font.LuckiestGuy, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.2,
		})
		local iconSide = if big then 110 else 46
		UI.icon(card, if big then "Chest" elseif reward.Gems then "GemBig" else "CoinPile", {
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, title.Size.Y.Offset + 2), Size = UDim2.fromOffset(iconSide, iconSide),
		})
		UI.label(card, {
			AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 4, 1, -4), Size = UDim2.new(1, -8, 0, if big then 54 else 30),
			Text = rewardText(reward), TextSize = if big then 18 else 13, Font = Enum.Font.GothamBlack, TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Bottom, TextStrokeTransparency = 0.3,
		})
		local shade = UI.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, ZIndex = 3 }, card)
		UI.corner(shade, 12)
		local lock = UI.label(card, {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(40, 40), Text = "🔒",
			TextSize = if big then 40 else 28, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4,
		})
		-- Tic verde dibujado con dos barras (no depende de que la fuente tenga el símbolo)
		local check = UI.make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(if big then 70 else 50, if big then 70 else 50),
			BackgroundColor3 = Color3.fromRGB(40, 190, 80), ZIndex = 4,
		}, card)
		UI.corner(check, 40)
		UI.stroke(check, Color3.new(1, 1, 1), 3)
		local k = if big then 1.4 else 1
		UI.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.36, 0, 0.58, 0), Size = UDim2.fromOffset(14 * k, 5 * k), Rotation = 45, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 5 }, check)
		UI.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.58, 0, 0.48, 0), Size = UDim2.fromOffset(26 * k, 5 * k), Rotation = -50, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 5 }, check)
		return { Frame = card, BaseStroke = baseStroke, Shade = shade, Lock = lock, Check = check, Glow = glow }
	end
	local n = #RewardsConfig.Daily
	for i, reward in RewardsConfig.Daily do
		if i == n then
			dayCards[i] = dayCard(i, reward, UDim2.fromOffset(456, 34), UDim2.fromOffset(192, 218), true)
		else
			local col, rowIndex = (i - 1) % 3, (i - 1) // 3
			dayCards[i] = dayCard(i, reward, UDim2.fromOffset(col * 150, 34 + rowIndex * 114), UDim2.fromOffset(140, 104), false)
		end
	end

	claimButton = UI.button(content, "", Color3.fromRGB(60, 200, 90), { Position = UDim2.fromOffset(0, 262), Size = UDim2.new(1, 0, 0, 48), TextSize = 22, Font = Enum.Font.LuckiestGuy })
	UI.stroke(claimButton, Color3.fromRGB(20, 80, 30), 3)
	claimButton.Activated:Connect(function()
		local response = StateController.Request("ClaimDaily")
		CurrencyController.Toast(response.msg, if response.ok then UI.Colors.Gold else UI.Colors.Red)
		task.delay(0.3, refresh)
	end)
	streakLabel = UI.label(content, {
		Position = UDim2.fromOffset(0, 314), Size = UDim2.new(1, 0, 0, 18), TextSize = 12, TextColor3 = UI.Colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	-- Códigos
	UI.icon(content, "Codes", { Position = UDim2.fromOffset(0, 336), Size = UDim2.fromOffset(34, 34) })
	UI.label(content, { Position = UDim2.fromOffset(38, 342), Size = UDim2.new(1, -38, 0, 24), Text = "Redeem code", TextSize = 18, Font = Enum.Font.GothamBlack })
	local box = UI.make("TextBox", {
		Position = UDim2.fromOffset(0, 374), Size = UDim2.new(1, -150, 0, 40), BackgroundColor3 = UI.Colors.Card,
		Text = "", PlaceholderText = "Enter a code (Discord, YouTube, TikTok...)", Font = Enum.Font.GothamBold, TextSize = 16,
		TextColor3 = UI.Colors.Text, PlaceholderColor3 = UI.Colors.Muted, ClearTextOnFocus = false,
	}, content)
	UI.corner(box, 8)
	local redeem = UI.button(content, "Redeem", UI.Colors.Accent, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 374), Size = UDim2.fromOffset(140, 40) })
	redeem.Activated:Connect(function()
		if box.Text == "" then
			return
		end
		local response = StateController.Request("RedeemCode", box.Text)
		CurrencyController.Toast(response.msg, if response.ok then UI.Colors.Green else UI.Colors.Red)
		if response.ok then
			box.Text = ""
		end
	end)

	-- Botón en el menú principal (con punto rojo si hay diaria por reclamar)
	task.spawn(function()
		local playerGui = player:WaitForChild("PlayerGui")
		local menu = playerGui:WaitForChild("MainMenu", 20)
		local column = menu and menu:FindFirstChildWhichIsA("Frame")
		if not column then
			return
		end
		local b = UI.metalButton(column, "Rewards", UI.Colors.Gold, "Rewards", { Size = UDim2.fromOffset(196, 48), LayoutOrder = 0 })
		menuBadge = UI.label(b, {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(24, 24),
			BackgroundTransparency = 0, BackgroundColor3 = UI.Colors.Red, Text = "!", TextSize = 14, Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Center, Visible = false, ZIndex = 3,
		})
		UI.corner(menuBadge, 12)
		b.Activated:Connect(RewardsController.Toggle)
		if UserInputService.TouchEnabled then
			column.Size = UDim2.fromOffset(200, 290)
		end
		refresh()
	end)

	StateController.Changed:Connect(refresh)
	player:GetAttributeChangedSignal("VIP"):Connect(refresh)

	-- Se abre sola al entrar (después de la intro) si hay diaria pendiente
	task.spawn(function()
		local deadline = os.clock() + 30
		while not StateController.Get() and os.clock() < deadline do
			task.wait(0.5)
		end
		while not player:GetAttribute("TitleDone") do
			task.wait(0.3)
		end
		task.wait(if player:GetAttribute("TitleStart") then 12 else 2)
		local _, claimed = status()
		if StateController.Get() and not claimed and player:GetAttribute("Activity") == "Hub" then
			RewardsController.Open()
		end
	end)
end

return RewardsController
