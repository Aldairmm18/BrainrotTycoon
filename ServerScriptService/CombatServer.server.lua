-- ServerScriptService/CombatServer.server.lua
-- Gestiona ataques, daño, muerte y habilidades de clase

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local ClassConfig  = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ClassConfig"))
local WeaponConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WeaponConfig"))

local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local AttackEnemy     = RemoteEvents:WaitForChild("AttackEnemy")
local TakeDamageRE    = RemoteEvents:WaitForChild("TakeDamage")
local EnemyDied       = RemoteEvents:WaitForChild("EnemyDied")
local PlayerDied      = RemoteEvents:WaitForChild("PlayerDied")
local UpdateXP        = RemoteEvents:WaitForChild("UpdateXP")
local UpdateCoins     = RemoteEvents:WaitForChild("UpdateCoins")
local AbilityUsed     = RemoteEvents:WaitForChild("AbilityUsed")
local UseAbility      = RemoteEvents:WaitForChild("UseAbility")
local LevelUp         = RemoteEvents:WaitForChild("LevelUp")

local function waitForDSM()
	local t = 0
	while not _G.DataStoreManager and t < 10 do
		task.wait(0.5)
		t += 0.5
	end
	return _G.DataStoreManager
end
local DSM = waitForDSM()

-- Cooldowns de habilidades por jugador
local abilityCooldowns = {}  -- [userId] = os.clock()

-- Spawn points de base
local BASE_SPAWN_POS = Vector3.new(0, 5, 0)

-- ── Calcular daño del jugador ─────────────────────────────────────────────────
local function calculatePlayerDamage(data)
	local weaponKey = data.equippedWeapon or "EspadaMadera"
	local weaponData = data.ownedWeapons and data.ownedWeapons[weaponKey]
	local upgradeLevel = weaponData and weaponData.level or 1

	local baseDamage = data.baseDamage or 10
	local weaponBase = WeaponConfig[weaponKey] and WeaponConfig[weaponKey].damage or 10
	local multiplier = WeaponConfig.getMultiplier(upgradeLevel)

	return math.floor((baseDamage + weaponBase) * multiplier)
end

-- ── Atacar enemigo ────────────────────────────────────────────────────────────
AttackEnemy.OnServerEvent:Connect(function(player, enemyModel)
	if not enemyModel or not enemyModel.Parent then return end

	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	-- Validar distancia (anti-exploit)
	local char = player.Character
	if not char or not char.PrimaryPart then return end
	if not enemyModel.PrimaryPart then return end

	local distance = (char.PrimaryPart.Position - enemyModel.PrimaryPart.Position).Magnitude
	if distance > 25 then return end  -- max reach

	local damage  = calculatePlayerDamage(data)
	local humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid:TakeDamage(damage)

	if humanoid.Health <= 0 then
		-- Recoger recompensas
		local xp    = enemyModel:GetAttribute("XP")    or 10
		local coins = enemyModel:GetAttribute("Coins")  or 5
		local key   = enemyModel:GetAttribute("EnemyKey") or "SlimeVerde"

		DSM.AddCoins(player, coins)
		data.totalKills = (data.totalKills or 0) + 1
		DSM.MarkDirty(player)

		UpdateCoins:FireClient(player, data.coins)

		-- Notificar experiencia (LevelingServer lo procesa)
		if _G.LevelingServer then
			_G.LevelingServer.addXP(player, xp)
		end

		-- Notificar VFX
		EnemyDied:FireClient(player, enemyModel.PrimaryPart and enemyModel.PrimaryPart.Position, key)

		-- Actualizar misiones
		if _G.MissionServer then
			_G.MissionServer.onKill(player)
		end

		-- Limpiar enemigo
		task.wait(0.1)
		if enemyModel.Parent then
			enemyModel:Destroy()
		end
	end
end)

-- ── Daño al jugador ───────────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid")

		humanoid.Died:Connect(function()
			local userId = tostring(player.UserId)
			local data   = DSM and DSM.Get(userId)
			if data then
				data.totalDeaths = (data.totalDeaths or 0) + 1
				DSM.MarkDirty(player)
			end

			-- Penalizar timer de sesión
			if _G.TimerServer then
				_G.TimerServer.penalize(player, 30)
			end

			PlayerDied:FireClient(player)

			-- Respawn en base
			task.wait(3)
			if player.Parent then
				player:LoadCharacter()
				task.wait(1)
				local newChar = player.Character
				if newChar and newChar.PrimaryPart then
					newChar:SetPrimaryPartCFrame(CFrame.new(BASE_SPAWN_POS))
				end
			end
		end)
	end)
end)

-- ── Habilidades de clase ──────────────────────────────────────────────────────
UseAbility.OnServerEvent:Connect(function(player)
	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	local className = data.selectedClass or "Runner"
	local config    = ClassConfig[className]
	if not config then return end

	-- Cooldown check
	local now      = os.clock()
	local lastUsed = abilityCooldowns[userId] or 0
	if now - lastUsed < config.cooldown then return end
	abilityCooldowns[userId] = now

	-- Contar uso de habilidad para estrellas
	if _G.StarServer then
		_G.StarServer.onAbilityUsed(player)
	end

	local char      = player.Character
	local humanoid  = char and char:FindFirstChildOfClass("Humanoid")
	local ability   = config.ability

	if ability == "sprint" then
		if humanoid then
			humanoid.WalkSpeed = config.speed * 3
			task.delay(3, function()
				if player.Character then
					local h = player.Character:FindFirstChildOfClass("Humanoid")
					if h then h.WalkSpeed = config.speed end
				end
			end)
		end

	elseif ability == "shield" then
		-- Escudo: inmunidad temporal mediante ForceField
		local forceField = Instance.new("ForceField")
		forceField.Visible = true
		forceField.Parent  = char
		task.delay(5, function()
			if forceField and forceField.Parent then
				forceField:Destroy()
			end
		end)

	elseif ability == "berserker" then
		-- +100% daño por 4 segundos (flag en datos)
		data._berserkerUntil = os.clock() + 4
		DSM.MarkDirty(player)

	elseif ability == "aoe_freeze" then
		-- Congelar enemigos cercanos
		local rootPart = char and char.PrimaryPart
		if rootPart then
			for _, obj in ipairs(workspace:GetChildren()) do
				local h = obj:FindFirstChildOfClass("Humanoid")
				local rp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
				if h and rp and obj ~= char then
					local dist = (rootPart.Position - rp.Position).Magnitude
					if dist < 20 then
						local saved = h.WalkSpeed
						h.WalkSpeed = 0
						task.delay(3, function()
							if h and h.Parent then h.WalkSpeed = saved end
						end)
					end
				end
			end
		end

	elseif ability == "invisible" then
		-- Invisibilidad: reducir transparencia de partes
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.LocalTransparencyModifier = 0.9
				end
			end
			task.delay(4, function()
				if player.Character then
					for _, part in ipairs(player.Character:GetDescendants()) do
						if part:IsA("BasePart") then
							part.LocalTransparencyModifier = 0
						end
					end
				end
			end)
		end

	elseif ability == "teleport" then
		-- Teletransportación en la dirección de la cámara del jugador (20 studs)
		local rootPart = char and char.PrimaryPart
		if rootPart then
			local forward = rootPart.CFrame.LookVector
			local newPos  = rootPart.Position + forward * 20
			rootPart.CFrame = CFrame.new(newPos + Vector3.new(0, 2, 0))
		end
	end

	AbilityUsed:FireClient(player, ability, config.cooldown)
end)
