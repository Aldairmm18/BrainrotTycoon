-- ServerScriptService/EnemySpawner.server.lua
-- Genera oleadas de enemigos por jugador cada 45 segundos

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerStorage       = game:GetService("ServerStorage")
local PathfindingService  = game:GetService("PathfindingService")
local RunService          = game:GetService("RunService")

local EnemyConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EnemyConfig"))

local WAVE_INTERVAL = 45
local BASE_SPAWN_DISTANCE = 50

local function waitForDSM()
	local t = 0
	while not _G.DataStoreManager and t < 10 do
		task.wait(0.5)
		t += 0.5
	end
	return _G.DataStoreManager
end
local DSM = waitForDSM()

-- Estado de oleadas por jugador
local playerWaves = {}  -- [userId] = {wave=N, enemies={}}

-- ── Lógica de oleadas ─────────────────────────────────────────────────────────
local function getEnemiesForWave(wave, data)
	local enemies = {}
	local currentZone = #(data.unlockedZones or {1})  -- zona más alta desbloqueada

	-- Escalar HP y speed cada 5 oleadas
	local scaleFactor = 1 + math.floor(wave / 5) * 0.2

	if wave == 1 then
		for i = 1, 5 do table.insert(enemies, {key="SlimeVerde", scale=scaleFactor}) end

	elseif wave == 2 then
		for i = 1, 8 do table.insert(enemies, {key="SlimeVerde", scale=scaleFactor}) end
		for i = 1, 3 do table.insert(enemies, {key="Goblin",     scale=scaleFactor}) end

	elseif wave == 3 then
		for i = 1, 10 do table.insert(enemies, {key="Goblin",      scale=scaleFactor}) end
		if currentZone >= 2 then
			for i = 1, 2 do table.insert(enemies, {key="ShadowWolf", scale=scaleFactor}) end
		end

	elseif wave % 5 == 0 then
		-- Mini-boss wave
		table.insert(enemies, {key="MiniBoss", scale=scaleFactor})
		local count = 10 + wave * 0.5
		for i = 1, math.floor(count) do
			table.insert(enemies, {key="Goblin", scale=scaleFactor})
		end
	else
		-- Oleadas normales escaladas por zona
		local zonalEnemies = EnemyConfig.ZONE_ENEMIES[currentZone] or {"SlimeVerde"}
		local count = 8 + wave * 2
		for i = 1, math.min(count, 30) do
			local pick = zonalEnemies[math.random(1, #zonalEnemies)]
			table.insert(enemies, {key=pick, scale=scaleFactor})
		end
	end

	return enemies
end

-- ── Spawn de un enemigo ───────────────────────────────────────────────────────
local function spawnEnemy(player, enemyKey, scaleFactor)
	local config = EnemyConfig[enemyKey]
	if not config then return end

	-- Intentar clonar modelo desde ServerStorage
	local template = nil
	local enemiesFolder = ServerStorage:FindFirstChild("Enemies")
	if enemiesFolder then
		template = enemiesFolder:FindFirstChild(enemyKey)
	end

	local model
	if template then
		model = template:Clone()
	else
		-- Crear modelo básico si no existe template
		model = Instance.new("Model")
		model.Name = enemyKey

		local root = Instance.new("Part")
		root.Name        = "HumanoidRootPart"
		root.Size        = config.size or Vector3.new(4, 5, 4)
		root.BrickColor   = BrickColor.new(config.color and Color3.toHex(config.color) or "Bright red")
		root.Anchored    = false
		root.CanCollide  = true
		root.Parent      = model

		local humanoid = Instance.new("Humanoid")
		humanoid.MaxHealth  = config.hp * scaleFactor
		humanoid.Health     = config.hp * scaleFactor
		humanoid.WalkSpeed  = config.speed
		humanoid.Parent     = model

		model.PrimaryPart = root
	end

	-- Setear atributos
	model:SetAttribute("HP",       config.hp * scaleFactor)
	model:SetAttribute("MaxHP",    config.hp * scaleFactor)
	model:SetAttribute("Damage",   config.damage * scaleFactor)
	model:SetAttribute("Speed",    config.speed)
	model:SetAttribute("XP",       config.xp)
	model:SetAttribute("Coins",    config.coins)
	model:SetAttribute("TargetId", player.UserId)
	model:SetAttribute("EnemyKey", enemyKey)

	-- Posición aleatoria lejos del jugador
	local char = player.Character
	local spawnPos = Vector3.new(
		math.random(-200, 200),
		5,
		math.random(-200, 200)
	)
	if char and char.PrimaryPart then
		local dir = Vector3.new(math.random(-1,1), 0, math.random(-1,1)).Unit
		spawnPos = char.PrimaryPart.Position + dir * BASE_SPAWN_DISTANCE
		spawnPos = Vector3.new(spawnPos.X, 5, spawnPos.Z)
	end

	model.Parent = workspace
	if model.PrimaryPart then
		model:SetPrimaryPartCFrame(CFrame.new(spawnPos))
	end

	-- ── Movimiento hacia el jugador ───────────────────────────────────────────
	task.spawn(function()
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		while model.Parent and humanoid.Health > 0 do
			local targetChar = player.Character
			if targetChar and targetChar.PrimaryPart then
				humanoid:MoveTo(targetChar.PrimaryPart.Position)
			end
			task.wait(0.5)
		end
	end)

	-- ── Daño al jugador en contacto ────────────────────────────────────────────
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if root then
		root.Touched:Connect(function(hit)
			local hitChar = hit.Parent
			if hitChar == player.Character then
				local playerHumanoid = hitChar:FindFirstChildOfClass("Humanoid")
				if playerHumanoid and playerHumanoid.Health > 0 then
					local dmg = model:GetAttribute("Damage") or config.damage
					playerHumanoid:TakeDamage(dmg)
					task.wait(1) -- cooldown de daño
				end
			end
		end)
	end

	-- Registrar enemigo activo
	local userId = tostring(player.UserId)
	if playerWaves[userId] then
		table.insert(playerWaves[userId].enemies, model)
	end

	return model
end

-- ── Limpiar enemigos del jugador ──────────────────────────────────────────────
local function cleanupEnemies(userId)
	local state = playerWaves[userId]
	if not state then return end
	for _, enemy in ipairs(state.enemies) do
		if enemy and enemy.Parent then
			enemy:Destroy()
		end
	end
	state.enemies = {}
end

-- ── Loop de oleadas por jugador ───────────────────────────────────────────────
local function startWaveLoop(player)
	local userId  = tostring(player.UserId)
	playerWaves[userId] = {wave = 0, enemies = {}}

	while player.Parent and Players:FindFirstChild(player.Name) do
		task.wait(WAVE_INTERVAL)
		if not player.Parent then break end

		local data = DSM and DSM.Get(userId)
		if not data then break end

		-- No spawnear en modo Creativo
		if data.currentGameMode == "Creative" then
			task.wait(5)
			continue
		end

		playerWaves[userId].wave += 1
		local wave     = playerWaves[userId].wave
		local toSpawn  = getEnemiesForWave(wave, data)

		-- ShadowWolf en manada
		local finalList = {}
		for _, entry in ipairs(toSpawn) do
			local cfg = EnemyConfig[entry.key]
			if cfg and cfg.packSize then
				for p = 1, cfg.packSize do
					table.insert(finalList, entry)
				end
			else
				table.insert(finalList, entry)
			end
		end

		for _, entry in ipairs(finalList) do
			task.wait(0.3)
			spawnEnemy(player, entry.key, entry.scale)
		end
	end

	cleanupEnemies(userId)
	playerWaves[userId] = nil
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	task.wait(3)
	task.spawn(startWaveLoop, player)
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = tostring(player.UserId)
	cleanupEnemies(userId)
	playerWaves[userId] = nil
end)
