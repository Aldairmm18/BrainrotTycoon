-- DataStoreManager (Script)
-- ServerScriptService/DataStoreManager
-- Handles loading/saving player data via DataStore and creating leaderstats.

local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData  = require(script.Parent.BrainrotData)
local RarityConfig  = require(ReplicatedStorage.Modules.RarityConfig)

local DATASTORE_NAME    = "BrainrotTycoon_v1"
local AUTOSAVE_INTERVAL = 60

local playerStore = DataStoreService:GetDataStore(DATASTORE_NAME)

-- ─── Move kit models from Workspace → ServerStorage.BrainrotTemplates ───────────
-- Runs once at startup. Models in ServerStorage are invisible to clients.
-- GachaServer clones from here when spawning a player’s Brainrot.

local ServerStorage = game:GetService("ServerStorage")

local templates = ServerStorage:FindFirstChild("BrainrotTemplates")
if not templates then
	templates        = Instance.new("Folder")
	templates.Name   = "BrainrotTemplates"
	templates.Parent = ServerStorage
end

local TEMPLATE_NAMES = {
	"Tung Tung Tung S", "Ballerina Cappuc",
	"Boneca Ambalab",   "Cappuccino Assa",
	"Chimpanzini Ban",  "Pandaccini Banar",
	"Avocadini Guffo",  "Cacto Hipopotar",
	"Burbaloni Lolilo", "Chef Crabracadat",
	"Rhino Toasterino", "Trulimero Trulici",
	"Zibra Zubra Zibra","Mythic Lucky Blo",
	"BubbleGumMach",    "RainbowMachine",
	"CakeTrap",
}

for _, tname in ipairs(TEMPLATE_NAMES) do
	-- Only move if not already in ServerStorage
	if not templates:FindFirstChild(tname, true) then
		local model = workspace:FindFirstChild(tname, true)
		if model then
			model.Parent = templates
			print(("[DataStoreManager] Moved template '%s' to ServerStorage"):format(tname))
		end
	end
end


-- ─── World Setup (Baseplate + SpawnLocation) ─────────────────────────────────
-- Runs once at server startup to ensure characters don't fall into the void.

if not workspace:FindFirstChild("Baseplate") then
	local baseplate = Instance.new("Part")
	baseplate.Name       = "Baseplate"
	baseplate.Size       = Vector3.new(2048, 20, 2048)
	baseplate.Position   = Vector3.new(0, -10, 0)
	baseplate.Anchored   = true
	baseplate.Locked     = true
	baseplate.Material   = Enum.Material.SmoothPlastic
	baseplate.Color      = Color3.fromRGB(106, 127, 63)
	baseplate.TopSurface = Enum.SurfaceType.Smooth
	baseplate.Parent     = workspace
end

if not workspace:FindFirstChild("SpawnLocation") then
	local spawn = Instance.new("SpawnLocation")
	spawn.Size     = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(0, 12, 0)
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Parent   = workspace
end

-- ─── Player Base Platform ─────────────────────────────────────────────────────

local function createPlayerBase(player)
	local userId  = player.UserId
	local baseX   = (userId % 20) * 60

	-- Platform Part
	local base = Instance.new("Part")
	base.Name        = "Base_" .. player.Name
	base.Size        = Vector3.new(30, 1, 30)
	base.Position    = Vector3.new(baseX, 0, 0)
	base.Anchored    = true
	base.Color       = Color3.fromRGB(210, 210, 220)
	base.Material    = Enum.Material.SmoothPlastic
	base.TopSurface  = Enum.SurfaceType.Smooth
	base:SetAttribute("OwnerId", userId)
	base.Parent      = workspace

	-- BillboardGui with player name above base
	local billboard = Instance.new("BillboardGui")
	billboard.Size        = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 18, 0)
	billboard.AlwaysOnTop = false
	billboard.ResetOnSpawn = false
	billboard.Parent      = base

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size                   = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text                   = "🏠 " .. player.Name
	nameLabel.TextScaled             = true
	nameLabel.Font                   = Enum.Font.GothamBold
	nameLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Parent                 = billboard
end

local function removePlayerBase(player)
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "Base_" .. player.Name then
			obj:Destroy()
		end
	end
end

-- ─── Re-place saved Brainrot parts in the workspace ──────────────────────────

-- ─── Re-place saved Brainrots when player rejoins ───────────────────────────────
-- Tries 3D model templates first, falls back to Neon Ball Part.

local RARITY_COLORS_DSM = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(100, 160, 255),
	Rare      = Color3.fromRGB(50,  200, 120),
	Epic      = Color3.fromRGB(160, 100, 255),
	Legendary = Color3.fromRGB(255, 180, 0),
	Mythic    = Color3.fromRGB(255, 80,  40),
	Secret    = Color3.fromRGB(255, 50,  50),
}
local MAX_RESTORE = 25

local function restoreBrainrotParts(player, brainrots)
	local folderName = "Brainrots_" .. player.Name
	local folder = workspace:FindFirstChild(folderName)
	if not folder then
		folder        = Instance.new("Folder")
		folder.Name   = folderName
		folder.Parent = workspace
	end

	local playerList = Players:GetPlayers()
	local playerSlot = 0
	for i, p in ipairs(playerList) do
		if p == player then playerSlot = i - 1 break end
	end
	local baseX = playerSlot * 60
	task.spawn(function()
		for i, b in ipairs(brainrots) do
			if i > MAX_RESTORE then break end
			local row = math.floor((i - 1) / 5)
			local col = (i - 1) % 5
			local pos = Vector3.new(baseX + col * 10, 2, row * 10 - 40)

			-- Try 3D model template
			local model = nil
			if b.modelName then
				local tmplFolder = ServerStorage:FindFirstChild("BrainrotTemplates")
				if tmplFolder then
					local tmpl = tmplFolder:FindFirstChild(b.modelName, true)
					if tmpl then model = tmpl:Clone() end
				end
			end

			-- Fallback: plain coloured Part
			if not model then
				local part    = Instance.new("Part")
				part.Name     = b.name
				part.Size     = Vector3.new(4, 4, 4)
				part.Shape    = Enum.PartType.Ball
				part.Material = Enum.Material.Neon
				part.Color    = RARITY_COLORS_DSM[b.rarity] or Color3.fromRGB(180,180,180)
				part.Anchored = true
				model = part
			end

			-- Position + anchor
			if model:IsA("Model") then
				if model.PrimaryPart then
					model:SetPrimaryPartCFrame(CFrame.new(pos))
				else
					local first = model:FindFirstChildWhichIsA("BasePart", true)
					if first then first.Position = pos end
				end
				for _, desc in ipairs(model:GetDescendants()) do
					if desc:IsA("BasePart") then desc.Anchored = true end
				end
			else
				model.Position = pos
				model.Anchored = true
			end

			-- BillboardGui
			local cfg = RarityConfig[b.rarity]
			local primaryPart = model:IsA("Model")
				and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true))
				or model
			if primaryPart then
				local bb = Instance.new("BillboardGui")
				bb.Size = UDim2.new(0, 130, 0, 80)
				bb.StudsOffset = Vector3.new(0, 4, 0)
				bb.AlwaysOnTop = false
				bb.ResetOnSpawn = false
				bb.Parent = primaryPart

				local el = Instance.new("TextLabel")
				el.Size = UDim2.new(1,0,0.40,0)
				el.BackgroundTransparency = 1
				el.Text = b.emoji or "❓"
				el.TextScaled = true
				el.Font = Enum.Font.GothamBold
				el.Parent = bb

				local nl = Instance.new("TextLabel")
				nl.Size = UDim2.new(1,0,0.32,0)
				nl.Position = UDim2.new(0,0,0.40,0)
				nl.BackgroundTransparency = 1
				nl.Text = b.name
				nl.TextColor3 = Color3.fromRGB(255,255,255)
				nl.TextStrokeTransparency = 0
				nl.TextScaled = true
				nl.Font = Enum.Font.GothamBold
				nl.Parent = bb

				local cps = b.cashPerSec or (cfg and cfg.cashPerSec) or 0
				local cl = Instance.new("TextLabel")
				cl.Size = UDim2.new(1,0,0.28,0)
				cl.Position = UDim2.new(0,0,0.72,0)
				cl.BackgroundTransparency = 1
				cl.Text = "+$" .. cps .. "/seg"
				cl.TextColor3 = Color3.fromRGB(100,255,100)
				cl.TextStrokeTransparency = 0
				cl.TextScaled = true
				cl.Font = Enum.Font.Gotham
				cl.Parent = bb
			end

			model:SetAttribute("OwnerId",      player.UserId)
			model:SetAttribute("BrainrotName", b.name)
			model:SetAttribute("Rarity",       b.rarity)
			model.Name   = b.name .. "_" .. player.Name
			model.Parent = folder

			task.wait(0.05)  -- stagger to avoid frame spikes
		end
	end)
end

-- ─── Remove all workspace objects belonging to a player ──────────────────────

local function clearPlayerParts(userId, playerName)
	-- Destroy new per-player folder (created by spawnBrainrotInWorld)
	if playerName then
		local folder = workspace:FindFirstChild("Brainrots_" .. playerName)
		if folder then folder:Destroy() end
	end
	-- Sweep legacy shared folder too (backwards-compat)
	local legacyFolder = workspace:FindFirstChild("Brainrots")
	if legacyFolder then
		for _, obj in ipairs(legacyFolder:GetChildren()) do
			if obj:GetAttribute("OwnerId") == userId then obj:Destroy() end
		end
	end
end

-- ─── Save ─────────────────────────────────────────────────────────────────────

local function savePlayer(player)
	local data = BrainrotData.Get(player.UserId)
	if not data then return end

	local ok, err = pcall(function()
		playerStore:SetAsync(tostring(player.UserId), {
			cash         = data.cash,
			brainrots    = data.brainrots,
			rebirths     = data.rebirths,
			guardians    = data.guardians or 0,
			streak       = data.streak or 0,
			lastLoginDay = data.lastLoginDay or "",
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

	-- ── Daily Streak Bonus ──
	local today = os.date("*t")
	local todayStr = string.format("%04d-%02d-%02d", today.year, today.month, today.day)

	if data.lastLoginDay ~= todayStr then
		-- New day!
		if data.lastLoginDay ~= "" then
			-- (A more rigorous check would verify if lastLoginDay was exactly yesterday, 
			-- but for now we simply increment if it's a new day, per the request)
			data.streak = (data.streak or 0) + 1
		else
			data.streak = 1
		end
		data.lastLoginDay = todayStr

		local streakBonus = math.min(data.streak, 7) * 500
		BrainrotData.AddCash(player.UserId, streakBonus)

		-- Notify client (using CodeResult toast format)
		local RE = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if RE and RE:FindFirstChild("CodeResult") then
			-- Small delay so UI is loaded
			task.delay(3, function()
				RE.CodeResult:FireClient(player, true, 
					"🔥 ¡Día " .. data.streak .. " consecutivo! Bonus: $" .. streakBonus)
			end)
		end
	end

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

	-- 5. Create visual base platform for this player
	createPlayerBase(player)

	-- 6. Restore brainrot Parts if any saved
	if savedData and savedData.brainrots and #savedData.brainrots > 0 then
		restoreBrainrotParts(player, data.brainrots)
	end
end

-- ─── Player Removing ─────────────────────────────────────────────────────────

local function onPlayerRemoving(player)
	savePlayer(player)
	clearPlayerParts(player.UserId, player.Name)
	removePlayerBase(player)
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
