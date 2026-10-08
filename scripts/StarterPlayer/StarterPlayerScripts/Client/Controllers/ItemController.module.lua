-- ItemController: objetos de partida en el cliente.
--   * F (teclado) / cruceta derecha (mando) / botón "OBJETO" en pantalla (móvil) -> usar el objeto
--   * Mantén arriba/abajo al usarlo para lanzarlo hacia arriba/abajo
--   * Marcador abajo en el centro con el objeto que llevas y los usos que le quedan
--   * Los objetos del suelo giran y flotan (solo visual, en tu cliente)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")

local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local MovementController = require(script.Parent:WaitForChild("MovementController"))

local player = Players.LocalPlayer

local ItemController = {}

local NAMES = {
	Bomb = "Cursed Bomb", Kunai = "Kunais", Talisman = "Sealing Talisman",
	Hammer = "Giant Hammer", Katana = "Cursed Katana", Pill = "Revitalizing Pill",
}

local request: RemoteEvent

local function isTouch(): boolean
	if player:GetAttribute("ForceTouchUI") then
		return true
	end
	local last = UserInputService:GetLastInputType()
	return last == Enum.UserInputType.Touch or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
end

function ItemController.Use()
	local character = player.Character
	if not character or not character:GetAttribute("HeldItem") then
		return
	end
	local mv = MovementController.GetMoveVector()
	local dir = if -mv.Z > 0.5 then "Up" elseif mv.Z > 0.5 then "Down" else "Side"
	request:FireServer("UseItem", dir, MovementController.GetFacing())
end

function ItemController.Start()
	request = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CombatRequest")

	ContextActionService:BindAction("UseItem", function(_, state)
		if state == Enum.UserInputState.Begin then
			local character = player.Character
			if character and character:GetAttribute("HeldItem") then
				ItemController.Use()
				return Enum.ContextActionResult.Sink
			end
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.F, Enum.KeyCode.DPadRight)

	-- Marcador del objeto
	local gui = UI.screenGui("ItemHUD", 6)
	local box = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -118), Size = UDim2.fromOffset(300, 46),
		BackgroundColor3 = UI.Colors.Panel, BackgroundTransparency = 0.15, Visible = false,
	}, gui)
	UI.corner(box, 12)
	local stroke = UI.stroke(box, UI.Colors.Gold, 2)
	UI.autoScale(box)
	local nameLabel = UI.label(box, {
		Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -24, 0, 22), TextSize = 17, Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local hintLabel = UI.label(box, {
		Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -24, 0, 16), TextSize = 12, TextColor3 = UI.Colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	-- Botón táctil (móvil): grande, a la izquierda del rombo de ataques
	local touchButton = UI.make("TextButton", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -250, 1, -40), Size = UDim2.fromOffset(86, 86),
		BackgroundColor3 = Color3.fromRGB(150, 70, 220), Text = "ITEM", TextScaled = true, Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.new(1, 1, 1), Visible = false, AutoButtonColor = true,
	}, gui)
	UI.corner(touchButton, 999)
	UI.stroke(touchButton, Color3.new(1, 1, 1), 3)
	UI.make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, touchButton)
	UI.autoScale(touchButton)
	touchButton.Activated:Connect(ItemController.Use)

	RunService.RenderStepped:Connect(function()
		local character = player.Character
		local itemId = character and character:GetAttribute("HeldItem")
		box.Visible = itemId ~= nil
		touchButton.Visible = itemId ~= nil and isTouch()
		if itemId then
			local usesLeft = character:GetAttribute("ItemUses") or 1
			nameLabel.Text = `{NAMES[itemId] or itemId}{if usesLeft > 1 then `  ×{usesLeft}` else ""}`
			local last = UserInputService:GetLastInputType()
			hintLabel.Text = if isTouch() then "Tap ITEM to use it"
				elseif last.Name:find("Gamepad") then "D-pad → to use it (↑/↓ throws it up/down)"
				else "F to use it · W/S + F to throw it up/down"
			stroke.Color = UI.Colors.Gold:Lerp(Color3.new(1, 1, 1), 0.5 + 0.5 * math.sin(os.clock() * 6))
		end
		-- Objetos del suelo: flotan y giran
		local t = os.clock()
		for _, p in CollectionService:GetTagged("ItemPickup") do
			if p:IsA("BasePart") then
				local base = p:GetAttribute("BaseCF") :: CFrame?
				if not base then
					base = p.CFrame
					p:SetAttribute("BaseCF", base)
				end
				p.CFrame = base * CFrame.new(0, math.sin(t * 3 + base.Position.X) * 0.5, 0) * CFrame.Angles(0, t * 2.5, 0)
			end
		end
	end)
end

return ItemController
