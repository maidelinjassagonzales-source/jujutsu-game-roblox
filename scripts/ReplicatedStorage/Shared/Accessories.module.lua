-- Accessories: construye accesorios con Parts simples (pelo, bufandas, vendas...) soldados al rig R6.
-- No necesita subir mallas ni assets: cada pieza es { Body, Shape, Size, Offset, Color, Material }.
--   Body   = parte del cuerpo a la que se suelda ("Head", "Torso", "Left Arm"...)
--   Shape  = "Block" | "Ball" | "Wedge" | "Cylinder"
--   Offset = CFrame relativo a esa parte (la cara del personaje mira a -Z)
local Accessories = {}

local SHAPES = {
	Block = Enum.PartType.Block,
	Ball = Enum.PartType.Ball,
	Wedge = Enum.PartType.Wedge,
	Cylinder = Enum.PartType.Cylinder,
}

function Accessories.Build(model: Model, specs)
	if not specs then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "StyleParts"
	for i, spec in specs do
		local body = model:FindFirstChild(spec.Body or "Head") :: BasePart?
		if body then
			local p = Instance.new("Part")
			p.Name = `Style{i}`
			p.Shape = SHAPES[spec.Shape or "Block"] or Enum.PartType.Block
			p.Size = spec.Size
			p.Color = spec.Color
			p.Material = spec.Material or Enum.Material.SmoothPlastic
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
			p.CanCollide = false
			p.CanQuery = false -- los hitboxes no deben chocar con el pelo
			p.CanTouch = false
			p.Massless = true
			p.CastShadow = false
			p.CFrame = body.CFrame * spec.Offset
			local weld = Instance.new("Weld")
			weld.Part0 = body
			weld.Part1 = p
			weld.C0 = spec.Offset
			weld.Parent = p
			p.Parent = folder
		end
	end
	folder.Parent = model
end

-- Piezas modeladas en Blender (ModelConfig): pelo, armas, sombreros, cuerpos de maldición...
-- library = carpeta con las MeshParts (ServerStorage.MeshLibrary). Devuelve true si se puso alguna.
function Accessories.BuildMeshes(model: Model, pieces, library: Instance?, folderName: string?): boolean
	if not pieces or not library then
		return false
	end
	local folder = Instance.new("Folder")
	folder.Name = folderName or "MeshParts"
	local count = 0
	for _, spec in pieces do
		local body = model:FindFirstChild(spec.Attach) :: BasePart?
		local template = library:FindFirstChild(spec.Mesh) :: MeshPart?
		if body and template then
			local p = template:Clone()
			p.Anchored = false
			p.Size = spec.Size
			p.Color = spec.Color
			p.Material = spec.Material
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.CastShadow = true
			local offset = CFrame.new(spec.Offset)
			p.CFrame = body.CFrame * offset
			local weld = Instance.new("Weld")
			weld.Part0 = body
			weld.Part1 = p
			weld.C0 = offset
			weld.Parent = p
			p.Parent = folder
			count += 1
			for _, hidden in spec.Hide or {} do
				local part = model:FindFirstChild(hidden) :: BasePart?
				if part then
					part.Transparency = 1
					local face = part:FindFirstChildOfClass("Decal")
					if face then
						face:Destroy()
					end
				end
			end
		end
	end
	folder.Parent = model
	return count > 0
end

-- Ayudas para describir peinados en pocas líneas
local rad = math.rad

-- Pelo de pinchos: casquete + N pinchos (cuñas) repartidos por la cabeza
function Accessories.SpikyHair(color: Color3, height: number, spikes: { { number } }?)
	local list = {
		{ Body = "Head", Shape = "Block", Size = Vector3.new(1.32, 0.32, 1.32), Offset = CFrame.new(0, 0.55, 0.02), Color = color },
		{ Body = "Head", Shape = "Block", Size = Vector3.new(1.32, 0.55, 0.25), Offset = CFrame.new(0, 0.3, 0.55), Color = color },
	}
	local layout = spikes or {
		{ -0.4, -0.3, -15 }, { 0, -0.35, 0 }, { 0.4, -0.3, 15 },
		{ -0.35, 0.15, -20 }, { 0.05, 0.2, 5 }, { 0.4, 0.15, 20 },
		{ -0.2, 0.45, -10 }, { 0.25, 0.45, 12 },
	}
	for _, s in layout do
		table.insert(list, {
			Body = "Head", Shape = "Wedge", Size = Vector3.new(0.3, height, 0.4), Color = color,
			Offset = CFrame.new(s[1], 0.7 + height / 2, s[2]) * CFrame.Angles(rad(-10), 0, rad(s[3])),
		})
	end
	return list
end

-- Atajo para describir una pieza en una línea
function Accessories.Part(body: string, size: Vector3, offset: CFrame, color: Color3, shape: string?, material: Enum.Material?)
	return { Body = body, Size = size, Offset = offset, Color = color, Shape = shape, Material = material }
end

-- Arma en la mano derecha (hoja apuntando hacia delante)
function Accessories.Blade(arm: string, length: number, bladeColor: Color3, handleColor: Color3)
	return {
		Accessories.Part(arm, Vector3.new(0.15, 0.35, length), CFrame.new(0, -1.15, -0.4 - length / 2), bladeColor, nil, Enum.Material.Metal),
		Accessories.Part(arm, Vector3.new(0.7, 0.7, 0.15), CFrame.new(0, -1.15, -0.35), Color3.fromRGB(40, 40, 40)),
		Accessories.Part(arm, Vector3.new(0.28, 0.28, 1), CFrame.new(0, -1.15, 0.2), handleColor),
	}
end

-- Junta varias listas de piezas en una sola
function Accessories.Merge(...)
	local out = {}
	for _, list in { ... } do
		for _, item in list do
			table.insert(out, item)
		end
	end
	return out
end

return Accessories
