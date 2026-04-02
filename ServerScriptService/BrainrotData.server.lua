-- BrainrotData (ModuleScript)
-- ServerScriptService/BrainrotData
-- Central in-memory store for all player data during the session.

local BrainrotData = {}

-- playerData[userId] = { cash = number, brainrots = {}, rebirths = number }
local playerData = {}

local MAX_BRAINROTS = 10

-- Initialize a player's data table
function BrainrotData.Init(userId, savedData)
	savedData = savedData or {}
	playerData[userId] = {
		cash      = savedData.cash     or 0,
		brainrots = savedData.brainrots or {},
		rebirths  = savedData.rebirths  or 0,
	}
end

-- Get a player's full data table (reference)
function BrainrotData.Get(userId)
	return playerData[userId]
end

-- Remove a player's data from memory on leave
function BrainrotData.Remove(userId)
	playerData[userId] = nil
end

-- Add cash (server-authoritative)
function BrainrotData.AddCash(userId, amount)
	local data = playerData[userId]
	if not data then return end
	data.cash = data.cash + amount
end

-- Deduct cash; returns true if successful, false if insufficient
function BrainrotData.SpendCash(userId, amount)
	local data = playerData[userId]
	if not data then return false end
	if data.cash < amount then return false end
	data.cash = data.cash - amount
	return true
end

-- Add a Brainrot to the player's inventory
-- Returns false if inventory is full
function BrainrotData.AddBrainrot(userId, brainrotEntry)
	local data = playerData[userId]
	if not data then return false end
	if #data.brainrots >= MAX_BRAINROTS then return false, "Inventory full" end
	table.insert(data.brainrots, {
		name   = brainrotEntry.name,
		rarity = brainrotEntry.rarity,
		emoji  = brainrotEntry.emoji,
	})
	return true
end

-- Calculate total cashPerSec for a player from their inventory
function BrainrotData.GetTotalCashPerSec(userId, rarityConfig)
	local data = playerData[userId]
	if not data then return 0 end
	local total = 0
	for _, b in ipairs(data.brainrots) do
		local cfg = rarityConfig[b.rarity]
		if cfg then
			total = total + cfg.cashPerSec
		end
	end
	return total
end

return BrainrotData
