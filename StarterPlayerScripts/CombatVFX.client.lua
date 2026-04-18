-- StarterPlayerScripts/CombatVFX.client.lua
-- Efectos visuales: daño flotante, particulas, LevelUp, ZonaDesbloqueada

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local EnemyDied     = RemoteEvents:WaitForChild("EnemyDied")
local TakeDamageRE  = RemoteEvents:WaitForChild("TakeDamage")
local LevelUpRE     = RemoteEvents:WaitForChild("LevelUp")
local ZoneUnlocked  = RemoteEvents:WaitForChild("ZoneUnlocked")

local ENEMY_COLORS = {
	SlimeVerde   = Color3.fromRGB(50, 220, 80),
	SlimeRojo    = Color3.fromRGB(220, 50, 50),
	Goblin       = Color3.fromRGB(80, 160, 60),
	GoblinRapido = Color3.fromRGB(50, 120, 40),
	ShadowWolf   = Color3.fromRGB(100, 80, 180),
	GolemFuego   = Color3.fromRGB(255, 100, 20),
	DemonGuard   = Color3.fromRGB(180, 50, 255),
	MiniBoss     = Color3.fromRGB(255, 30, 30),
	VoidTitan    = Color3.fromRGB(80, 0, 200),
}

-- ── Texto flotante ────────────────────────────────────────────────────────────
local function createFloatingText(position3D, text, color, size)
	-- Crear un BillboardGui temporal en el mundo 3D
	local part = Instance.new("Part")
	part.Anchored    = true
	part.CanCollide  = false
	part.Transparency = 1
	part.Size        = Vector3.new(0.1, 0.1, 0.1)
	part.Position    = position3D + Vector3.new(0, 2, 0)
	part.Parent      = workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Size             = UDim2.new(0, 80, 0, 40)
	billboard.StudsOffset      = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop      = true
	billboard.LightInfluence   = 0
	billboard.Parent           = part

	local label = Instance.new("TextLabel")
	label.Size             = UDim2.new(1, 0, 1, 0)
	label.Text             = text
	label.TextColor3       = color or Color3.fromRGB(255, 80, 80)
	label.TextScaled       = true
	label.Font             = Enum.Font.GothamBold
	label.BackgroundTransparency = 1
	label.TextStrokeTransparency = 0.3
	label.Parent           = billboard

	-- Animar: float up + fade out
	task.spawn(function()
		local startTime = os.clock()
		local duration  = 1.5
		while os.clock() - startTime < duration do
			local t = (os.clock() - startTime) / duration
			part.Position = position3D + Vector3.new(0, 2 + t * 4, 0)
			label.TextTransparency = t
			task.wait(0.03)
		end
		part:Destroy()
	end)
end

-- ── Partículas de muerte de enemigo ───────────────────────────────────────────
local function spawnDeathParticles(position, enemyKey)
	local color = ENEMY_COLORS[enemyKey] or Color3.fromRGB(200, 200, 200)

	-- Crear partículas simples con pequeñas parts
	for i = 1, 6 do
		local part = Instance.new("Part")
		part.Size        = Vector3.new(0.3, 0.3, 0.3)
		part.Position    = position + Vector3.new(math.random(-1,1), 1, math.random(-1,1))
		part.BrickColor  = BrickColor.new(color:ToHex())
		part.Material    = Enum.Material.Neon
		part.Anchored    = false
		part.CanCollide  = false
		part.Velocity    = Vector3.new(math.random(-10,10), math.random(10,20), math.random(-10,10))
		part.Parent      = workspace

		task.delay(1, function()
			if part and part.Parent then
				TweenService:Create(part, TweenInfo.new(0.4), {Transparency = 1}):Play()
				task.wait(0.4)
				part:Destroy()
			end
		end)
	end
end

-- ── Eventos entrada ───────────────────────────────────────────────────────────
EnemyDied.OnClientEvent:Connect(function(position, enemyKey)
	if not position then return end
	-- Partículas de muerte
	spawnDeathParticles(position, enemyKey)
	-- Texto de kill
	createFloatingText(position, "+Kill!", ENEMY_COLORS[enemyKey] or Color3.fromRGB(255, 200, 50))
end)

TakeDamageRE.OnClientEvent:Connect(function(damage, position)
	local pos = position
	if not pos then
		local char = player.Character
		if char and char.PrimaryPart then
			pos = char.PrimaryPart.Position
		end
	end
	if pos then
		createFloatingText(pos, "-" .. tostring(math.floor(damage or 0)), Color3.fromRGB(255, 50, 50), 28)
	end
end)

LevelUpRE.OnClientEvent:Connect(function(level)
	local char = player.Character
	if not char or not char.PrimaryPart then return end
	local pos = char.PrimaryPart.Position

	-- Texto flotante grande
	createFloatingText(pos, "LEVEL UP! → " .. tostring(level), Color3.fromRGB(100, 200, 255))

	-- Flash en la pantalla
	local flash = Instance.new("Frame")
	flash.Size              = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3  = Color3.fromRGB(80, 120, 255)
	flash.BackgroundTransparency = 0.0
	flash.BorderSizePixel   = 0
	flash.ZIndex            = 10
	flash.Parent            = playerGui

	TweenService:Create(flash, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {
		BackgroundTransparency = 1
	}):Play()
	task.delay(0.6, function()
		if flash then flash:Destroy() end
	end)
end)

ZoneUnlocked.OnClientEvent:Connect(function(zoneIndex, zoneData)
	local char = player.Character
	local pos  = char and char.PrimaryPart and char.PrimaryPart.Position or Vector3.new(0, 5, 0)
	local name = zoneData and zoneData.name or ("Zona " .. tostring(zoneIndex))
	createFloatingText(pos + Vector3.new(0, 4, 0), "🗺 " .. name .. " ¡Desbloqueada!", Color3.fromRGB(255, 220, 50))
end)
