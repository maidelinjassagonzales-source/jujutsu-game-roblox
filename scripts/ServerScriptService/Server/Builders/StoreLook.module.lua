-- StoreLook: viste a un luchador con el modelo de su personaje sacado de la Creator Store de Roblox
-- (guardados sin scripts en ServerStorage.StoreCharacters por tools/load_store_chars.lua).
-- Copia ropa, accesorios (pelo, armas...), cara, forma de la cabeza, colores del cuerpo y las piezas
-- extra soldadas al cuerpo (re-soldadas a nuestro rig con el mismo desfase).
local ServerStorage = game:GetService("ServerStorage")

local StoreLook = {}

local STANDARD = {
	Head = true, Torso = true, ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true,
	HumanoidRootPart = true,
}

-- Modelos R15 de la tienda: sus piezas del cuerpo NO son adornos. Cada parte R6 toma el color/material
-- de su equivalente R15, y las piezas R15 no se pegan encima de nuestro cuerpo (eso deformaba al personaje).
local R15_BODY = {
	UpperTorso = true, LowerTorso = true,
	LeftUpperArm = true, LeftLowerArm = true, LeftHand = true, RightUpperArm = true, RightLowerArm = true, RightHand = true,
	LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true, RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
}
local R15_TO_R6 = {
	UpperTorso = "Torso", LowerTorso = "Torso",
	LeftUpperArm = "Left Arm", LeftLowerArm = "Left Arm", LeftHand = "Left Arm",
	RightUpperArm = "Right Arm", RightLowerArm = "Right Arm", RightHand = "Right Arm",
	LeftUpperLeg = "Left Leg", LeftLowerLeg = "Left Leg", LeftFoot = "Left Leg",
	RightUpperLeg = "Right Leg", RightLowerLeg = "Right Leg", RightFoot = "Right Leg",
}
local R15_SOURCE = { -- de qué pieza R15 sale el aspecto de cada parte R6
	Torso = "UpperTorso", ["Left Arm"] = "LeftUpperArm", ["Right Arm"] = "RightUpperArm",
	["Left Leg"] = "LeftUpperLeg", ["Right Leg"] = "RightUpperLeg",
}

local function library(): Instance?
	return ServerStorage:FindFirstChild("CharacterModels") or ServerStorage:FindFirstChild("StoreCharacters")
end

function StoreLook.Has(characterId: string): boolean
	local lib = library()
	return lib ~= nil and lib:FindFirstChild(characterId) ~= nil
end

-- Parte del cuerpo por nombre (ignora Models/Folders que se llamen igual)
local function bodyPart(parent: Instance, name: string): BasePart?
	for _, c in parent:GetChildren() do
		if c.Name == name and c:IsA("BasePart") then
			return c
		end
	end
	return nil
end

local function prepPart(part: BasePart)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
end

-- Coloca cada pieza soldada donde dice su soldadura. Sin esto, fuera del workspace (retratos,
-- podio, pantalla de victoria) el pelo y los accesorios se quedan donde estaban en el modelo original.
function StoreLook.Snap(model: Model)
	-- Accesorios: AddAccessory no siempre crea la soldadura fuera del workspace. Se coloca cada
	-- asa en su attachment del cuerpo (mismo nombre) y, si no tiene soldadura, se le pone una.
	local bodyAtts = {}
	for name in STANDARD do
		local part = model:FindFirstChild(name)
		if part then
			for _, a in part:GetChildren() do
				if a:IsA("Attachment") then
					bodyAtts[a.Name] = a
				end
			end
		end
	end
	for _, acc in model:GetChildren() do
		local handle = acc:IsA("Accessory") and acc:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			for _, ha in handle:GetChildren() do
				local ba = ha:IsA("Attachment") and bodyAtts[ha.Name]
				if ba then
					handle.CFrame = ba.WorldCFrame * ha.CFrame:Inverse()
					local welded = false
					for _, w in handle:GetChildren() do
						if w:IsA("JointInstance") or w:IsA("WeldConstraint") or w:IsA("RigidConstraint") then
							welded = true
						end
					end
					if not welded then
						local weld = Instance.new("Weld")
						weld.Name = "AccessoryWeld"
						weld.Part0 = ba.Parent :: BasePart
						weld.Part1 = handle
						weld.C0 = ba.CFrame
						weld.C1 = ha.CFrame
						weld.Parent = handle
					end
					break
				end
			end
		end
	end
	for _ = 1, 4 do -- varias pasadas para cadenas (pelo soldado a una pieza soldada a la cabeza)
		for _, j in model:GetDescendants() do
			if j:IsA("Weld") or j:IsA("Motor6D") then
				local p0, p1 = j.Part0, j.Part1
				if p0 and p1 and not (STANDARD[p1.Name] and p1.Parent == model) then
					p1.CFrame = p0.CFrame * j.C0 * j.C1:Inverse()
				end
			elseif j:IsA("RigidConstraint") then
				-- (las versiones nuevas de AddAccessory usan esto en vez de una Weld)
				local a0, a1 = j.Attachment0, j.Attachment1
				local p1 = a1 and a1.Parent
				if a0 and p1 and p1:IsA("BasePart") and not (STANDARD[p1.Name] and p1.Parent == model) then
					p1.CFrame = a0.WorldCFrame * a1.CFrame:Inverse()
				end
			end
		end
	end
end

-- Devuelve true si se aplicó
function StoreLook.Apply(model: Model, characterId: string): boolean
	local lib = library()
	return StoreLook.ApplyTemplate(model, lib and lib:FindFirstChild(characterId), characterId)
end

function StoreLook.ApplyTemplate(model: Model, template: Instance?, characterId: string): boolean
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not template or not humanoid then
		return false
	end
	local src = template:Clone()
	for _, d in src:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("ModuleScript") then
			d:Destroy() -- por si acaso: nada de código ajeno
		end
	end

	-- Quitar lo que traiga el rig
	for _, c in model:GetChildren() do
		if c:IsA("Accessory") or c:IsA("Clothing") or c:IsA("ShirtGraphic") or c:IsA("BodyColors") or c:IsA("CharacterMesh") then
			c:Destroy()
		end
	end

	-- Partes del cuerpo: color, material, adjuntos y la cabeza (cara + malla)
	local isR15 = bodyPart(src, "UpperTorso") ~= nil
	for name in STANDARD do
		local a = bodyPart(src, name) or (isR15 and R15_SOURCE[name] and bodyPart(src, R15_SOURCE[name])) or nil
		local b = bodyPart(model, name)
		if a and b and a:IsA("BasePart") and b:IsA("BasePart") and name ~= "HumanoidRootPart" then
			b.Color = a.Color
			b.Material = if a.Material == Enum.Material.Plastic then Enum.Material.SmoothPlastic else a.Material
			b.Transparency = if a.Transparency >= 1 and name ~= "Head" then 0 else a.Transparency
			for _, att in a:GetChildren() do
				if att:IsA("Attachment") and not b:FindFirstChild(att.Name) and not isR15 then
					att:Clone().Parent = b -- (las de R15 están en otras posiciones: el rig R6 ya trae las suyas)
				end
			end
			if name == "Head" then
				-- Cara siempre; la malla de la cabeza solo si el modelo trae una (las cabezas R15 son MeshPart:
				-- si quitáramos la nuestra, la cabeza se quedaría en un bloque)
				local hasMesh = a:FindFirstChildWhichIsA("DataModelMesh") ~= nil
				for _, d in b:GetChildren() do
					if d:IsA("Decal") or (hasMesh and d:IsA("DataModelMesh")) then
						d:Destroy()
					end
				end
				for _, d in a:GetChildren() do
					if d:IsA("Decal") or d:IsA("DataModelMesh") then
						d:Clone().Parent = b
					end
				end
			end
		end
	end

	-- Piezas extra soldadas a una parte estándar: apuntar el desfase y re-soldar luego a la nuestra
	local rewelds = {}
	for _, j in src:GetDescendants() do
		if j:IsA("JointInstance") or j:IsA("WeldConstraint") then
			local p0, p1 = (j :: any).Part0, (j :: any).Part1
			if p0 and p1 then
				local std, other
				if STANDARD[p0.Name] and p0.Parent == src and not (STANDARD[p1.Name] and p1.Parent == src) then
					std, other = p0, p1
				elseif STANDARD[p1.Name] and p1.Parent == src and not (STANDARD[p0.Name] and p0.Parent == src) then
					std, other = p1, p0
				end
				if std and not other:FindFirstAncestorOfClass("Accessory") then
					table.insert(rewelds, { Std = std.Name, Part = other, Offset = std.CFrame:ToObjectSpace(other.CFrame) })
					j:Destroy()
				end
			end
		end
	end

	for _, c in src:GetChildren() do
		if c:IsA("Accessory") then
			for _, p in c:GetDescendants() do
				if p:IsA("BasePart") then
					prepPart(p)
				end
			end
			-- Fuera las soldaduras viejas (apuntan al cuerpo del modelo de la tienda, que se borra)
			local handle = c:FindFirstChild("Handle")
			for _, w in (handle and handle:GetChildren() or {}) do
				if w:IsA("JointInstance") or w:IsA("WeldConstraint") or w:IsA("RigidConstraint") then
					w:Destroy()
				end
			end
			c.Parent = nil -- si sigue dentro del modelo de la tienda, Roblox lo da por "ya puesto"
			humanoid:AddAccessory(c)
		elseif c:IsA("Clothing") or c:IsA("ShirtGraphic") or c:IsA("BodyColors") or c:IsA("CharacterMesh") then
			c.Parent = model
		elseif (c:IsA("BasePart") or c:IsA("Model") or c:IsA("Folder")) and not (c:IsA("BasePart") and (STANDARD[c.Name] or R15_BODY[c.Name])) then
			if STANDARD[c.Name] then
				c.Name = c.Name .. "Extras" -- p.ej. un Model "Head" con el pelo: que no se confunda con la cabeza
			end
			for _, p in (if c:IsA("BasePart") then { c } else {}) do
				prepPart(p)
			end
			for _, p in c:GetDescendants() do
				if p:IsA("BasePart") then
					prepPart(p)
				end
			end
			c.Parent = model
		end
	end
	-- Piezas sueltas (sin ninguna soldadura): a la parte del cuerpo más cercana, con su desfase original
	-- (GetJoints no funciona fuera del workspace: se miran las soldaduras a mano)
	local welded = {}
	for _, r in rewelds do
		welded[r.Part] = true
	end
	for _, j in model:GetDescendants() do
		if j:IsA("JointInstance") or j:IsA("WeldConstraint") then
			local p0, p1 = (j :: any).Part0, (j :: any).Part1
			if p0 then
				welded[p0] = true
			end
			if p1 then
				welded[p1] = true
			end
		end
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and not (STANDARD[d.Name] and d.Parent == model) and not welded[d] and not d:FindFirstAncestorOfClass("Accessory")
			then
			local best, bestDist, bestName = nil, math.huge, nil
			for name in STANDARD do
				local part = bodyPart(template, name)
				if part and name ~= "HumanoidRootPart" then
					local dist = (part.Position - d.Position).Magnitude
					if dist < bestDist then
						best, bestDist, bestName = part, dist, name
					end
				end
			end
			-- En modelos R15 también cuentan sus piezas (brazo superior -> brazo R6, etc.)
			for r15, r6 in R15_TO_R6 do
				local part = bodyPart(template, r15)
				if part then
					local dist = (part.Position - d.Position).Magnitude
					if dist < bestDist then
						best, bestDist, bestName = part, dist, r6
					end
				end
			end
			local ours = bestName and bodyPart(model, bestName)
			if best and ours then
				local weld = Instance.new("Weld")
				weld.Part0 = ours
				weld.Part1 = d
				weld.C0 = best.CFrame:ToObjectSpace(d.CFrame)
				weld.Parent = d
			end
		end
	end
	for _, r in rewelds do
		local ours = bodyPart(model, r.Std)
		if ours and r.Part:IsDescendantOf(model) then
			local weld = Instance.new("Weld")
			weld.Part0 = ours
			weld.Part1 = r.Part
			weld.C0 = r.Offset
			weld.Parent = r.Part
		end
	end
	src:Destroy()
	StoreLook.Snap(model)
	model:SetAttribute("StoreLook", characterId)
	return true
end

return StoreLook
