-- StoreService: tienda de Gemas (boosters temporales, efectos de KO, títulos) y equipar cosméticos.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CatalogConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CatalogConfig"))

local StoreService = {}
StoreService.Handlers = {}

local services

local function result(ok: boolean, msg: string)
	return { ok = ok, msg = msg }
end

StoreService.Handlers.BuyItem = function(player: Player, itemId: any)
	local item = type(itemId) == "string" and CatalogConfig.StoreItems[itemId]
	local data = services.DataService.Get(player)
	if not item or not data then
		return result(false, "Unknown item")
	end
	if item.StoryOnly or not item.Gems then
		return result(false, "This item isn't for sale")
	end
	if item.Kind == "Effect" and data.OwnedEffects[itemId] then
		return result(false, "You already own it")
	end
	if item.Kind == "Title" and data.OwnedTitles[itemId] then
		return result(false, "You already own it")
	end
	if not services.EconomyService.SpendCurrency(player, "Gems", item.Gems, `Tienda:{itemId}`) then
		return result(false, "You don't have enough Gems")
	end

	services.DataService.Update(player, function(d)
		if item.Kind == "Boost" then
			local key = if item.Boost == "Coins" then "CoinsUntil" else "XPUntil"
			-- Se acumula: si ya tienes uno activo, se alarga
			d.Boosts[key] = math.max(d.Boosts[key], os.time()) + item.Duration
		elseif item.Kind == "Effect" then
			d.OwnedEffects[itemId] = true
			d.EquippedEffect = itemId
		elseif item.Kind == "Title" then
			d.OwnedTitles[itemId] = true
			d.EquippedTitle = itemId
		end
	end)
	task.spawn(services.DataService.Save, player, false)
	services.BoosterService.Refresh(player)
	services.FighterService.RefreshCosmetics(player)
	services.DataService.PushState(player)
	return result(true, `{item.Name}!`)
end

-- Equipar / quitar (itemId = false para quitar)
StoreService.Handlers.EquipCosmetic = function(player: Player, kind: any, itemId: any)
	local data = services.DataService.Get(player)
	if not data or (kind ~= "Effect" and kind ~= "Title") then
		return result(false, "Invalid request")
	end
	local owns = if kind == "Effect" then data.OwnedEffects else data.OwnedTitles
	if itemId and (type(itemId) ~= "string" or not owns[itemId]) then
		return result(false, "You don't own it")
	end
	services.DataService.Update(player, function(d)
		if kind == "Effect" then
			d.EquippedEffect = itemId or ""
		else
			d.EquippedTitle = itemId or ""
		end
	end)
	services.FighterService.RefreshCosmetics(player)
	services.DataService.PushState(player)
	return result(true, if itemId then "Equipped" else "Removed")
end

function StoreService.Start(s)
	services = s
end

return StoreService
