-- UnlockService: compra/selección de personajes y skins (Fase 3).
-- Reglas (CatalogConfig):
--   * Personaje en Acceso Anticipado -> SOLO Gemas durante 14 días
--   * Después -> Monedas Malditas (F2P) o atajo con Gemas
--   * Skins: Monedas, Gemas o exclusivas del Pase de Batalla (no se venden)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))
local EconomyConfig = require(Shared:WaitForChild("EconomyConfig"))
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local UnlockService = {}
UnlockService.Handlers = {}

local FighterService, MatchService

local function result(ok: boolean, msg: string)
	return { ok = ok, msg = msg }
end

local function currencyName(currency: string): string
	return EconomyConfig.Currencies[currency].DisplayName
end

local function afterGemSpend(player: Player)
	-- Gastar Gemas es dinero real: guardamos enseguida en lugar de esperar al autoguardado
	task.spawn(DataService.Save, player, false)
end

UnlockService.Handlers.BuyCharacter = function(player: Player, id: any, currency: any)
	if type(id) ~= "string" or (currency ~= "Coins" and currency ~= "Gems") then
		return result(false, "Invalid request")
	end
	local entry = CatalogConfig.Characters[id]
	if not entry or not CharacterRegistry.Get(id) then
		return result(false, "Unknown character")
	end
	local data = DataService.Get(player)
	if not data then
		return result(false, "Your data is still loading")
	end
	if data.OwnedCharacters[id] then
		return result(false, "You already own this character")
	end

	local status = CatalogConfig.GetCharacterStatus(id, os.time())
	if status == "Upcoming" then
		return result(false, "This character isn't out yet")
	end

	local priceCoins, priceGems, levelRequired = CatalogConfig.GetPrices(id)
	local price
	if status == "Starter" then
		price = 0
	elseif currency == "Gems" then
		price = priceGems -- las Gemas se saltan el requisito de nivel
	elseif status == "EarlyAccess" then
		return result(false, "During Early Access it can only be unlocked with Gems")
	else
		price = priceCoins
		if price and levelRequired and data.Level < levelRequired then
			return result(false, `You need Level {levelRequired} to buy it with Coins (or get it now with Gems)`)
		end
	end
	if not price then
		return result(false, if currency == "Coins" then "Exclusive: only available with Gems" else "Can't be bought with that currency")
	end

	if price > 0 and not EconomyService.SpendCurrency(player, currency, price, `Personaje:{id}`) then
		return result(false, `You don't have enough {currencyName(currency)}`)
	end
	DataService.Update(player, function(d)
		d.OwnedCharacters[id] = true
	end)
	if currency == "Gems" then
		afterGemSpend(player)
	end
	DataService.PushState(player)
	return result(true, `{CharacterRegistry.Get(id).DisplayName} unlocked!`)
end

UnlockService.Handlers.SelectCharacter = function(player: Player, id: any)
	if type(id) ~= "string" then
		return result(false, "Invalid request")
	end
	local data = DataService.Get(player)
	if not data or not data.OwnedCharacters[id] then
		return result(false, "You don't own this character")
	end
	if not MatchService.CanChangeLoadout(player) then
		return result(false, "You can only switch characters in the Hub")
	end
	if data.SelectedCharacter ~= id then
		FighterService.SelectCharacter(player, id)
	end
	return result(true, `You chose {CharacterRegistry.Get(id).DisplayName}`)
end

-- Modo prueba: juega con cualquier personaje en el Dojo para probarlo antes de comprarlo
UnlockService.Handlers.TryCharacter = function(player: Player, id: any)
	if type(id) ~= "string" or not CharacterRegistry.Get(id) or not CatalogConfig.Characters[id] then
		return result(false, "Unknown character")
	end
	if not MatchService.CanChangeLoadout(player) then
		return result(false, "Finish the match before trying characters")
	end
	FighterService.TryCharacter(player, id)
	return result(true, `Trying {CharacterRegistry.Get(id).DisplayName} in the Dojo`)
end

UnlockService.Handlers.BuySkin = function(player: Player, skinId: any)
	local skin = type(skinId) == "string" and CatalogConfig.Skins[skinId]
	if not skin then
		return result(false, "Unknown skin")
	end
	local data = DataService.Get(player)
	if not data then
		return result(false, "Your data is still loading")
	end
	if data.OwnedSkins[skinId] then
		return result(false, "You already own this skin")
	end
	if skin.BattlePassOnly then
		return result(false, "This skin is only available in the Battle Pass")
	elseif skin.StoryOnly then
		return result(false, "This skin is earned by completing Story Mode")
	elseif skin.RouletteOnly then
		return result(false, "This skin only drops from the Cursed Roulette")
	end
	local currency = if skin.PriceGems then "Gems" else "Coins"
	local price = skin.PriceGems or skin.PriceCoins
	if not price or not EconomyService.SpendCurrency(player, currency, price, `Skin:{skinId}`) then
		return result(false, `You don't have enough {currencyName(currency)}`)
	end
	DataService.Update(player, function(d)
		d.OwnedSkins[skinId] = true
	end)
	if currency == "Gems" then
		afterGemSpend(player)
	end
	DataService.PushState(player)
	return result(true, `{skin.Name} skin unlocked!`)
end

-- skinId = false/nil para quitar la skin
UnlockService.Handlers.EquipSkin = function(player: Player, characterId: any, skinId: any)
	if type(characterId) ~= "string" or not CharacterRegistry.Get(characterId) then
		return result(false, "Invalid request")
	end
	local data = DataService.Get(player)
	if not data then
		return result(false, "Your data is still loading")
	end
	if skinId then
		local skin = type(skinId) == "string" and CatalogConfig.Skins[skinId]
		if not skin or skin.Character ~= characterId or not data.OwnedSkins[skinId] then
			return result(false, "You don't own this skin")
		end
	end
	if not MatchService.CanChangeLoadout(player) then
		return result(false, "You can't change skins during a match")
	end
	DataService.Update(player, function(d)
		d.EquippedSkins[characterId] = skinId or nil
	end)
	if data.SelectedCharacter == characterId then
		FighterService.SpawnCharacter(player, true)
	end
	DataService.PushState(player)
	return result(true, if skinId then "Skin equipped" else "Skin removed")
end

function UnlockService.Start(services)
	FighterService = services.FighterService
	MatchService = services.MatchService
end

return UnlockService
