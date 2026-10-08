-- EnvMeshes: coloca los modelos de escenario hechos en Blender (ServerStorage.MeshLibrary + ModelConfig.Environment).
-- Todas las funciones devuelven nil si la librería no está importada (los builders usan entonces sus piezas simples).
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Copia fresca del módulo: la Command Bar de Studio (instalador) cachea los require
local ModelConfig = (function()
	local m = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModelConfig")
	local c = m:Clone()
	c.Parent = m.Parent
	local ok, result = pcall(require, c)
	c:Destroy()
	return if ok then result else require(m)
end)()

local EnvMeshes = {}

local function library()
	return ServerStorage:FindFirstChild("MeshLibrary")
end

function EnvMeshes.Available(): boolean
	return library() ~= nil
end

-- base = CFrame del origen del objeto en Blender; scale = número o Vector3 (x, alto, z)
function EnvMeshes.Place(parent: Instance, name: string, base: CFrame, scale, props): MeshPart?
	local lib = library()
	local spec = ModelConfig.Environment[name]
	local template = lib and spec and lib:FindFirstChild(spec.Mesh) :: MeshPart?
	if not template then
		return nil
	end
	local s = if typeof(scale) == "Vector3" then scale else Vector3.one * (scale or 1)
	local p = template:Clone()
	p.Anchored = true
	p.Size = spec.Size * s
	p.CFrame = base * CFrame.new(spec.Offset * s)
	p.Color = spec.Color
	p.Material = spec.Material
	p.CanCollide = false
	p.CanTouch = false
	p.CastShadow = true
	for k, v in props or {} do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

function EnvMeshes.Tree(parent: Instance, pos: Vector3, scale: number, rotY: number?)
	local base = CFrame.new(pos) * CFrame.Angles(0, rotY or 0, 0)
	local trunk = EnvMeshes.Place(parent, "SakuraTrunk", base, scale, { CanCollide = true })
	local canopy = EnvMeshes.Place(parent, "SakuraCanopy", base, scale, { CastShadow = true, CanQuery = false })
	if canopy then
		CollectionService:AddTag(canopy, "SakuraCanopy") -- de aquí caen los pétalos (cliente)
	end
	return trunk
end

-- width = distancia entre pilares (el modelo base mide 10); se cruza en dirección Z (sideways = en X)
function EnvMeshes.Torii(parent: Instance, pos: Vector3, width: number, height: number, red: Color3?, sideways: boolean?)
	local base = CFrame.new(pos) * CFrame.Angles(0, if sideways then math.rad(90) else 0, 0)
	local s = Vector3.new(width / 10, height / 11.5, math.max(1, width / 14))
	local body = EnvMeshes.Place(parent, "ToriiRed", base, s, { CanCollide = true, Color = red })
	EnvMeshes.Place(parent, "ToriiBlack", base, s)
	return body
end

function EnvMeshes.Lantern(parent: Instance, pos: Vector3, scale: number?)
	local base = CFrame.new(pos)
	local body = EnvMeshes.Place(parent, "StoneLantern", base, scale or 0.9, { CanCollide = true })
	local glow = EnvMeshes.Place(parent, "StoneLanternLight", base, scale or 0.9)
	if glow then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 180, 110)
		light.Range = 18
		light.Brightness = 1.6
		light.Parent = glow
	end
	return body
end

-- Puesto de comida: devuelve el mostrador (para colgarle el ProximityPrompt)
function EnvMeshes.Yatai(parent: Instance, cframe: CFrame, scale: number, roofColor: Color3, norenColor: Color3)
	local body = EnvMeshes.Place(parent, "Yatai", cframe, scale, { CanCollide = true })
	if not body then
		return nil
	end
	EnvMeshes.Place(parent, "YataiRoof", cframe, scale, { Color = roofColor })
	EnvMeshes.Place(parent, "YataiNoren", cframe, scale, { Color = norenColor })
	local lamps = EnvMeshes.Place(parent, "YataiLamps", cframe, scale)
	if lamps then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 150, 110)
		light.Range = 22
		light.Brightness = 1.4
		light.Parent = lamps
	end
	return body
end

-- Caseta japonesa (tienda / pase): devuelve el mostrador (madera) para colgarle el ProximityPrompt
function EnvMeshes.Shop(parent: Instance, cframe: CFrame, scale: number, clothColor: Color3)
	local body = EnvMeshes.Place(parent, "ShopWood", cframe, scale, { CanCollide = true })
	if not body then
		return nil
	end
	EnvMeshes.Place(parent, "ShopRoof", cframe, scale)
	EnvMeshes.Place(parent, "ShopCloth", cframe, scale, { Color = clothColor })
	EnvMeshes.Place(parent, "ShopGoods", cframe, scale)
	local lamps = EnvMeshes.Place(parent, "ShopLamps", cframe, scale)
	if lamps then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 160, 110)
		light.Range = 24
		light.Brightness = 1.6
		light.Parent = lamps
	end
	return body
end

-- Tejado japonés con aleros curvos ajustado a una huella (ancho x fondo) y una altura
function EnvMeshes.Roof(parent: Instance, cframe: CFrame, width: number, depth: number, height: number, color: Color3?)
	local spec = ModelConfig.Environment.Roof
	if not spec then
		return nil
	end
	local s = Vector3.new(width / spec.Size.X, height / spec.Size.Y, depth / spec.Size.Z)
	return EnvMeshes.Place(parent, "Roof", cframe, s, { Color = color or spec.Color })
end

function EnvMeshes.Rock(parent: Instance, cframe: CFrame, scale)
	return EnvMeshes.Place(parent, "Rock", cframe, scale)
end

return EnvMeshes
