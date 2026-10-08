-- Portrait: "sprites" 3D de los personajes dentro de un ViewportFrame.
-- Usa los modelos que el servidor deja en ReplicatedStorage.Portraits (con pelo, armas, colores...).
--   Portrait.Create(parent, characterId, "Bust" | "Full", props?) -> ViewportFrame
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Portrait = {}

local function getTemplate(characterId: string): Model?
	local folder = ReplicatedStorage:FindFirstChild("Portraits") or ReplicatedStorage:WaitForChild("Portraits", 10)
	return folder and folder:FindFirstChild(characterId) :: Model?
end

function Portrait.Create(parent: Instance, characterId: string, mode: string?, props): ViewportFrame
	local viewport = Instance.new("ViewportFrame")
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(170, 170, 180)
	viewport.LightColor = Color3.new(1, 1, 1)
	viewport.LightDirection = Vector3.new(-0.5, -1, 0.8)
	for k, v in props or {} do
		(viewport :: any)[k] = v
	end
	viewport.Parent = parent

	local camera = Instance.new("Camera")
	camera.FieldOfView = if mode == "Full" then 30 else 22
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	task.spawn(function()
		local template = getTemplate(characterId)
		if not template or not viewport.Parent then
			return
		end
		local world = Instance.new("WorldModel")
		world.Parent = viewport
		local model = template:Clone()
		model.Parent = world
		local head = model:FindFirstChild("Head") :: BasePart?
		local torso = model:FindFirstChild("Torso") :: BasePart?
		if mode == "Full" and torso then
			-- Cuerpo entero girando despacio (para la tienda)
			local angle = math.rad(25)
			local target = torso.Position + Vector3.new(0, 0.3, 0)
			local conn
			conn = RunService.RenderStepped:Connect(function(dt)
				if not viewport.Parent then
					conn:Disconnect()
					return
				end
				angle += dt * 0.6
				camera.CFrame = CFrame.lookAt(target + Vector3.new(math.sin(angle) * 13, 1.5, -math.cos(angle) * 13), target)
			end)
		elseif head then
			-- Busto: de frente y un poco ladeado (la cara del rig mira a -Z)
			local target = head.Position + Vector3.new(0, -0.15, 0)
			camera.CFrame = CFrame.lookAt(target + Vector3.new(1.4, 0.5, -5.2), target)
		end
	end)
	return viewport
end

return Portrait
