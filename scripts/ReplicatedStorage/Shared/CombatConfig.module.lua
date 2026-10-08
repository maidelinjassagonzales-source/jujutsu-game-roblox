-- CombatConfig: todos los valores ajustables del combate estilo Platform Fighter.
-- Cambia aquí el "feel" del juego sin tocar la lógica.
local CombatConfig = {
	-- Físicas generales
	Gravity = 80, -- muy flotante: más tiempo en el aire para pelear y hacer combos (antes 140)
	WalkSpeed = 22,
	JumpPower = 62,
	JumpScale = 0.6, -- multiplica el JumpPower de cada personaje: saltos más bajos (~8.5 studs en vez de ~14)
	-- Compensa la gravedad baja en lanzamientos y recuperaciones: llegan a la MISMA altura que con
	-- gravedad 140 (no se adelantan los KOs por arriba), pero tardan más en caer = más combos aéreos
	VerticalScale = math.sqrt(80 / 140),
	MaxAirJumps = 1, -- salto doble
	DoubleJumpVelocity = 42,
	FastFallSpeed = 80, -- mantener S/abajo en el aire

	-- Ataques fuertes cargables (mantener el botón en el suelo, como los smash)
	SmashChargeTime = 1, -- segundos hasta la carga máxima (se suelta solo al llegar)
	SmashChargeBonus = 0.4, -- +40% de daño a carga máxima
	PlaneZ = 0, -- el combate ocurre en el plano X/Y

	-- Knockback estilo Smash
	LaunchSpeedMultiplier = 0.62, -- unidades de KB -> studs/s (antes 0.75: a 60% ya se salía del mapa; ahora un golpe fuerte desde el borde mata sobre 130-150%)
	KnockbackDecay = 45, -- studs/s que pierde la velocidad horizontal por segundo
	HitstunFactor = 0.4 / 60, -- segundos de hitstun por unidad de KB (fórmula de Smash: KB * 0.4 frames)
	MinHitstun = 0.15,
	GroundSpikeBounceAngle = 80, -- un spike contra alguien en el suelo lo hace rebotar hacia arriba
	MaxPercent = 999,

	-- Partida
	DefaultStocks = 3,
	RespawnDelay = 1.2,
	RespawnInvulnerability = 2,
	BlastZone = { Left = -140, Right = 140, Top = 95, Bottom = -50 },
	SpawnPoints = {
		Vector3.new(-20, 6, 0),
		Vector3.new(20, 6, 0),
		Vector3.new(-8, 6, 0),
		Vector3.new(8, 6, 0),
	},
	RespawnPoint = Vector3.new(0, 34, 0),

	-- Cámara lateral
	Camera = {
		MinDistance = 30,
		MaxDistance = 105,
		SpreadFactor = 0.6,
		Height = 6,
		Smoothness = 7,
	},

	-- Defensa estilo Smash
	Defense = {
		ShieldMax = 50, -- vida del escudo
		ShieldMinToRaise = 8, -- con menos no se puede levantar
		ShieldDrain = 9, -- se gasta por segundo mientras lo mantienes
		ShieldRegen = 7, -- se recarga por segundo sin escudo
		ShieldDamageMult = 1.3, -- daño de los golpes al escudo
		ShieldBreakStun = 2.6, -- aturdimiento al romperse
		RollSpeed = 62, RollTime = 0.3, RollLag = 0.15, -- rodar con escudo + izquierda/derecha
		SpotDodgeTime = 0.3, SpotDodgeLag = 0.12, -- escudo + abajo
		AirDodgeTime = 0.3, AirDodgeLag = 0.2, -- escudo en el aire (1 por salto)
		GrabStartup = 0.08, GrabActive = 0.12, GrabWhiffLag = 0.45, GrabHold = 0.45,
	},

	-- Partidas (Fase 5): con 2+ jugadores empieza una partida; con 1 se juega en modo práctica
	MinPlayersForMatch = 2,
	MatchStocks = 3,
	CountdownTime = 5,
	MatchDuration = 240,
	ResultsTime = 10,
	SpectatorPoint = Vector3.new(0, 300, -30), -- donde esperan los eliminados (fuera de cámara)

	DefaultCharacter = "Brawler",
	SpawnTrainingDummy = true,
}

return CombatConfig
