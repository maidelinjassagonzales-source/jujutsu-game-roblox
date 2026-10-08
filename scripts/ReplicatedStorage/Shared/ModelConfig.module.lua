-- GENERADO por tools/models_to_lua.py (modelos de Blender: tools/blender_models.py). No editar a mano.
-- Las mallas están en ServerStorage.MeshLibrary (importadas en Studio con el Importador 3D).
local ModelConfig = {}

ModelConfig.Characters = {
	BloodBrother = {
		Base = {
			{ Mesh = "Char_BloodBrother_Hair", Attach = "Head", Size = Vector3.new(1.591, 1.5404, 1.6836), Offset = Vector3.new(-0.0001, 0.4177, 0.0831), Color = Color3.fromRGB(26, 24, 32), Material = Enum.Material.SmoothPlastic },
		},
	},
	BoogieBrawler = {
		Base = {
			{ Mesh = "Char_BoogieBrawler_Hair", Attach = "Head", Size = Vector3.new(1.5881, 1.3482, 1.6194), Offset = Vector3.new(-0.0001, 0.3448, 0.1151), Color = Color3.fromRGB(40, 30, 25), Material = Enum.Material.SmoothPlastic },
		},
	},
	Brawler = {
		Base = {
			{ Mesh = "Char_Brawler_Hair", Attach = "Head", Size = Vector3.new(1.591, 1.5971, 1.8151), Offset = Vector3.new(-0.0001, 0.446, 0.0182), Color = Color3.fromRGB(240, 150, 165), Material = Enum.Material.SmoothPlastic },
		},
	},
	CurseGrade2 = {
		Base = {
			{ Mesh = "Char_CurseGrade2_Body", Attach = "Torso", Size = Vector3.new(2.9419, 4.6942, 3.0245), Offset = Vector3.new(0, 1.0626, 0.0295), Color = Color3.fromRGB(60, 110, 75), Material = Enum.Material.SmoothPlastic, Hide = { "Head", "Torso" } },
			{ Mesh = "Char_CurseGrade2_Mouth", Attach = "Torso", Size = Vector3.new(1.6742, 0.9, 0.4), Offset = Vector3.new(-0, 1.7, -1.38), Color = Color3.fromRGB(120, 10, 25), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_CurseGrade2_Teeth", Attach = "Torso", Size = Vector3.new(1.58, 0.7196, 0.1177), Offset = Vector3.new(0.04, 1.7, -1.4898), Color = Color3.fromRGB(245, 240, 220), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_CurseGrade2_Eyes", Attach = "Torso", Size = Vector3.new(1.2545, 0.24, 0.16), Offset = Vector3.new(0, 2.55, -1.35), Color = Color3.fromRGB(255, 40, 40), Material = Enum.Material.Neon },
			{ Mesh = "Char_CurseGrade2_ClawsR", Attach = "Right Arm", Size = Vector3.new(0.7503, 0.8297, 1.0815), Offset = Vector3.new(-0.0049, -1.3569, -0.6623), Color = Color3.fromRGB(230, 225, 205), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_CurseGrade2_ClawsL", Attach = "Left Arm", Size = Vector3.new(0.7503, 0.8297, 1.0815), Offset = Vector3.new(-0.0049, -1.3569, -0.6623), Color = Color3.fromRGB(230, 225, 205), Material = Enum.Material.SmoothPlastic },
		},
	},
	CurseMaster = {
		Base = {
			{ Mesh = "Char_CurseMaster_Hair", Attach = "Head", Size = Vector3.new(1.8179, 1.2497, 2.0247), Offset = Vector3.new(-0.0157, 0.2723, 0.3041), Color = Color3.fromRGB(26, 24, 32), Material = Enum.Material.SmoothPlastic },
		},
	},
	CurseMinion = {
		Base = {
			{ Mesh = "Char_CurseMinion_Body", Attach = "Torso", Size = Vector3.new(2.6443, 3.684, 2.2164), Offset = Vector3.new(0, 0.9591, -0.0237), Color = Color3.fromRGB(110, 80, 140), Material = Enum.Material.SmoothPlastic, Hide = { "Head", "Torso" } },
			{ Mesh = "Char_CurseMinion_Eyes", Attach = "Torso", Size = Vector3.new(1.1936, 1.3207, 0.1899), Offset = Vector3.new(-0.2181, 1.7845, -0.9826), Color = Color3.fromRGB(255, 235, 90), Material = Enum.Material.Neon },
			{ Mesh = "Char_CurseMinion_Pupils", Attach = "Torso", Size = Vector3.new(0.977, 1.1607, 0.1099), Offset = Vector3.new(-0.2181, 1.7845, -1.0626), Color = Color3.fromRGB(15, 10, 10), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_CurseMinion_Teeth", Attach = "Torso", Size = Vector3.new(1.2867, 0.2998, 0.1277), Offset = Vector3.new(0, 0.6126, -1.0224), Color = Color3.fromRGB(245, 240, 220), Material = Enum.Material.SmoothPlastic },
		},
	},
	CursedKing = {
		Base = {
			{ Mesh = "Char_CursedKing_Hair", Attach = "Head", Size = Vector3.new(1.7379, 1.5896, 1.9086), Offset = Vector3.new(-0.0278, 0.4426, 0.2457), Color = Color3.fromRGB(240, 150, 165), Material = Enum.Material.SmoothPlastic },
		},
	},
	Executor = {
		Base = {
			{ Mesh = "Char_Executor_Hair", Attach = "Head", Size = Vector3.new(1.5908, 1.2979, 1.8351), Offset = Vector3.new(-0.0001, 0.2964, 0.0074), Color = Color3.fromRGB(235, 205, 120), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_Executor_Goggles", Attach = "Head", Size = Vector3.new(0.95, 0.26, 0.06), Offset = Vector3.new(0, 0.06, -0.63), Color = Color3.fromRGB(70, 55, 30), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_Executor_Blade", Attach = "Right Arm", Size = Vector3.new(0.14, 0.6, 2.6), Offset = Vector3.new(0, -1.05, -1.6), Color = Color3.fromRGB(225, 220, 205), Material = Enum.Material.SmoothPlastic },
		},
	},
	FoxNinja = {
		Base = {
			{ Mesh = "Char_FoxNinja_Hair", Attach = "Head", Size = Vector3.new(2.0089, 1.7914, 2.1711), Offset = Vector3.new(0.0294, 0.5434, 0.1089), Color = Color3.fromRGB(250, 205, 60), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_FoxNinja_Headband", Attach = "Head", Size = Vector3.new(1.36, 0.2, 1.36), Offset = Vector3.new(0, 0.42, -0), Color = Color3.fromRGB(30, 40, 90), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_FoxNinja_Plate", Attach = "Head", Size = Vector3.new(0.6, 0.2, 0.05), Offset = Vector3.new(0, 0.42, -0.69), Color = Color3.fromRGB(200, 205, 215), Material = Enum.Material.Metal },
		},
	},
	Gambler = {
		Base = {
			{ Mesh = "Char_Gambler_Hair", Attach = "Head", Size = Vector3.new(1.591, 1.5964, 1.6339), Offset = Vector3.new(-0.0001, 0.4457, 0.1085), Color = Color3.fromRGB(60, 75, 80), Material = Enum.Material.SmoothPlastic },
		},
	},
	GoldenWarrior = {
		Base = {
			{ Mesh = "Char_GoldenWarrior_Hair", Attach = "Head", Size = Vector3.new(2.5227, 2.1762, 2.2938), Offset = Vector3.new(-0.0004, 0.7359, 0.1659), Color = Color3.fromRGB(26, 24, 32), Material = Enum.Material.SmoothPlastic },
		},
		Transform = {
			{ Mesh = "Char_GoldenWarrior_HairSSJ", Attach = "Head", Size = Vector3.new(2.22, 2.3513, 2.0986), Offset = Vector3.new(-0.0282, 0.8232, 0.2944), Color = Color3.fromRGB(255, 215, 60), Material = Enum.Material.SmoothPlastic },
		},
	},
	Hunter = {
		Base = {
			{ Mesh = "Char_Hunter_Hair", Attach = "Head", Size = Vector3.new(1.5911, 1.288, 1.6969), Offset = Vector3.new(-0.0001, 0.2914, 0.0765), Color = Color3.fromRGB(26, 24, 32), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_Hunter_KatanaBlade", Attach = "Right Arm", Size = Vector3.new(0.1723, 0.4212, 3.5572), Offset = Vector3.new(0, -0.9596, -2.1109), Color = Color3.fromRGB(170, 175, 190), Material = Enum.Material.Metal },
			{ Mesh = "Char_Hunter_KatanaHilt", Attach = "Right Arm", Size = Vector3.new(0.52, 0.52, 1.12), Offset = Vector3.new(0, -1.05, 0.215), Color = Color3.fromRGB(30, 25, 35), Material = Enum.Material.SmoothPlastic },
		},
	},
	NailWitch = {
		Base = {
			{ Mesh = "Char_NailWitch_Hair", Attach = "Head", Size = Vector3.new(2.1522, 1.3131, 2.0163), Offset = Vector3.new(0.0132, 0.304, 0.2231), Color = Color3.fromRGB(185, 105, 55), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_NailWitch_Hammer", Attach = "Right Arm", Size = Vector3.new(0.75, 0.4, 1.75), Offset = Vector3.new(0, -1.05, -0.475), Color = Color3.fromRGB(110, 110, 120), Material = Enum.Material.Metal },
		},
	},
	RubberPirate = {
		Base = {
			{ Mesh = "Char_RubberPirate_Hair", Attach = "Head", Size = Vector3.new(1.8702, 1.2502, 1.8781), Offset = Vector3.new(0.012, 0.2726, 0.1232), Color = Color3.fromRGB(26, 24, 32), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_RubberPirate_Hat", Attach = "Head", Size = Vector3.new(2.3, 0.84, 2.3), Offset = Vector3.new(0, 0.72, -0), Color = Color3.fromRGB(235, 205, 120), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_RubberPirate_HatBand", Attach = "Head", Size = Vector3.new(1.46, 0.16, 1.46), Offset = Vector3.new(0, 0.78, -0), Color = Color3.fromRGB(200, 30, 35), Material = Enum.Material.SmoothPlastic },
		},
	},
	ShadowSummoner = {
		Base = {
			{ Mesh = "Char_ShadowSummoner_Hair", Attach = "Head", Size = Vector3.new(2.3255, 1.9559, 2.1415), Offset = Vector3.new(0.0165, 0.6257, 0.1281), Color = Color3.fromRGB(26, 24, 32), Material = Enum.Material.SmoothPlastic },
		},
	},
	Sorcerer = {
		Base = {
			{ Mesh = "Char_Sorcerer_Hair", Attach = "Head", Size = Vector3.new(1.8465, 2.123, 1.8726), Offset = Vector3.new(-0.001, 0.7093, 0.2094), Color = Color3.fromRGB(240, 242, 250), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_Sorcerer_Blindfold", Attach = "Head", Size = Vector3.new(1.32, 0.28, 1.32), Offset = Vector3.new(0, 0.08, -0.02), Color = Color3.fromRGB(18, 18, 24), Material = Enum.Material.SmoothPlastic },
		},
	},
	Stitched = {
		Base = {
			{ Mesh = "Char_Stitched_Hair", Attach = "Head", Size = Vector3.new(2.2037, 1.3686, 2.3373), Offset = Vector3.new(0.0114, 0.3321, 0.4555), Color = Color3.fromRGB(150, 165, 190), Material = Enum.Material.SmoothPlastic },
		},
	},
	Swordsman = {
		Base = {
			{ Mesh = "Char_Swordsman_Hair", Attach = "Head", Size = Vector3.new(2.1997, 1.4237, 1.8779), Offset = Vector3.new(-0.0436, 0.3596, 0.2102), Color = Color3.fromRGB(26, 24, 32), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_Swordsman_KatanaBlade", Attach = "Right Arm", Size = Vector3.new(0.1723, 0.4213, 3.959), Offset = Vector3.new(0, -0.9595, -2.31), Color = Color3.fromRGB(225, 228, 235), Material = Enum.Material.Metal },
			{ Mesh = "Char_Swordsman_KatanaHilt", Attach = "Right Arm", Size = Vector3.new(0.52, 0.52, 1.12), Offset = Vector3.new(0, -1.05, 0.215), Color = Color3.fromRGB(30, 25, 35), Material = Enum.Material.SmoothPlastic },
		},
	},
	ThreeBlades = {
		Base = {
			{ Mesh = "Char_ThreeBlades_Hair", Attach = "Head", Size = Vector3.new(1.5881, 1.2641, 1.6334), Offset = Vector3.new(-0.0001, 0.28, 0.1082), Color = Color3.fromRGB(60, 140, 75), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_ThreeBlades_KatanaBladeR", Attach = "Right Arm", Size = Vector3.new(0.1723, 0.4213, 3.959), Offset = Vector3.new(0, -0.9595, -2.31), Color = Color3.fromRGB(225, 228, 235), Material = Enum.Material.Metal },
			{ Mesh = "Char_ThreeBlades_KatanaHiltR", Attach = "Right Arm", Size = Vector3.new(0.52, 0.52, 1.12), Offset = Vector3.new(0, -1.05, 0.215), Color = Color3.fromRGB(30, 25, 35), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_ThreeBlades_KatanaBladeL", Attach = "Left Arm", Size = Vector3.new(0.1723, 0.4213, 3.959), Offset = Vector3.new(0, -0.9595, -2.31), Color = Color3.fromRGB(225, 228, 235), Material = Enum.Material.Metal },
			{ Mesh = "Char_ThreeBlades_KatanaHiltL", Attach = "Left Arm", Size = Vector3.new(0.52, 0.52, 1.12), Offset = Vector3.new(0, -1.05, 0.215), Color = Color3.fromRGB(30, 25, 35), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_ThreeBlades_MouthBlade", Attach = "Head", Size = Vector3.new(3, 0.06, 0.22), Offset = Vector3.new(1.9, -0.32, -0.65), Color = Color3.fromRGB(225, 228, 235), Material = Enum.Material.Metal },
			{ Mesh = "Char_ThreeBlades_MouthHilt", Attach = "Head", Size = Vector3.new(1, 0.2, 0.2), Offset = Vector3.new(-0.1, -0.32, -0.65), Color = Color3.fromRGB(20, 20, 25), Material = Enum.Material.SmoothPlastic },
		},
	},
	Viking = {
		Base = {
			{ Mesh = "Char_Viking_Hair", Attach = "Head", Size = Vector3.new(2.296, 1.4495, 2.334), Offset = Vector3.new(0.0001, 0.3722, 0.4021), Color = Color3.fromRGB(225, 190, 110), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_Viking_DaggerR", Attach = "Right Arm", Size = Vector3.new(0.1697, 0.22, 1.6), Offset = Vector3.new(0, -1.05, -1.1), Color = Color3.fromRGB(200, 205, 215), Material = Enum.Material.Metal },
			{ Mesh = "Char_Viking_DaggerHiltR", Attach = "Right Arm", Size = Vector3.new(0.45, 0.16, 0.665), Offset = Vector3.new(0, -1.05, 0.0175), Color = Color3.fromRGB(90, 60, 40), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_Viking_DaggerL", Attach = "Left Arm", Size = Vector3.new(0.1697, 0.22, 1.6), Offset = Vector3.new(0, -1.05, -1.1), Color = Color3.fromRGB(200, 205, 215), Material = Enum.Material.Metal },
			{ Mesh = "Char_Viking_DaggerHiltL", Attach = "Left Arm", Size = Vector3.new(0.45, 0.16, 0.665), Offset = Vector3.new(0, -1.05, 0.0175), Color = Color3.fromRGB(90, 60, 40), Material = Enum.Material.SmoothPlastic },
		},
	},
	VolcanoCurse = {
		Base = {
			{ Mesh = "Char_VolcanoCurse_Head", Attach = "Head", Size = Vector3.new(1.4084, 2.0992, 1.4084), Offset = Vector3.new(0.0001, 0.2504, -0), Color = Color3.fromRGB(210, 185, 150), Material = Enum.Material.SmoothPlastic, Hide = { "Head" } },
			{ Mesh = "Char_VolcanoCurse_Lava", Attach = "Head", Size = Vector3.new(0.92, 0.12, 0.92), Offset = Vector3.new(0, 1.28, -0), Color = Color3.fromRGB(255, 110, 20), Material = Enum.Material.Neon },
			{ Mesh = "Char_VolcanoCurse_Eye", Attach = "Head", Size = Vector3.new(0.5909, 0.52, 0.24), Offset = Vector3.new(-0, 0.1, -0.6), Color = Color3.fromRGB(250, 245, 230), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_VolcanoCurse_Pupil", Attach = "Head", Size = Vector3.new(0.197, 0.24, 0.08), Offset = Vector3.new(-0, 0.1, -0.71), Color = Color3.fromRGB(20, 10, 10), Material = Enum.Material.SmoothPlastic },
		},
	},
	WaterSlayer = {
		Base = {
			{ Mesh = "Char_WaterSlayer_Hair", Attach = "Head", Size = Vector3.new(1.6425, 1.4835, 1.7613), Offset = Vector3.new(0.0209, 0.3892, 0.0464), Color = Color3.fromRGB(110, 30, 35), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_WaterSlayer_Earrings", Attach = "Head", Size = Vector3.new(1.36, 0.35, 0.2), Offset = Vector3.new(0, -0.25, -0.05), Color = Color3.fromRGB(240, 235, 225), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_WaterSlayer_KatanaBlade", Attach = "Right Arm", Size = Vector3.new(0.1723, 0.4213, 3.959), Offset = Vector3.new(0, -0.9595, -2.31), Color = Color3.fromRGB(40, 45, 60), Material = Enum.Material.Metal },
			{ Mesh = "Char_WaterSlayer_KatanaHilt", Attach = "Right Arm", Size = Vector3.new(0.52, 0.52, 1.12), Offset = Vector3.new(0, -1.05, 0.215), Color = Color3.fromRGB(30, 25, 35), Material = Enum.Material.SmoothPlastic },
		},
	},
	WeaponMaster = {
		Base = {
			{ Mesh = "Char_WeaponMaster_Hair", Attach = "Head", Size = Vector3.new(1.591, 1.4847, 1.822), Offset = Vector3.new(-0.0001, 0.1877, 0.1526), Color = Color3.fromRGB(40, 70, 45), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_WeaponMaster_Glasses", Attach = "Head", Size = Vector3.new(1.28, 0.34, 0.63), Offset = Vector3.new(0, 0.06, -0.335), Color = Color3.fromRGB(30, 30, 30), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_WeaponMaster_Staff", Attach = "Right Arm", Size = Vector3.new(0.18, 0.18, 6.2), Offset = Vector3.new(0, -1.05, -0.6), Color = Color3.fromRGB(120, 75, 40), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_WeaponMaster_SpearHead", Attach = "Right Arm", Size = Vector3.new(0.2828, 0.2828, 0.9), Offset = Vector3.new(0, -1.05, -4.1), Color = Color3.fromRGB(200, 205, 215), Material = Enum.Material.Metal },
		},
	},
	YoungSorcerer = {
		Base = {
			{ Mesh = "Char_YoungSorcerer_Hair", Attach = "Head", Size = Vector3.new(2.0907, 1.6754, 1.9443), Offset = Vector3.new(0.0153, 0.4855, 0.1718), Color = Color3.fromRGB(240, 242, 250), Material = Enum.Material.SmoothPlastic },
			{ Mesh = "Char_YoungSorcerer_Sunglasses", Attach = "Head", Size = Vector3.new(0.9, 0.38, 0.05), Offset = Vector3.new(0, 0.05, -0.64), Color = Color3.fromRGB(15, 15, 20), Material = Enum.Material.SmoothPlastic },
		},
	},
}

ModelConfig.Environment = {
	Bamboo = { Mesh = "Env_Bamboo", Attach = "World", Size = Vector3.new(4.2335, 17.6254, 4.5604), Offset = Vector3.new(0.1536, 8.7998, 0.0272), Color = Color3.fromRGB(110, 160, 70), Material = Enum.Material.SmoothPlastic },
	BambooLeaves = { Mesh = "Env_BambooLeaves", Attach = "World", Size = Vector3.new(7.7392, 8.8212, 7.0687), Offset = Vector3.new(0.3505, 13.3918, 0.2254), Color = Color3.fromRGB(90, 170, 80), Material = Enum.Material.SmoothPlastic },
	Bench = { Mesh = "Env_Bench", Attach = "World", Size = Vector3.new(5, 2.9, 1.6), Offset = Vector3.new(0, 1.45, -0), Color = Color3.fromRGB(130, 85, 55), Material = Enum.Material.SmoothPlastic },
	Bridge = { Mesh = "Env_Bridge", Attach = "World", Size = Vector3.new(6.16, 5.1633, 16.36), Offset = Vector3.new(0, 2.3783, -0), Color = Color3.fromRGB(200, 50, 40), Material = Enum.Material.SmoothPlastic },
	Makiwara = { Mesh = "Env_Makiwara", Attach = "World", Size = Vector3.new(2, 5, 2), Offset = Vector3.new(0, 2.5, -0), Color = Color3.fromRGB(120, 80, 50), Material = Enum.Material.SmoothPlastic },
	MakiwaraRope = { Mesh = "Env_MakiwaraRope", Attach = "World", Size = Vector3.new(0.96, 1.26, 0.96), Offset = Vector3.new(0, 3.95, -0), Color = Color3.fromRGB(215, 190, 140), Material = Enum.Material.SmoothPlastic },
	PagodaBody = { Mesh = "Env_PagodaBody", Attach = "World", Size = Vector3.new(9, 32.1, 9), Offset = Vector3.new(0, 15.95, -0), Color = Color3.fromRGB(235, 225, 205), Material = Enum.Material.SmoothPlastic },
	PagodaRoofs = { Mesh = "Env_PagodaRoofs", Attach = "World", Size = Vector3.new(13.2, 22.3768, 13.2), Offset = Vector3.new(0, 15.6616, -0), Color = Color3.fromRGB(55, 58, 72), Material = Enum.Material.SmoothPlastic },
	PortalCharms = { Mesh = "Env_PortalCharms", Attach = "World", Size = Vector3.new(11.9127, 5.4459, 0.05), Offset = Vector3.new(0, 9.4271, -0.95), Color = Color3.fromRGB(245, 235, 200), Material = Enum.Material.SmoothPlastic },
	PortalStone = { Mesh = "Env_PortalStone", Attach = "World", Size = Vector3.new(16, 13.1267, 4.5), Offset = Vector3.new(0, 6.4633, -0), Color = Color3.fromRGB(95, 92, 100), Material = Enum.Material.SmoothPlastic },
	PortalSwirl = { Mesh = "Env_PortalSwirl", Attach = "World", Size = Vector3.new(10.6716, 10.8309, 1.3337), Offset = Vector3.new(-0.2792, 6.1976, -0), Color = Color3.fromRGB(170, 80, 255), Material = Enum.Material.Neon },
	Rock = { Mesh = "Env_Rock", Attach = "World", Size = Vector3.new(6.4174, 5.4467, 6.6408), Offset = Vector3.new(-0.3589, 0.1113, 0), Color = Color3.fromRGB(110, 100, 95), Material = Enum.Material.SmoothPlastic },
	Roof = { Mesh = "Env_Roof", Attach = "World", Size = Vector3.new(20, 5.1552, 12), Offset = Vector3.new(0, 2.6474, -0), Color = Color3.fromRGB(60, 62, 75), Material = Enum.Material.SmoothPlastic },
	SakuraCanopy = { Mesh = "Env_SakuraCanopy", Attach = "World", Size = Vector3.new(14.3011, 7.8997, 14.4484), Offset = Vector3.new(0.1305, 10.0026, -0.6222), Color = Color3.fromRGB(255, 180, 205), Material = Enum.Material.SmoothPlastic },
	SakuraTrunk = { Mesh = "Env_SakuraTrunk", Attach = "World", Size = Vector3.new(7.9507, 10.791, 7.8142), Offset = Vector3.new(-0.109, 4.7957, -0.2914), Color = Color3.fromRGB(85, 55, 45), Material = Enum.Material.SmoothPlastic },
	ShopCloth = { Mesh = "Env_ShopCloth", Attach = "World", Size = Vector3.new(14.6, 5, 0.305), Offset = Vector3.new(0, 5.6, -3.8725), Color = Color3.fromRGB(40, 50, 120), Material = Enum.Material.SmoothPlastic },
	ShopGoods = { Mesh = "Env_ShopGoods", Attach = "World", Size = Vector3.new(10.0651, 4.2, 6.57), Offset = Vector3.new(-0.3175, 4.35, 0.235), Color = Color3.fromRGB(235, 205, 150), Material = Enum.Material.SmoothPlastic },
	ShopLamps = { Mesh = "Env_ShopLamps", Attach = "World", Size = Vector3.new(9.5, 2.8, 1.1), Offset = Vector3.new(0, 6.05, -4.1), Color = Color3.fromRGB(255, 150, 90), Material = Enum.Material.Neon },
	ShopRoof = { Mesh = "Env_ShopRoof", Attach = "World", Size = Vector3.new(16.4, 3.95, 12), Offset = Vector3.new(0, 10, -0), Color = Color3.fromRGB(55, 58, 72), Material = Enum.Material.SmoothPlastic },
	ShopWood = { Mesh = "Env_ShopWood", Attach = "World", Size = Vector3.new(15.04, 9, 10.6), Offset = Vector3.new(0, 4.5, -1.05), Color = Color3.fromRGB(120, 78, 50), Material = Enum.Material.SmoothPlastic },
	StoneLantern = { Mesh = "Env_StoneLantern", Attach = "World", Size = Vector3.new(3.2, 6.4, 2.7713), Offset = Vector3.new(0, 3.2, -0), Color = Color3.fromRGB(150, 146, 140), Material = Enum.Material.SmoothPlastic },
	StoneLanternLight = { Mesh = "Env_StoneLanternLight", Attach = "World", Size = Vector3.new(1.05, 1.05, 1.05), Offset = Vector3.new(0, 4, -0), Color = Color3.fromRGB(255, 190, 110), Material = Enum.Material.Neon },
	ToriiBlack = { Mesh = "Env_ToriiBlack", Attach = "World", Size = Vector3.new(15.6196, 2.1243, 0.65), Offset = Vector3.new(0, 12.0371, -0), Color = Color3.fromRGB(30, 25, 25), Material = Enum.Material.SmoothPlastic },
	ToriiRed = { Mesh = "Env_ToriiRed", Attach = "World", Size = Vector3.new(13.2, 11.125, 1.5), Offset = Vector3.new(0, 5.5625, -0), Color = Color3.fromRGB(210, 45, 35), Material = Enum.Material.SmoothPlastic },
	Vending = { Mesh = "Env_Vending", Attach = "World", Size = Vector3.new(3.2, 6.4, 2.2), Offset = Vector3.new(0, 3.2, -0), Color = Color3.fromRGB(200, 40, 45), Material = Enum.Material.SmoothPlastic },
	VendingFront = { Mesh = "Env_VendingFront", Attach = "World", Size = Vector3.new(2.6, 3.2, 0.11), Offset = Vector3.new(0, 4.3, -1.145), Color = Color3.fromRGB(220, 240, 255), Material = Enum.Material.Neon },
	Yatai = { Mesh = "Env_Yatai", Attach = "World", Size = Vector3.new(8.6, 5.6, 4.325), Offset = Vector3.new(0, 2.8, -0.5375), Color = Color3.fromRGB(140, 95, 60), Material = Enum.Material.SmoothPlastic },
	YataiLamps = { Mesh = "Env_YataiLamps", Attach = "World", Size = Vector3.new(7.8, 1.4, 1), Offset = Vector3.new(0, 4.3, -2.2), Color = Color3.fromRGB(255, 120, 80), Material = Enum.Material.Neon },
	YataiNoren = { Mesh = "Env_YataiNoren", Attach = "World", Size = Vector3.new(7.35, 1.3, 0.06), Offset = Vector3.new(0, 4.55, -2.95), Color = Color3.fromRGB(30, 40, 90), Material = Enum.Material.SmoothPlastic },
	YataiRoof = { Mesh = "Env_YataiRoof", Attach = "World", Size = Vector3.new(9.6, 1.3339, 5.6), Offset = Vector3.new(0, 5.6669, -0.2), Color = Color3.fromRGB(200, 60, 50), Material = Enum.Material.SmoothPlastic },
}

return ModelConfig
