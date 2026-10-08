local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local src, out = process.args[1], process.args[2]
local game = roblox.deserializePlace(fs.readFile(src))
fs.writeDir(out)
local count = 0
local tree = {}
local function walk(inst, path, depth)
	for _, c in inst:GetChildren() do
		local p = path .. "/" .. c.Name:gsub("[/\\:]", "_")
		if depth < 4 or c:IsA("LuaSourceContainer") then
			table.insert(tree, string.rep("  ", depth) .. c.Name .. " [" .. c.ClassName .. "]")
		end
		if c:IsA("LuaSourceContainer") then
			local ext = c:IsA("ModuleScript") and ".module.lua" or (c:IsA("LocalScript") and ".client.lua" or ".server.lua")
			fs.writeDir(out .. path)
			fs.writeFile(out .. p .. ext, c.Source)
			count += 1
		end
		walk(c, p, depth + 1)
	end
end
for _, svc in game:GetChildren() do
	table.insert(tree, svc.Name .. " [" .. svc.ClassName .. "]")
	walk(svc, "/" .. svc.Name, 1)
end
fs.writeFile(out .. "/_tree.txt", table.concat(tree, "\n"))
print("scripts:", count)
