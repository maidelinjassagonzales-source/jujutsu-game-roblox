-- StateController: copia local (solo lectura) de la colección del jugador:
-- personajes, skins, Pase de Batalla y estadísticas. El servidor la reenvía cuando cambia.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateController = {}

local state = nil
local changed = Instance.new("BindableEvent")
StateController.Changed = changed.Event

local shopRequest: RemoteFunction

function StateController.Get()
	return state
end

-- Hora del servidor (para cuentas atrás de Acceso Anticipado y temporadas)
function StateController.Now(): number
	return workspace:GetServerTimeNow()
end

-- Envía una acción al servidor. Devuelve { ok, msg }.
function StateController.Request(action: string, ...): { ok: boolean, msg: string }
	local ok, response = pcall(shopRequest.InvokeServer, shopRequest, action, ...)
	if not ok or type(response) ~= "table" then
		return { ok = false, msg = "No se pudo contactar con el servidor" }
	end
	return response
end

function StateController.Start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	shopRequest = remotes:WaitForChild("ShopRequest")

	remotes:WaitForChild("EconomyFeedback").OnClientEvent:Connect(function(kind, payload)
		if kind == "State" then
			state = payload
			changed:Fire(state)
		end
	end)

	task.spawn(function()
		local ok, initial = pcall(shopRequest.InvokeServer, shopRequest, "GetState")
		if ok and type(initial) == "table" and not state then
			state = initial
			changed:Fire(state)
		end
	end)
end

return StateController
