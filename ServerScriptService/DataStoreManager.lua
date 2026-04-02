-- DataStoreManager (Script)
-- ServerScriptService/DataStoreManager
-- Handles loading and saving player data via DataStoreService.

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(script.Parent.BrainrotData)

local store = DataStoreService:GetDataStore("BrainrotTycoon_v1")

local AUTO_SAVE_INTERVAL = 60  -- seconds

-- ─── Helpers ────────────────────────────────────────────────────────────────

local function getKey(player)
	return "player_" .. tostring(player.UserId)
end

local function createLeaderstats(player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name  = "leaderstats"
	leaderstats.Parent = player

	local cashVal = Instance.new("IntValue")
	cashVal.Name   = "Cash"
	cashVal.Value  = data.cash
	cashVal.Parent = leaderstats

	local rebirthVal = Instance.new("IntValue")
	rebirthVal.Name   = "Rebirths"
	rebirthVal.Value  = data.rebirths
	rebirthVal.Parent = leaderstats
end

local function saveData(player)
	local data = BrainrotData.Get(player.UserId)
	if not data then return end

	-- Sync leaderstats from in-memory data
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local cashVal    = ls:FindFirstChild("Cash")
		local rebirthVal = ls:FindFirstChild("Rebirths")
		if cashVal    then cashVal.Value    = data.cash     end
		if rebirthVal then rebirthVal.Value = data.rebirths end
	end

	local key = getKey(player)
	local success, err = pcall(function()
		store:SetAsync(key, {
			cash      = data.cash,
			brainrots = data.brainrots,
			rebirths  = data.rebirths,
		})
	end)

	if not success then
		warn("[DataStoreManager] Failed to save data for", player.Name, "->", err)
	else
		print("[DataStoreManager] Saved data for", player.Name)
	end
end

local function loadData(player)
	local key = getKey(player)
	local savedData

	local success, result = pcall(function()
		savedData = store:GetAsync(key)
	end)

	if not success then
		warn("[DataStoreManager] Failed to load data for", player.Name, "->", result)
		savedData = nil
	end

	BrainrotData.Init(player.UserId, savedData)
	local data = BrainrotData.Get(player.UserId)
	createLeaderstats(player, data)
	print("[DataStoreManager] Loaded data for", player.Name, "| Cash:", data.cash, "| Rebirths:", data.rebirths)
end

-- ─── Event Connections ──────────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
	loadData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	BrainrotData.Remove(player.UserId)
end)

-- Handle server shutdown (game:BindToClose)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveData(player)
	end
end)

-- ─── Auto-Save Loop ─────────────────────────────────────────────────────────

task.spawn(function()
	while true do
		task.wait(AUTO_SAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			saveData(player)
		end
	end
end)
