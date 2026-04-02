-- LeaderboardGlobal (Script)
-- ServerScriptService/LeaderboardGlobal
-- Maintains an OrderedDataStore for all-time top players.

local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(script.Parent.BrainrotData)

local orderedStore = DataStoreService:GetOrderedDataStore("GlobalLeaderboard_v1")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- We expose a simple RemoteEvent to push leaderboard to clients on request
-- Clients listen via GetGlobalLB (created in default.project.json)
local GetGlobalLB = RemoteEvents:WaitForChild("GetGlobalLB")

-- ─── Score Formula ────────────────────────────────────────────────────────────
local function calcScore(userId)
	local data = BrainrotData.Get(userId)
	if not data then return 0 end
	return math.floor(data.cash + (data.rebirths * 1000000))
end

-- ─── Fetch Top 10 ────────────────────────────────────────────────────────────
local cachedTop = {}

local function fetchTop10()
	local ok, pages = pcall(function()
		return orderedStore:GetSortedAsync(false, 10)
	end)
	if not ok then
		warn("[LeaderboardGlobal] GetSortedAsync failed: " .. tostring(pages))
		return
	end

	local results = {}
	local ok2, err2 = pcall(function()
		local page = pages:GetCurrentPage()
		for rank, entry in ipairs(page) do
			local nameOk, name = pcall(function()
				return game:GetService("Players"):GetNameFromUserIdAsync(entry.key)
			end)
			table.insert(results, {
				rank  = rank,
				name  = nameOk and name or ("Player " .. entry.key),
				score = entry.value,
			})
		end
	end)
	if not ok2 then
		warn("[LeaderboardGlobal] Page read failed: " .. tostring(err2))
		return
	end

	cachedTop = results
end

-- ─── Update Score for a player ────────────────────────────────────────────────
local function updateScore(player)
	local score = calcScore(player.UserId)
	if score <= 0 then return end
	local ok, err = pcall(function()
		orderedStore:SetAsync(tostring(player.UserId), score)
	end)
	if not ok then
		warn("[LeaderboardGlobal] SetAsync failed: " .. tostring(err))
	end
end

-- ─── Client Request ──────────────────────────────────────────────────────────
GetGlobalLB.OnServerEvent:Connect(function(player)
	GetGlobalLB:FireClient(player, cachedTop)
end)

-- ─── Update Loop (every 60 seconds) ──────────────────────────────────────────
task.spawn(function()
	-- Initial fetch
	task.wait(5)
	fetchTop10()

	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			updateScore(player)
		end
		fetchTop10()
	end
end)

Players.PlayerRemoving:Connect(function(player)
	updateScore(player)
end)
