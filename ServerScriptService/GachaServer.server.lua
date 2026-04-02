-- GachaServer (Script)
-- ServerScriptService/GachaServer
-- Handles egg purchases, rarity rolls, and placing Brainrot Parts in the world.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData  = require(script.Parent.BrainrotData)
local RarityConfig  = require(ReplicatedStorage.Modules.RarityConfig)
local BrainrotList  = require(ReplicatedStorage.Modules.BrainrotList)

local RemoteEvents  = ReplicatedStorage.RemoteEvents
local BuyEgg        = RemoteEvents.BuyEgg
local GachaResult   = RemoteEvents.GachaResult

local EGG_COST      = 500
local MAX_BRAINROTS = 25            -- 5×5 grid cap
local GRID_SPACING  = 6             -- studs between each Part centre
local PLAYER_AREA_WIDTH = 50        -- studs allocated per player on the X axis
local BASE_Y        = 1.5           -- Y so the 3-stud-tall Part sits on the baseplate

-- ─── Rarity Roll ─────────────────────────────────────────────────────────────
-- Standard cumulative thresholds
local CUMULATIVE_NORMAL = {
	{ rarity = "Common",    threshold = 0.60   },
	{ rarity = "Uncommon",  threshold = 0.85   },
	{ rarity = "Rare",      threshold = 0.95   },
	{ rarity = "Epic",      threshold = 0.99   },
	{ rarity = "Legendary", threshold = 0.999  },
	{ rarity = "Mythic",    threshold = 0.9999 },
	{ rarity = "Secret",    threshold = 1.0    },
}

-- Lucky Egg cumulative thresholds (higher Rare+ chances)
local CUMULATIVE_LUCKY = {
	{ rarity = "Common",    threshold = 0.40   },
	{ rarity = "Uncommon",  threshold = 0.65   },
	{ rarity = "Rare",      threshold = 0.85   },
	{ rarity = "Epic",      threshold = 0.95   },
	{ rarity = "Legendary", threshold = 0.99   },
	{ rarity = "Mythic",    threshold = 0.999  },
	{ rarity = "Secret",    threshold = 1.0    },
}

-- Pass lucky=true when the player owns GP_LUCKY_EGG
local function rollRarity(lucky)
	local table_ = lucky and CUMULATIVE_LUCKY or CUMULATIVE_NORMAL
	local roll = math.random()
	for _, entry in ipairs(table_) do
		if roll <= entry.threshold then
			return entry.rarity
		end
	end
	return "Secret"   -- fallback
end

-- ─── Grid Slot → World Position ──────────────────────────────────────────────

local function getSlotPosition(userId, slotIndex)
	-- Player area offset: each player owns a 50-stud column on X
	local areaX = (userId % 20) * PLAYER_AREA_WIDTH

	-- Flatten slot (0-based) into row/col inside a 5×5 grid
	local col = slotIndex % 5
	local row = math.floor(slotIndex / 5)

	local x = areaX + (col * GRID_SPACING) - (2 * GRID_SPACING)
	local z = row * GRID_SPACING
	return Vector3.new(x, BASE_Y, z)
end

-- ─── Remove Oldest Brainrot Part From Workspace ──────────────────────────────

local function removeOldestPart(userId)
	local brainrotFolder = workspace:FindFirstChild("Brainrots")
	if not brainrotFolder then return end

	local oldest = nil
	local oldestTime = math.huge

	for _, part in ipairs(brainrotFolder:GetChildren()) do
		local owner = part:GetAttribute("OwnerId")
		local t     = part:GetAttribute("SpawnTime") or 0
		if owner == userId and t < oldestTime then
			oldest    = part
			oldestTime = t
		end
	end

	if oldest then
		oldest:Destroy()
	end
end

-- ─── Count Player Parts ───────────────────────────────────────────────────────

local function countPlayerParts(userId)
	local brainrotFolder = workspace:FindFirstChild("Brainrots")
	if not brainrotFolder then return 0 end
	local count = 0
	for _, part in ipairs(brainrotFolder:GetChildren()) do
		if part:GetAttribute("OwnerId") == userId then
			count = count + 1
		end
	end
	return count
end

-- ─── Place Brainrot Part ─────────────────────────────────────────────────────

local function placeBrainrotPart(player, brainrot)
	-- Ensure Brainrots folder exists
	local brainrotFolder = workspace:FindFirstChild("Brainrots")
	if not brainrotFolder then
		brainrotFolder = Instance.new("Folder")
		brainrotFolder.Name = "Brainrots"
		brainrotFolder.Parent = workspace
	end

	local userId = player.UserId

	-- Enforce 5×5 = 25 max; evict oldest if at cap
	if countPlayerParts(userId) >= MAX_BRAINROTS then
		removeOldestPart(userId)
	end

	-- Find next free slot index (0–24)
	local usedSlots = {}
	for _, part in ipairs(brainrotFolder:GetChildren()) do
		if part:GetAttribute("OwnerId") == userId then
			local slot = part:GetAttribute("SlotIndex")
			if slot then usedSlots[slot] = true end
		end
	end

	local slotIndex = 0
	for i = 0, MAX_BRAINROTS - 1 do
		if not usedSlots[i] then
			slotIndex = i
			break
		end
	end

	local cfg      = RarityConfig[brainrot.rarity]
	local position = getSlotPosition(userId, slotIndex)

	-- Main Part
	local part = Instance.new("Part")
	part.Size      = Vector3.new(3, 3, 3)
	part.Anchored  = true
	part.CastShadow = true
	part.Color     = cfg and cfg.color or Color3.fromRGB(200, 200, 200)
	part.Material  = Enum.Material.SmoothPlastic
	part.Position  = position
	part.Name      = brainrot.name
	part:SetAttribute("OwnerId",   userId)
	part:SetAttribute("SlotIndex", slotIndex)
	part:SetAttribute("SpawnTime", os.time())

	-- CashPerSec NumberValue
	local cashVal = Instance.new("NumberValue")
	cashVal.Name  = "CashPerSec"
	cashVal.Value = cfg and cfg.cashPerSec or 0
	cashVal.Parent = part

	-- BillboardGui – emoji + name label
	local billboard = Instance.new("BillboardGui")
	billboard.Name          = "BillboardGui"
	billboard.Size          = UDim2.new(0, 120, 0, 60)
	billboard.StudsOffset   = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop   = false
	billboard.ResetOnSpawn  = false
	billboard.Parent        = part

	local emojiLabel = Instance.new("TextLabel")
	emojiLabel.Name            = "Emoji"
	emojiLabel.Size            = UDim2.new(1, 0, 0.55, 0)
	emojiLabel.BackgroundTransparency = 1
	emojiLabel.Text            = brainrot.emoji or "❓"
	emojiLabel.TextScaled      = true
	emojiLabel.Font            = Enum.Font.GothamBold
	emojiLabel.TextColor3      = Color3.fromRGB(255, 255, 255)
	emojiLabel.Parent          = billboard

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name             = "Name"
	nameLabel.Size             = UDim2.new(1, 0, 0.45, 0)
	nameLabel.Position         = UDim2.new(0, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text             = brainrot.name
	nameLabel.TextScaled       = true
	nameLabel.Font             = Enum.Font.Gotham
	nameLabel.TextColor3       = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent           = billboard

	part.Parent = brainrotFolder
end

-- ─── Main Handler ─────────────────────────────────────────────────────────────

BuyEgg.OnServerEvent:Connect(function(player)
	local userId = player.UserId
	local data   = BrainrotData.Get(userId)
	if not data then return end

	-- 1. Verify funds (server-authoritative)
	if data.cash < EGG_COST then
		warn(("[GachaServer] %s tried to buy egg but only has %d cash"):format(player.Name, data.cash))
		return
	end

	-- 2. Deduct cost
	BrainrotData.SpendCash(userId, EGG_COST)

	-- 3. Roll rarity (Lucky Egg boosts Rare+ chances)
	local isLucky = player:FindFirstChild("GP_LUCKY_EGG") ~= nil
	local rarity = rollRarity(isLucky)

	-- 4. Pick a random Brainrot of that rarity
	local pool = BrainrotList.GetByRarity(rarity)
	if #pool == 0 then
		-- Fallback to Common if pool is empty
		rarity = "Common"
		pool   = BrainrotList.GetByRarity("Common")
	end
	local chosen = pool[math.random(1, #pool)]

	-- 5. Add to player inventory
	BrainrotData.AddBrainrot(userId, {
		name   = chosen.name,
		rarity = chosen.rarity,
		emoji  = chosen.emoji,
	})

	-- 6. Place the Part in the Workspace
	placeBrainrotPart(player, chosen)

	-- 7. Fire result back to client
	local cfg = RarityConfig[rarity]
	GachaResult:FireClient(player, {
		name       = chosen.name,
		rarity     = chosen.rarity,
		cashPerSec = cfg and cfg.cashPerSec or 0,
		emoji      = chosen.emoji,
	})

	-- Sync leaderstats
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local cashVal = ls:FindFirstChild("Cash")
		if cashVal then cashVal.Value = math.floor(data.cash) end
	end
end)
