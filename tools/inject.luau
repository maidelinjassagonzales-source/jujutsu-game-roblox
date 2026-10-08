-- Reinyecta los scripts editados (carpeta src) en el .rbxl. Crea los que no existan.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local src, dir, out = process.args[1], process.args[2], process.args[3]
local game = roblox.deserializePlace(fs.readFile(src))
local Instance = roblox.Instance
local changed, created = 0, 0
local function classFor(file)
	if file:match("%.module%.lua$") then return "ModuleScript", file:gsub("%.module%.lua$", "") end
	if file:match("%.client%.lua$") then return "LocalScript", file:gsub("%.client%.lua$", "") end
	if file:match("%.server%.lua$") then return "Script", file:gsub("%.server%.lua$", "") end
end
local function visit(path, parent)
	for _, name in fs.readDir(path) do
		local full = path .. "/" .. name
		if fs.isDir(full) then
			local child = parent:FindFirstChild(name)
			if not child then
				child = Instance.new("Folder"); child.Name = name; child.Parent = parent; created += 1
			end
			visit(full, child)
		else
			local class, base = classFor(name)
			if class then
				local inst = parent:FindFirstChild(base)
				if not inst then
					inst = Instance.new(class); inst.Name = base; inst.Parent = parent; created += 1
				end
				local source = fs.readFile(full)
				if inst.Source ~= source then inst.Source = source; changed += 1 end
			end
		end
	end
end
for _, svcName in fs.readDir(dir) do
	if fs.isDir(dir .. "/" .. svcName) then
		local svc = game:GetService(svcName)
		visit(dir .. "/" .. svcName, svc)
	end
end
-- Carpeta donde se meten los personajes de la Toolbox (ver FighterService)
local storage = game:GetService("ServerStorage")
if not storage:FindFirstChild("CharacterModels") then
	local f = Instance.new("Folder"); f.Name = "CharacterModels"; f.Parent = storage; created += 1
end
-- Las carpetas creadas como contenedor de scripts que también son scripts: se manejan aparte
fs.writeFile(out, roblox.serializePlace(game))
print("cambiados:", changed, "creados:", created)
