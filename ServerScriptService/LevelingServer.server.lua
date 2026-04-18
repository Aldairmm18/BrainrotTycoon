-- ServerScriptService/LevelingServer.server.lua
-- XP, subida de nivel y desbloqueo de zonas

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateXP     = RemoteEvents:WaitForChild("UpdateXP")
local LevelUp      = RemoteEvents:WaitForChild("LevelUp")
local UpdateCoins  = RemoteEvents:WaitForChild("UpdateCoins")

local function waitForDSM()
	local t = 0
	while not _G.DataStoreManager and t < 10 do
		task.wait(0.5)
		t += 0.5
	end
	return _G.DataStoreManager
end
local DSM = waitForDSM()

-- XP necesaria para subir del nivel actual al siguiente
local function xpRequired(level)
	return level * 100 + (level * level * 5)
end

-- Stats ganados al subir de nivel
local function applyLevelStats(player, data)
	local char     = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")

	data.baseHP     = (data.baseHP or 100)    + 2
	data.baseSpeed  = (data.baseSpeed or 16)  + 0.1
	data.baseDamage = (data.baseDamage or 10) + 1

	-- Aplicar HP al humanoid
	if humanoid then
		humanoid.MaxHealth = data.baseHP
		if humanoid.Health > data.baseHP then
			humanoid.Health = data.baseHP
		end
	end
end

-- Rebirth XP multiplier
local REBIRTH_MULTIPLIERS = {1.0, 1.5, 2.0, 2.5, 3.0, 3.0, 3.0, 3.0, 3.0, 3.0, 8.0}

local function getXPMultiplier(rebirthCount)
	return REBIRTH_MULTIPLIERS[math.min(rebirthCount + 1, #REBIRTH_MULTIPLIERS)]
end

-- Añadir XP y manejar level up
local function addXP(player, rawXP)
	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	local multiplier = getXPMultiplier(data.rebirthCount or 0)
	local xp         = math.floor(rawXP * multiplier)

	data.xp = (data.xp or 0) + xp

	local leveled = false

	-- Comprobar múltiples subidas de nivel
	while data.xp >= xpRequired(data.level or 1) do
		data.xp    = data.xp - xpRequired(data.level)
		data.level = (data.level or 1) + 1
		leveled    = true

		applyLevelStats(player, data)

		-- Verificar zonas desbloqueadas
		if _G.ZoneServer then
			_G.ZoneServer.checkZoneUnlocks(player, data)
		end

		-- Bonus cada 5 niveles (se le pregunta al cliente por UI)
		local bonusMsg = nil
		if data.level % 5 == 0 then
			bonusMsg = "bonus_choice"
		end

		LevelUp:FireClient(player, data.level, bonusMsg)
	end

	DSM.MarkDirty(player)
	UpdateXP:FireClient(player, data.xp, xpRequired(data.level), data.level)
end

-- Exponer globalmente
_G.LevelingServer = {addXP = addXP}

-- Al entrar jugador: enviar estado actual de XP
Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	local data = DSM and DSM.Get(tostring(player.UserId))
	if data then
		UpdateXP:FireClient(player, data.xp or 0, xpRequired(data.level or 1), data.level or 1)
	end
end)
