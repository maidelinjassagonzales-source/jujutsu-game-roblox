-- EconomyService: toda modificación de monedas pasa por aquí (servidor autoritativo).
--   * Monedas Malditas por combate (daño, KOs, tiempo jugado) con tope diario
--   * XP y niveles (con goteo F2P de gemas cada N niveles)
--   * Compra de Gemas con Robux (Developer Products) con protección anti-duplicado
--   * Hook GetMultiplier para los boosters de la Fase 4
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local EconomyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EconomyConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local EconomyService = {}

local VALID_CURRENCIES = { Coins = true, Gems = true }
local LEDGER_SIZE = 50
local PURCHASE_HISTORY_SIZE = 100

local feedback: RemoteEvent
local damageBuffer = setmetatable({}, { __mode = "k" }) -- [Player] = daño acumulado aún sin convertir
local lastCombatAt = setmetatable({}, { __mode = "k" }) -- [Player] = os.clock()
local multiplierProviders = {} -- Fase 4: boosters de skins / gamepasses
local xpListeners = {}
local fractionCarry = setmetatable({}, { __mode = "k" }) -- [Player] = { Coins = 0.x, XP = 0.x }

-- fn(player, amount): el Pase de Batalla escucha el XP ganado
function EconomyService.OnXPGained(fn)
	table.insert(xpListeners, fn)
end

-- Aplica el multiplicador conservando decimales entre recompensas,
-- para que un +5% también cuente en recompensas pequeñas (1 moneda * 1.05...).
local function applyMultiplier(player: Player, kind: string, amount: number): number
	local carry = fractionCarry[player] or { Coins = 0, XP = 0 }
	fractionCarry[player] = carry
	local exact = amount * EconomyService.GetMultiplier(player, kind) + carry[kind]
	local whole = math.floor(exact)
	carry[kind] = exact - whole
	return whole
end

local function today(): number
	return math.floor(os.time() / 86400)
end

local function notify(player: Player, payload)
	feedback:FireClient(player, "Reward", payload)
end

local function pushCapped(list, value, cap)
	table.insert(list, value)
	while #list > cap do
		table.remove(list, 1)
	end
end

-- Fase 4 registrará aquí los boosters (+5% por skin de pago, etc.). Devuelve un multiplicador >= 1.
function EconomyService.RegisterMultiplier(fn: (Player, string) -> number)
	table.insert(multiplierProviders, fn)
end

function EconomyService.GetMultiplier(player: Player, kind: string): number
	local total = 1
	for _, fn in multiplierProviders do
		local ok, m = pcall(fn, player, kind)
		if ok and type(m) == "number" and m > 0 then
			total += m - 1
		end
	end
	return total
end

function EconomyService.GetBalance(player: Player, currency: string): number
	local data = DataService.Get(player)
	return if data then data[currency] or 0 else 0
end

function EconomyService.AddCurrency(player: Player, currency: string, amount: number, reason: string): boolean
	if not VALID_CURRENCIES[currency] or amount <= 0 or amount ~= amount then
		return false
	end
	amount = math.floor(amount)
	return DataService.Update(player, function(data)
		data[currency] += amount
		if currency == "Gems" then
			pushCapped(data.GemLedger, { T = os.time(), D = amount, R = reason }, LEDGER_SIZE)
		end
	end)
end

-- Gasto atómico: comprueba saldo y descuenta en el mismo paso.
function EconomyService.SpendCurrency(player: Player, currency: string, amount: number, reason: string): boolean
	if not VALID_CURRENCIES[currency] or amount <= 0 or amount ~= amount then
		return false
	end
	amount = math.floor(amount)
	local success = false
	DataService.Update(player, function(data)
		if data[currency] >= amount then
			data[currency] -= amount
			success = true
			if currency == "Gems" then
				pushCapped(data.GemLedger, { T = os.time(), D = -amount, R = reason }, LEDGER_SIZE)
			end
		end
	end)
	return success
end

function EconomyService.AddXP(player: Player, amount: number)
	if amount <= 0 then
		return
	end
	for _, fn in xpListeners do
		task.spawn(fn, player, math.floor(amount))
	end
	local levelsGained, coinsFromLevels, gemsFromLevels = 0, 0, 0
	local rewards = EconomyConfig.Rewards
	DataService.Update(player, function(data)
		data.XP += math.floor(amount)
		while data.XP >= EconomyConfig.XPForLevel(data.Level) do
			data.XP -= EconomyConfig.XPForLevel(data.Level)
			data.Level += 1
			levelsGained += 1
			coinsFromLevels += rewards.LevelUpCoins
			if data.Level % rewards.GemsEveryNLevels.Every == 0 then
				gemsFromLevels += rewards.GemsEveryNLevels.Gems
			end
		end
	end)
	if levelsGained > 0 then
		EconomyService.AddCurrency(player, "Coins", coinsFromLevels, "LevelUp")
		if gemsFromLevels > 0 then
			EconomyService.AddCurrency(player, "Gems", gemsFromLevels, "LevelUp")
		end
		feedback:FireClient(player, "LevelUp", player:GetAttribute("Level"), coinsFromLevels, gemsFromLevels)
	end
end

-- Recompensa de combate: aplica multiplicadores y (salvo ignoreCap) el tope diario de monedas.
function EconomyService.GrantCombatReward(player: Player, coins: number, xp: number, reason: string, ignoreCap: boolean?)
	local data = DataService.Get(player)
	if not data then
		return
	end

	coins = applyMultiplier(player, "Coins", coins)
	xp = applyMultiplier(player, "XP", xp)

	if data.Daily.Day ~= today() then
		DataService.Update(player, function(d)
			d.Daily.Day = today()
			d.Daily.CombatCoins = 0
		end)
	end
	if not ignoreCap then
		local cap = EconomyConfig.Rewards.DailyCombatCoinCap
		coins = math.clamp(coins, 0, math.max(cap - data.Daily.CombatCoins, 0))
	end

	if coins > 0 then
		if not ignoreCap then
			DataService.Update(player, function(d)
				d.Daily.CombatCoins += coins
			end)
		end
		EconomyService.AddCurrency(player, "Coins", coins, reason)
	end
	if xp > 0 then
		EconomyService.AddXP(player, xp)
	end
	if coins > 0 or xp > 0 then
		notify(player, { Coins = coins, XP = xp, Reason = reason })
	end
end

local function isRewardableVictim(victim: Model): boolean
	if Players:GetPlayerFromCharacter(victim) or victim:GetAttribute("IsNPC") then
		return true -- jugadores y enemigos de la historia (con tope diario)
	end
	return EconomyConfig.RewardDummiesInStudio and RunService:IsStudio()
end

local function onHit(attacker: Model, victim: Model, damage: number)
	local player = Players:GetPlayerFromCharacter(attacker)
	if not player or not isRewardableVictim(victim) then
		return
	end
	lastCombatAt[player] = os.clock()

	DataService.Update(player, function(data)
		data.Stats.DamageDealt += damage
	end)

	-- Convertimos daño en monedas por bloques de 10% para no spamear notificaciones
	local buffered = (damageBuffer[player] or 0) + damage
	local chunks = math.floor(buffered / 10)
	damageBuffer[player] = buffered - chunks * 10

	local rewards = EconomyConfig.Rewards
	local xp = damage * rewards.XPPerDamage
	if chunks > 0 then
		EconomyService.GrantCombatReward(player, chunks * rewards.CoinsPer10Damage, xp, "Daño")
	else
		EconomyService.AddXP(player, applyMultiplier(player, "XP", xp))
	end
end

local function onKO(victim: Model, killer: Model?)
	local victimPlayer = Players:GetPlayerFromCharacter(victim)
	if victimPlayer then
		lastCombatAt[victimPlayer] = os.clock()
	end
	if not killer then
		return
	end
	local player = Players:GetPlayerFromCharacter(killer)
	if not player or player == victimPlayer or not isRewardableVictim(victim) then
		return
	end
	DataService.Update(player, function(data)
		data.Stats.KOs += 1
	end)
	local ko = EconomyConfig.Rewards.KO
	local mult = if victim:GetAttribute("IsNPC") then 0.4 else 1 -- los enemigos de la historia dan menos
	EconomyService.GrantCombatReward(player, ko.Coins * mult, ko.XP * mult, "KO")
end

-- Compras con Robux. ProcessReceipt solo puede definirse en UN script de todo el juego.
local gemsByProductId = {}
for _, pack in EconomyConfig.GemPacks do
	if pack.Id ~= 0 then
		gemsByProductId[pack.Id] = pack.Gems
	end
end

-- Otros productos de Robux (p. ej. el Pase Premium) se registran aquí:
--   handler(player, data) se ejecuta dentro de DataService.Update; undo(data) lo revierte si falla el guardado
local productHandlers = {}
function EconomyService.RegisterProduct(productId: number, handler, undo, onGranted)
	if productId ~= 0 then
		productHandlers[productId] = { Grant = handler, Undo = undo, OnGranted = onGranted }
	end
end

local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- se reintentará cuando vuelva
	end
	local data = DataService.WaitFor(player, 15)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Idempotencia: si ya entregamos este PurchaseId, no se vuelve a dar
	if table.find(data.PurchaseHistory, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local custom = productHandlers[receipt.ProductId]
	if custom then
		DataService.Update(player, function(d)
			custom.Grant(player, d)
			pushCapped(d.PurchaseHistory, receipt.PurchaseId, PURCHASE_HISTORY_SIZE)
		end)
		if not DataService.Save(player, false) then
			DataService.Update(player, function(d)
				custom.Undo(d)
				local idx = table.find(d.PurchaseHistory, receipt.PurchaseId)
				if idx then
					table.remove(d.PurchaseHistory, idx)
				end
			end)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if custom.OnGranted then
			custom.OnGranted(player)
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local gems = gemsByProductId[receipt.ProductId]
	if not gems then
		warn("[EconomyService] ProductId desconocido:", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	EconomyService.AddCurrency(player, "Gems", gems, `Robux:{receipt.ProductId}`)
	DataService.Update(player, function(d)
		pushCapped(d.PurchaseHistory, receipt.PurchaseId, PURCHASE_HISTORY_SIZE)
	end)

	-- Guardar ANTES de confirmar: si falla, Roblox reintentará y no se pierde la compra
	if not DataService.Save(player, false) then
		DataService.Update(player, function(d)
			d.Gems -= gems
			local idx = table.find(d.PurchaseHistory, receipt.PurchaseId)
			if idx then
				table.remove(d.PurchaseHistory, idx)
			end
		end)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	notify(player, { Gems = gems, Reason = "Compra" })
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function EconomyService.Start(remotes: Folder, combatService, koService)
	feedback = remotes:WaitForChild("EconomyFeedback")

	combatService.OnHit(onHit)
	koService.OnKO(onKO)
	MarketplaceService.ProcessReceipt = processReceipt

	-- Recompensa por tiempo jugado (solo si has peleado en el intervalo: anti-AFK)
	task.spawn(function()
		local playtime = EconomyConfig.Rewards.Playtime
		while true do
			task.wait(playtime.Interval)
			for _, player in Players:GetPlayers() do
				if DataService.Get(player) then
					DataService.Update(player, function(data)
						data.Stats.PlaytimeSeconds += playtime.Interval
					end)
					local last = lastCombatAt[player]
					if last and os.clock() - last <= playtime.Interval then
						EconomyService.GrantCombatReward(player, playtime.Coins, playtime.XP, "Tiempo de juego")
					end
				end
			end
		end
	end)
end

return EconomyService
