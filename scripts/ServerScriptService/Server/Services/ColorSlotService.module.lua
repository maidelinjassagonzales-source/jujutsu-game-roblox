-- ColorSlotService: colores alternativos "estilo Smash".
-- Si en la misma arena hay varios luchadores con el mismo personaje (y la misma skin), el primero
-- se queda con sus colores y los demás reciben una paleta alternativa (rojo, azul, verde, amarillo...):
-- ropa y pelo teñidos + contorno del color del jugador para distinguirlos de un vistazo.
local CollectionService = game:GetService("CollectionService")

local ColorSlotService = {}

local PALETTE = {
	Color3.fromRGB(255, 80, 80), -- rojo
	Color3.fromRGB(80, 150, 255), -- azul
	Color3.fromRGB(90, 230, 120), -- verde
	Color3.fromRGB(255, 215, 70), -- amarillo
	Color3.fromRGB(200, 110, 255), -- morado
	Color3.fromRGB(255, 150, 60), -- naranja
}

-- Piezas del cuerpo: no se tiñen (la piel tiene que seguir siendo piel)
local BODY = { Head = true, Torso = true, ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true, HumanoidRootPart = true }

local function tintable(model: Model)
	local list = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Shirt") or d:IsA("Pants") then
			table.insert(list, d)
		elseif d:IsA("BasePart") and not BODY[d.Name] and d.Transparency < 1 and not d:GetAttribute("FX") then
			table.insert(list, d)
		end
	end
	return list
end

local function apply(model: Model, slot: number)
	if (model:GetAttribute("ColorSlot") or 0) == slot then
		return
	end
	model:SetAttribute("ColorSlot", slot)
	local color = PALETTE[((slot - 1) % #PALETTE) + 1]
	for _, obj in tintable(model) do
		local prop = if obj:IsA("BasePart") then "Color" else "Color3"
		local original = obj:GetAttribute("SlotOriginal")
		if original == nil then
			original = (obj :: any)[prop]
			obj:SetAttribute("SlotOriginal", original)
		end
		if slot == 0 then
			(obj :: any)[prop] = original
		elseif prop == "Color3" then
			-- La ropa se multiplica por Color3: un tono claro del color de la paleta
			(obj :: any)[prop] = Color3.new(1, 1, 1):Lerp(color, 0.55)
		else
			(obj :: any)[prop] = original:Lerp(color, 0.6)
		end
	end
	local outline = model:FindFirstChild("SlotOutline")
	if slot == 0 then
		if outline then
			outline:Destroy()
		end
	else
		if not outline then
			outline = Instance.new("Highlight")
			outline.Name = "SlotOutline"
			outline.FillTransparency = 1
			outline.OutlineTransparency = 0.15
			outline.DepthMode = Enum.HighlightDepthMode.Occluded
			outline.Parent = model
		end
		outline.OutlineColor = color
	end
end

local function refresh()
	local groups = {}
	for _, model in CollectionService:GetTagged("Fighter") do
		local arena = model:GetAttribute("ArenaId")
		if model:IsA("Model") and model.Parent and arena and arena ~= "Lobby" then
			if not model:GetAttribute("SlotSince") then
				model:SetAttribute("SlotSince", os.clock())
			end
			local key = `{arena}|{model:GetAttribute("CharacterId")}|{model:GetAttribute("SkinId") or ""}`
			groups[key] = groups[key] or {}
			table.insert(groups[key], model)
		elseif model:IsA("Model") and (model:GetAttribute("ColorSlot") or 0) ~= 0 then
			apply(model, 0)
		end
	end
	for _, list in groups do
		-- Orden estable: el que llegó antes conserva sus colores originales
		table.sort(list, function(a, b)
			local sa, sb = a:GetAttribute("SlotSince"), b:GetAttribute("SlotSince")
			if sa ~= sb then
				return sa < sb
			end
			return a.Name < b.Name
		end)
		for i, model in list do
			apply(model, i - 1)
		end
	end
end

function ColorSlotService.Start()
	task.spawn(function()
		while true do
			pcall(refresh)
			task.wait(0.75)
		end
	end)
end

return ColorSlotService
