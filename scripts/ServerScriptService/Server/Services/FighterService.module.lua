-- FighterService: crea los personajes R6 y los convierte en "luchadores".
-- Atributos replicados en cada luchador:
--   Percent, Stocks, CharacterId, SkinId, Weight, DisplayName, Title, KOEffect,
--   ArenaId (en qué arena está), MoveMode ("Arena" 2D | "Free" 3D), Invulnerable, KOing, Eliminated
-- El jugador guarda su zona en sus propios atributos (ArenaId, MoveMode, Activity) para que
-- sobreviva si se recrea el personaje (al cambiar de skin, por ejemplo).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("CombatConfig"))
local CatalogConfig = require(Shared:WaitForChild("CatalogConfig"))
local ClothingConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClothingConfig"))
local ModelConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModelConfig"))
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))
local Accessories = require(Shared:WaitForChild("Accessories"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local ArenaService = require(script.Parent:WaitForChild("ArenaService"))

local FighterService = {}

local dummy: Model? = nil
local DUMMY_OFFSET = Vector3.new(14, 6, 0)
local FREE_WALKSPEED = 22 -- paseando por el Lobby
local FREE_JUMPPOWER = 52

function FighterService.ApplyMovement(model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local data = CharacterRegistry.Get(model:GetAttribute("CharacterId"))
	if not humanoid or not data or model:GetAttribute("IsDummy") then
		return
	end
	humanoid.UseJumpPower = true
	if model:GetAttribute("MoveMode") == "Free" then
		humanoid.WalkSpeed = FREE_WALKSPEED
		humanoid.JumpPower = FREE_JUMPPOWER
	else
		-- SpeedMult / JumpMult: transformaciones de la ulti
		humanoid.JumpPower = (data.JumpPower or Config.JumpPower) * (model:GetAttribute("JumpMult") or 1)
		humanoid.WalkSpeed = (data.WalkSpeed or Config.WalkSpeed) * (model:GetAttribute("SpeedMult") or 1)
	end
end

function FighterService.SetupFighter(model: Model, characterId: string?, ownerName: string?)
	local data = CharacterRegistry.Get(characterId) or CharacterRegistry.Get(Config.DefaultCharacter)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not data or not humanoid then
		return
	end

	model:SetAttribute("CharacterId", data.Id)
	model:SetAttribute("Weight", data.Weight)
	model:SetAttribute("DisplayName", if ownerName then `{ownerName} · {data.DisplayName}` else data.DisplayName)
	if model:GetAttribute("Percent") == nil then
		model:SetAttribute("Percent", 0)
	end
	if model:GetAttribute("Stocks") == nil then
		model:SetAttribute("Stocks", Config.DefaultStocks)
	end
	if model:GetAttribute("ArenaId") == nil then
		model:SetAttribute("ArenaId", "Hub")
	end

	-- No hay barra de vida: el Humanoid nunca muere, el KO lo deciden las blast zones.
	humanoid.BreakJointsOnDeath = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	FighterService.ApplyMovement(model)

	CollectionService:AddTag(model, "Fighter")
end

-- Crea un rig R6 desde una descripción (API nueva *Async; si no existe, la clásica)
local function createRig(description: HumanoidDescription): Model
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R6)
	end)
	if ok and model then
		return model
	end
	return (Players :: any).CreateHumanoidModelFromDescription(Players, description, Enum.HumanoidRigType.R6)
end

-- ===== Modelos de la Toolbox (Creator Store) =====
-- Mete un personaje de la tienda de assets en ServerStorage > CharacterModels y ponle de nombre el Id
-- del luchador (Brawler, Sorcerer, CursedKing... o su nombre visible). El juego copia su "look" (ropa,
-- cara, colores, pelo y accesorios) sobre nuestro rig R6, así las animaciones y el combate siguen igual.
-- Sirven modelos R6 y R15. Los scripts que traiga el modelo se BORRAN (los modelos gratis a veces traen virus).
local R15_TO_R6 = {
	Head = "Head", UpperTorso = "Torso", LowerTorso = "Torso", Torso = "Torso",
	LeftUpperArm = "Left Arm", LeftLowerArm = "Left Arm", LeftHand = "Left Arm", ["Left Arm"] = "Left Arm",
	RightUpperArm = "Right Arm", RightLowerArm = "Right Arm", RightHand = "Right Arm", ["Right Arm"] = "Right Arm",
	LeftUpperLeg = "Left Leg", LeftLowerLeg = "Left Leg", LeftFoot = "Left Leg", ["Left Leg"] = "Left Leg",
	RightUpperLeg = "Right Leg", RightLowerLeg = "Right Leg", RightFoot = "Right Leg", ["Right Leg"] = "Right Leg",
	HumanoidRootPart = "HumanoidRootPart",
}

local function findImported(data): Model?
	local folder = ServerStorage:FindFirstChild("CharacterModels")
	if not folder then
		return nil
	end
	local found = folder:FindFirstChild(data.Id) or folder:FindFirstChild(data.DisplayName)
	return if found and found:IsA("Model") then found else nil
end

local function stripScripts(root: Instance)
	for _, d in root:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
end

-- Parte del cuerpo del modelo importado a la que va pegada una pieza suelta (pelo de partes, armas...)
local function attachedBodyPart(part: BasePart): string?
	for _, j in part:GetJoints() do
		local other = if j.Part0 == part then j.Part1 else j.Part0
		if other and R15_TO_R6[other.Name] then
			return R15_TO_R6[other.Name]
		end
	end
	return nil
end

local function applyImportedLook(model: Model, template: Model)
	local source = template:Clone()
	stripScripts(source)
	local humanoid = model:FindFirstChildOfClass("Humanoid")

	-- Ropa clásica, colores del cuerpo y cara
	for _, className in { "Shirt", "Pants", "ShirtGraphic", "BodyColors" } do
		local item = source:FindFirstChildOfClass(className)
		if item then
			local old = model:FindFirstChildOfClass(className)
			if old then
				old:Destroy()
			end
			item.Parent = model
		end
	end
	local srcHead = source:FindFirstChild("Head")
	local head = model:FindFirstChild("Head")
	if srcHead and head then
		local face = srcHead:FindFirstChildWhichIsA("Decal")
		if face then
			local old = head:FindFirstChild("face")
			if old then
				old:Destroy()
			end
			face.Name = "face"
			face.Parent = head
		end
		local headMesh = srcHead:FindFirstChildWhichIsA("SpecialMesh")
		if headMesh then
			local old = head:FindFirstChildWhichIsA("SpecialMesh")
			if old then
				old:Destroy()
			end
			headMesh.Parent = head
		end
	end
	-- Mallas de cuerpo R6 (CharacterMesh)
	for _, d in source:GetChildren() do
		if d:IsA("CharacterMesh") then
			d.Parent = model
		end
	end
	-- Accesorios (pelo, sombreros, armas a la espalda...): Roblox los coloca por sus attachments
	for _, d in source:GetDescendants() do
		if d:IsA("Accessory") and humanoid then
			local handle = d:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				for _, w in handle:GetChildren() do
					if w:IsA("JointInstance") or w:IsA("WeldConstraint") then
						w:Destroy()
					end
				end
				handle.Anchored = false
				handle.CanCollide = false
				handle.Massless = true
			end
			pcall(humanoid.AddAccessory, humanoid, d)
		end
	end
	-- Piezas sueltas pegadas al cuerpo (pelo hecho con partes, armaduras...): se sueldan a la misma parte
	for _, part in source:GetDescendants() do
		if part:IsA("BasePart") and not R15_TO_R6[part.Name] and not part:FindFirstAncestorOfClass("Accessory") then
			local bodyName = attachedBodyPart(part)
			local srcBody = bodyName and source:FindFirstChild(bodyName, true)
			local body = bodyName and model:FindFirstChild(bodyName)
			if body and srcBody and srcBody:IsA("BasePart") then
				local offset = srcBody.CFrame:ToObjectSpace(part.CFrame)
				for _, j in part:GetJoints() do
					j:Destroy()
				end
				part.Anchored = false
				part.CanCollide = false
				part.Massless = true
				part.CFrame = body.CFrame * offset
				part.Parent = model
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = body
				weld.Part1 = part
				weld.Parent = part
			end
		end
	end
	source:Destroy()
end

local function buildModel(characterId: string, skinId: string?, plain: boolean?): Model
	local data = CharacterRegistry.Get(characterId) or CharacterRegistry.Get(Config.DefaultCharacter)
	local skin = skinId and CatalogConfig.Skins[skinId]
	if skin and skin.Character ~= data.Id then
		skin = nil
	end
	local colors = if skin then skin.Colors else data.Appearance

	local imported = if not plain then findImported(data) else nil
	-- Ropa propia del personaje (sin skin): el cuerpo debajo es piel (manos, brazos y piernas al aire)
	local outfit = if not skin and not plain and not imported then ClothingConfig.Characters[data.Id] else nil
	local dressed = outfit ~= nil and (outfit.Shirt ~= 0 or outfit.Pants ~= 0)
	local description = Instance.new("HumanoidDescription")
	if colors then
		local skinTone = colors.Head
		description.HeadColor = colors.Head
		description.TorsoColor = if dressed then skinTone else colors.Torso
		description.LeftArmColor = if dressed then skinTone else colors.Arms
		description.RightArmColor = if dressed then skinTone else colors.Arms
		description.LeftLegColor = if dressed and outfit.Pants ~= 0 then skinTone else colors.Legs
		description.RightLegColor = if dressed and outfit.Pants ~= 0 then skinTone else colors.Legs
	end

	local model = createRig(description)
	model.Archivable = true -- necesario para clonarlo en la pantalla de victoria y el podio
	-- Animaciones: las hace PoseController (procedurales). El Animate de Roblox se sumaría y las duplicaría.
	local animate = model:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	model:SetAttribute("AnimeSmashRig", true) -- marca: lo hemos construido nosotros (R6)
	model.PrimaryPart = model:FindFirstChild("HumanoidRootPart") :: BasePart -- pivote en el torso, no en la cabeza

	-- Camisa, pantalón y cara anime (texturas propias)
	if outfit then
		if outfit.Shirt ~= 0 then
			local shirt = Instance.new("Shirt")
			shirt.ShirtTemplate = `rbxassetid://{outfit.Shirt}`
			shirt.Parent = model
		end
		if outfit.Pants ~= 0 then
			local pants = Instance.new("Pants")
			pants.PantsTemplate = `rbxassetid://{outfit.Pants}`
			pants.Parent = model
		end
	end
	local faceId = (ClothingConfig.Characters[data.Id] or {}).Face
	local head = model:FindFirstChild("Head")
	if faceId and faceId ~= 0 and head and not plain then
		local decal = head:FindFirstChild("face") or Instance.new("Decal")
		decal.Name = "face"
		decal.Face = Enum.NormalId.Front
		decal.Texture = `rbxassetid://{faceId}`
		decal.Parent = head
	end
	-- Pelo, armas, sombreros, cuerpos de maldición: modelos de Blender (si están importados);
	-- si no, las piezas simples de antes
	if imported then
		applyImportedLook(model, imported)
	elseif not plain then
		local library = game:GetService("ServerStorage"):FindFirstChild("MeshLibrary")
		local meshes = ModelConfig.Characters[data.Id]
		if not (meshes and Accessories.BuildMeshes(model, meshes.Base, library)) then
			Accessories.Build(model, data.Style)
		end
	end
	model:SetAttribute("SkinId", if skin then skinId else nil)

	-- Aura de partículas para las skins premium (pura cosmética = "flexeo")
	local torso = model:FindFirstChild("Torso")
	if skin and skin.Aura and torso then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "SkinAura"
		emitter.Color = ColorSequence.new(skin.Aura)
		emitter.LightEmission = 1
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.1), NumberSequenceKeypoint.new(1, 0) })
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
		emitter.Lifetime = NumberRange.new(0.4, 0.8)
		emitter.Rate = 22
		emitter.Speed = NumberRange.new(2, 4)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Parent = torso
	end
	return model
end

-- ===== Avatar de Roblox del jugador (solo en el Lobby; para pelear se transforma en su luchador)
local avatarCache = {} -- [userId] = HumanoidDescription | false

local function fetchAvatar(player: Player): HumanoidDescription?
	local cached = avatarCache[player.UserId]
	if cached == nil then
		local ok, desc = false, nil
		if player.UserId > 0 then
			ok, desc = pcall(function()
				return Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
			end)
			if not ok then -- versiones antiguas del motor
				ok, desc = pcall(function()
					return (Players :: any).GetHumanoidDescriptionFromUserId(Players, player.UserId)
				end)
			end
		end
		cached = if ok and desc then desc else false
		avatarCache[player.UserId] = cached
	end
	return if cached then cached else nil
end

local function buildAvatar(player: Player): Model?
	local desc = fetchAvatar(player)
	if not desc then
		return nil
	end
	local ok, model = pcall(function()
		return createRig(desc:Clone())
	end)
	if not ok or not model then
		return nil
	end
	model.Archivable = true
	model:SetAttribute("AnimeSmashRig", true)
	model:SetAttribute("LobbyAvatar", true)
	model.PrimaryPart = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local animate = model:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	return model
end

local function wantsAvatar(player: Player): boolean
	return player:GetAttribute("ArenaId") == "Lobby"
end

-- Enemigos y jefes del modo historia
function FighterService.BuildNPC(characterId: string, displayName: string?, stocks: number?): Model
	local model = buildModel(characterId, nil)
	model.Name = displayName or characterId
	model:SetAttribute("IsNPC", true)
	model:SetAttribute("Stocks", stocks or 1)
	FighterService.SetupFighter(model, characterId, nil)
	if displayName then
		model:SetAttribute("DisplayName", displayName)
	end
	return model
end

local function applyCosmetics(player: Player, model: Model)
	local data = DataService.Get(player)
	if data then
		model:SetAttribute("Title", data.EquippedTitle)
		model:SetAttribute("KOEffect", data.EquippedEffect)
	end
end

-- (Re)crea el personaje del jugador. Con preserve=true mantiene posición, %, stocks y estado.
function FighterService.SpawnCharacter(player: Player, preserve: boolean?)
	local data = DataService.Get(player)
	local characterId = player:GetAttribute("SelectedCharacter") or Config.DefaultCharacter
	-- Prueba en el Dojo: cualquier personaje, aunque no lo tengas (solo mientras estés en el Dojo)
	local trial = player:GetAttribute("TrialCharacter")
	if trial and player:GetAttribute("ArenaId") == "Hub" and CharacterRegistry.Get(trial) then
		characterId = trial
	end
	local skinId = data and data.EquippedSkins[characterId]

	local old = player.Character
	local saved = nil
	if preserve and old and old.Parent then
		saved = { Pivot = old:GetPivot(), Attributes = old:GetAttributes() }
	end

	local model = (wantsAvatar(player) and buildAvatar(player)) or buildModel(characterId, skinId)
	model.Name = player.Name
	model:SetAttribute("ArenaId", player:GetAttribute("ArenaId") or "Lobby")
	model:SetAttribute("MoveMode", player:GetAttribute("MoveMode") or "Free")
	applyCosmetics(player, model)
	if saved then
		for _, attr in { "Percent", "Stocks", "Eliminated" } do
			model:SetAttribute(attr, saved.Attributes[attr])
		end
		model:SetAttribute("SkipSpawnPoint", true)
	end

	player.Character = model
	model.Parent = workspace
	if saved then
		model:PivotTo(saved.Pivot)
	end
	if old and old ~= model then
		old:Destroy()
	end
end

function FighterService.SelectCharacter(player: Player, characterId: string)
	DataService.Update(player, function(data)
		data.SelectedCharacter = characterId
	end)
	FighterService.SpawnCharacter(player, true)
end

function FighterService.RefreshCosmetics(player: Player)
	if player.Character then
		applyCosmetics(player, player.Character)
	end
end

-- Tecla T (atajo): rota entre los personajes que el jugador POSEE.
function FighterService.CycleCharacter(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local owned = {}
	for _, id in CharacterRegistry.GetOrder() do
		if data.OwnedCharacters[id] and CatalogConfig.Characters[id] then
			table.insert(owned, id)
		end
	end
	if #owned <= 1 then
		return
	end
	local index = table.find(owned, data.SelectedCharacter) or 0
	FighterService.SelectCharacter(player, owned[index % #owned + 1])
end

-- Probar un personaje que no tienes contra el muñeco del Dojo
function FighterService.TryCharacter(player: Player, characterId: string)
	if player:GetAttribute("ArenaId") ~= "Hub" then
		FighterService.SendToDojo(player)
	end
	player:SetAttribute("TrialCharacter", characterId)
	FighterService.SpawnCharacter(player, true)
end

-- Coloca a un luchador en un punto de salida de SU arena
function FighterService.TeleportToSpawn(model: Model, index: number?)
	if model:GetAttribute("ArenaId") == "Lobby" then
		model:PivotTo(ArenaService.LobbySpawnCFrame())
		local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
		end
		return
	end
	local arena = ArenaService.Get(model:GetAttribute("ArenaId")) or ArenaService.Hub()
	model:PivotTo(ArenaService.SpawnCFrame(arena, index or math.random(1, 4)))
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
	end
end

-- Cambia la zona del jugador: arena 2D ("Hub" = Dojo, "Arena3"...) o el Lobby 3D ("Lobby", modo "Free")
function FighterService.SetZone(player: Player, arenaId: string, moveMode: string?, activity: string?)
	-- Al salir del Dojo se acaba la prueba de personaje
	local endTrial = arenaId ~= "Hub" and player:GetAttribute("TrialCharacter") ~= nil
	if endTrial then
		player:SetAttribute("TrialCharacter", nil)
	end
	player:SetAttribute("ArenaId", arenaId)
	player:SetAttribute("MoveMode", moveMode or "Arena")
	player:SetAttribute("Activity", activity or (if arenaId == "Hub" then "Hub" else player:GetAttribute("Activity")))
	-- Lobby = tu avatar de Roblox · arenas = tu luchador. Si no toca el que llevas, se cambia.
	local current = player.Character
	if current and (endTrial or (current:GetAttribute("LobbyAvatar") == true) ~= wantsAvatar(player)) then
		local pivot = current:GetPivot()
		FighterService.SpawnCharacter(player, false)
		if player.Character and player.Character ~= current then
			player.Character:SetAttribute("SkipSpawnPoint", true) -- quien llama lo coloca
			player.Character:PivotTo(pivot)
		end
	end
	local model = player.Character
	if model then
		model:SetAttribute("ArenaId", arenaId)
		model:SetAttribute("MoveMode", moveMode or "Arena")
		FighterService.ApplyMovement(model)
	end
end

local function resetAndPlace(player: Player)
	local model = player.Character
	if not model then
		return
	end
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	model:SetAttribute("Percent", 0)
	model:SetAttribute("Stocks", Config.DefaultStocks)
	model:SetAttribute("Eliminated", false)
	model:SetAttribute("KOing", false)
	model:SetAttribute("Invulnerable", false)
	model:SetAttribute("Ult", 0)
	FighterService.TeleportToSpawn(model)
	if hrp then
		hrp.Anchored = false
	end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		remotes.CombatFeedback:FireClient(player, "Respawned")
	end
end

-- Vuelta al Lobby 3D (tras partidas, historia...) con todo reiniciado
function FighterService.SendToHub(player: Player)
	FighterService.SetZone(player, "Lobby", "Free", "Hub")
	resetAndPlace(player)
end

-- Dojo de práctica: la arena 2D de la Escuela con el muñeco
function FighterService.SendToDojo(player: Player)
	FighterService.SetZone(player, "Hub", "Arena", "Hub")
	resetAndPlace(player)
end

local function onCharacterAdded(player: Player, model: Model)
	-- Un personaje que no hemos construido (p.ej. el avatar R15 por defecto) se sustituye por el nuestro
	if not model:GetAttribute("AnimeSmashRig") then
		task.defer(function()
			if player.Parent and player.Character == model then
				FighterService.SpawnCharacter(player, false)
			end
		end)
		return
	end

	model:WaitForChild("Humanoid")
	model:WaitForChild("HumanoidRootPart")
	FighterService.SetupFighter(model, player:GetAttribute("SelectedCharacter"), player.DisplayName)
	if model:GetAttribute("LobbyAvatar") then
		model:SetAttribute("DisplayName", player.DisplayName) -- en el Lobby eres tú, no tu luchador
	end

	if not model:GetAttribute("SkipSpawnPoint") then
		task.defer(function()
			if model.Parent and not model:GetAttribute("Eliminated") then
				FighterService.TeleportToSpawn(model)
			end
		end)
	end
end

local function onPlayerAdded(player: Player)
	player:SetAttribute("ArenaId", "Lobby")
	player:SetAttribute("MoveMode", "Free")
	player:SetAttribute("Activity", "Hub")
	player.CharacterAdded:Connect(function(model)
		onCharacterAdded(player, model)
	end)
	-- Esperamos al perfil para aparecer con el personaje y la skin guardados
	task.spawn(fetchAvatar, player)
	DataService.WaitFor(player, 20)
	if not player.Parent then
		return
	end
	if player:GetAttribute("SelectedCharacter") == nil then
		player:SetAttribute("SelectedCharacter", Config.DefaultCharacter)
	end
	FighterService.SpawnCharacter(player, false)
end

local function createDummy(): Model?
	local ok, model = pcall(buildModel, "Brawler", nil, true)
	if not ok or not model then
		warn("[FighterService] No se pudo crear el muñeco de práctica:", model)
		return nil
	end
	model.Name = "TrainingDummy"
	model:SetAttribute("IsDummy", true)
	model:SetAttribute("ArenaId", "Hub")
	FighterService.SetupFighter(model, "Brawler", nil)
	model:SetAttribute("DisplayName", "Muñeco de práctica")
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	return model
end

-- El muñeco vive en el Hub (modo práctica)
function FighterService.SetDummyEnabled(enabled: boolean)
	if not Config.SpawnTrainingDummy then
		return
	end
	if not dummy or not dummy.Parent then
		dummy = createDummy()
		if not dummy then
			return
		end
	end
	local model = dummy :: Model
	if enabled then
		local pos = ArenaService.Hub().Center + DUMMY_OFFSET
		model:SetAttribute("Percent", 0)
		model:SetAttribute("Stocks", Config.DefaultStocks)
		model.Parent = workspace
		model:PivotTo(CFrame.lookAt(pos, pos - Vector3.xAxis))
		local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart
		hrp.Anchored = false
		hrp:SetNetworkOwner(nil) -- el servidor simula su física (y su knockback)
	else
		model.Parent = ServerStorage
	end
end

-- Retratos: un modelo estático por personaje en ReplicatedStorage.Portraits.
-- El cliente los clona en ViewportFrames (tienda, HUD, diálogos) = "sprites" 3D sin subir imágenes.
local function buildPortraits()
	local folder = ReplicatedStorage:FindFirstChild("Portraits") or Instance.new("Folder")
	folder.Name = "Portraits"
	for _, id in CharacterRegistry.GetOrder() do
		if not folder:FindFirstChild(id) then
			local ok, model = pcall(buildModel, id, nil)
			if ok and model then
				model.Name = id
				for _, d in model:GetDescendants() do
					if d:IsA("BaseScript") then
						d:Destroy()
					elseif d:IsA("BasePart") then
						d.Anchored = true
						d.CanCollide = false
						d.CanQuery = false
					end
				end
				model:PivotTo(CFrame.new())
				model.Parent = folder
			end
		end
	end
	folder.Parent = ReplicatedStorage
end

function FighterService.Start()
	task.spawn(buildPortraits)
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	FighterService.SetDummyEnabled(true)
end

return FighterService
