-- CharacterRegistry: carga todos los ModuleScripts de la carpeta Characters.
-- Para añadir un luchador nuevo basta con crear otro ModuleScript ahí.
local CharactersFolder = script.Parent:WaitForChild("Characters")

local CharacterRegistry = {}

local byId = {}
local order = {}

for _, module in CharactersFolder:GetChildren() do
	if module:IsA("ModuleScript") then
		local data = require(module)
		byId[data.Id] = data
		table.insert(order, data.Id)
	end
end
table.sort(order)

function CharacterRegistry.Get(id: string?)
	return id and byId[id] or nil
end

function CharacterRegistry.GetOrder(): { string }
	return table.clone(order)
end

return CharacterRegistry
