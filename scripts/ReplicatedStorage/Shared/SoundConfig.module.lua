-- SoundConfig: IDs de los audios (generados por tools/gen_audio.py y subidos a Roblox).
-- Si un ID es 0 ese audio simplemente no suena (el juego funciona igual).
return {
	LobbyMusic = 88663418182917, -- assets/audio/LobbyMusic.wav (noche en la Escuela, koto)
	BattleMusic = 78552890115148, -- assets/audio/BattleMusic.wav (taiko + shamisen)
	SFX = 140026273700392, -- assets/audio/SFX.wav (todos los efectos; ver SoundRegions)

	MusicVolume = 0.35,
	SFXVolume = 0.7,
	-- Efectos que suenan en 3D (en la posición del luchador) en vez de en la interfaz
	Spatial = { HitLight = true, HitHeavy = true, Swing = true, Dash = true, Shield = true, ShieldBreak = true, Grab = true, Special = true, Jump = true, KO = false },
}
