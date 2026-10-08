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

-- Rivales en la misma arena (los NPC no se atacan entre sí)
local function enemiesOf(model: Model): { Model }
	local list = {}
	local arena = model:GetAttribute("ArenaId")
	for _, other in CollectionService:GetTagged("Fighter") do
		if other ~= model and other:GetAttribute("ArenaId") == arena and not other:GetAttribute("Eliminated")
			and not other:GetAttribute("KOing") and not (other:GetAttribute("IsNPC") and model:GetAttribute("IsNPC")) and root(other) then
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
local runTransform -- definida más abajo (el dominio de Hakari la usa)
local function runDomain(model: Model, cfg)
	local enemies = enemiesOf(model)
	if cfg.Freeze then
		for _, e in enemies do
			services.CombatService.Stun(e, cfg.Duration)
		end
	end
	local gap = cfg.Duration / (cfg.Ticks + 1)
	for _ = 1, cfg.Ticks do
		task.wait(gap)
		if not model.Parent or model:GetAttribute("KOing") then
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

local function swapHair(model: Model, on: boolean)
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

-- ===== Activación
function UltimateService.CanActivate(model: Model): boolean
	local cfg = UltimateConfig.Characters[model:GetAttribute("CharacterId") or ""]
	return cfg ~= nil and (model:GetAttribute("Ult") or 0) >= 100 and not model:GetAttribute("UltActive")
		and model:GetAttribute("MoveMode") ~= "Free" and not model:GetAttribute("KOing") and not model:GetAttribute("Eliminated")
		and not services.CombatService.IsStunned(model)
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
	local windup = UltimateConfig.WindupFor(cfg.Kind)
	if services.QuestService then
		services.QuestService.Add(Players:GetPlayerFromCharacter(model), "Ults", 1)
	end
	model:SetAttribute("Ult", 0)
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
		local arena = model:GetAttribute("ArenaId")
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
				runDomain(model, cfg)
			elseif cfg.Kind == "Transform" then
				runTransform(model, cfg)
			else
				runBurst(model, cfg)
			end
		end)
		if not ok then
			warn("[UltimateService]", err)
		end
		if model.Parent then
			model:SetAttribute("UltActive", false)
		end
	end)
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
end

return UltimateService
