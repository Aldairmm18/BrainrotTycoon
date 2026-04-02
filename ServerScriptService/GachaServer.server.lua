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

-- ─── Spawn Brainrot in World (3D model or Neon-Ball fallback) ───────────────

local TweenService   = game:GetService("TweenService")
local ServerStorage  = game:GetService("ServerStorage")

local RARITY_COLORS = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(100, 160, 255),
	Rare      = Color3.fromRGB(50,  200, 120),
	Epic      = Color3.fromRGB(160, 100, 255),
	Legendary = Color3.fromRGB(255, 180, 0),
	Mythic    = Color3.fromRGB(255, 80,  40),
	Secret    = Color3.fromRGB(255, 50,  50),
}

local function attachBillboard(primaryPart, brainrot)
	local billboard = Instance.new("BillboardGui")
	billboard.Name        = "BrainrotBillboard"
	billboard.Size        = UDim2.new(0, 130, 0, 80)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = false
	billboard.ResetOnSpawn = false
	billboard.Parent      = primaryPart

	local cfg = RarityConfig[brainrot.rarity]

	local emojiL = Instance.new("TextLabel")
	emojiL.Size                   = UDim2.new(1, 0, 0.40, 0)
	emojiL.BackgroundTransparency = 1
	emojiL.Text                   = brainrot.emoji or "❓"
	emojiL.TextScaled             = true
	emojiL.Font                   = Enum.Font.GothamBold
	emojiL.Parent                 = billboard

	local nameL = Instance.new("TextLabel")
	nameL.Size                    = UDim2.new(1, 0, 0.32, 0)
	nameL.Position                = UDim2.new(0, 0, 0.40, 0)
	nameL.BackgroundTransparency  = 1
	nameL.Text                    = brainrot.name
	nameL.TextColor3              = Color3.fromRGB(255, 255, 255)
	nameL.TextStrokeTransparency  = 0
	nameL.TextScaled              = true
	nameL.Font                    = Enum.Font.GothamBold
	nameL.Parent                  = billboard

	local cps = brainrot.cashPerSec or (cfg and cfg.cashPerSec) or 0
	local cashL = Instance.new("TextLabel")
	cashL.Size                    = UDim2.new(1, 0, 0.28, 0)
	cashL.Position                = UDim2.new(0, 0, 0.72, 0)
	cashL.BackgroundTransparency  = 1
	cashL.Text                    = "+$" .. cps .. "/seg"
	cashL.TextColor3              = Color3.fromRGB(100, 255, 100)
	cashL.TextStrokeTransparency  = 0
	cashL.TextScaled              = true
	cashL.Font                    = Enum.Font.Gotham
	cashL.Parent                  = billboard
end

local function spawnBrainrotInWorld(player, brainrot, index)
	-- Per-player folder in Workspace
	local folderName   = "Brainrots_" .. player.Name
	local playerFolder = workspace:FindFirstChild(folderName)
	if not playerFolder then
		playerFolder        = Instance.new("Folder")
		playerFolder.Name   = folderName
		playerFolder.Parent = workspace
	end

	-- 5×5 grid position inside the player’s personal plot
	local safeIndex = math.max(1, index)
	local row   = math.floor((safeIndex - 1) / 5)
	local col   = (safeIndex - 1) % 5
	local playerList = Players:GetPlayers()
	local playerSlot = 0
	for i, p in ipairs(playerList) do
		if p == player then playerSlot = i - 1 break end
	end
	local baseX = playerSlot * 60
	local pos   = Vector3.new(baseX + col * 10, 2, row * 10 - 40)

	-- ─ Try to clone 3D model from ServerStorage ─────────────────────────────
	local model = nil

	if brainrot.modelName then
		local templates = ServerStorage:FindFirstChild("BrainrotTemplates")
		if templates then
			local template = templates:FindFirstChild(brainrot.modelName, true)
			if template then
				model = template:Clone()
			end
		end
	end

	-- ─ Fallback: Neon Ball Part ──────────────────────────────────────────
	if not model then
		local part      = Instance.new("Part")
		part.Name     = brainrot.name
		part.Size     = Vector3.new(0.1, 0.1, 0.1)  -- starts tiny; tweened
		part.Shape    = Enum.PartType.Ball
		part.Material = Enum.Material.Neon
		part.Color    = RARITY_COLORS[brainrot.rarity] or Color3.fromRGB(180,180,180)
		part.Anchored = true
		model = part
	end

	-- ─ Position & anchor all BaseParts ───────────────────────────────────
	if model:IsA("Model") then
		if model.PrimaryPart then
			model:SetPrimaryPartCFrame(CFrame.new(pos))
		else
			-- No PrimaryPart set — move model via its first BasePart
			local first = model:FindFirstChildWhichIsA("BasePart", true)
			if first then first.Position = pos end
		end
		for _, desc in ipairs(model:GetDescendants()) do
			if desc:IsA("BasePart") then desc.Anchored = true end
		end
	else
		-- It’s a plain Part (fallback)
		model.Position = pos
		model.Anchored = true
	end

	-- ─ BillboardGui ──────────────────────────────────────────────────
	local primaryPart = model:IsA("Model")
		and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true))
		or model
	if primaryPart then
		attachBillboard(primaryPart, brainrot)
		
		local light = Instance.new("PointLight")
		light.Brightness = 3
		light.Range = 12
		light.Color = RARITY_COLORS[brainrot.rarity] or Color3.fromRGB(255, 255, 255)
		light.Parent = primaryPart
	end

	-- ─ Ownership attributes ───────────────────────────────────────────
	model:SetAttribute("OwnerId",     player.UserId)
	model:SetAttribute("BrainrotName",brainrot.name)
	model:SetAttribute("Rarity",      brainrot.rarity)
	model.Name   = brainrot.name .. "_" .. player.Name
	model.Parent = playerFolder

	-- ─ Spawn animation ───────────────────────────────────────────────
	if model:IsA("Model") and model.PrimaryPart then
		local landCF = model.PrimaryPart.CFrame
		model:SetPrimaryPartCFrame(CFrame.new(pos + Vector3.new(0, 20, 0)))
		TweenService:Create(
			model.PrimaryPart,
			TweenInfo.new(0.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
			{ CFrame = landCF }
		):Play()
	elseif not model:IsA("Model") then
		-- Plain Part fallback: scale pop-in
		TweenService:Create(
			model,
			TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = Vector3.new(6, 6, 6) }
		):Play()
	end

	return model
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

	-- 5. Add to player inventory (include modelName + cashPerSec for restore)
	local cfg = RarityConfig[chosen.rarity]
	BrainrotData.AddBrainrot(userId, {
		name      = chosen.name,
		rarity    = chosen.rarity,
		emoji     = chosen.emoji,
		modelName = chosen.modelName,
		cashPerSec= chosen.cashPerSec or (cfg and cfg.cashPerSec) or 0,
	})

	-- 6. Place neon Ball in the world (new per-player folder system)
	local brainrotCount = #BrainrotData.Get(userId).brainrots
	spawnBrainrotInWorld(player, chosen, brainrotCount)

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
