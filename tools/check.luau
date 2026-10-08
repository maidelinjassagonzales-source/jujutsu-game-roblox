local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local bad = 0
local function walk(d)
	for _, n in fs.readDir(d) do
		local p = d .. "/" .. n
		if fs.isDir(p) then walk(p)
		elseif n:match("%.lua$") then
			local ok, err = pcall(luau.compile, fs.readFile(p))
			if not ok then bad += 1; print(p, err) end
		end
	end
end
walk(process.args[1])
print("errores:", bad)
