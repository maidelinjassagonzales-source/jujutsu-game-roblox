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
		return result(false, "Petición inválida")
	end
	local entry = CatalogConfig.Characters[id]
	if not entry or not CharacterRegistry.Get(id) then
		return result(false, "Personaje desconocido")
	end
	local data = DataService.Get(player)
	if not data then
		return result(false, "Tus datos aún se están cargando")
	end
	if data.OwnedCharacters[id] then
		return result(false, "Ya tienes este personaje")
	end

	local status = CatalogConfig.GetCharacterStatus(id, os.time())
	if status == "Upcoming" then
		return result(false, "Este personaje aún no ha salido")
	end

	local priceCoins, priceGems, levelRequired = CatalogConfig.GetPrices(id)
	local price
	if status == "Starter" then
		price = 0
	elseif currency == "Gems" then
		price = priceGems -- las Gemas se saltan el requisito de nivel
	elseif status == "EarlyAccess" then
		return result(false, "En Acceso Anticipado solo se puede conseguir con Gemas")
	else
		price = priceCoins
		if price and levelRequired and data.Level < levelRequired then
			return result(false, `Necesitas Nivel {levelRequired} para comprarlo con Monedas (o consíguelo ya con Gemas)`)
		end
	end
	if not price then
		return result(false, if currency == "Coins" then "Exclusivo: solo se consigue con Gemas" else "No se puede comprar con esa moneda")
	end

	if price > 0 and not EconomyService.SpendCurrency(player, currency, price, `Personaje:{id}`) then
		return result(false, `No tienes suficientes {currencyName(currency)}`)
	end
	DataService.Update(player, function(d)
		d.OwnedCharacters[id] = true
	end)
	if currency == "Gems" then
		afterGemSpend(player)
	end
	DataService.PushState(player)
	return result(true, `¡{CharacterRegistry.Get(id).DisplayName} desbloqueado!`)
end

UnlockService.Handlers.SelectCharacter = function(player: Player, id: any)
	if type(id) ~= "string" then
		return result(false, "Petición inválida")
	end
	local data = DataService.Get(player)
	if not data or not data.OwnedCharacters[id] then
		return result(false, "No tienes este personaje")
	end
	if not MatchService.CanChangeLoadout(player) then
		return result(false, "Solo puedes cambiar de personaje en el Hub")
	end
	if data.SelectedCharacter ~= id then
		FighterService.SelectCharacter(player, id)
	end
	return result(true, `Has elegido a {CharacterRegistry.Get(id).DisplayName}`)
end

-- Modo prueba: juega con cualquier personaje en el Dojo para probarlo antes de comprarlo
UnlockService.Handlers.TryCharacter = function(player: Player, id: any)
	if type(id) ~= "string" or not CharacterRegistry.Get(id) or not CatalogConfig.Characters[id] then
		return result(false, "Personaje desconocido")
	end
	if not MatchService.CanChangeLoadout(player) then
		return result(false, "Termina la partida antes de probar personajes")
	end
	FighterService.TryCharacter(player, id)
	return result(true, `Probando a {CharacterRegistry.Get(id).DisplayName} en el Dojo`)
end

UnlockService.Handlers.BuySkin = function(player: Player, skinId: any)
	local skin = type(skinId) == "string" and CatalogConfig.Skins[skinId]
	if not skin then
		return result(false, "Skin desconocida")
	end
	local data = DataService.Get(player)
	if not data then
		return result(false, "Tus datos aún se están cargando")
	end
	if data.OwnedSkins[skinId] then
		return result(false, "Ya tienes esta skin")
	end
	if skin.BattlePassOnly then
		return result(false, "Esta skin solo se consigue en el Pase de Batalla")
	elseif skin.StoryOnly then
		return result(false, "Esta skin se consigue completando el Modo Historia")
	elseif skin.RouletteOnly then
		return result(false, "Esta skin solo sale en la Ruleta Maldita")
	end
	local currency = if skin.PriceGems then "Gems" else "Coins"
	local price = skin.PriceGems or skin.PriceCoins
	if not price or not EconomyService.SpendCurrency(player, currency, price, `Skin:{skinId}`) then
		return result(false, `No tienes suficientes {currencyName(currency)}`)
	end
	DataService.Update(player, function(d)
		d.OwnedSkins[skinId] = true
	end)
	if currency == "Gems" then
		afterGemSpend(player)
	end
	DataService.PushState(player)
	return result(true, `¡Skin {skin.Name} conseguida!`)
end

-- skinId = false/nil para quitar la skin
UnlockService.Handlers.EquipSkin = function(player: Player, characterId: any, skinId: any)
	if type(characterId) ~= "string" or not CharacterRegistry.Get(characterId) then
		return result(false, "Petición inválida")
	end
	local data = DataService.Get(player)
	if not data then
		return result(false, "Tus datos aún se están cargando")
	end
	if skinId then
		local skin = type(skinId) == "string" and CatalogConfig.Skins[skinId]
		if not skin or skin.Character ~= characterId or not data.OwnedSkins[skinId] then
			return result(false, "No tienes esta skin")
		end
	end
	if not MatchService.CanChangeLoadout(player) then
		return result(false, "No puedes cambiar de skin durante una partida")
	end
	DataService.Update(player, function(d)
		d.EquippedSkins[characterId] = skinId or nil
	end)
	if data.SelectedCharacter == characterId then
		FighterService.SpawnCharacter(player, true)
	end
	DataService.PushState(player)
	return result(true, if skinId then "Skin equipada" else "Skin quitada")
end

function UnlockService.Start(services)
	FighterService = services.FighterService
	MatchService = services.MatchService
end

return UnlockService
