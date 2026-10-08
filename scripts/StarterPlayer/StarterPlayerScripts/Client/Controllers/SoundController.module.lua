-- SoundController: música según la zona (Lobby / combate) y efectos de los eventos del juego.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SoundConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundConfig"))
local Sfx = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Sfx"))

local player = Players.LocalPlayer

local SoundController = {}

local tracks = {} -- [name] = Sound
local current: string? = nil

local function makeTrack(name: string, id: number): Sound?
	if id == 0 then
		return nil
	end
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = `rbxassetid://{id}`
	s.Looped = true
	s.Volume = 0
	s.Parent = SoundService
	tracks[name] = s
	return s
end

local function setMusic(name: string)
	if current == name then
		return
	end
	current = name
	for trackName, sound in tracks do
		local target = if trackName == name then SoundConfig.MusicVolume else 0
		if target > 0 and not sound.IsPlaying then
			sound:Play()
		end
		local tween = TweenService:Create(sound, TweenInfo.new(1.2), { Volume = target })
		tween:Play()
		if target == 0 then
			tween.Completed:Once(function()
				if current ~= trackName then
					sound:Pause()
				end
			end)
		end
	end
end

local function rootOf(model: Instance?): BasePart?
	return model and model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") :: BasePart? or nil
end

function SoundController.Start()
	makeTrack("LobbyMusic", SoundConfig.LobbyMusic)
	makeTrack("BattleMusic", SoundConfig.BattleMusic)

	-- Música: Lobby tranquilo / combate (Dojo, partidas, historia)
	task.spawn(function()
		while true do
			local arenaId = player:GetAttribute("ArenaId")
			setMusic(if arenaId == "Lobby" or arenaId == nil then "LobbyMusic" else "BattleMusic")
			task.wait(0.5)
		end
	end)

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes:WaitForChild("CombatFeedback").OnClientEvent:Connect(function(kind, a, b, c)
		if kind == "Hit" then
			-- b = daño, c = knockback
			local heavy = (c or 0) > 45 or (b or 0) >= 12
			Sfx.Play(if heavy then "HitHeavy" else "HitLight", rootOf(a), if heavy then 1 else 0.8, 0.92 + math.random() * 0.16)
		elseif kind == "KO" then
			Sfx.Play("KO")
		elseif kind == "ShieldHit" then
			Sfx.Play("Shield", rootOf(a))
		elseif kind == "ShieldBreak" then
			Sfx.Play("ShieldBreak", rootOf(a))
		elseif kind == "Grabbed" then
			Sfx.Play("Grab", rootOf(a))
		elseif kind == "Swap" then
			Sfx.Play("Special", rootOf(a), 0.8, 1.3)
		elseif kind == "MoveStarted" and typeof(b) == "string" then
			local root = rootOf(a)
			if b:find("^Special") then
				Sfx.Play("Special", root)
			elseif b:find("^Dodge") then
				Sfx.Play("Dash", root)
			elseif b:find("^Throw") then
				Sfx.Play("Swing", root, 1, 0.8)
			elseif b ~= "Grab" then
				Sfx.Play("Swing", root, 0.7, if b:find("Heavy") then 0.8 else 1.1)
			end
		end
	end)

	remotes:WaitForChild("MatchFeedback").OnClientEvent:Connect(function(kind, a)
		if kind == "Countdown" and type(a) == "number" then
			for i = 0, a - 1 do
				task.delay(i, Sfx.Play, "Count")
			end
		elseif kind == "Start" then
			Sfx.Play("Go")
		elseif kind == "Results" and type(a) == "table" then
			if a.WinnerUserId == player.UserId then
				Sfx.Play("Victory")
			end
		elseif kind == "StoryResult" and type(a) == "table" and a.Won then
			Sfx.Play("Victory")
		end
	end)

	remotes:WaitForChild("EconomyFeedback").OnClientEvent:Connect(function(kind)
		if kind == "LevelUp" or kind == "BPTier" then
			Sfx.Play("LevelUp")
		end
	end)
end

return SoundController
