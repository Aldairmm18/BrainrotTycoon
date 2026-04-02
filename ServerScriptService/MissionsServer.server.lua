-- MissionsServer (Script)
-- ServerScriptService/MissionsServer
-- Daily missions system: 3 random missions per player, reset each day.

local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(script.Parent.BrainrotData)

local RemoteEvents   = ReplicatedStorage:WaitForChild("RemoteEvents")
local GetMissions    = RemoteEvents:WaitForChild("GetMissions")
local MissionUpdate  = RemoteEvents:WaitForChild("MissionUpdate")
local ClaimMission   = RemoteEvents:WaitForChild("ClaimMission")

local missionStore = DataStoreService:GetDataStore("BrainrotMissions_v1")

-- ─── Mission Pool ──────────────────────────────────────────────────────────────
local MISSION_POOL = {
	{ id="buy_eggs_5",      desc="Compra 5 huevos",              goal=5,         reward=2500,  type="eggs_bought" },
	{ id="get_rare",        desc="Consigue un Rare o mejor",     goal=1,         reward=5000,  type="rare_obtained" },
	{ id="play_10min",      desc="Juega 10 minutos",             goal=600,       reward=1000,  type="time_played" },
	{ id="earn_50k",        desc="Gana $50,000 de income",       goal=50000,     reward=3000,  type="cash_earned" },
	{ id="buy_shop_3",      desc="Compra 3 items del shop",      goal=3,         reward=2000,  type="shop_bought" },
	{ id="open_shop_5",     desc="Abre el shop 5 veces",         goal=5,         reward=1500,  type="shop_opened" },
	{ id="get_10_brainrots",desc="Consigue 10 Brainrots",        goal=10,        reward=10000, type="brainrots_total" },
	{ id="get_epic",        desc="Consigue un Epic o mejor",     goal=1,         reward=15000, type="epic_obtained" },
}

-- In-memory mission state: [userId] = { missions={}, date="YYYY-MM-DD", sessionStart }
local _missions = {}

local function getTodayDate()
	-- Returns YYYY-MM-DD using UTC os.time
	local t = os.date("!*t", os.time())
	return string.format("%04d-%02d-%02d", t.year, t.month, t.day)
end

local function pickDailyMissions()
	-- Shuffle pool and pick 3
	local pool = {}
	for _, m in ipairs(MISSION_POOL) do table.insert(pool, m) end
	-- Fisher-Yates
	for i = #pool, 2, -1 do
		local j = math.random(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local picked = {}
	for i = 1, 3 do
		table.insert(picked, {
			id       = pool[i].id,
			desc     = pool[i].desc,
			goal     = pool[i].goal,
			reward   = pool[i].reward,
			type     = pool[i].type,
			progress = 0,
			claimed  = false,
		})
	end
	return picked
end

local function initMissions(userId)
	local today = getTodayDate()
	local saved
	local ok, err = pcall(function()
		saved = missionStore:GetAsync(tostring(userId))
	end)
	if not ok then
		warn("[MissionsServer] Load failed for " .. userId .. ": " .. tostring(err))
	end

	if saved and saved.date == today then
		_missions[userId] = saved
	else
		_missions[userId] = {
			date         = today,
			missions     = pickDailyMissions(),
			sessionStart = os.time(),
		}
	end
end

local function saveMissions(userId)
	local state = _missions[userId]
	if not state then return end
	local ok, err = pcall(function()
		missionStore:SetAsync(tostring(userId), state)
	end)
	if not ok then
		warn("[MissionsServer] Save failed for " .. userId .. ": " .. tostring(err))
	end
end

local function sendMissions(player)
	local state = _missions[player.UserId]
	if not state then return end
	MissionUpdate:FireClient(player, state.missions)
end

-- ─── Progress Tracking API (called by other scripts) ─────────────────────────
local MissionsServer = {}

function MissionsServer.Progress(userId, missionType, amount)
	local state = _missions[userId]
	if not state then return end
	local changed = false
	for _, m in ipairs(state.missions) do
		if m.type == missionType and not m.claimed then
			local before = m.progress
			m.progress = math.min(m.progress + (amount or 1), m.goal)
			if m.progress ~= before then changed = true end
		end
	end
	if changed then
		local player = game:GetService("Players"):GetPlayerByUserId(userId)
		if player then
			MissionUpdate:FireClient(player, state.missions)
		end
	end
end

-- Time-played ticker (runs per-second in EconomyServer loop style)
task.spawn(function()
	while true do
		task.wait(1)
		for userId, state in pairs(_missions) do
			MissionsServer.Progress(userId, "time_played", 1)
		end
	end
end)

-- ─── Claim Handler ────────────────────────────────────────────────────────────
ClaimMission.OnServerEvent:Connect(function(player, missionId)
	local state = _missions[player.UserId]
	if not state then return end

	for _, m in ipairs(state.missions) do
		if m.id == missionId and not m.claimed and m.progress >= m.goal then
			m.claimed = true
			BrainrotData.AddCash(player.UserId, m.reward)
			-- Sync leaderstats
			local data = BrainrotData.Get(player.UserId)
			local ls   = player:FindFirstChild("leaderstats")
			if ls and data then
				local cashVal = ls:FindFirstChild("Cash")
				if cashVal then cashVal.Value = math.floor(data.cash) end
			end
			-- Notify
			MissionUpdate:FireClient(player, state.missions)
			saveMissions(player.UserId)
			break
		end
	end
end)

-- ─── Get Missions Request ─────────────────────────────────────────────────────
GetMissions.OnServerEvent:Connect(sendMissions)

-- ─── Player Join / Leave ─────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	initMissions(player.UserId)
	task.wait(1)   -- wait for leaderstats etc
	sendMissions(player)
end)

Players.PlayerRemoving:Connect(function(player)
	saveMissions(player.UserId)
	_missions[player.UserId] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		initMissions(player.UserId)
		sendMissions(player)
	end)
end

-- Auto-save every 2 minutes
task.spawn(function()
	while true do
		task.wait(120)
		for _, player in ipairs(Players:GetPlayers()) do
			saveMissions(player.UserId)
		end
	end
end)

return MissionsServer
