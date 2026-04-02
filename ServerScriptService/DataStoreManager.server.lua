-- DataStoreManager (Script)
-- ServerScriptService/DataStoreManager
-- Handles loading/saving player data via DataStore and creating leaderstats.

local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData  = require(script.Parent.BrainrotData)
local RarityConfig  = require(ReplicatedStorage.Modules.RarityConfig)
local BrainrotList  = require(ReplicatedStorage.Modules.BrainrotList)

local DATASTORE_NAME  = "BrainrotTycoon_v1"
local AUTOSAVE_INTERVAL = 60

local playerStore = DataStoreService:GetDataStore(DATASTORE_NAME)

-- ─── Re-place saved Brainrot parts in the workspace ──────────────────────────

local function restoreBrainrotParts(player, brainrots)
	local brainrotFolder = workspace:FindFirstChild("Brainrots")
	if not brainrotFolder then
		brainrotFolder = Instance.new("Folder")
		brainrotFolder.Name   = "Brainrots"
		brainrotFolder.Parent = workspace
	end

	local userId      = player.UserId
	local GRID_SPACING      = 6
	local PLAYER_AREA_WIDTH = 50
	local BASE_Y            = 1.5
	local MAX_BRAINROTS     = 25

	local function getSlotPos(slotIndex)
		local areaX = (userId % 20) * PLAYER_AREA_WIDTH
		local col   = slotIndex % 5
		local row   = math.floor(slotIndex / 5)
		return Vector3.new(areaX + (col * GRID_SPACING) - (2 * GRID_SPACING), BASE_Y, row * GRID_SPACING)
	end

	for i, b in ipairs(brainrots) do
		if i > MAX_BRAINROTS then break end
		local slotIndex = i - 1

		local cfg = RarityConfig[b.rarity]

		local part = Instance.new("Part")
		part.Size      = Vector3.new(3, 3, 3)
		part.Anchored  = true
		part.Color     = cfg and cfg.color or Color3.fromRGB(200, 200, 200)
		part.Material  = Enum.Material.SmoothPlastic
		part.Position  = getSlotPos(slotIndex)
		part.Name      = b.name
		part:SetAttribute("OwnerId",   userId)
		part:SetAttribute("SlotIndex", slotIndex)
		part:SetAttribute("SpawnTime", os.time() - (MAX_BRAINROTS - i))  -- preserve order

		local cashVal = Instance.new("NumberValue")
		cashVal.Name  = "CashPerSec"
		cashVal.Value = cfg and cfg.cashPerSec or 0
		cashVal.Parent = part

		local billboard = Instance.new("BillboardGui")
		billboard.Size         = UDim2.new(0, 120, 0, 60)
		billboard.StudsOffset  = Vector3.new(0, 2.5, 0)
		billboard.AlwaysOnTop  = false
		billboard.ResetOnSpawn = false
		billboard.Parent       = part

		local emojiLabel = Instance.new("TextLabel")
		emojiLabel.Size                     = UDim2.new(1, 0, 0.55, 0)
		emojiLabel.BackgroundTransparency   = 1
		emojiLabel.Text                     = b.emoji or "❓"
		emojiLabel.TextScaled               = true
		emojiLabel.Font                     = Enum.Font.GothamBold
		emojiLabel.TextColor3               = Color3.fromRGB(255, 255, 255)
		emojiLabel.Parent                   = billboard

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size                      = UDim2.new(1, 0, 0.45, 0)
		nameLabel.Position                  = UDim2.new(0, 0, 0.55, 0)
		nameLabel.BackgroundTransparency    = 1
		nameLabel.Text                      = b.name
		nameLabel.TextScaled                = true
		nameLabel.Font                      = Enum.Font.Gotham
		nameLabel.TextColor3                = Color3.fromRGB(255, 255, 255)
		nameLabel.TextStrokeTransparency    = 0.5
		nameLabel.Parent                    = billboard

		part.Parent = brainrotFolder
	end
end

-- ─── Remove all workspace Parts belonging to a player ────────────────────────

local function clearPlayerParts(userId)
	local brainrotFolder = workspace:FindFirstChild("Brainrots")
	if not brainrotFolder then return end
	for _, part in ipairs(brainrotFolder:GetChildren()) do
		if part:GetAttribute("OwnerId") == userId then
			part:Destroy()
		end
	end
end

-- ─── Save ─────────────────────────────────────────────────────────────────────

local function savePlayer(player)
	local data = BrainrotData.Get(player.UserId)
	if not data then return end

	local ok, err = pcall(function()
		playerStore:SetAsync(tostring(player.UserId), {
			cash      = data.cash,
			brainrots = data.brainrots,
			rebirths  = data.rebirths,
		})
	end)

	if not ok then
		warn(("[DataStoreManager] Failed to save data for %s: %s"):format(player.Name, tostring(err)))
	end
end

-- ─── Player Added ─────────────────────────────────────────────────────────────

local function onPlayerAdded(player)
	-- 1. Init default data
	BrainrotData.Init(player.UserId)

	-- 2. Load from DataStore
	local savedData
	local ok, err = pcall(function()
		savedData = playerStore:GetAsync(tostring(player.UserId))
	end)

	if ok and savedData then
		-- 3. Restore saved state
		BrainrotData.Restore(player.UserId, savedData)
		print(("[DataStoreManager] Loaded data for %s"):format(player.Name))
	elseif not ok then
		warn(("[DataStoreManager] Failed to load data for %s: %s"):format(player.Name, tostring(err)))
	end

	local data = BrainrotData.Get(player.UserId)

	-- 4. Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name   = "leaderstats"
	leaderstats.Parent = player

	local cashValue = Instance.new("IntValue")
	cashValue.Name   = "Cash"
	cashValue.Value  = math.floor(data.cash)
	cashValue.Parent = leaderstats

	local rebirthsValue = Instance.new("IntValue")
	rebirthsValue.Name   = "Rebirths"
	rebirthsValue.Value  = data.rebirths
	rebirthsValue.Parent = leaderstats

	-- 5. Restore brainrot Parts if any saved
	if savedData and savedData.brainrots and #savedData.brainrots > 0 then
		restoreBrainrotParts(player, data.brainrots)
	end
end

-- ─── Player Removing ─────────────────────────────────────────────────────────

local function onPlayerRemoving(player)
	savePlayer(player)
	clearPlayerParts(player.UserId)
end

-- ─── Bind Events ─────────────────────────────────────────────────────────────

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players who joined before the script ran (Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- ─── Auto-Save Loop ──────────────────────────────────────────────────────────

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayer(player)
		end
	end
end)
