-- Sfx: reproduce un efecto del "sprite" SFX.wav (cada efecto es una región del mismo audio).
--   Sfx.Play("HitHeavy", parteOpcional, volumen?, tono?)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundConfig = require(Shared:WaitForChild("SoundConfig"))
local SoundRegions = require(Shared:WaitForChild("SoundRegions"))

local Sfx = {}

local template: Sound? = nil
local lastPlayed = {} -- antispam por efecto

local function getTemplate(): Sound?
	if template then
		return template
	end
	if SoundConfig.SFX == 0 then
		return nil
	end
	local s = Instance.new("Sound")
	s.Name = "SFXTemplate"
	s.SoundId = `rbxassetid://{SoundConfig.SFX}`
	s.Volume = SoundConfig.SFXVolume
	s.PlaybackRegionsEnabled = true
	s.Parent = SoundService
	template = s
	return s
end

function Sfx.Play(name: string, at: Instance?, volume: number?, pitch: number?)
	local region = SoundRegions[name]
	local base = getTemplate()
	if not region or not base then
		return
	end
	local now = os.clock()
	if now - (lastPlayed[name] or 0) < 0.03 then
		return
	end
	lastPlayed[name] = now
	local sound = base:Clone()
	sound.PlaybackRegion = NumberRange.new(region.Start, region.Start + region.Length)
	sound.Volume = SoundConfig.SFXVolume * (volume or 1)
	sound.PlaybackSpeed = pitch or 1
	if at and SoundConfig.Spatial[name] then
		sound.RollOffMinDistance = 20
		sound.RollOffMaxDistance = 180
		sound.Parent = at
	else
		sound.Parent = SoundService
	end
	sound:Play()
	Debris:AddItem(sound, region.Length / (pitch or 1) + 0.3)
end

return Sfx
