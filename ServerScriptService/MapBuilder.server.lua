-- ServerScriptService/MapBuilder.server.lua
-- Construye el mapa completo de SurvivalRush usando BaseParts + InsertService
-- Solo corre una vez: si el mapa ya existe, no hace nada.

local RunService    = game:GetService("RunService")
local InsertService = game:GetService("InsertService")
local Workspace     = game:GetService("Workspace")
local Lighting      = game:GetService("Lighting")

-- Solo construir en Studio (o la primera vez en un servidor sin mapa)
local mapFolder = Workspace:FindFirstChild("SurvivalRushMap")
if mapFolder then
	print("[MapBuilder] Mapa ya existe, saltando construcción.")
	return
end

print("[MapBuilder] Construyendo mapa de SurvivalRush...")

-- ══════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ══════════════════════════════════════════════════════════════════════════════

local map = Instance.new("Folder")
map.Name   = "SurvivalRushMap"
map.Parent = Workspace

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored    = true
	p.CanCollide  = true
	p.TopSurface  = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent or map
	return p
end

local function wedge(props, parent)
	local w = Instance.new("WedgePart")
	w.Anchored    = true
	w.CanCollide  = true
	w.TopSurface  = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		w[k] = v
	end
	w.Parent = parent or map
	return w
end

local function label3D(text, position, color, parent)
	local billboard = part({
		Size     = Vector3.new(0.1, 0.1, 0.1),
		Position = position,
		Transparency = 1,
		CanCollide = false,
	}, parent or map)

	local b = Instance.new("BillboardGui")
	b.Size          = UDim2.new(0, 300, 0, 60)
	b.StudsOffset   = Vector3.new(0, 3, 0)
	b.AlwaysOnTop   = false
	b.Parent        = billboard

	local t = Instance.new("TextLabel")
	t.Size          = UDim2.new(1, 0, 1, 0)
	t.Text          = text
	t.TextColor3    = color or Color3.fromRGB(255, 255, 255)
	t.TextScaled    = true
	t.Font          = Enum.Font.GothamBold
	t.BackgroundTransparency = 1
	t.TextStrokeTransparency = 0
	t.Parent        = b

	return billboard
end

local function addSurface(surfaceGui, parent)
	surfaceGui.Parent = parent
end

local function tryInsertModel(assetId, position, name, parent)
	local ok, model = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if ok and model then
		local child = model:GetChildren()[1]
		if child then
			child.Name   = name or child.Name
			child.Parent = parent or map
			if child:IsA("Model") and child.PrimaryPart then
				child:SetPrimaryPartCFrame(CFrame.new(position))
			elseif child:IsA("BasePart") then
				child.Position = position
			end
			model:Destroy()
			return child
		end
	end
	return nil
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DEL MAPA
-- ══════════════════════════════════════════════════════════════════════════════

-- Layout horizontal en Z: BASE(0) → Z1(300) → Z2(650) → Z3(1050) → Z4(1500)
-- Cada zona tiene su folder

local folders = {}
for _, name in ipairs({"Base", "Zona1", "Zona2", "Zona3", "Zona4", "Doors", "Props"}) do
	local f = Instance.new("Folder")
	f.Name   = name
	f.Parent = map
	folders[name] = f
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CONFIGURAR ILUMINACIÓN GLOBAL
-- ══════════════════════════════════════════════════════════════════════════════
Lighting.Brightness      = 2
Lighting.ClockTime       = 14
Lighting.Ambient         = Color3.fromRGB(80, 80, 100)
Lighting.OutdoorAmbient  = Color3.fromRGB(120, 120, 140)
Lighting.FogEnd          = 1200
Lighting.FogStart        = 800
Lighting.FogColor        = Color3.fromRGB(180, 190, 210)

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density   = 0.4
atmosphere.Offset    = 0.1
atmosphere.Color     = Color3.fromRGB(150, 170, 200)
atmosphere.Glare     = 0.3
atmosphere.Haze      = 1.5
atmosphere.Parent    = Lighting

-- ══════════════════════════════════════════════════════════════════════════════
-- BASE (HOME BASE) — Centro del mapa
-- ══════════════════════════════════════════════════════════════════════════════
print("[MapBuilder] Construyendo Base...")
local BASE_CENTER = Vector3.new(0, 0, 0)
local BASE_Y      = 0  -- piso Y

-- Piso principal de la base
part({
	Name     = "BasePlatform",
	Size     = Vector3.new(160, 4, 160),
	Position = Vector3.new(BASE_CENTER.X, BASE_Y - 2, BASE_CENTER.Z),
	Material = Enum.Material.SmoothPlastic,
	Color    = Color3.fromRGB(50, 55, 70),
}, folders.Base)

-- Borde decorativo
for i = 0, 3 do
	local angle = math.rad(i * 90)
	local bx    = math.cos(angle) * 80
	local bz    = math.sin(angle) * 80
	part({
		Name     = "BaseBorder_" .. i,
		Size     = Vector3.new(4, 3, 160),
		Position = Vector3.new(bx, BASE_Y + 1.5, bz),
		CFrame   = CFrame.new(bx, BASE_Y + 1.5, bz) * CFrame.Angles(0, angle, 0),
		Material = Enum.Material.Neon,
		Color    = Color3.fromRGB(80, 120, 255),
	}, folders.Base)
end

-- Plataforma de spawn (círculo central en el centro)
part({
	Name     = "SpawnPlatform",
	Size     = Vector3.new(30, 1, 30),
	Position = Vector3.new(0, BASE_Y + 0.5, 0),
	Material = Enum.Material.SmoothPlastic,
	Color    = Color3.fromRGB(70, 80, 100),
}, folders.Base)

-- Spawn point
local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name     = "SpawnLocation"
spawnLocation.Size     = Vector3.new(6, 1, 6)
spawnLocation.Position = Vector3.new(0, BASE_Y + 1.5, 0)
spawnLocation.Material = Enum.Material.Neon
spawnLocation.Color    = Color3.fromRGB(80, 180, 255)
spawnLocation.AllowTeamChangeOnTouch = false
spawnLocation.Neutral  = true
spawnLocation.TopSurface = Enum.SurfaceType.Smooth
spawnLocation.Anchored = true
spawnLocation.Parent   = folders.Base

-- ── Cofre de regalo diario (lado izquierdo) ────────────────────────────────
local chestPlatform = part({
	Name     = "ChestPlatform",
	Size     = Vector3.new(12, 1, 12),
	Position = Vector3.new(-50, BASE_Y + 0.5, -20),
	Material = Enum.Material.SmoothPlastic,
	Color    = Color3.fromRGB(100, 80, 40),
}, folders.Base)

-- Cofre visual
part({
	Name     = "DailyChest",
	Size     = Vector3.new(5, 4, 4),
	Position = Vector3.new(-50, BASE_Y + 3, -20),
	Material = Enum.Material.SmoothPlastic,
	Color    = Color3.fromRGB(180, 120, 30),
}, folders.Base)
part({
	Name     = "DailyChestLid",
	Size     = Vector3.new(5, 1.5, 4),
	Position = Vector3.new(-50, BASE_Y + 5.75, -20),
	Material = Enum.Material.SmoothPlastic,
	Color    = Color3.fromRGB(220, 160, 40),
}, folders.Base)
part({
	Name     = "DailyChestGlow",
	Size     = Vector3.new(5.2, 0.2, 4.2),
	Position = Vector3.new(-50, BASE_Y + 2, -20),
	Material = Enum.Material.Neon,
	Color    = Color3.fromRGB(255, 200, 50),
	CanCollide = false,
}, folders.Base)
label3D("🎁 REGALO DIARIO", Vector3.new(-50, BASE_Y + 9, -20), Color3.fromRGB(255, 200, 50), folders.Base)

-- ── Panel de clases (derecha) ──────────────────────────────────────────────
part({
	Name     = "ClassPanel",
	Size     = Vector3.new(16, 8, 1),
	Position = Vector3.new(50, BASE_Y + 5, -20),
	Material = Enum.Material.SmoothPlastic,
	Color    = Color3.fromRGB(30, 40, 80),
}, folders.Base)
part({
	Name     = "ClassPanelGlow",
	Size     = Vector3.new(16.2, 8.2, 0.3),
	Position = Vector3.new(50, BASE_Y + 5, -20.3),
	Material = Enum.Material.Neon,
	Color    = Color3.fromRGB(100, 150, 255),
	CanCollide = false,
}, folders.Base)
label3D("⚔ SELECCIÓN DE CLASE", Vector3.new(50, BASE_Y + 12, -20), Color3.fromRGB(100, 180, 255), folders.Base)

-- ── Portal de modos de juego (frente) ──────────────────────────────────────
local function buildPortal(cx, cz, color, labelText, parent)
	-- Bases
	part({ Size=Vector3.new(4,1,4), Position=Vector3.new(cx-5, BASE_Y+0.5, cz), Material=Enum.Material.Neon, Color=color, CanCollide=false }, parent)
	part({ Size=Vector3.new(4,1,4), Position=Vector3.new(cx+5, BASE_Y+0.5, cz), Material=Enum.Material.Neon, Color=color, CanCollide=false }, parent)
	-- Pilares
	part({ Name="PortalPillarL", Size=Vector3.new(2,14,2), Position=Vector3.new(cx-5, BASE_Y+7.5, cz), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(40,40,60) }, parent)
	part({ Name="PortalPillarR", Size=Vector3.new(2,14,2), Position=Vector3.new(cx+5, BASE_Y+7.5, cz), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(40,40,60) }, parent)
	-- Arco superior
	part({ Name="PortalTop",   Size=Vector3.new(12,2,2), Position=Vector3.new(cx, BASE_Y+15, cz), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(40,40,60) }, parent)
	-- Portal interior (neon)
	local portalInner = part({ Name="PortalInner", Size=Vector3.new(8,12,0.5), Position=Vector3.new(cx, BASE_Y+8, cz), Material=Enum.Material.Neon, Color=color, CanCollide=false, Transparency=0.3 }, parent)
	label3D(labelText, Vector3.new(cx, BASE_Y+18, cz), color, parent)
	return portalInner
end

-- Portal hacia Zona 1 (frente)
local portalFolder = Instance.new("Folder")
portalFolder.Name   = "Portals"
portalFolder.Parent = folders.Base

buildPortal(0, -70, Color3.fromRGB(50, 180, 80), "🌿 ZONA 1 — Campo Abierto", portalFolder)

-- Portal de modos de juego
part({ Name="GameModePortalPad", Size=Vector3.new(22,1,22), Position=Vector3.new(0, BASE_Y+0.5, 55), Material=Enum.Material.Neon, Color=Color3.fromRGB(50,50,120), Transparency=0.6, CanCollide=false }, folders.Base)
label3D("🌀 MODOS DE JUEGO\n(Toca para seleccionar)", Vector3.new(0, BASE_Y+8, 55), Color3.fromRGB(150, 150, 255), folders.Base)

-- Rebirth Station (derecha)
local rebirthPad = part({ Name="RebirthStation", Size=Vector3.new(16,1,16), Position=Vector3.new(55, BASE_Y+0.5, 30), Material=Enum.Material.Neon, Color=Color3.fromRGB(150,0,200), Transparency=0.5, CanCollide=false }, folders.Base)
label3D("♻ REBIRTH STATION\n(Nivel 60 requerido)", Vector3.new(55, BASE_Y+10, 30), Color3.fromRGB(200, 100, 255), folders.Base)

-- Leaderboard visual (fondo de la base)
part({ Name="LeaderboardBack", Size=Vector3.new(30,15,1), Position=Vector3.new(0, BASE_Y+8, 78), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(20,20,40) }, folders.Base)
part({ Name="LeaderboardGlow", Size=Vector3.new(30.3,15.3,0.3), Position=Vector3.new(0, BASE_Y+8, 78.3), Material=Enum.Material.Neon, Color=Color3.fromRGB(255,180,30), CanCollide=false, Transparency=0.5 }, folders.Base)
label3D("🏆 LEADERBOARD", Vector3.new(0, BASE_Y+19, 78), Color3.fromRGB(255,200,50), folders.Base)

-- Weapon Rack (cofre giratorio)
part({ Name="WeaponRackBase", Size=Vector3.new(8,1,8), Position=Vector3.new(-30, BASE_Y+0.5, 30), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(80,60,40) }, folders.Base)
part({ Name="WeaponRackChest", Size=Vector3.new(5,4,4), Position=Vector3.new(-30, BASE_Y+3.5, 30), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(100,70,30) }, folders.Base)
part({ Name="WeaponRackGlow", Size=Vector3.new(5.2,4.2,4.2), Position=Vector3.new(-30, BASE_Y+3.5, 30), Material=Enum.Material.Neon, Color=Color3.fromRGB(80,200,255), CanCollide=false, Transparency=0.6 }, folders.Base)
label3D("⚔ ARMA INICIAL\n(Gira para revelar)", Vector3.new(-30, BASE_Y+10, 30), Color3.fromRGB(80,200,255), folders.Base)

-- Luces decorativas en la base
for i = 0, 7 do
	local angle = math.rad(i * 45)
	local lx = math.cos(angle) * 65
	local lz = math.sin(angle) * 65
	part({ Size=Vector3.new(1,8,1), Position=Vector3.new(lx, BASE_Y+4, lz), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(40,40,50) }, folders.Base)
	part({ Size=Vector3.new(2,1.5,2), Position=Vector3.new(lx, BASE_Y+8.5, lz), Material=Enum.Material.Neon, Color=Color3.fromRGB(120,180,255), CanCollide=false }, folders.Base)
end

print("[MapBuilder] Base completada.")
task.wait(0.1)

-- ══════════════════════════════════════════════════════════════════════════════
-- ZONA 1 — CAMPO ABIERTO (Z: -150 a -500)
-- ══════════════════════════════════════════════════════════════════════════════
print("[MapBuilder] Construyendo Zona 1 — Campo Abierto...")

local Z1_CENTER_Z = -340
local Z1_Y        = 0

-- Terreno principal
part({
	Name     = "Z1Terrain",
	Size     = Vector3.new(280, 4, 340),
	Position = Vector3.new(0, Z1_Y - 2, Z1_CENTER_Z),
	Material = Enum.Material.Grass,
	Color    = Color3.fromRGB(90, 140, 60),
}, folders.Zona1)

-- Camino central
part({ Name="Z1Path", Size=Vector3.new(14,0.3,320), Position=Vector3.new(0, Z1_Y+0.16, Z1_CENTER_Z), Material=Enum.Material.Cobblestone, Color=Color3.fromRGB(150,130,100), CanCollide=false }, folders.Zona1)

-- Colinas decorativas
local hills = {
	{-80, Z1_Y-1, -250, 40,12,30},
	{90,  Z1_Y-1, -300, 50,10,35},
	{-100,Z1_Y-1, -400, 35,8,25},
	{85,  Z1_Y-1, -200, 30,9,30},
}
for _, h in ipairs(hills) do
	local hillPart = part({ Size=Vector3.new(h[4],h[5],h[6]), Position=Vector3.new(h[1],h[2],h[3]), Material=Enum.Material.Grass, Color=Color3.fromRGB(80,130,55) }, folders.Zona1)
	hillPart.Name = "Z1Hill"
end

-- Árboles (usando partes simples ya que InsertService puede fallar)
local function buildTree(cx, cy, cz, trunkColor, leafColor, height, width, parentFolder)
	height = height or 12
	width  = width or 8
	-- Tronco
	part({ Name="TreeTrunk", Size=Vector3.new(2,height,2), Position=Vector3.new(cx, cy+height/2, cz), Material=Enum.Material.Wood, Color=trunkColor or Color3.fromRGB(100,70,40), CanCollide=true }, parentFolder)
	-- Copa (3 esferas con cilindros al no tener esferas: usamos partes cilindricas)
	part({ Name="TreeLeaves1", Size=Vector3.new(width,width*0.7,width),   Position=Vector3.new(cx, cy+height+width*0.2, cz),    Material=Enum.Material.Grass, Color=leafColor or Color3.fromRGB(50,140,50), CanCollide=false }, parentFolder)
	part({ Name="TreeLeaves2", Size=Vector3.new(width*0.7,width*0.5,width*0.7), Position=Vector3.new(cx, cy+height+width*0.6, cz), Material=Enum.Material.Grass, Color=leafColor or Color3.fromRGB(60,160,55), CanCollide=false }, parentFolder)
end

local zone1Trees = {
	{-40, Z1_Y, -200}, {40,  Z1_Y, -220}, {-60, Z1_Y, -280},
	{70,  Z1_Y, -260}, {-90, Z1_Y, -320}, {100, Z1_Y, -350},
	{-50, Z1_Y, -400}, {60,  Z1_Y, -420}, {-110,Z1_Y, -180},
	{110, Z1_Y, -190}, {-30, Z1_Y, -450}, {85,  Z1_Y, -460},
}
for _, t in ipairs(zone1Trees) do
	buildTree(t[1], t[2], t[3], Color3.fromRGB(100,70,40), Color3.fromRGB(50,150,50), 10+math.random(0,5), 8+math.random(0,4), folders.Zona1)
end

-- Rocas decorativas
local z1Rocks = {{-70,Z1_Y,-240,5,3,4},{80,Z1_Y,-310,4,2.5,3},{-95,Z1_Y,-370,6,4,5},{105,Z1_Y,-190,3,2,3}}
for _, r in ipairs(z1Rocks) do
	part({ Name="Z1Rock", Size=Vector3.new(r[4],r[5],r[6]), Position=Vector3.new(r[1],r[2]+r[5]/2,r[3]), Material=Enum.Material.Rock, Color=Color3.fromRGB(110,100,95), CFrame=CFrame.new(r[1],r[2]+r[5]/2,r[3])*CFrame.Angles(math.random()*0.3,math.random()*0.5,math.random()*0.3) }, folders.Zona1)
end

-- TIENDAS ZONA 1
local function buildShop(cx, cy, cz, shopName, color, parentFolder)
	-- Base de la tienda
	part({ Name=shopName.."_Floor", Size=Vector3.new(14,0.5,12), Position=Vector3.new(cx, cy+0.25, cz), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(80,70,60) }, parentFolder)
	-- Paredes
	part({ Name=shopName.."_WallBack", Size=Vector3.new(14,10,1), Position=Vector3.new(cx, cy+5.5, cz-5.5), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(120,100,80) }, parentFolder)
	part({ Name=shopName.."_WallL",   Size=Vector3.new(1,10,12), Position=Vector3.new(cx-6.5, cy+5.5, cz),  Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(120,100,80) }, parentFolder)
	part({ Name=shopName.."_WallR",   Size=Vector3.new(1,10,12), Position=Vector3.new(cx+6.5, cy+5.5, cz),  Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(120,100,80) }, parentFolder)
	-- Techo
	part({ Name=shopName.."_Roof",    Size=Vector3.new(16,1,14), Position=Vector3.new(cx, cy+11.5, cz),     Material=Enum.Material.SmoothPlastic, Color=color }, parentFolder)
	-- Mostrador
	part({ Name=shopName.."_Counter", Size=Vector3.new(10,3,2), Position=Vector3.new(cx, cy+2, cz+1),      Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(160,130,90) }, parentFolder)
	-- Sign
	part({ Name=shopName.."_Sign",    Size=Vector3.new(10,3,0.5), Position=Vector3.new(cx, cy+13, cz-5.3), Material=Enum.Material.SmoothPlastic, Color=color }, parentFolder)
	label3D(shopName:gsub("_", " "), Vector3.new(cx, cy+16, cz-5), Color3.fromRGB(255,255,255), parentFolder)
	-- Glow en el techo
	part({ Name=shopName.."_Glow",    Size=Vector3.new(16.2,0.3,14.2), Position=Vector3.new(cx, cy+12.1, cz), Material=Enum.Material.Neon, Color=color, CanCollide=false, Transparency=0.4 }, parentFolder)
end

buildShop(-90, Z1_Y, -250, "Armería Básica",        Color3.fromRGB(80,160,80),  folders.Zona1)
buildShop( 90, Z1_Y, -280, "Farmacia de Velocidad",  Color3.fromRGB(80,160,200), folders.Zona1)

-- Upgrade Bench Zona 1
part({ Name="UpgradeBench_Z1", Size=Vector3.new(8,4,5), Position=Vector3.new(-30, Z1_Y+2, -400), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(80,60,40) }, folders.Zona1)
label3D("⬆ UPGRADE BENCH", Vector3.new(-30, Z1_Y+10, -400), Color3.fromRGB(255,180,50), folders.Zona1)

-- Hoguera decorativa zona 1
part({ Name="Z1Campfire_Stone", Size=Vector3.new(4,1,4), Position=Vector3.new(30, Z1_Y+0.5, -300), Material=Enum.Material.Rock, Color=Color3.fromRGB(100,90,80) }, folders.Zona1)
part({ Name="Z1Campfire_Fire",  Size=Vector3.new(2,3,2), Position=Vector3.new(30, Z1_Y+2.5, -300), Material=Enum.Material.Neon, Color=Color3.fromRGB(255,120,30), CanCollide=false, Transparency=0.2 }, folders.Zona1)

local pl1 = Instance.new("PointLight")
pl1.Brightness = 5; pl1.Range = 30; pl1.Color = Color3.fromRGB(255,120,30)
pl1.Parent = folders.Zona1["Z1Campfire_Fire"] or folders.Zona1:FindFirstChild("Z1Campfire_Fire")

print("[MapBuilder] Zona 1 completada.")
task.wait(0.1)

-- ══════════════════════════════════════════════════════════════════════════════
-- PUERTA entre BASE y ZONA 1
-- ══════════════════════════════════════════════════════════════════════════════
local door1 = part({
	Name     = "ZoneDoor_1_to_2",
	Size     = Vector3.new(14, 18, 2),
	Position = Vector3.new(0, 9, -155),
	Material = Enum.Material.Neon,
	Color    = Color3.fromRGB(50, 200, 80),
	Transparency = 0.6,
	CanCollide   = false,
}, folders.Doors)
-- Pilares de la puerta
part({ Name="Door1_PillarL", Size=Vector3.new(3,20,3), Position=Vector3.new(-8, 10, -155), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(60,60,80) }, folders.Doors)
part({ Name="Door1_PillarR", Size=Vector3.new(3,20,3), Position=Vector3.new( 8, 10, -155), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(60,60,80) }, folders.Doors)
part({ Name="Door1_Arch",    Size=Vector3.new(20,3,3), Position=Vector3.new( 0, 20, -155), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(60,60,80) }, folders.Doors)
label3D("ZONA 1 — Campo Abierto\nNivel 1", Vector3.new(0, 25, -155), Color3.fromRGB(50,220,80), folders.Doors)

-- ══════════════════════════════════════════════════════════════════════════════
-- ZONA 2 — BOSQUE OSCURO (Z: -550 a -900)
-- ══════════════════════════════════════════════════════════════════════════════
print("[MapBuilder] Construyendo Zona 2 — Bosque Oscuro...")

local Z2_CENTER_Z = -720
local Z2_Y        = 0

part({
	Name     = "Z2Terrain",
	Size     = Vector3.new(300, 4, 380),
	Position = Vector3.new(0, Z2_Y - 2, Z2_CENTER_Z),
	Material = Enum.Material.Grass,
	Color    = Color3.fromRGB(30, 60, 30),
}, folders.Zona2)

-- Niebla suelo
part({ Name="Z2GroundFog", Size=Vector3.new(290,1,370), Position=Vector3.new(0, Z2_Y+0.5, Z2_CENTER_Z), Material=Enum.Material.Neon, Color=Color3.fromRGB(20,40,20), Transparency=0.85, CanCollide=false }, folders.Zona2)

-- Camino oscuro
part({ Name="Z2Path", Size=Vector3.new(12,0.4,360), Position=Vector3.new(0, Z2_Y+0.2, Z2_CENTER_Z), Material=Enum.Material.Mud, Color=Color3.fromRGB(50,40,30), CanCollide=false }, folders.Zona2)

-- Árboles oscuros y densos
local zone2Trees = {
	{-35,Z2_Y,-580},{35,Z2_Y,-600},{-55,Z2_Y,-640},{60,Z2_Y,-660},
	{-75,Z2_Y,-700},{80,Z2_Y,-720},{-40,Z2_Y,-760},{45,Z2_Y,-780},
	{-90,Z2_Y,-630},{95,Z2_Y,-650},{-20,Z2_Y,-820},{25,Z2_Y,-840},
	{-110,Z2_Y,-580},{115,Z2_Y,-600},{-60,Z2_Y,-870},{65,Z2_Y,-850},
	{-30,Z2_Y,-900},{30,Z2_Y,-880},{-80,Z2_Y,-800},{85,Z2_Y,-810},
}
for _, t in ipairs(zone2Trees) do
	local h = 14 + math.random(0,8)
	local w = 10 + math.random(0,5)
	buildTree(t[1], t[2], t[3], Color3.fromRGB(40,30,20), Color3.fromRGB(20,60,20), h, w, folders.Zona2)
end

-- Hongos brillantes decorativos
local mushrooms = {{-25,Z2_Y,-620},{50,Z2_Y,-680},{-70,Z2_Y,-740},{40,Z2_Y,-800},{-30,Z2_Y,-860}}
for _, m in ipairs(mushrooms) do
	part({ Name="Z2Mushroom_Stem", Size=Vector3.new(2,4,2), Position=Vector3.new(m[1],m[2]+2,m[3]), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(200,180,160) }, folders.Zona2)
	part({ Name="Z2Mushroom_Cap",  Size=Vector3.new(6,2,6), Position=Vector3.new(m[1],m[2]+5.5,m[3]), Material=Enum.Material.Neon, Color=Color3.fromRGB(100,255,150), CanCollide=false, Transparency=0.2 }, folders.Zona2)
end

-- Piedras luminosas del bosque
for i = 1, 8 do
	local rx = math.random(-120, 120)
	local rz = math.random(-900, -540)
	part({ Name="Z2GlowRock_"..i, Size=Vector3.new(3,2,3), Position=Vector3.new(rx,Z2_Y+1,rz), Material=Enum.Material.Neon, Color=Color3.fromRGB(50,120,80), Transparency=0.4, CanCollide=true }, folders.Zona2)
end

-- Tiendas Zona 2
buildShop(-100, Z2_Y, -660, "Armería Media",    Color3.fromRGB(80,120,200), folders.Zona2)
buildShop( 100, Z2_Y, -720, "Tienda de Stats",  Color3.fromRGB(160,80,200), folders.Zona2)

-- Upgrade Bench Zona 2
part({ Name="UpgradeBench_Z2", Size=Vector3.new(8,4,5), Position=Vector3.new(40, Z2_Y+2, -850), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(60,50,80) }, folders.Zona2)
label3D("⬆ UPGRADE BENCH", Vector3.new(40, Z2_Y+10, -850), Color3.fromRGB(180,100,255), folders.Zona2)

-- Puerta Zona 1 → Zona 2
local door2 = part({
	Name     = "ZoneDoor_2",
	Size     = Vector3.new(14, 20, 2),
	Position = Vector3.new(0, 10, -530),
	Material = Enum.Material.Neon,
	Color    = Color3.fromRGB(30, 80, 180),
	Transparency = 0.6,
	CanCollide   = true,
}, folders.Doors)
part({ Name="Door2_PillarL", Size=Vector3.new(3,22,3), Position=Vector3.new(-8, 11, -530), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(30,30,50) }, folders.Doors)
part({ Name="Door2_PillarR", Size=Vector3.new(3,22,3), Position=Vector3.new( 8, 11, -530), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(30,30,50) }, folders.Doors)
part({ Name="Door2_Arch",    Size=Vector3.new(20,3,3), Position=Vector3.new( 0, 22, -530), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(30,30,50) }, folders.Doors)
label3D("ZONA 2 — Bosque Oscuro\nNivel 10 requerido", Vector3.new(0, 27, -530), Color3.fromRGB(80,140,255), folders.Doors)

print("[MapBuilder] Zona 2 completada.")
task.wait(0.1)

-- ══════════════════════════════════════════════════════════════════════════════
-- ZONA 3 — RUINAS VOLCÁNICAS (Z: -960 a -1350)
-- ══════════════════════════════════════════════════════════════════════════════
print("[MapBuilder] Construyendo Zona 3 — Ruinas Volcánicas...")

local Z3_CENTER_Z = -1150
local Z3_Y        = 0

part({
	Name     = "Z3Terrain",
	Size     = Vector3.new(320, 4, 380),
	Position = Vector3.new(0, Z3_Y - 2, Z3_CENTER_Z),
	Material = Enum.Material.Basalt,
	Color    = Color3.fromRGB(50, 35, 30),
}, folders.Zona3)

-- Lava rivers
local lavaRivers = {
	{-80, Z3_Y+0.3, -1050, 20, 0.4, 80},
	{ 70, Z3_Y+0.3, -1150, 18, 0.4, 100},
	{-50, Z3_Y+0.3, -1250, 15, 0.4, 60},
	{  0, Z3_Y+0.3, -1100, 300,0.4, 12},  -- rio horizontal
}
for _, r in ipairs(lavaRivers) do
	part({ Name="Z3Lava", Size=Vector3.new(r[4],r[5],r[6]), Position=Vector3.new(r[1],r[2],r[3]), Material=Enum.Material.Neon, Color=Color3.fromRGB(255,80,10), Transparency=0.15, CanCollide=false }, folders.Zona3)
end

-- Puentes sobre lava (plataformas)
local bridges = {{-30,Z3_Y,-1080},{30,Z3_Y,-1080},{0,Z3_Y,-1110},{-20,Z3_Y,-1140},{20,Z3_Y,-1140}}
for i, b in ipairs(bridges) do
	part({ Name="Z3Bridge_"..i, Size=Vector3.new(12,1,8), Position=Vector3.new(b[1],b[2]+0.5,b[3]), Material=Enum.Material.Basalt, Color=Color3.fromRGB(70,50,40) }, folders.Zona3)
end

-- Columnas de roca volcánica
local columns = {
	{-100,Z3_Y,-1000,6,25,6},{90,Z3_Y,-1020,5,20,5},
	{-80,Z3_Y,-1200,7,30,6},{85,Z3_Y,-1180,5,22,5},
	{-110,Z3_Y,-1100,4,18,4},{105,Z3_Y,-1120,6,24,6},
}
for _, c in ipairs(columns) do
	part({ Name="Z3Column", Size=Vector3.new(c[4],c[5],c[6]), Position=Vector3.new(c[1],c[2]+c[5]/2,c[3]), Material=Enum.Material.Basalt, Color=Color3.fromRGB(60,40,30) }, folders.Zona3)
	-- Tope brillante
	part({ Name="Z3ColumnTop", Size=Vector3.new(c[4]+2,1,c[6]+2), Position=Vector3.new(c[1],c[2]+c[5]+0.5,c[3]), Material=Enum.Material.Neon, Color=Color3.fromRGB(255,80,10), CanCollide=false, Transparency=0.3 }, folders.Zona3)
end

-- Ruinas (arcos rotos)
local function buildRuin(cx, cy, cz, w, h, parentFolder)
	part({ Name="Ruin_BaseL", Size=Vector3.new(3,h,3), Position=Vector3.new(cx-w/2,cy+h/2,cz), Material=Enum.Material.Basalt, Color=Color3.fromRGB(80,60,50) }, parentFolder)
	part({ Name="Ruin_BaseR", Size=Vector3.new(3,h*0.6,3), Position=Vector3.new(cx+w/2,cy+h*0.3,cz), Material=Enum.Material.Basalt, Color=Color3.fromRGB(80,60,50) }, parentFolder)
	part({ Name="Ruin_Arch",  Size=Vector3.new(w,3,3), Position=Vector3.new(cx,cy+h-1.5,cz), Material=Enum.Material.Basalt, Color=Color3.fromRGB(70,50,40) }, parentFolder)
end

buildRuin(-60, Z3_Y, -1050, 20, 16, folders.Zona3)
buildRuin( 50, Z3_Y, -1200, 18, 14, folders.Zona3)
buildRuin(-30, Z3_Y, -1300, 22, 18, folders.Zona3)

-- Grietas con lava (decorativas)
local cracks = {{0,Z3_Y+0.2,-1050},{-40,Z3_Y+0.2,-1150},{60,Z3_Y+0.2,-1250}}
for _, c in ipairs(cracks) do
	part({ Name="Z3Crack", Size=Vector3.new(3,0.3,20), Position=Vector3.new(c[1],c[2],c[3]), Material=Enum.Material.Neon, Color=Color3.fromRGB(255,60,0), CanCollide=false, Transparency=0.2 }, folders.Zona3)
end

-- Tienda Avanzada Zona 3
buildShop(110, Z3_Y, -1100, "Armería Avanzada", Color3.fromRGB(255,80,20), folders.Zona3)

-- Upgrade Bench Zona 3
part({ Name="UpgradeBench_Z3", Size=Vector3.new(8,4,5), Position=Vector3.new(-100, Z3_Y+2, -1250), Material=Enum.Material.Basalt, Color=Color3.fromRGB(80,30,20) }, folders.Zona3)
label3D("⬆ UPGRADE BENCH", Vector3.new(-100, Z3_Y+10, -1250), Color3.fromRGB(255,100,30), folders.Zona3)

-- Luces de lava ambiental
for i = 1, 10 do
	local lx = math.random(-120, 120)
	local lz = math.random(-1350, -960)
	local glow = part({ Name="Z3LavaGlow_"..i, Size=Vector3.new(2,0.3,2), Position=Vector3.new(lx,Z3_Y+0.2,lz), Material=Enum.Material.Neon, Color=Color3.fromRGB(255,80,0), CanCollide=false, Transparency=0.3 }, folders.Zona3)
end

-- Puerta Zona 2 → Zona 3
local door3 = part({
	Name     = "ZoneDoor_3",
	Size     = Vector3.new(14, 22, 2),
	Position = Vector3.new(0, 11, -940),
	Material = Enum.Material.Neon,
	Color    = Color3.fromRGB(255, 80, 20),
	Transparency = 0.6,
	CanCollide   = true,
}, folders.Doors)
part({ Name="Door3_PillarL", Size=Vector3.new(3,24,3), Position=Vector3.new(-8, 12, -940), Material=Enum.Material.Basalt, Color=Color3.fromRGB(50,30,20) }, folders.Doors)
part({ Name="Door3_PillarR", Size=Vector3.new(3,24,3), Position=Vector3.new( 8, 12, -940), Material=Enum.Material.Basalt, Color=Color3.fromRGB(50,30,20) }, folders.Doors)
part({ Name="Door3_Arch",    Size=Vector3.new(20,3,3), Position=Vector3.new( 0, 24, -940), Material=Enum.Material.Basalt, Color=Color3.fromRGB(50,30,20) }, folders.Doors)
label3D("ZONA 3 — Ruinas Volcánicas\nNivel 30 requerido", Vector3.new(0, 29, -940), Color3.fromRGB(255,120,30), folders.Doors)

print("[MapBuilder] Zona 3 completada.")
task.wait(0.1)

-- ══════════════════════════════════════════════════════════════════════════════
-- ZONA 4 — EL VOID (Z: -1420 a -1900)
-- ══════════════════════════════════════════════════════════════════════════════
print("[MapBuilder] Construyendo Zona 4 — El Void...")

local Z4_CENTER_Z = -1660
local Z4_Y        = 0

-- Piso del Void (oscuro con plataformas flotantes)
part({
	Name     = "Z4Void_Floor",
	Size     = Vector3.new(350, 4, 500),
	Position = Vector3.new(0, Z4_Y - 30, Z4_CENTER_Z),
	Material = Enum.Material.Neon,
	Color    = Color3.fromRGB(5, 0, 15),
	Transparency = 0.5,
	CanCollide = false,
}, folders.Zona4)

-- Plataformas principales
local voidPlatforms = {
	{0,   Z4_Y,   Z4_CENTER_Z,     180, 4, 180},  -- principal
	{-100,Z4_Y-5, -1500,           60,  3, 60},
	{ 100,Z4_Y-5, -1520,           60,  3, 60},
	{-80, Z4_Y-3, -1600,           80,  3, 80},
	{ 80, Z4_Y-3, -1620,           80,  3, 80},
	{0,   Z4_Y,   -1800,           100, 4, 100},  -- boss arena
}
for i, p in ipairs(voidPlatforms) do
	part({ Name="Z4Platform_"..i, Size=Vector3.new(p[4],p[5],p[6]), Position=Vector3.new(p[1],p[2]-p[5]/2,p[3]), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(15,5,30) }, folders.Zona4)
	-- Borde neon
	part({ Name="Z4PlatEdge_"..i, Size=Vector3.new(p[4]+2,0.5,p[6]+2), Position=Vector3.new(p[1],p[2]+0.25,p[3]), Material=Enum.Material.Neon, Color=Color3.fromRGB(120,0,200), CanCollide=false, Transparency=0.3 }, folders.Zona4)
end

-- Pilares del Void
local voidPillars = {
	{-80,Z4_Y,-1460},{80,Z4_Y,-1460},{-80,Z4_Y,-1700},{80,Z4_Y,-1700},
	{-80,Z4_Y,-1860},{80,Z4_Y,-1860},{0,Z4_Y,-1780},
}
for i, p in ipairs(voidPillars) do
	local h = 30 + math.random(0,20)
	part({ Name="Z4Pillar_"..i,     Size=Vector3.new(4,h,4), Position=Vector3.new(p[1],p[2]+h/2,p[3]), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(20,5,40) }, folders.Zona4)
	part({ Name="Z4PillarGlow_"..i, Size=Vector3.new(5,1,5), Position=Vector3.new(p[1],p[2]+h,p[3]),   Material=Enum.Material.Neon, Color=Color3.fromRGB(180,0,255), CanCollide=false, Transparency=0.2 }, folders.Zona4)
end

-- Cristales flotantes del Void
for i = 1, 15 do
	local cx = math.random(-150, 150)
	local cy = math.random(5, 40)
	local cz = math.random(-1900, -1420)
	local cs = math.random(2, 6)
	part({ Name="Z4Crystal_"..i, Size=Vector3.new(cs,cs*2,cs), Position=Vector3.new(cx,cy,cz),
		Material=Enum.Material.Neon, Color=Color3.fromRGB(100+math.random(0,100),0,200+math.random(0,55)),
		CanCollide=false, Transparency=0.3,
		CFrame=CFrame.new(cx,cy,cz)*CFrame.Angles(math.random()*math.pi, math.random()*math.pi, math.random()*math.pi)
	}, folders.Zona4)
end

-- Estrellas del Void (pequeños puntos de luz)
for i = 1, 20 do
	local sx = math.random(-160, 160)
	local sy = math.random(50, 150)
	local sz = math.random(-1900, -1420)
	part({ Name="Z4Star_"..i, Size=Vector3.new(0.5,0.5,0.5), Position=Vector3.new(sx,sy,sz), Material=Enum.Material.Neon, Color=Color3.fromRGB(255,255,255), CanCollide=false, Transparency=0.1 }, folders.Zona4)
end

-- Boss arena (plataforma final)
part({ Name="Z4BossArena_Ring", Size=Vector3.new(105,0.5,105), Position=Vector3.new(0,Z4_Y+0.25,-1800), Material=Enum.Material.Neon, Color=Color3.fromRGB(180,0,200), CanCollide=false, Transparency=0.5 }, folders.Zona4)
label3D("👁 BOSS ARENA — VOID TITAN", Vector3.new(0, Z4_Y+15, -1800), Color3.fromRGB(200,0,255), folders.Zona4)

-- Tienda Legendaria Zona 4
buildShop(110, Z4_Y, -1620, "Tienda del Void", Color3.fromRGB(120, 0, 200), folders.Zona4)

-- Upgrade Bench Zona 4
part({ Name="UpgradeBench_Z4", Size=Vector3.new(8,4,5), Position=Vector3.new(-100, Z4_Y+2, -1700), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(30,10,50) }, folders.Zona4)
label3D("⬆ UPGRADE BENCH", Vector3.new(-100, Z4_Y+10, -1700), Color3.fromRGB(200,100,255), folders.Zona4)

-- Puente entre plataformas flotantes del Void
local bridges4 = {{-40,Z4_Y,-1480},{0,Z4_Y,-1500},{40,Z4_Y,-1480},{-20,Z4_Y,-1540},{20,Z4_Y,-1540}}
for i, b in ipairs(bridges4) do
	part({ Name="Z4Bridge_"..i, Size=Vector3.new(10,1,8), Position=Vector3.new(b[1],b[2]+0.5,b[3]), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(20,5,40) }, folders.Zona4)
end

-- Puerta Zona 3 → Zona 4
local door4 = part({
	Name     = "ZoneDoor_4",
	Size     = Vector3.new(14, 25, 2),
	Position = Vector3.new(0, 12.5, -1410),
	Material = Enum.Material.Neon,
	Color    = Color3.fromRGB(120, 0, 200),
	Transparency = 0.6,
	CanCollide   = true,
}, folders.Doors)
part({ Name="Door4_PillarL", Size=Vector3.new(3,27,3), Position=Vector3.new(-8, 13.5, -1410), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(20,5,40) }, folders.Doors)
part({ Name="Door4_PillarR", Size=Vector3.new(3,27,3), Position=Vector3.new( 8, 13.5, -1410), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(20,5,40) }, folders.Doors)
part({ Name="Door4_Arch",    Size=Vector3.new(20,3,3), Position=Vector3.new( 0, 27,   -1410), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(20,5,40) }, folders.Doors)
label3D("ZONA 4 — El Void\nNivel 60 + Rebirth 1", Vector3.new(0, 32, -1410), Color3.fromRGB(180,0,255), folders.Doors)

print("[MapBuilder] Zona 4 completada.")
task.wait(0.1)

-- ══════════════════════════════════════════════════════════════════════════════
-- PROPS Y DETALLES FINALES
-- ══════════════════════════════════════════════════════════════════════════════

-- Vallado lateral de las zonas (paredes invisibles)
local function addBoundaryWalls(zStart, zEnd, width, y)
	part({ Name="BoundL", Size=Vector3.new(2,30,math.abs(zEnd-zStart)), Position=Vector3.new(-width/2, y+15, (zStart+zEnd)/2), Transparency=1, CanCollide=true }, folders.Props)
	part({ Name="BoundR", Size=Vector3.new(2,30,math.abs(zEnd-zStart)), Position=Vector3.new( width/2, y+15, (zStart+zEnd)/2), Transparency=1, CanCollide=true }, folders.Props)
end

addBoundaryWalls(-80, -520,  200, 0)   -- Base → final Zona1
addBoundaryWalls(-520, -940, 240, 0)   -- Zona2
addBoundaryWalls(-940,-1400, 260, 0)   -- Zona3
addBoundaryWalls(-1400,-1900,280, 0)   -- Zona4

-- Pared del fondo del Void
part({ Name="VoidBackWall", Size=Vector3.new(290,60,2), Position=Vector3.new(0,30,-1910), Transparency=0.9, CanCollide=true, Material=Enum.Material.Neon, Color=Color3.fromRGB(80,0,120) }, folders.Props)

-- Piso invisible bajo el void (seguridad anti-caída)
part({ Name="VoidSafety", Size=Vector3.new(400,2,600), Position=Vector3.new(0,-60,-1300), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(0,0,0), CanCollide=true, Transparency=1 }, folders.Props)

-- Señales de dirección en el camino
local signs = {
	{0, 0, -130, "↓ Zona 1", Color3.fromRGB(50,220,80)},
	{0, 0, -510, "↓ Zona 2 (Nivel 10)", Color3.fromRGB(80,140,255)},
	{0, 0, -920, "↓ Zona 3 (Nivel 30)", Color3.fromRGB(255,120,30)},
	{0, 0,-1390, "↓ Zona 4 (Nivel 60+R)", Color3.fromRGB(180,0,255)},
}
for _, s in ipairs(signs) do
	part({ Name="DirectionSign", Size=Vector3.new(1,8,1), Position=Vector3.new(s[1]+10,s[2]+4,s[3]), Material=Enum.Material.Wood, Color=Color3.fromRGB(100,70,40) }, folders.Props)
	part({ Name="DirectionSignBoard", Size=Vector3.new(10,3,0.5), Position=Vector3.new(s[1]+14,s[2]+8,s[3]), Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(50,50,70) }, folders.Props)
	label3D(s[4], Vector3.new(s[1]+14, s[2]+12, s[3]), s[5], folders.Props)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SPAWN ENEMIES REFERENCE FOLDER (vacío, para el spawner)
-- ══════════════════════════════════════════════════════════════════════════════
local enemiesFolder = Instance.new("Folder")
enemiesFolder.Name   = "Enemies"
enemiesFolder.Parent = game:GetService("ServerStorage")

local weaponsFolder = Instance.new("Folder")
weaponsFolder.Name   = "Weapons"
weaponsFolder.Parent = game:GetService("ServerStorage")

print("[MapBuilder] ✅ Mapa de SurvivalRush construido exitosamente!")
print("[MapBuilder] Zonas: BASE | Z1(Campo Abierto) | Z2(Bosque Oscuro) | Z3(Ruinas Volcánicas) | Z4(El Void)")
print("[MapBuilder] Tiendas: Armería Básica, Farmacia Velocidad, Armería Media, Tienda Stats, Armería Avanzada, Tienda del Void")
print("[MapBuilder] Puertas: ZoneDoor_2, ZoneDoor_3, ZoneDoor_4 (CanCollide=true por defecto)")
