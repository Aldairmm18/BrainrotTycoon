-- ServerScriptService/LeaderboardServer.server.lua
-- 4 leaderboards: Velocidad, Nivel, Supervivencia (semanal), Kills (mensual)

local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents     = ReplicatedStorage:WaitForChild("RemoteEvents")
local GetLeaderboard   = RemoteEvents:WaitForChild("GetLeaderboard")
local LeaderboardData  = RemoteEvents:WaitForChild("LeaderboardData")

local function waitForDSM()
	local t = 0
	while not _G.DataStoreManager and t < 10 do
		task.wait(0.5)
		t += 0.5
	end
	return _G.DataStoreManager
end
local DSM = waitForDSM()

-- Semana y mes actual para reset keys
local function getWeekKey()   return os.date("%Y-W%U") end
local function getMonthKey()  return os.date("%Y-%m") end

local LB = {
	Speed    = DataStoreService:GetOrderedDataStore("SurvivalRush_LB_Speed"),
	Level    = DataStoreService:GetOrderedDataStore("SurvivalRush_LB_Level"),
	Survival = DataStoreService:GetOrderedDataStore("SurvivalRush_LB_Survival_" .. getWeekKey()),
	Kills    = DataStoreService:GetOrderedDataStore("SurvivalRush_LB_Kills_"    .. getMonthKey()),
}

local LB_TYPES = {"Speed", "Level", "Survival", "Kills"}

-- Actualizar una entrada en el leaderboard
local function updateLB(lbType, userId, value)
	local store = LB[lbType]
	if not store then return end
	local ok, err = pcall(function()
		store:SetAsync("u_" .. userId, math.floor(value))
	end)
	if not ok then
		warn("[LeaderboardServer] Error actualizando " .. lbType .. ": " .. tostring(err))
	end
end

-- Obtener top 10
local function getTop10(lbType)
	local store = LB[lbType]
	if not store then return {} end

	local pages
	local ok, err = pcall(function()
		pages = store:GetSortedAsync(false, 10)
	end)
	if not ok or not pages then return {} end

	local entries
	local ok2, err2 = pcall(function()
		entries = pages:GetCurrentPage()
	end)
	if not ok2 then return {} end

	local results = {}
	for rank, data in ipairs(entries or {}) do
		local userId    = tostring(data.key):sub(3) -- remove "u_" prefix
		local value     = data.value
		local name      = "Unknown"

		local ok3, result = pcall(function()
			return Players:GetNameFromUserIdAsync(tonumber(userId))
		end)
		if ok3 and result then name = result end

		table.insert(results, {
			rank    = rank,
			userId  = userId,
			name    = name,
			value   = value,
		})
	end

	return results
end

-- ── Actualizar LBs al cambiar stats ──────────────────────────────────────────
local function refreshPlayerLBs(player)
	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	updateLB("Speed",    userId, data.baseSpeed    or 16)
	updateLB("Level",    userId, data.level        or 1)
	updateLB("Survival", userId, data.bestSessionTime or 0)
	updateLB("Kills",    userId, data.totalKills   or 0)
end

-- ── Solicitud del cliente ─────────────────────────────────────────────────────
GetLeaderboard.OnServerEvent:Connect(function(player, lbType)
	if not table.find(LB_TYPES, lbType) then
		warn("[LeaderboardServer] Tipo inválido: " .. tostring(lbType))
		return
	end

	local top10 = getTop10(lbType)
	LeaderboardData:FireClient(player, lbType, top10)
end)

-- ── Actualizar al salir ───────────────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
	task.spawn(refreshPlayerLBs, player)
end)

-- ── Actualizar periódicamente ─────────────────────────────────────────────────
task.spawn(function()
	while true do
		task.wait(300) -- cada 5 minutos
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(refreshPlayerLBs, player)
		end
	end
end)

-- Exponer para uso externo
_G.LeaderboardServer = {refreshPlayerLBs = refreshPlayerLBs}
