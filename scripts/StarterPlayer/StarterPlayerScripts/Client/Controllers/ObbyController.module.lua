-- ObbyController: la parte del cliente de la obby "Ascenso Maldito".
--   * Anima plataformas móviles, barras giratorias y plataformas que desaparecen (sincronizado con la
--     hora del servidor, así todos lo ven igual). Las móviles llevan velocidad: te llevan encima.
--   * Trampolines, lava/barras (te devuelven al checkpoint) y caídas al vacío.
--   * Marca los checkpoints y la meta (los valida el servidor).
--   * Marcador arriba: cronómetro, checkpoint, mejor tiempo y botones (checkpoint, reiniciar, salir).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("UI"))
local Sfx = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Sfx"))
local StateController = require(script.Parent:WaitForChild("StateController"))
local CurrencyController = require(script.Parent:WaitForChild("CurrencyController"))

local player = Players.LocalPlayer

local ObbyController = {}

local ORANGE = Color3.fromRGB(255, 170, 60)

local panel: Frame
local timerLabel: TextLabel
local cpLabel: TextLabel
local bestLabel: TextLabel
local finishing = false
local lastBounce = 0
local lastCheckpointAsk = 0
local lastRespawn = 0

local function root(): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function inObby(): boolean
	return player:GetAttribute("InObby") == true
end

local function obbyModel(): Model?
	return workspace:FindFirstChild("Obby") :: Model?
end

local function padFor(index: number): BasePart?
	if index <= 0 then
		for _, p in CollectionService:GetTagged("ObbyStart") do
			return p
		end
		return nil
	end
	for _, p in CollectionService:GetTagged("ObbyCheckpoint") do
		if p:GetAttribute("Index") == index then
			return p
		end
	end
	return nil
end

local function fmt(t: number): string
	return string.format("%d:%04.1f", t // 60, t % 60)
end

-- Volver al último checkpoint (lo hace el propio cliente: es instantáneo)
local function respawn(reason: string?)
	local now = os.clock()
	if now - lastRespawn < 0.6 then
		return
	end
	lastRespawn = now
	local pad = padFor(player:GetAttribute("ObbyCheckpoint") or 0)
	local c = player.Character
	local r = root()
	if not pad or not c or not r then
		return
	end
	local pos = pad.Position + Vector3.new(0, 4, 0)
	c:PivotTo(CFrame.lookAt(pos, pos + Vector3.xAxis))
	r.AssemblyLinearVelocity = Vector3.zero
	Sfx.Play("Click", nil, 0.6, 0.7)
	if reason then
		CurrencyController.Toast(reason, UI.Colors.Muted)
	end
end

-- ¿Está el jugador encima de esta pieza?
local function standingOn(r: BasePart, p: BasePart, margin: number?): boolean
	local rel = p.CFrame:PointToObjectSpace(r.Position)
	local half = p.Size / 2
	local m = margin or 0.5
	return math.abs(rel.X) <= half.X + m and math.abs(rel.Z) <= half.Z + m and rel.Y > 0 and rel.Y < half.Y + 4
end

local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include

local function celebrate(text: string, record: boolean?)
	local gui = panel.Parent :: ScreenGui
	local title = UI.label(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(760, 90),
		Text = if record then "NEW RECORD!" else "OBBY COMPLETE!", TextSize = 58, Font = UI.TitleFont,
		TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0, ZIndex = 20,
	})
	UI.gradient(title, Color3.new(1, 1, 1), ORANGE)
	local s = UI.make("UIScale", { Scale = 2 }, title)
	TweenService:Create(s, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	Sfx.Play("LevelUp", nil, 1)
	CurrencyController.Toast(text, UI.Colors.Gold)
	task.delay(2.6, function()
		TweenService:Create(title, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.wait(0.45)
		title:Destroy()
	end)
end

local function step()
	local t = workspace:GetServerTimeNow()

	-- Plataformas móviles (con velocidad: te llevan encima)
	for _, p in CollectionService:GetTagged("ObbyMover") do
		if p:IsA("BasePart") then
			local origin = p:GetAttribute("Origin") :: CFrame?
			local offset = p:GetAttribute("Offset") :: Vector3?
			local period = p:GetAttribute("Period") or 3
			if origin and offset then
				local w = math.pi * 2 / period
				p.CFrame = origin + offset * math.sin(t * w)
				p.AssemblyLinearVelocity = offset * math.cos(t * w) * w
			end
		end
	end
	-- Barras giratorias
	for _, p in CollectionService:GetTagged("ObbySpinner") do
		if p:IsA("BasePart") then
			local origin = p:GetAttribute("Origin") :: CFrame?
			local speed = p:GetAttribute("Speed") or 1.5
			if origin then
				p.CFrame = origin * CFrame.Angles(0, t * speed, 0)
				p.AssemblyAngularVelocity = Vector3.new(0, speed, 0)
			end
		end
	end
	-- Plataformas que aparecen y desaparecen (parpadean antes de irse)
	for _, p in CollectionService:GetTagged("ObbyFade") do
		if p:IsA("BasePart") then
			local on, off = p:GetAttribute("On") or 2, p:GetAttribute("Off") or 1
			local phase = (t + (p:GetAttribute("Offset") or 0)) % (on + off)
			local visible = phase < on
			p.CanCollide = visible
			if not visible then
				p.Transparency = 0.9
			elseif phase > on - 0.6 then
				p.Transparency = if math.floor(phase * 10) % 2 == 0 then 0.6 else 0.1 -- aviso
			else
				p.Transparency = 0.1
			end
		end
	end

	if not inObby() then
		panel.Visible = false
		return
	end
	panel.Visible = true
	local r = root()
	local c = player.Character
	if not r or not c then
		return
	end

	-- Marcador
	local started = player:GetAttribute("ObbyStartedAt") or t
	timerLabel.Text = fmt(math.max(0, t - started))
	local cp = player:GetAttribute("ObbyCheckpoint") or 0
	local model = obbyModel()
	local total = model and model:GetAttribute("Checkpoints") or 4
	cpLabel.Text = `CHECKPOINT {cp}/{total}`
	local st = StateController.Get()
	local best = st and st.Obby and st.Obby.BestTime or 0
	bestLabel.Text = if best > 0 then `RECORD {fmt(best)}` else "NO RECORD"

	-- Caída al vacío
	local baseY = model and model:GetAttribute("BaseY")
	if baseY and r.Position.Y < baseY then
		respawn("You fell! Back to the checkpoint")
		return
	end

	-- Lava y barras: tocar = volver al checkpoint
	overlap.FilterDescendantsInstances = { c }
	for _, kill in CollectionService:GetTagged("ObbyKill") do
		if kill:IsA("BasePart") and #workspace:GetPartBoundsInBox(kill.CFrame, kill.Size + Vector3.new(0.4, 0.6, 0.4), overlap) > 0 then
			respawn(if kill.Name == "Lava" then "The cursed lava burns!" else "You got swept!")
			return
		end
	end

	-- Trampolines
	for _, pad in CollectionService:GetTagged("ObbyBounce") do
		if pad:IsA("BasePart") and os.clock() - lastBounce > 0.5 and standingOn(r, pad, 0.3) then
			lastBounce = os.clock()
			local v = r.AssemblyLinearVelocity
			r.AssemblyLinearVelocity = Vector3.new(v.X, pad:GetAttribute("Power") or 90, v.Z)
			Sfx.Play("Jump", r, 0.9, 0.8)
		end
	end

	-- Checkpoints (en orden)
	local nextPad = padFor(cp + 1)
	if nextPad and os.clock() - lastCheckpointAsk > 0.5 and (Vector3.new(nextPad.Position.X, 0, nextPad.Position.Z) - Vector3.new(r.Position.X, 0, r.Position.Z)).Magnitude < 5.5
		and math.abs(r.Position.Y - nextPad.Position.Y) < 6 then
		lastCheckpointAsk = os.clock()
		task.spawn(function()
			local response = StateController.Request("ObbyCheckpoint", cp + 1)
			if response.ok and response.msg ~= "" then
				Sfx.Play("LevelUp", nil, 0.6)
				CurrencyController.Toast(response.msg, ORANGE)
			end
		end)
	end

	-- Meta
	if not finishing and cp >= total then
		for _, f in CollectionService:GetTagged("ObbyFinish") do
			if f:IsA("BasePart") and (Vector3.new(f.Position.X, 0, f.Position.Z) - Vector3.new(r.Position.X, 0, r.Position.Z)).Magnitude < 7
				and math.abs(r.Position.Y - f.Position.Y) < 6 then
				finishing = true
				task.spawn(function()
					local response = StateController.Request("ObbyFinish") :: any
					if response.ok then
						celebrate(response.msg, response.Record)
					elseif response.msg ~= "" then
						CurrencyController.Toast(response.msg, UI.Colors.Red)
					end
					task.wait(1)
					finishing = false
				end)
			end
		end
	end
end

function ObbyController.Start()
	local gui = UI.screenGui("ObbyHUD", 6)
	panel = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(520, 76),
		BackgroundColor3 = Color3.new(1, 1, 1), Visible = false,
	}, gui)
	UI.autoScale(panel)
	UI.corner(panel, 14)
	UI.gradient(panel, Color3.fromRGB(60, 36, 20), Color3.fromRGB(16, 12, 10))
	UI.animatedStroke(panel, ORANGE, 2)
	local title = UI.label(panel, {
		Position = UDim2.fromOffset(14, 4), Size = UDim2.new(1, -28, 0, 24), Text = "OBBY · CURSED ASCENT", TextSize = 18,
		Font = UI.TitleFont, TextStrokeTransparency = 0.5,
	})
	UI.gradient(title, Color3.new(1, 1, 1), ORANGE)
	timerLabel = UI.label(panel, {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 2), Size = UDim2.fromOffset(120, 28), Text = "0:00.0",
		TextSize = 24, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = ORANGE,
	})
	cpLabel = UI.label(panel, { Position = UDim2.fromOffset(14, 30), Size = UDim2.fromOffset(160, 16), TextSize = 12, Font = Enum.Font.GothamBlack })
	bestLabel = UI.label(panel, { Position = UDim2.fromOffset(176, 30), Size = UDim2.fromOffset(140, 16), TextSize = 12, Font = Enum.Font.GothamBlack, TextColor3 = UI.Colors.Gold })
	local row = UI.make("Frame", { Position = UDim2.new(0, 14, 1, -28), Size = UDim2.new(1, -28, 0, 24), BackgroundTransparency = 1 }, panel)
	UI.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right }, row)
	local function btn(text: string, color: Color3, fn: () -> ())
		UI.button(row, text, color, { Size = UDim2.fromOffset(120, 24), TextSize = 12 }).Activated:Connect(fn)
	end
	btn("To checkpoint", Color3.fromRGB(90, 70, 140), function()
		respawn(nil)
	end)
	btn("Restart", Color3.fromRGB(200, 120, 40), function()
		StateController.Request("ObbyRestart")
	end)
	btn("Exit", UI.Colors.Red, function()
		StateController.Request("LeaveObby")
	end)

	RunService.Heartbeat:Connect(function()
		local ok, err = pcall(step)
		if not ok then
			warn("[ObbyController]", err)
		end
	end)
end

return ObbyController
