-- RewardsService: recompensa diaria (racha de 7 días) y canje de códigos. Todo validado en el servidor.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RewardsConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RewardsConfig"))

local RewardsService = {}
RewardsService.Handlers = {}

local services

local function result(ok: boolean, msg: string)
	return { ok = ok, msg = msg }
end

local function grant(player: Player, reward, multiplier: number, reason: string): string
	local parts = {}
	if reward.Coins then
		local coins = math.floor(reward.Coins * multiplier)
		services.EconomyService.AddCurrency(player, "Coins", coins, reason)
		table.insert(parts, `+{coins} 呪`)
	end
	if reward.Gems then
		services.EconomyService.AddCurrency(player, "Gems", reward.Gems, reason)
		table.insert(parts, `+{reward.Gems} 晶`)
	end
	if reward.XP then
		services.EconomyService.AddXP(player, reward.XP)
		table.insert(parts, `+{reward.XP} XP`)
	end
	return table.concat(parts, "  ")
end

-- Día de la racha que toca hoy (1..7) y si ya se ha reclamado
function RewardsService.DailyStatus(data): (number, boolean)
	local today = RewardsConfig.Today(os.time())
	local login = data.Login
	if login.LastDay == today then
		return login.Streak, true
	end
	local streak = if login.LastDay == today - 1 then login.Streak % #RewardsConfig.Daily + 1 else 1
	return streak, false
end

RewardsService.Handlers.ClaimDaily = function(player: Player)
	local data = services.DataService.Get(player)
	if not data then
		return result(false, "Cargando tus datos...")
	end
	local day, claimed = RewardsService.DailyStatus(data)
	if claimed then
		return result(false, "Ya reclamaste la recompensa de hoy. ¡Vuelve mañana!")
	end
	services.DataService.Update(player, function(d)
		d.Login.LastDay = RewardsConfig.Today(os.time())
		d.Login.Streak = day
	end)
	local multiplier = 1 + (if player:GetAttribute("VIP") then RewardsConfig.VIPDailyBonus else 0)
	local text = grant(player, RewardsConfig.Daily[day], multiplier, `Diaria:{day}`)
	services.DataService.PushState(player)
	return result(true, `Día {day}: {text}`)
end

RewardsService.Handlers.RedeemCode = function(player: Player, code: any)
	if type(code) ~= "string" or #code > 32 then
		return result(false, "Código no válido")
	end
	code = string.upper((code:gsub("%s", "")))
	local reward = RewardsConfig.Codes[code]
	if not reward or (reward.Expires and os.time() >= reward.Expires) then
		return result(false, "Ese código no existe o ha caducado")
	end
	local data = services.DataService.Get(player)
	if not data then
		return result(false, "Cargando tus datos...")
	end
	if data.RedeemedCodes[code] then
		return result(false, "Ya canjeaste ese código")
	end
	services.DataService.Update(player, function(d)
		d.RedeemedCodes[code] = true
	end)
	local text = grant(player, reward, 1, `Codigo:{code}`)
	services.DataService.PushState(player)
	return result(true, `Código {code}: {text}`)
end

-- Recompensa del tutorial (una sola vez)
RewardsService.Handlers.CompleteTutorial = function(player: Player)
	local data = services.DataService.Get(player)
	if not data then
		return result(false, "")
	end
	if data.Tutorial.Done then
		return result(true, "Tutorial completado")
	end
	services.DataService.Update(player, function(d)
		d.Tutorial.Done = true
	end)
	local text = grant(player, { Coins = 1000, Gems = 30 }, 1, "Tutorial")
	services.DataService.PushState(player)
	return result(true, `¡Tutorial completado! {text}`)
end

function RewardsService.Start(s)
	services = s
end

return RewardsService
