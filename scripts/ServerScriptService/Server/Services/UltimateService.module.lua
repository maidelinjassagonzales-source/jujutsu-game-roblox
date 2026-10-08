-- UltimateService: barra de ulti (atributo "Ult" 0-100 en el luchador) y ejecución de las ultis
-- (Expansión de Dominio, Transformación, Técnica definitiva). Todo autoritativo en el servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UltimateConfig = require(Shared:WaitForChild("UltimateConfig"))
local ModelConfig = require(Shared:WaitForChild("ModelConfig"))
local Accessories = require(Shared:WaitForChild("Accessories"))

local UltimateService = {}

local services
local feedback: RemoteEvent

local function charge(model: Model?, amount: number)
	if not model or not model.Parent or model:GetAttribute("UltActive") then
		return
	end
	if not UltimateConfig.Characters[model:GetAttribute("CharacterId") or ""] then
		return
	end
	model:SetAttribute("Ult", math.min(100, (model:GetAttribute("Ult") or 0) + amount))
end

local function root(model: Model): BasePart?
	return model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Rivales en la misma arena (sin compañeros de equipo; los NPC de la historia no se atacan entre sí)
local function enemiesOf(model: Model): { Model }
	local list = {}
	local arena = model:GetAttribute("ArenaId")
	for _, other in CollectionService:GetTagged("Fighter") do
		if other ~= model and other:GetAttribute("ArenaId") == arena and not other:GetAttribute("Eliminated")
			and not other:GetAttribute("KOing") and services.CombatService.CanHurt(model, other) and root(other) then
			table.insert(list, other)
		end
	end
	return list
end

local function sureHit(caster: Model, victim: Model, damage: number, kb: number, angle: number?)
	local a, v = root(caster), root(victim)
	if not a or not v then
		return
	end
	local facing = if v.Position.X >= a.Position.X then 1 else -1
	services.CombatService.ApplyHit(caster, victim, {
		Damage = damage, BaseKnockback = kb, KnockbackGrowth = if kb > 20 then 90 else 15, Angle = angle or 45,
		SureHit = true, IgnoresShield = true, NoUltCharge = true,
	}, facing)
end

-- ===== Tipos de ulti
-- Token del dominio en curso de cada lanzador: si cambia (choque de dominios), el dominio se corta
local castToken = setmetatable({}, { __mode = "k" }) -- [model] = token

local runTransform -- definida más abajo (el dominio de Hakari la usa)
local function runDomain(model: Model, cfg, token)
	local enemies = enemiesOf(model)
	if cfg.Freeze then
		for _, e in enemies do
			services.CombatService.Stun(e, cfg.Duration)
		end
	end
	local gap = cfg.Duration / (cfg.Ticks + 1)
	for _ = 1, cfg.Ticks do
		task.wait(gap)
		if not model.Parent or model:GetAttribute("KOing") or (token and castToken[model] ~= token) then
			return
		end
		for _, e in enemies do
			if e.Parent and not e:GetAttribute("KOing") then
				feedback:FireAllClients("DomainTick", model, e, cfg.Theme)
				sureHit(model, e, cfg.TickDamage, 3, 80)
				if cfg.Burn then
					feedback:FireAllClients("Burn", e)
				end
			end
		end
	end
	task.wait(gap)
	if cfg.Final then
		for _, e in enemies do
			if e.Parent and not e:GetAttribute("KOing") then
				feedback:FireAllClients("DomainTick", model, e, cfg.Theme, true)
				sureHit(model, e, cfg.Final.Damage, cfg.Final.KB, 40)
			end
		end
	end
	-- Hakari: al cerrar el dominio, tirada de pachinko -> JACKPOT = transformación
	if cfg.Jackpot and model.Parent then
		local won = math.random() < (cfg.JackpotChance or 1 / 3)
		feedback:FireAllClients("Jackpot", model, won)
		if won then
			task.wait(0.8)
			local j = cfg.Jackpot
			feedback:FireAllClients("Ultimate", model, {
				Kind = j.Kind, Name = j.Name, Japanese = j.Japanese, Color = j.Color, Duration = j.Duration, Theme = j.Theme,
				Windup = 0.6, CharacterId = model:GetAttribute("CharacterId"),
			})
			task.wait(0.6)
			runTransform(model, j)
		end
	end
end

local TRANSFORM_ATTRS = { "DamageMult", "SpeedMult", "JumpMult", "KBResist", "BlackFlashMode", "Transformed" }

-- Pelo de los modelos de la tienda (accesorios): se vuelve dorado brillante y luego se restaura
local function tintStoreHair(model: Model, on: boolean)
	for _, acc in model:GetChildren() do
		local handle = acc:IsA("Accessory") and acc:FindFirstChild("Handle") :: BasePart?
		if handle and (handle:FindFirstChild("HairAttachment") or handle:FindFirstChild("HatAttachment")) then
			local mesh = handle:FindFirstChildWhichIsA("SpecialMesh")
			if on then
				handle:SetAttribute("OrigColor", handle.Color)
				handle.Color = Color3.fromRGB(255, 225, 70)
				handle.Material = Enum.Material.Neon
				if mesh then
					handle:SetAttribute("OrigTexture", mesh.TextureId)
					mesh.TextureId = ""
				elseif handle:IsA("MeshPart") then
					handle:SetAttribute("OrigTexture", handle.TextureID)
					handle.TextureID = ""
				end
			elseif handle:GetAttribute("OrigColor") then
				handle.Color = handle:GetAttribute("OrigColor")
				handle.Material = Enum.Material.SmoothPlastic
				if mesh then
					mesh.TextureId = handle:GetAttribute("OrigTexture") or ""
				elseif handle:IsA("MeshPart") then
					handle.TextureID = handle:GetAttribute("OrigTexture") or ""
				end
			end
		end
	end
end

local function swapHair(model: Model, on: boolean)
	if model:GetAttribute("StoreLook") then
		tintStoreHair(model, on)
		return
	end
	local pieces = ModelConfig.Characters[model:GetAttribute("CharacterId") or ""]
	if not pieces or not pieces.Transform then
		return
	end
	local base = model:FindFirstChild("MeshParts")
	for _, p in (base and base:GetChildren() or {}) do
		if p:IsA("BasePart") and p.Name:find("Hair") then
			p.Transparency = if on then 1 else 0
		end
	end
	local old = model:FindFirstChild("UltParts")
	if old then
		old:Destroy()
	end
	if on then
		Accessories.BuildMeshes(model, pieces.Transform, ServerStorage:FindFirstChild("MeshLibrary"), "UltParts")
	end
end

function runTransform(model: Model, cfg)
	model:SetAttribute("DamageMult", cfg.Damage)
	model:SetAttribute("SpeedMult", cfg.Speed)
	model:SetAttribute("JumpMult", cfg.Jump)
	model:SetAttribute("KBResist", cfg.KBResist)
	model:SetAttribute("BlackFlashMode", cfg.BlackFlash == true)
	model:SetAttribute("Transformed", cfg.Name)
	services.FighterService.ApplyMovement(model)
	if cfg.HairSwap then
		swapHair(model, true)
	end
	task.wait(cfg.Duration)
	if not model.Parent then
		return
	end
	for _, attr in TRANSFORM_ATTRS do
		model:SetAttribute(attr, nil)
	end
	services.FighterService.ApplyMovement(model)
	if cfg.HairSwap then
		swapHair(model, false)
	end
end

local function runBurst(model: Model, cfg)
	if cfg.SureHit then
		for _, e in enemiesOf(model) do
			sureHit(model, e, cfg.Damage, cfg.KB, 45)
		end
		return
	end
	local hrp = root(model)
	if not hrp then
		return
	end
	local facing = if hrp.CFrame.LookVector.X >= 0 then 1 else -1
	services.CombatService.ExecuteMove(model, {
		Damage = cfg.Damage, BaseKnockback = cfg.KB, KnockbackGrowth = 95, Angle = 38, Startup = 0, Active = 0, Endlag = 0,
		NoUltCharge = true, Name = cfg.Name, -- el nombre elige el efecto visual en el cliente
		Projectile = { Speed = cfg.Speed, Lifetime = 2.2, Size = Vector3.one * cfg.Size, Color = cfg.Color, Pierce = true },
	}, facing)
end

-- ===== CHOQUE DE DOMINIOS
-- Si un hechicero expande su dominio mientras otro dominio está activo (o cargándose) en la misma arena,
-- los dos dominios chocan: pantalla partida, cada uno debe pulsar rápido la secuencia de teclas de su lado.
-- Un fallo (tecla equivocada o tardar demasiado) = pierde. El primero en completarla gana y su dominio se impone.
local domainCasts = {} -- [arenaId] = { Caster = model, Cfg = cfg, Clashing = bool }
local clashOf = setmetatable({}, { __mode = "k" }) -- [model] = clash
-- Símbolos neutros: cada cliente los enseña según su dispositivo
-- (teclado W/S/A/D/J/K · mando cruceta + Ⓐ/Ⓑ · móvil botones en pantalla)
local CLASH_KEYS = { "Up", "Down", "Left", "Right", "A", "B" }
local CLASH_LENGTH = 8
local CLASH_PER_KEY = 1.3 -- segundos máximos para cada tecla
local CLASH_INTRO = 2.4 -- presentación antes de empezar a pulsar
local clashCounter = 0

local function displayNameOf(model: Model): string
	local player = Players:GetPlayerFromCharacter(model)
	return if player then player.DisplayName else (model:GetAttribute("DisplayName") or model.Name)
end

local function registerClashKey(clash, side: number, key: string)
	local s = clash.Sides[side]
	if clash.Over or s.Failed or s.Done or os.clock() < clash.StartAt then
		return -- antes del "¡YA!" las pulsaciones no cuentan (ni para bien ni para mal)
	end
	if key == clash.Seq[s.Index + 1] then
		s.Index += 1
		s.Deadline = os.clock() + CLASH_PER_KEY
		if s.Index >= #clash.Seq then
			s.Done = os.clock()
		end
		feedback:FireAllClients("ClashProgress", clash.Id, side, s.Index, false)
	else
		s.Failed = true
		feedback:FireAllClients("ClashProgress", clash.Id, side, s.Index, true)
	end
end

-- Pulsación de un jugador (llega por CombatRequest "ClashKey")
function UltimateService.ClashKey(model: Model, key: any)
	local clash = clashOf[model]
	if not clash or type(key) ~= "string" then
		return
	end
	for side, s in clash.Sides do
		if s.Model == model then
			registerClashKey(clash, side, key)
		end
	end
end

local function arenaFighters(arenaId: string): { Model }
	local list = {}
	for _, other in CollectionService:GetTagged("Fighter") do
		if other:GetAttribute("ArenaId") == arenaId and not other:GetAttribute("Eliminated") and not other:GetAttribute("KOing") then
			table.insert(list, other)
		end
	end
	return list
end

local runWinnerDomain -- definida más abajo

local function startClash(a: Model, aCfg, b: Model, bCfg)
	local arenaId = a:GetAttribute("ArenaId")
	castToken[a] = nil -- corta el dominio que ya estaba en marcha
	domainCasts[arenaId] = { Caster = a, Cfg = aCfg, Clashing = true }
	clashCounter += 1
	local seq = {}
	for i = 1, CLASH_LENGTH do
		seq[i] = CLASH_KEYS[math.random(1, #CLASH_KEYS)]
	end
	local now = os.clock()
	local clash = {
		Id = clashCounter, Seq = seq, StartAt = now + CLASH_INTRO, Over = false,
		Sides = {
			{ Model = a, Cfg = aCfg, Index = 0, Deadline = now + CLASH_INTRO + CLASH_PER_KEY * 1.5 },
			{ Model = b, Cfg = bCfg, Index = 0, Deadline = now + CLASH_INTRO + CLASH_PER_KEY * 1.5 },
		},
	}
	clashOf[a], clashOf[b] = clash, clash

	-- Todos quietos e intocables mientras dura el choque
	local fighters = arenaFighters(arenaId)
	for _, f in fighters do
		local r = root(f)
		if r then
			r.AssemblyLinearVelocity = Vector3.zero
			r.Anchored = true
		end
		f:SetAttribute("Invulnerable", true)
		services.CombatService.SetBusy(f, CLASH_INTRO + CLASH_PER_KEY * (CLASH_LENGTH + 2) + 3)
	end

	feedback:FireAllClients("DomainClash", {
		Id = clash.Id, A = a, B = b, Seq = seq, PerKey = CLASH_PER_KEY, Intro = CLASH_INTRO, Arena = arenaId,
		NameA = aCfg.Name, NameB = bCfg.Name, JapaneseA = aCfg.Japanese, JapaneseB = bCfg.Japanese,
		ColorA = aCfg.Color, ColorB = bCfg.Color, PlayerA = displayNameOf(a), PlayerB = displayNameOf(b),
	})

	-- Los bots pulsan solos (más rápidos y precisos cuanto más nivel)
	for side, s in clash.Sides do
		if not Players:GetPlayerFromCharacter(s.Model) then
			task.spawn(function()
				local level = s.Model:GetAttribute("Level") or 2
				task.wait(CLASH_INTRO + 0.1)
				while not clash.Over and not s.Failed and not s.Done do
					task.wait(0.42 + math.random() * 0.45 - level * 0.03)
					if clash.Over then
						break
					end
					local slip = math.random() < 0.035 + (5 - level) * 0.012
					registerClashKey(clash, side, if slip then "?" else seq[s.Index + 1])
				end
			end)
		end
	end

	-- Árbitro: tiempo agotado, fallos, o alguien termina
	while not clash.Over do
		local t = os.clock()
		for side, s in clash.Sides do
			if not s.Failed and not s.Done and t > s.Deadline then
				s.Failed = true
				feedback:FireAllClients("ClashProgress", clash.Id, side, s.Index, true)
			end
			if not s.Model.Parent then
				s.Failed = true
			end
		end
		local s1, s2 = clash.Sides[1], clash.Sides[2]
		if s1.Failed or s2.Failed or s1.Done or s2.Done then
			if s1.Failed and s2.Failed then
				clash.Winner = if s1.Index >= s2.Index then 1 else 2
			elseif s1.Failed then
				clash.Winner = 2
			elseif s2.Failed then
				clash.Winner = 1
			elseif s1.Done and s2.Done then
				clash.Winner = if s1.Done <= s2.Done then 1 else 2
			else
				clash.Winner = if s1.Done then 1 else 2
			end
			clash.Over = true
		end
		task.wait()
	end

	local winner = clash.Sides[clash.Winner]
	local loser = clash.Sides[3 - clash.Winner]
	feedback:FireAllClients("ClashEnd", clash.Id, clash.Winner, displayNameOf(winner.Model), winner.Cfg.Name)
	task.wait(2)

	clashOf[a], clashOf[b] = nil, nil
	for _, f in fighters do
		if f.Parent and not f:GetAttribute("Eliminated") then
			local r = root(f)
			if r then
				r.Anchored = false
			end
			f:SetAttribute("Invulnerable", false)
			services.CombatService.ClearBusy(f)
		end
	end
	domainCasts[arenaId] = nil
	if loser.Model.Parent then
		loser.Model:SetAttribute("UltActive", false)
		services.CombatService.Stun(loser.Model, 1.2) -- el dominio roto deja aturdido un momento
	end
	if winner.Model.Parent then
		runWinnerDomain(winner.Model, winner.Cfg)
	end
end

-- ===== Activación
function UltimateService.CanActivate(model: Model): boolean
	local cfg = UltimateConfig.Characters[model:GetAttribute("CharacterId") or ""]
	return cfg ~= nil and (model:GetAttribute("Ult") or 0) >= 100 and not model:GetAttribute("UltActive")
		and model:GetAttribute("MoveMode") ~= "Free" and not model:GetAttribute("KOing") and not model:GetAttribute("Eliminated")
		and not services.CombatService.IsStunned(model) and not clashOf[model]
end

-- Ejecuta una ulti ya validada (cinemática + efecto). windupOverride: el ganador de un choque va más rápido
local function runUltimate(model: Model, cfg, windupOverride: number?)
	local windup = windupOverride or UltimateConfig.WindupFor(cfg.Kind)
	local arena = model:GetAttribute("ArenaId")
	local token = {}
	castToken[model] = token
	if cfg.Kind == "Domain" then
		domainCasts[arena] = { Caster = model, Cfg = cfg }
	end
	model:SetAttribute("UltActive", true)
	model:SetAttribute("Invulnerable", true)
	services.CombatService.SetBusy(model, windup)
	feedback:FireAllClients("Ultimate", model, {
		Kind = cfg.Kind, Name = cfg.Name, Japanese = cfg.Japanese, Color = cfg.Color, Duration = cfg.Duration or 1.5,
		Windup = windup, CharacterId = model:GetAttribute("CharacterId"), Theme = cfg.Theme, Canon = cfg.Canon,
	})
	task.spawn(function()
		-- Durante la cinemática todos quedan congelados (el lanzador y, en los dominios, también los rivales)
		local frozen = {}
		for _, other in CollectionService:GetTagged("Fighter") do
			local isCaster = other == model
			local otherRoot = root(other)
			if otherRoot and not otherRoot.Anchored and (isCaster or (cfg.Kind == "Domain" and other:GetAttribute("ArenaId") == arena)) then
				otherRoot.AssemblyLinearVelocity = Vector3.zero
				otherRoot.Anchored = true
				table.insert(frozen, otherRoot)
				if not isCaster then
					services.CombatService.SetBusy(other, windup)
					other:SetAttribute("Invulnerable", true) -- nadie puede pegar ni ser pegado durante la cinemática
				end
			end
		end
		task.wait(windup)
		if castToken[model] ~= token then
			return -- un choque de dominios se ha hecho cargo (él descongela a todos)
		end
		for _, r in frozen do
			if r.Parent then
				r.Anchored = false
				local m = r.Parent
				if m ~= model and m:IsA("Model") then
					m:SetAttribute("Invulnerable", false)
				end
			end
		end
		if not model.Parent then
			return
		end
		model:SetAttribute("Invulnerable", false)
		local ok, err = pcall(function()
			if cfg.Kind == "Domain" then
				runDomain(model, cfg, token)
			elseif cfg.Kind == "Transform" then
				runTransform(model, cfg)
			else
				runBurst(model, cfg)
			end
		end)
		if not ok then
			warn("[UltimateService]", err)
		end
		if castToken[model] == token then
			castToken[model] = nil
			local current = domainCasts[arena]
			if current and current.Caster == model and not current.Clashing then
				domainCasts[arena] = nil
			end
			if model.Parent then
				model:SetAttribute("UltActive", false)
			end
		end
	end)
end

function runWinnerDomain(model: Model, cfg)
	runUltimate(model, cfg, 1.2)
end

function UltimateService.Activate(model: Model): boolean
	if not UltimateService.CanActivate(model) then
		return false
	end
	local cfg = UltimateConfig.Characters[model:GetAttribute("CharacterId")]
	if cfg.Kind == "Gamble" then
		local jackpot = math.random() < 1 / 3
		cfg = if jackpot then cfg.Jackpot else cfg.Miss
	end
	if services.QuestService then
		services.QuestService.Add(Players:GetPlayerFromCharacter(model), "Ults", 1)
	end
	model:SetAttribute("Ult", 0)

	-- ¿Ya hay otro dominio activo en esta arena? -> ¡CHOQUE DE DOMINIOS!
	if cfg.Kind == "Domain" then
		local arenaId = model:GetAttribute("ArenaId")
		local other = domainCasts[arenaId]
		if other and other.Caster ~= model and other.Caster.Parent and not other.Clashing
			and other.Caster:GetAttribute("UltActive") and not clashOf[other.Caster] then
			model:SetAttribute("UltActive", true)
			task.spawn(function()
				local ok, err = pcall(startClash, other.Caster, other.Cfg, model, cfg)
				if not ok then
					warn("[UltimateService] Choque de dominios:", err)
					clashOf[other.Caster], clashOf[model] = nil, nil
					domainCasts[arenaId] = nil
					for _, f in arenaFighters(arenaId) do
						local r = root(f)
						if r then
							r.Anchored = false
						end
						f:SetAttribute("Invulnerable", false)
					end
					model:SetAttribute("UltActive", false)
				end
			end)
			return true
		end
	end

	runUltimate(model, cfg)
	return true
end


function UltimateService.Reset(model: Model)
	model:SetAttribute("Ult", 0)
	model:SetAttribute("UltActive", false)
	for _, attr in TRANSFORM_ATTRS do
		model:SetAttribute(attr, nil)
	end
end

function UltimateService.Start(remotes: Folder, s)
	services = s
	feedback = remotes:WaitForChild("CombatFeedback")
	services.CombatService.OnHit(function(attacker: Model, victim: Model, damage: number, move)
		if move and move.NoUltCharge then
			return
		end
		charge(attacker, damage * UltimateConfig.ChargeDealt)
		charge(victim, damage * UltimateConfig.ChargeTaken)
	end)
	services.CombatService.UltimateHandler = UltimateService.Activate
	services.CombatService.ClashKeyHandler = UltimateService.ClashKey
end

return UltimateService