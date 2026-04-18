-- ServerScriptService/MissionServer.server.lua
-- Misiones diarias: asignación, progreso y reclamo

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MissionConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MissionConfig"))

local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local GetMissions     = RemoteEvents:WaitForChild("GetMissions")
local MissionsData    = RemoteEvents:WaitForChild("MissionsData")
local MissionProgress = RemoteEvents:WaitForChild("MissionProgress")
local ClaimMission    = RemoteEvents:WaitForChild("ClaimMission")
local MissionClaimed  = RemoteEvents:WaitForChild("MissionClaimed")
local UpdateCoins     = RemoteEvents:WaitForChild("UpdateCoins")

local function waitForDSM()
	local t = 0
	while not _G.DataStoreManager and t < 10 do
		task.wait(0.5)
		t += 0.5
	end
	return _G.DataStoreManager
end
local DSM = waitForDSM()

local function getToday()
	return os.date("%Y-%m-%d")
end

-- Seleccionar 1 misión aleatoria de cada dificultad
local function pickDailyMissions()
	local pool   = MissionConfig.POOL
	local easy   = {}
	local medium = {}
	local hard   = {}

	for _, m in ipairs(pool) do
		if m.difficulty == "easy"   then table.insert(easy,   m) end
		if m.difficulty == "medium" then table.insert(medium, m) end
		if m.difficulty == "hard"   then table.insert(hard,   m) end
	end

	local function pick(list)
		return list[math.random(1, #list)]
	end

	return {
		{mission = pick(easy),   progress = 0, claimed = false},
		{mission = pick(medium), progress = 0, claimed = false},
		{mission = pick(hard),   progress = 0, claimed = false},
	}
end

-- Verificar y resetear misiones del día
local function ensureDailyMissions(data)
	local today = getToday()
	if data.lastMissionReset ~= today then
		data.missionsToday     = pickDailyMissions()
		data.lastMissionReset  = today
	end
end

-- ── Solicitar misiones ────────────────────────────────────────────────────────
GetMissions.OnServerEvent:Connect(function(player)
	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	ensureDailyMissions(data)
	DSM.MarkDirty(player)
	MissionsData:FireClient(player, data.missionsToday)
end)

-- ── Actualizar progreso en kills ──────────────────────────────────────────────
local function onKill(player)
	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	ensureDailyMissions(data)

	local updated = false
	for i, entry in ipairs(data.missionsToday or {}) do
		if not entry.claimed then
			local mtype = entry.mission.type
			if mtype == "kill" or mtype == "kill_zone" then
				entry.progress = (entry.progress or 0) + 1
				updated = true

				-- Notificar progreso al cliente
				MissionProgress:FireClient(player, i, entry.progress, entry.mission.target)

				-- Marcar completada si alcanza el objetivo
				if entry.progress >= entry.mission.target then
					-- Completada pero no reclamada
				end
			end
		end
	end

	if updated then DSM.MarkDirty(player) end
end

-- ── Reclamar misión completada ────────────────────────────────────────────────
ClaimMission.OnServerEvent:Connect(function(player, missionIndex)
	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	local entry = data.missionsToday and data.missionsToday[missionIndex]
	if not entry then return end
	if entry.claimed then return end
	if (entry.progress or 0) < entry.mission.target then return end

	entry.claimed = true

	-- Entregar recompensa
	local reward = entry.mission.reward
	if reward then
		if reward.type == "coins" then
			DSM.AddCoins(player, reward.amount or 0)
			UpdateCoins:FireClient(player, data.coins)
		elseif reward.type == "multi" then
			for _, item in ipairs(reward.items or {}) do
				if item.type == "coins" then
					DSM.AddCoins(player, item.amount or 0)
				end
			end
			UpdateCoins:FireClient(player, data.coins)
		end
	end

	-- Marcar misión completada para estrellas
	local timer = _G.TimerServer and _G.TimerServer.getTimer(userId)
	if timer then timer.missionComplete = true end

	DSM.MarkDirty(player)
	MissionClaimed:FireClient(player, missionIndex, reward)
end)

_G.MissionServer = {onKill = onKill}

-- Al entrar jugador: auto-configurar misiones del día
Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	local data = DSM and DSM.Get(tostring(player.UserId))
	if data then
		ensureDailyMissions(data)
		DSM.MarkDirty(player)
	end
end)
