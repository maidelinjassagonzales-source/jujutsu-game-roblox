-- Sustituye SOLO el código de los scripts indicados (ruta relativa -> archivo), sin tocar nada más del lugar.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local src, out = process.args[1], process.args[2]
local game = roblox.deserializePlace(fs.readFile(src))
local n = 0
for i = 3, #process.args, 2 do
	local path, file = process.args[i], process.args[i + 1]
	local parts = string.split(path, "/")
	local inst = game:GetService(parts[1])
	for j = 2, #parts do
		inst = inst and inst:FindFirstChild(parts[j])
	end
	assert(inst and inst:IsA("LuaSourceContainer"), "No encontrado: " .. path)
	inst.Source = fs.readFile(file)
	n += 1
end
fs.writeFile(out, roblox.serializePlace(game))
print("scripts actualizados:", n)
