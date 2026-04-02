-- BrainrotData (ModuleScript-style server Script)
-- ServerScriptService/BrainrotData
-- Central in-memory data store for all player data (server only).

local BrainrotData = {}

local _data = {}  -- indexed by userId

-- ─── Init ────────────────────────────────────────────────────────────────────

function BrainrotData.Init(userId)
	if not _data[userId] then
		_data[userId] = {
			cash      = 100,   -- starting cash so player can buy first egg
			brainrots = {},
			rebirths  = 0,
			guardians = 0,     -- 🛡️ purchased guardians (reduce steal %%)
		}
	end
end

-- ─── Getters ─────────────────────────────────────────────────────────────────

function BrainrotData.Get(userId)
	return _data[userId]
end

-- ─── Cash Operations ─────────────────────────────────────────────────────────

function BrainrotData.AddCash(userId, amount)
	local d = _data[userId]
	if not d then return end
	d.cash = d.cash + amount
end

-- Returns true if spend succeeded, false if insufficient funds.
function BrainrotData.SpendCash(userId, amount)
	local d = _data[userId]
	if not d then return false end
	if d.cash < amount then return false end
	d.cash = d.cash - amount
	return true
end

-- ─── Brainrot Operations ─────────────────────────────────────────────────────

function BrainrotData.AddBrainrot(userId, brainrotData)
	local d = _data[userId]
	if not d then return end
	table.insert(d.brainrots, brainrotData)
end

-- ─── Economy Helpers ─────────────────────────────────────────────────────────

-- Sums cashPerSec for all brainrots the player owns using RarityConfig.
function BrainrotData.GetTotalCashPerSec(userId, RarityConfig)
	local d = _data[userId]
	if not d then return 0 end
	local total = 0
	for _, b in ipairs(d.brainrots) do
		local cfg = RarityConfig[b.rarity]
		if cfg then
			total = total + cfg.cashPerSec
		end
	end
	return total
end

-- ─── Rebirth ─────────────────────────────────────────────────────────────────

function BrainrotData.Rebirth(userId)
	local d = _data[userId]
	if not d then return false end
	if #d.brainrots < 10 then return false end
	d.cash      = 0
	d.brainrots = {}
	d.rebirths  = d.rebirths + 1
	return true
end

-- ─── Raw Restore (used by DataStoreManager) ──────────────────────────────────

function BrainrotData.Restore(userId, savedData)
	_data[userId] = {
		cash      = savedData.cash      or 100,
		brainrots = savedData.brainrots or {},
		rebirths  = savedData.rebirths  or 0,
		guardians = savedData.guardians or 0,
	}
end

return BrainrotData
