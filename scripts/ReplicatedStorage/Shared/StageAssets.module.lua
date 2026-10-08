-- StageAssets: texturas propias de los escenarios (tools/gen_textures.py, subidas a Roblox).
--   Materials -> MaterialVariants "CC_<Nombre>" (color + relieve). Los crea el instalador en MaterialService.
--   Signs     -> imágenes para carteles de neón, pantallas y fachadas (brillan: LightInfluence 0).
local StageAssets = {}

StageAssets.Materials = {
	Stone = { Base = Enum.Material.Slate, Color = 132008276904533, Normal = 114590840067193, Studs = 16 },
	Wood = { Base = Enum.Material.WoodPlanks, Color = 101543149214311, Normal = 98453776753298, Studs = 12 },
	Roof = { Base = Enum.Material.Slate, Color = 107886853902528, Normal = 96176804282757, Studs = 10 },
	Shoji = { Base = Enum.Material.Fabric, Color = 124799561813750, Normal = 109542993861886, Studs = 10 },
	Asphalt = { Base = Enum.Material.Asphalt, Color = 114882783876338, Normal = 109433622452612, Studs = 20 },
	Crosswalk = { Base = Enum.Material.Asphalt, Color = 121248639040898, Normal = 109064108924246, Studs = 16 },
	Shrine = { Base = Enum.Material.Basalt, Color = 76822419165296, Normal = 83451307561384, Studs = 18 },
	Plaster = { Base = Enum.Material.Concrete, Color = 98933316337972, Normal = 88800632999994, Studs = 24 },
}

StageAssets.Signs = {
	Shibuya = 127884677166743,
	Ramen = 90770332168047,
	Karaoke = 109290196132614,
	Jujutsu = 136694671366545,
	Hotel = 120176626965645,
	Facade = 140099622961214,
	Cosmic = 120500493881369,
	Poster = 70439557645692,
}

function StageAssets.VariantName(name: string): string
	return `CC_{name}`
end

-- Crea (o actualiza) los MaterialVariants. Debe ejecutarse con permisos de Studio (instalador).
function StageAssets.InstallVariants()
	local MaterialService = game:GetService("MaterialService")
	for name, m in StageAssets.Materials do
		local variantName = StageAssets.VariantName(name)
		local variant = MaterialService:FindFirstChild(variantName) or Instance.new("MaterialVariant")
		variant.Name = variantName
		variant.BaseMaterial = m.Base
		variant.ColorMap = `rbxassetid://{m.Color}`
		variant.NormalMap = `rbxassetid://{m.Normal}`
		variant.StudsPerTile = m.Studs
		variant.Parent = MaterialService
	end
end

return StageAssets
