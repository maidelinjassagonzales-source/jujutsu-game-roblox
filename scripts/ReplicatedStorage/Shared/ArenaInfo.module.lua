-- ArenaInfo: lectura de la información replicada de cada arena (cliente y servidor).
-- El servidor crea ReplicatedStorage.ArenaInfo.<ArenaId> (Configuration) con atributos:
--   StageId, CenterX, Left, Right, Top, Bottom (coordenadas de MUNDO), MatchState, EndsAt
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArenaInfo = {}

function ArenaInfo.Folder(): Folder?
	return ReplicatedStorage:FindFirstChild("ArenaInfo") :: Folder?
end

function ArenaInfo.Get(arenaId: string?): Configuration?
	local folder = ArenaInfo.Folder()
	return if folder and arenaId then folder:FindFirstChild(arenaId) :: Configuration? else nil
end

-- Límites absolutos de la arena: left, right, bottom, top (o nil si no es una arena 2D, p.ej. la obby)
function ArenaInfo.Bounds(arenaId: string?): (number?, number?, number?, number?)
	local info = ArenaInfo.Get(arenaId)
	if not info then
		return nil
	end
	return info:GetAttribute("Left"), info:GetAttribute("Right"), info:GetAttribute("Bottom"), info:GetAttribute("Top")
end

return ArenaInfo
