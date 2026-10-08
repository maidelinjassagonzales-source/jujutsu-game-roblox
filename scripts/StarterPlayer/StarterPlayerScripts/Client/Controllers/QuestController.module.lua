-- QuestController: ventana de MISIONES DIARIAS (3 misiones + cofre extra al completarlas todas).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("QuestConfig"))
local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local StateController = require(script.Parent:WaitForChild("StateController"))
local CurrencyController = require(script.Parent:WaitForChild("CurrencyController"))

local QuestController = {}

local GREEN = Color3.fromRGB(80, 230, 130)
local KIND_ICON = { KOs = "Duel", Damage = "FFA", Matches = "Play", Wins = "Rewards", Specials = "Characters", Ults = "Boost", Obby = "Lobby", Roulette = "Chest" }

local frame: Frame
local list: Frame
local resetLabel: TextLabel
local claimableChanged = Instance.new("BindableEvent")
QuestController.ClaimableChanged = claimableChanged.Event

local function quests()
	local st = StateController.Get()
	local q = st and st.Quests
	if not q or q.Day ~= math.floor(StateController.Now() / 86400) then
		return nil
	end
	return q
end

function QuestController.ClaimableCount(): number
	local q = quests()
	if not q then
		return 0
	end
	local n, allClaimed = 0, #q.List > 0
	for _, entry in q.List do
		local quest = QuestConfig.Get(entry.Id)
		if quest and not entry.Claimed and entry.Progress >= quest.Goal then
			n += 1
		end
		allClaimed = allClaimed and entry.Claimed
	end
	if allClaimed and not q.BonusClaimed then
		n += 1
	end
	return n
end

local function request(action: string, ...)
	local response = StateController.Request(action, ...)
	if response.msg and response.msg ~= "" then
		CurrencyController.Toast(response.msg, if response.ok then UI.Colors.Gold else UI.Colors.Red)
	end
end

local function rewardRow(parent: Instance, reward, props)
	local row = UI.make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X }, parent)
	for k, v in props do
		(row :: any)[k] = v
	end
	UI.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center }, row)
	if reward.Coins then
		UI.currencyChip(row, "Coins", reward.Coins, { Size = UDim2.fromOffset(0, 20) })
	end
	if reward.Gems then
		UI.currencyChip(row, "Gems", reward.Gems, { Size = UDim2.fromOffset(0, 20) })
	end
	if reward.XP then
		UI.label(row, { Text = `+{reward.XP} XP`, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20), TextSize = 14, Font = Enum.Font.GothamBlack, TextColor3 = UI.Colors.Gold })
	end
	return row
end

local function refresh()
	claimableChanged:Fire(QuestController.ClaimableCount())
	if not frame.Visible then
		return
	end
	for _, c in list:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local q = quests()
	if not q then
		UI.label(list, { Size = UDim2.new(1, 0, 0, 30), Text = "Cargando misiones...", TextColor3 = UI.Colors.Muted, TextXAlignment = Enum.TextXAlignment.Center })
		return
	end
	local allClaimed = #q.List > 0
	for i, entry in q.List do
		local quest = QuestConfig.Get(entry.Id)
		if quest then
			local done = entry.Progress >= quest.Goal
			allClaimed = allClaimed and entry.Claimed
			local card = UI.make("Frame", { Size = UDim2.new(1, -8, 0, 84), BackgroundColor3 = Color3.new(1, 1, 1), LayoutOrder = i }, list)
			UI.corner(card, 12)
			UI.gradient(card, if done then Color3.fromRGB(30, 70, 45) else Color3.fromRGB(44, 36, 66), Color3.fromRGB(20, 18, 30), 0)
			if done and not entry.Claimed then
				UI.animatedStroke(card, GREEN, 2)
			else
				UI.stroke(card, Color3.fromRGB(110, 100, 140), 1).Transparency = 0.4
			end
			local tile = UI.make("Frame", { Position = UDim2.fromOffset(10, 12), Size = UDim2.fromOffset(60, 60), BackgroundColor3 = Color3.fromRGB(70, 60, 100) }, card)
			UI.corner(tile, 10)
			UI.icon(tile, KIND_ICON[quest.Kind] or "Rewards", { Size = UDim2.fromScale(1, 1) })
			UI.label(card, { Position = UDim2.fromOffset(82, 8), Size = UDim2.new(1, -240, 0, 24), Text = quest.Text, TextSize = 17, Font = Enum.Font.GothamBlack })
			local bar = UI.progressBar(card, entry.Progress / quest.Goal, if done then GREEN else UI.Colors.Gold, {
				Position = UDim2.fromOffset(82, 36), Size = UDim2.new(1, -240, 0, 14),
			})
			UI.label(bar, {
				Size = UDim2.fromScale(1, 1), Text = `{entry.Progress} / {quest.Goal}`, TextSize = 11, Font = Enum.Font.GothamBlack,
				TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3, ZIndex = 3,
			})
			rewardRow(card, quest.Reward, { Position = UDim2.fromOffset(82, 56) })
			local props = { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(130, 40), TextSize = 15 }
			if entry.Claimed then
				UI.button(card, "COBRADA", UI.Colors.Disabled, props)
			elseif done then
				local b = UI.button(card, "COBRAR", UI.Colors.Green, props)
				UI.shine(b, 1.2)
				b.Activated:Connect(function()
					request("ClaimQuest", i)
				end)
			else
				UI.button(card, "EN CURSO", Color3.fromRGB(70, 60, 95), props)
			end
		end
	end
	-- Cofre extra
	local chest = UI.make("Frame", { Size = UDim2.new(1, -8, 0, 70), BackgroundColor3 = Color3.new(1, 1, 1), LayoutOrder = 10 }, list)
	UI.corner(chest, 12)
	UI.gradient(chest, Color3.fromRGB(96, 70, 20), Color3.fromRGB(30, 22, 12), 0)
	UI.stroke(chest, UI.Colors.Gold, 1.5)
	UI.icon(chest, "Chest", { Position = UDim2.fromOffset(10, 5), Size = UDim2.fromOffset(60, 60) })
	UI.label(chest, { Position = UDim2.fromOffset(82, 10), Size = UDim2.new(1, -240, 0, 22), Text = "Cofre: completa las 3 misiones", TextSize = 16, Font = Enum.Font.GothamBlack })
	rewardRow(chest, QuestConfig.AllDoneBonus, { Position = UDim2.fromOffset(82, 38) })
	local props = { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(130, 40), TextSize = 15 }
	if q.BonusClaimed then
		UI.button(chest, "ABIERTO", UI.Colors.Disabled, props)
	elseif allClaimed then
		local b = UI.button(chest, "ABRIR", Color3.fromRGB(235, 165, 20), props)
		UI.shine(b, 1)
		b.Activated:Connect(function()
			request("ClaimQuestBonus")
		end)
	else
		UI.button(chest, "BLOQUEADO", Color3.fromRGB(70, 60, 95), props)
	end
end

function QuestController.Open()
	UI.show(frame)
	if not quests() then
		task.spawn(StateController.Request, "GetQuests")
	end
	refresh()
end

function QuestController.Toggle()
	if frame.Visible then
		frame.Visible = false
	else
		QuestController.Open()
	end
end

function QuestController.Start()
	local gui = UI.screenGui("Quests", 10)
	local content
	frame, content = UI.modal(gui, "📜 Misiones diarias", UDim2.fromOffset(640, 480), Color3.fromRGB(80, 230, 130))
	resetLabel = UI.label(content, { Size = UDim2.new(1, 0, 0, 18), TextSize = 12, TextColor3 = UI.Colors.Muted, Text = "" })
	list = UI.make("Frame", { Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 1, -24), BackgroundTransparency = 1 }, content)
	UI.make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	StateController.Changed:Connect(refresh)
	-- Cuenta atrás hasta las nuevas misiones + pedirlas al entrar
	task.spawn(function()
		while not StateController.Get() do
			task.wait(1)
		end
		StateController.Request("GetQuests")
		while true do
			local now = StateController.Now()
			resetLabel.Text = `Nuevas misiones en {UI.formatDuration(86400 - now % 86400)}`
			task.wait(1)
		end
	end)
	-- Que el aviso del menú se actualice aunque la ventana esté cerrada
	Players.LocalPlayer:GetAttributeChangedSignal("Coins"):Connect(function()
		claimableChanged:Fire(QuestController.ClaimableCount())
	end)
end

return QuestController
