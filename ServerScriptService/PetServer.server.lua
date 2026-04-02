-- PetServer (Script)
-- ServerScriptService/PetServer
-- Pet egg system: purchase, equip, unequip. Pets float above the player.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(script.Parent.BrainrotData)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local EquipPet     = RemoteEvents:WaitForChild("EquipPet")
local UnequipPet   = RemoteEvents:WaitForChild("UnequipPet")
local PetUpdate    = RemoteEvents:WaitForChild("PetUpdate")
local BuyEgg       = RemoteEvents:WaitForChild("BuyEgg")  -- reuse BuyEgg pattern

-- Separate RemoteEvent for pet egg
local BuyPetEgg = ReplicatedStorage.RemoteEvents:WaitForChild("BuyPetEgg")

local PET_EGG_COST = 2000

-- ─── Pet Definitions ──────────────────────────────────────────────────────────
local PET_POOL = {
	{ name="Gatito Común",      emoji="🐱", rarity="Common",    multiplier=0.05, threshold=0.60 },
	{ name="Perrito Suerte",    emoji="🐶", rarity="Uncommon",  multiplier=0.10, threshold=0.85 },
	{ name="Dragoncito",        emoji="🐲", rarity="Rare",      multiplier=0.20, threshold=0.95 },
	{ name="Unicornio Dorado",  emoji="🦄", rarity="Epic",      multiplier=0.50, threshold=0.99 },
	{ name="Fénix Legendario",  emoji="🔥", rarity="Legendary", multiplier=1.00, threshold=1.00 },
}

-- ─── In-memory pet state: [userId] = { inventory={}, equipped=nil } ───────────
local _pets = {}

local function initPets(userId)
	if not _pets[userId] then
		_pets[userId] = { inventory = {}, equipped = nil }
	end
end

local function rollPet()
	local roll = math.random()
	for _, pet in ipairs(PET_POOL) do
		if roll <= pet.threshold then
			return pet
		end
	end
	return PET_POOL[#PET_POOL]
end

-- ─── Place/remove floating billboard above player head ────────────────────────
local function updatePetBillboard(player, petData)
	local char = player.Character
	if not char then return end

	-- Remove old pet billboard
	local old = char:FindFirstChild("PetBillboard")
	if old then old:Destroy() end

	if not petData then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name         = "PetBillboard"
	billboard.Size         = UDim2.new(0, 80, 0, 80)
	billboard.StudsOffset  = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop  = false
	billboard.ResetOnSpawn = false
	billboard.Parent       = hrp

	local emojiLbl = Instance.new("TextLabel")
	emojiLbl.Size                   = UDim2.new(1, 0, 0.65, 0)
	emojiLbl.BackgroundTransparency = 1
	emojiLbl.Text                   = petData.emoji
	emojiLbl.TextScaled             = true
	emojiLbl.ZIndex                 = 5
	emojiLbl.Parent                 = billboard

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size                   = UDim2.new(1, 0, 0.35, 0)
	nameLbl.Position               = UDim2.new(0, 0, 0.65, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text                   = petData.name
	nameLbl.TextScaled             = true
	nameLbl.Font                   = Enum.Font.GothamBold
	nameLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
	nameLbl.TextStrokeTransparency = 0.4
	nameLbl.ZIndex                 = 5
	nameLbl.Parent                 = billboard
end

-- ─── Get pet multiplier for a player ─────────────────────────────────────────
local PetServer = {}

function PetServer.GetMultiplier(userId)
	local state = _pets[userId]
	if not state or not state.equipped then return 1 end
	return 1 + state.equipped.multiplier
end

-- ─── Buy Pet Egg ──────────────────────────────────────────────────────────────
BuyPetEgg.OnServerEvent:Connect(function(player)
	local userId = player.UserId
	local data   = BrainrotData.Get(userId)
	if not data then return end

	if data.cash < PET_EGG_COST then
		warn(("[PetServer] %s insufficient cash for Pet Egg"):format(player.Name))
		return
	end

	BrainrotData.SpendCash(userId, PET_EGG_COST)
	initPets(userId)

	local pet = rollPet()
	table.insert(_pets[userId].inventory, pet)

	-- Sync leaderstats
	local ls = player:FindFirstChild("leaderstats")
	if ls and data then
		local c = ls:FindFirstChild("Cash")
		if c then c.Value = math.floor(data.cash) end
	end

	PetUpdate:FireClient(player, _pets[userId].inventory, _pets[userId].equipped, pet)
end)

-- ─── Equip ────────────────────────────────────────────────────────────────────
EquipPet.OnServerEvent:Connect(function(player, petIndex)
	local state = _pets[player.UserId]
	if not state then return end

	local pet = state.inventory[petIndex]
	if not pet then return end

	state.equipped = pet
	updatePetBillboard(player, pet)
	PetUpdate:FireClient(player, state.inventory, state.equipped, nil)
end)

-- ─── Unequip ─────────────────────────────────────────────────────────────────
UnequipPet.OnServerEvent:Connect(function(player)
	local state = _pets[player.UserId]
	if not state then return end
	state.equipped = nil
	updatePetBillboard(player, nil)
	PetUpdate:FireClient(player, state.inventory, nil, nil)
end)

-- ─── Player events ────────────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	initPets(player.UserId)
	player.CharacterAdded:Connect(function()
		local state = _pets[player.UserId]
		if state and state.equipped then
			task.wait(0.5)
			updatePetBillboard(player, state.equipped)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	_pets[player.UserId] = nil
end)

return PetServer
