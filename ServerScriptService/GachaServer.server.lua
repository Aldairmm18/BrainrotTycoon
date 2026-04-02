-- GachaServer (Script)
-- ServerScriptService/GachaServer
-- Handles egg purchases, random drop resolution, inventory management,
-- and Brainrot Part placement on the player's base.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local BrainrotData  = require(script.Parent.BrainrotData)
local RarityConfig  = require(ReplicatedStorage.Modules.RarityConfig)
local BrainrotList  = require(ReplicatedStorage.Modules.BrainrotList)

local BuyEgg       = ReplicatedStorage.RemoteEvents.BuyEgg
local PlaceBrainrot= ReplicatedStorage.RemoteEvents.PlaceBrainrot
local UpdateCash   = ReplicatedStorage.RemoteEvents.UpdateCash

local EGG_PRICE    = 500
local GRID_SIZE    = 3  -- studs between brainrot parts
local BASE_HEIGHT  = 1  -- height offset above the base

-- ─── Gacha Roll ─────────────────────────────────────────────────────────────

-- Build a weighted pool from BrainrotList using rarity dropChances
local function rollBrainrot()
	-- Build cumulative table from rarities in order
	local cumulative = {}
	local runningSum = 0
	for _, rarityName in ipairs(RarityConfig.Order) do
		runningSum = runningSum + RarityConfig[rarityName].dropChance
		table.insert(cumulative, { rarity = rarityName, threshold = runningSum })
	end

	local roll = math.random()  -- [0, 1)
	local chosenRarity = RarityConfig.Order[#RarityConfig.Order]  -- fallback to last

	for _, entry in ipairs(cumulative) do
		if roll < entry.threshold then
			chosenRarity = entry.rarity
			break
		end
	end

	-- Pick a random Brainrot of that rarity
	local pool = BrainrotList.GetByRarity(chosenRarity)
	if #pool == 0 then
		-- Fallback: pick first of any rarity
		return BrainrotList[1]
	end
	return pool[math.random(1, #pool)]
end

-- ─── Part Placement ─────────────────────────────────────────────────────────

local function getPlayerBase(player)
	-- Look for a BasePart named after the player in Workspace
	local baseFolder = Workspace:FindFirstChild("PlayerBases")
	if not baseFolder then
		baseFolder = Instance.new("Folder")
		baseFolder.Name   = "PlayerBases"
		baseFolder.Parent = Workspace
	end

	local playerFolder = baseFolder:FindFirstChild(player.Name)
	if not playerFolder then
		playerFolder = Instance.new("Folder")
		playerFolder.Name   = player.Name
		playerFolder.Parent = baseFolder
	end
	return playerFolder
end

local function placeBrainrotPart(player, brainrot, slotIndex)
	local rarityData = RarityConfig[brainrot.rarity]
	if not rarityData then return end

	local playerBase = getPlayerBase(player)

	-- Find character HumanoidRootPart for base position origin
	local character = player.Character
	local origin    = Vector3.new(0, 0, 0)
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			origin = hrp.Position + Vector3.new(0, -2.5, 0)
		end
	end

	-- Arrange in a row, offsetting by slot index
	local cols = 5
	local col  = (slotIndex - 1) % cols
	local row  = math.floor((slotIndex - 1) / cols)

	local part = Instance.new("Part")
	part.Name     = brainrot.name
	part.Size     = Vector3.new(2, 2, 2)
	part.Color    = rarityData.color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.Position = origin + Vector3.new(
		col * GRID_SIZE - (cols * GRID_SIZE / 2),
		BASE_HEIGHT,
		row * GRID_SIZE + 3
	)

	-- Label
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size          = UDim2.new(0, 80, 0, 40)
	billboardGui.StudsOffset   = Vector3.new(0, 2, 0)
	billboardGui.AlwaysOnTop   = false
	billboardGui.Parent        = part

	local label = Instance.new("TextLabel")
	label.Size            = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text            = brainrot.emoji .. "\n" .. brainrot.name
	label.TextColor3      = Color3.fromRGB(255, 255, 255)
	label.TextScaled      = true
	label.Font            = Enum.Font.GothamBold
	label.Parent          = billboardGui

	part.Parent = playerBase

	return part
end

-- ─── BuyEgg Handler ─────────────────────────────────────────────────────────

BuyEgg.OnServerEvent:Connect(function(player, isDirectBuy, directBrainrotName)
	local data = BrainrotData.Get(player.UserId)
	if not data then return end

	local price = EGG_PRICE
	local brainrot

	if isDirectBuy and directBrainrotName then
		-- Direct shop purchase
		local entry = BrainrotList.FindByName(directBrainrotName)
		if not entry then return end
		local directPrice = RarityConfig.DirectPrice[entry.rarity]
		if not directPrice then
			player:Kick("Attempted to buy non-purchasable rarity directly.")
			return
		end
		price    = directPrice
		brainrot = entry
	else
		-- Gacha roll
		brainrot = rollBrainrot()
	end

	-- 1. Verify funds
	if data.cash < price then
		-- Not enough cash - fire back with nil to signal failure
		BuyEgg:FireClient(player, nil, "not_enough_cash")
		return
	end

	-- 2. Check inventory capacity
	if #data.brainrots >= 10 then
		BuyEgg:FireClient(player, nil, "inventory_full")
		return
	end

	-- 3. Deduct cash (server-authoritative)
	local spent = BrainrotData.SpendCash(player.UserId, price)
	if not spent then return end

	-- 4. Add to inventory
	BrainrotData.AddBrainrot(player.UserId, brainrot)

	-- 5. Place Part in Workspace
	local slotIndex = #data.brainrots  -- already updated by AddBrainrot
	task.spawn(function()
		placeBrainrotPart(player, brainrot, slotIndex)
	end)

	-- 6. Sync leaderstats
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local cashVal = ls:FindFirstChild("Cash")
		if cashVal then cashVal.Value = math.floor(data.cash) end
	end

	-- 7. Notify client of new cash and obtained brainrot
	UpdateCash:FireClient(player, math.floor(data.cash))
	BuyEgg:FireClient(player, brainrot, "success")
end)

-- ─── PlaceBrainrot Handler (manual re-place) ───────────────────────────────

PlaceBrainrot.OnServerEvent:Connect(function(player, brainrotName)
	local data = BrainrotData.Get(player.UserId)
	if not data then return end

	local entry = BrainrotList.FindByName(brainrotName)
	if not entry then return end

	local slotIndex = #data.brainrots
	task.spawn(function()
		placeBrainrotPart(player, entry, slotIndex)
	end)
end)
