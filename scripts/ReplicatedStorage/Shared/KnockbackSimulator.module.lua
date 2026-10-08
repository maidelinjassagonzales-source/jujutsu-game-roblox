-- KnockbackSimulator: aplica el "tumble" (salir volando) a un personaje.
-- Debe ejecutarse donde vive la física del personaje:
--   * Jugadores -> en su propio cliente (son dueños de su red física)
--   * NPCs / muñecos -> en el servidor
local RunService = game:GetService("RunService")

local Config = require(script.Parent:WaitForChild("CombatConfig"))

local KnockbackSimulator = {}

local active = setmetatable({}, { __mode = "k" }) -- [model] = token

local function stopTumble(model: Model, humanoid: Humanoid?)
	if humanoid then
		humanoid.PlatformStand = false
		if humanoid:GetState() == Enum.HumanoidStateType.Physics then
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		end
	end
	model:SetAttribute("InHitstun", false)
end

function KnockbackSimulator.IsActive(model: Model?): boolean
	return model ~= nil and active[model] ~= nil
end

function KnockbackSimulator.Apply(model: Model, velocity: Vector3, hitstun: number)
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		return
	end

	local token = {}
	active[model] = token
	model:SetAttribute("InHitstun", true)

	-- Estado Physics: el Humanoid deja de frenar y de "pegarse" al suelo (si no, se come el lanzamiento)
	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	hrp.AssemblyLinearVelocity = velocity
	hrp.AssemblyAngularVelocity = Vector3.zero

	local LAUNCH_LOCK = 0.06 -- durante los primeros frames se reafirma la velocidad de salida
	local elapsed = 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if active[model] ~= token or not hrp.Parent then
			conn:Disconnect()
			return
		end
		elapsed += dt

		if elapsed <= LAUNCH_LOCK then
			hrp.AssemblyLinearVelocity = velocity
		else
			-- Decaimiento horizontal (respeta choques con paredes porque parte de la velocidad real)
			local v = hrp.AssemblyLinearVelocity
			local decay = Config.KnockbackDecay * dt
			local vx = if math.abs(v.X) <= decay then 0 else v.X - math.sign(v.X) * decay
			hrp.AssemblyLinearVelocity = Vector3.new(vx, v.Y, 0)
		end
		hrp.AssemblyAngularVelocity = Vector3.zero

		if elapsed >= hitstun then
			conn:Disconnect()
			active[model] = nil
			stopTumble(model, humanoid)

			-- Volver a ponerlo de pie mirando a izquierda/derecha
			local pos = hrp.Position
			local facing = if hrp.CFrame.LookVector.X >= 0 then 1 else -1
			hrp.CFrame = CFrame.lookAt(pos, pos + Vector3.new(facing, 0, 0))
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall) -- sale de Physics; aterriza solo
		end
	end)
end

function KnockbackSimulator.Cancel(model: Model)
	active[model] = nil
	stopTumble(model, model:FindFirstChildOfClass("Humanoid"))
end

return KnockbackSimulator
