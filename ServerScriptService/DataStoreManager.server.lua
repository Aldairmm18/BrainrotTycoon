-- DataStoreManager (Script)
-- ServerScriptService/DataStoreManager
-- Handles loading/saving player data via DataStore and creating leaderstats.

local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local ServerStorage     = game:GetService("ServerStorage")

local BrainrotData  = require(script.Parent.BrainrotData)
local RarityConfig  = require(ReplicatedStorage.Modules.RarityConfig)

local DATASTORE_NAME    = "BrainrotTycoon_v1"
local AUTOSAVE_INTERVAL = 120   -- FIX 7: 120s (fewer API calls)

local playerStore = DataStoreService:GetDataStore(DATASTORE_NAME)

-- ─── FIX 1: Limpiar el kit SAB del Workspace ─────────────────────────────────
local sabItems = {
	"Map", "SAB", "Shops", "MainModule", "EZConfig",
	"RoadPanel", "MapCenter", "MainHighlight", "Road",
	"Sounds", "ToolsAdds", "Items", "Ignore", "Lighting",
	"MovingAnimals", "RenderedMoving", "Plots", "Events",
	"Interacts", "CandySpinWheel", "CandyWeather",
	"(Delete This)",
}
for _, sabName in ipairs(sabItems) do
	local obj = workspace:FindFirstChild(sabName)
	if obj then
		obj:Destroy()
		print("[SAB Cleanup] Removed:", sabName)
	end
end
-- Destroy leftover SAB scripts by name
for _, obj in ipairs(game:GetDescendants()) do
	if obj:IsA("Script") or obj:IsA("LocalScript") then
		local n = obj.Name
		if n == "GameMode" or n == "Package" or n == "ControlPoint" then
			pcall(function() obj:Destroy() end)
			print("[SAB Cleanup] Removed script:", n)
		end
	end
end

-- ─── FIX 1 (cont): Enforce WalkSpeed=16 / JumpPower=50 always ───────────────
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local hum = character:WaitForChild("Humanoid", 5)
		if hum then
			hum.WalkSpeed = 16   -- velocidad normal Roblox
			hum.JumpPower = 50   -- salto normal Roblox
		end
	end)
end)

-- ─── Move kit models → ServerStorage.BrainrotTemplates ───────────────────────
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
	if not templates:FindFirstChild(tname, true) then
		local model = workspace:FindFirstChild(tname, true)
		if model then
			model.Parent = templates
			print(("[DataStoreManager] Moved template '%s' → ServerStorage"):format(tname))
		end
	end
end


-- ─── World Setup: Baseplate + Central SpawnLocation ──────────────────────────
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

-- FIX 6: Central SpawnLocation at (0,2,0)
if not workspace:FindFirstChild("MainSpawn") then
	local spawn = Instance.new("SpawnLocation")
	spawn.Name      = "MainSpawn"
	spawn.Size      = Vector3.new(10, 1, 10)
	spawn.Position  = Vector3.new(0, 2, 0)
	spawn.Anchored  = true
	spawn.Duration  = 0
	spawn.BrickColor = BrickColor.new("Bright yellow")
	spawn.Material  = Enum.Material.Neon
	spawn.Parent    = workspace
end

-- ─── FIX 2: Dynamic Map ───────────────────────────────────────────────────────

-- Giant "BRAINROT TYCOON" sign above spawn
if not workspace:FindFirstChild("TitleSign") then
	local sign = Instance.new("Part")
	sign.Name     = "TitleSign"
	sign.Size     = Vector3.new(40, 8, 1)
	sign.Position = Vector3.new(0, 20, 20)
	sign.Anchored = true
	sign.Material = Enum.Material.Neon
	sign.Color    = Color3.fromRGB(255, 100, 0)
	sign.Parent   = workspace

	local signGui = Instance.new("SurfaceGui")
	signGui.Face   = Enum.NormalId.Front
	signGui.Parent = sign

	local signLabel = Instance.new("TextLabel")
	signLabel.Size                   = UDim2.new(1, 0, 1, 0)
	signLabel.BackgroundTransparency = 1
	signLabel.Text                   = "🐟 BRAINROT TYCOON 🐟"
	signLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
	signLabel.TextStrokeTransparency = 0
	signLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
	signLabel.TextScaled             = true
	signLabel.Font                   = Enum.Font.GothamBold
	signLabel.Parent                 = signGui
end

-- Showcase Brainrots near spawn (Z=10 arc)
if not workspace:FindFirstChild("Showcase_TungTungSahur") then
	local showcaseBrainrots = {
		{name="Tung Tung Sahur",      emoji="🥁", color=Color3.fromRGB(100,160,255), pos=Vector3.new(-20,4,10)},
		{name="Cappuccino Assassino", emoji="☕", color=Color3.fromRGB(160,100,255), pos=Vector3.new(-10,4,10)},
		{name="Ballerina Cappuccina", emoji="💃", color=Color3.fromRGB(50,200,120),  pos=Vector3.new(0,4,10)},
		{name="Mythic Lucky Block",   emoji="🍀", color=Color3.fromRGB(255,180,0),   pos=Vector3.new(10,4,10)},
		{name="La Vaca Saturno",      emoji="🪐", color=Color3.fromRGB(255,50,50),   pos=Vector3.new(20,4,10)},
	}

	for _, data in ipairs(showcaseBrainrots) do
		local part = Instance.new("Part")
		part.Name       = "Showcase_" .. data.name:gsub("%s","")
		part.Size       = Vector3.new(7, 7, 7)
		part.Position   = data.pos
		part.Anchored   = true
		part.Shape      = Enum.PartType.Ball
		part.Material   = Enum.Material.Neon
		part.Color      = data.color
		part.CanCollide = false
		part.CastShadow = false
		part.Parent     = workspace

		local light = Instance.new("PointLight")
		light.Brightness = 5
		light.Range      = 20
		light.Color      = data.color
		light.Parent     = part

		local bb = Instance.new("BillboardGui")
		bb.Size        = UDim2.new(0, 120, 0, 70)
		bb.StudsOffset = Vector3.new(0, 5, 0)
		bb.Parent      = part

		local emojiL = Instance.new("TextLabel")
		emojiL.Size                   = UDim2.new(1, 0, 0.55, 0)
		emojiL.BackgroundTransparency = 1
		emojiL.Text                   = data.emoji
		emojiL.TextScaled             = true
		emojiL.Parent                 = bb

		local nameL = Instance.new("TextLabel")
		nameL.Size                   = UDim2.new(1, 0, 0.45, 0)
		nameL.Position               = UDim2.new(0, 0, 0.55, 0)
		nameL.BackgroundTransparency = 1
		nameL.Text                   = data.name
		nameL.TextColor3             = Color3.fromRGB(255, 255, 255)
		nameL.TextStrokeTransparency = 0
		nameL.TextScaled             = true
		nameL.Font                   = Enum.Font.GothamBold
		nameL.Parent                 = bb

		RunService.Heartbeat:Connect(function(dt)
			if part.Parent then
				part.CFrame = part.CFrame * CFrame.Angles(0, dt * 0.8, 0)
			end
		end)
	end
end

-- Physical Leaderboard board (behind spawn, Z=-20)
if not workspace:FindFirstChild("LeaderboardBoard") then
	local leaderPart = Instance.new("Part")
	leaderPart.Name     = "LeaderboardBoard"
	leaderPart.Size     = Vector3.new(20, 15, 1)
	leaderPart.Position = Vector3.new(0, 10, -20)
	leaderPart.Anchored = true
	leaderPart.Material = Enum.Material.SmoothPlastic
	leaderPart.Color    = Color3.fromRGB(20, 20, 40)
	leaderPart.Parent   = workspace

	local leaderGui = Instance.new("SurfaceGui")
	leaderGui.Name       = "LeaderSurfaceGui"
	leaderGui.Face       = Enum.NormalId.Front
	leaderGui.CanvasSize = Vector2.new(400, 300)
	leaderGui.Parent     = leaderPart

	local leaderTitle = Instance.new("TextLabel")
	leaderTitle.Size                   = UDim2.new(1, 0, 0.20, 0)
	leaderTitle.BackgroundTransparency = 1
	leaderTitle.Text                   = "🏆 TOP JUGADORES"
	leaderTitle.TextColor3             = Color3.fromRGB(255, 220, 0)
	leaderTitle.TextScaled             = true
	leaderTitle.Font                   = Enum.Font.GothamBold
	leaderTitle.Parent                 = leaderGui

	local function fmtN(n)
		if n >= 1e9 then return string.format("%.1fB", n/1e9)
		elseif n >= 1e6 then return string.format("%.1fM", n/1e6)
		elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
		else return tostring(math.floor(n)) end
	end

	task.spawn(function()
		while true do
			task.wait(30)
			-- Clear old entries
			for _, c in ipairs(leaderGui:GetChildren()) do
				if c.Name == "LeaderEntry" then c:Destroy() end
			end
			-- Sort players by cash leaderstats
			local plrs = Players:GetPlayers()
			table.sort(plrs, function(a, b)
				local aV = a:FindFirstChild("leaderstats") and a.leaderstats:FindFirstChild("Cash")
				local bV = b:FindFirstChild("leaderstats") and b.leaderstats:FindFirstChild("Cash")
				return (aV and aV.Value or 0) > (bV and bV.Value or 0)
			end)
			local medals = {"🥇","🥈","🥉","4️⃣","5️⃣"}
			for i, p in ipairs(plrs) do
				if i > 5 then break end
				local stats = p:FindFirstChild("leaderstats")
				local cash  = stats and stats:FindFirstChild("Cash") and stats.Cash.Value or 0
				local entry = Instance.new("TextLabel")
				entry.Name                   = "LeaderEntry"
				entry.Size                   = UDim2.new(1, 0, 0.13, 0)
				entry.Position               = UDim2.new(0, 0, 0.18 + (i-1)*0.15, 0)
				entry.BackgroundTransparency = 1
				entry.Text                   = (medals[i] or tostring(i)..".") .. " " .. p.Name .. " — $" .. fmtN(cash)
				entry.TextColor3             = i == 1 and Color3.fromRGB(255,220,0) or Color3.fromRGB(255,255,255)
				entry.TextScaled             = true
				entry.Font                   = Enum.Font.GothamBold
				entry.Parent                 = leaderGui
			end
		end
	end)
end

-- Old Z=-60 zone (kept for backwards compat, but showcase replaced with Z=10 one above)
if not workspace:FindFirstChild("ShowcaseZone") then
	local showcase = Instance.new("Part")
	showcase.Name     = "ShowcaseZone"
	showcase.Size     = Vector3.new(120, 1, 30)
	showcase.Position = Vector3.new(0, -1, -60)
	showcase.Anchored = true
	showcase.Material = Enum.Material.Neon
	showcase.Color    = Color3.fromRGB(30, 0, 60)
	showcase.Parent   = workspace
end

-- ─── FIX 3: Player Base (indexed, colored platform + neon sign + SpawnLoc) ───

local _playerIndex    = 0
local _playerIndexMap = {}   -- userId → index

local BASE_COLOR3 = {
	Color3.fromRGB(100, 150, 255),
	Color3.fromRGB(255, 150, 100),
	Color3.fromRGB(100, 255, 150),
	Color3.fromRGB(255, 100, 255),
	Color3.fromRGB(255, 255, 100),
}

local function createPlayerBase(player)
	if workspace:FindFirstChild("PlayerBase_" .. player.Name) then return end

	_playerIndex = _playerIndex + 1
	_playerIndexMap[player.UserId] = _playerIndex
	local idx      = _playerIndex
	local baseC    = BASE_COLOR3[((idx - 1) % #BASE_COLOR3) + 1]
	local baseX    = (idx - 1) * 60 - 150
	local basePos  = Vector3.new(baseX, 0, -60)

	-- Colored platform
	local basePart = Instance.new("Part")
	basePart.Name       = "PlayerBase_" .. player.Name
	basePart.Size       = Vector3.new(50, 1, 50)
	basePart.Position   = basePos
	basePart.Anchored   = true
	basePart.Material   = Enum.Material.SmoothPlastic
	basePart.Color      = baseC
	basePart.TopSurface = Enum.SurfaceType.Smooth
	basePart:SetAttribute("OwnerId", player.UserId)
	basePart.Parent     = workspace

	-- Neon name sign facing the centre
	local nameSign = Instance.new("Part")
	nameSign.Name       = "PlayerBase_Sign_" .. player.Name
	nameSign.Size       = Vector3.new(20, 4, 1)
	nameSign.Position   = Vector3.new(baseX, 8, -85)
	nameSign.Anchored   = true
	nameSign.Material   = Enum.Material.Neon
	nameSign.Color      = baseC
	nameSign.Parent     = workspace

	local nameGui = Instance.new("SurfaceGui")
	nameGui.Face   = Enum.NormalId.Front
	nameGui.Parent = nameSign

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size                   = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text                   = "🏠 Base de " .. player.Name
	nameLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled             = true
	nameLabel.Font                   = Enum.Font.GothamBold
	nameLabel.Parent                 = nameGui

	-- Per-player SpawnLocation inside their base
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name       = "Spawn_" .. player.Name
	spawnLoc.Size       = Vector3.new(6, 1, 6)
	spawnLoc.Position   = basePos + Vector3.new(0, 1.5, 20)
	spawnLoc.Anchored   = true
	spawnLoc.BrickColor = BrickColor.new("Bright yellow")
	spawnLoc.Duration   = 0
	spawnLoc.Parent     = workspace
end

local function removePlayerBase(player)
	for _, obj in ipairs(workspace:GetChildren()) do
		local n = obj.Name
		if n == "PlayerBase_" .. player.Name
			or n == "PlayerBase_Sign_" .. player.Name
			or n == "Spawn_" .. player.Name
			or n == "Base_" .. player.Name then
			obj:Destroy()
		end
	end
	_playerIndexMap[player.UserId] = nil
end


-- ─── Re-place saved Brainrots on rejoin ──────────────────────────────────────

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

	-- FIX 4: use the player's actual base position
	local playerBase = workspace:FindFirstChild("PlayerBase_" .. player.Name)
	local basePos    = playerBase and playerBase.Position or Vector3.new(0, 0, 0)

	task.spawn(function()
		for i, b in ipairs(brainrots) do
			if i > MAX_RESTORE then break end
			local row = math.floor((i - 1) / 5)
			local col = (i - 1) % 5
			local pos = Vector3.new(
				basePos.X - 20 + col * 10,
				basePos.Y + 5,
				basePos.Z - 20 + row * 10
			)

			-- Try 3D model template
			local model = nil
			if b.modelName then
				local tmplFolder = ServerStorage:FindFirstChild("BrainrotTemplates")
				if tmplFolder then
					local tmpl = tmplFolder:FindFirstChild(b.modelName, true)
					if tmpl then model = tmpl:Clone() end
				end
			end

			-- Fallback: plain coloured Neon Ball
			if not model then
				local part    = Instance.new("Part")
				part.Name     = b.name
				part.Size     = Vector3.new(6, 6, 6)
				part.Shape    = Enum.PartType.Ball
				part.Material = Enum.Material.Neon
				part.Color    = RARITY_COLORS_DSM[b.rarity] or Color3.fromRGB(180, 180, 180)
				part.Anchored = true
				model         = part
			end

			-- Position + anchor all BaseParts
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

			-- PointLight
			local primaryPart = model:IsA("Model")
				and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true))
				or model
			if primaryPart then
				local pl = Instance.new("PointLight")
				pl.Brightness = 3
				pl.Range      = 12
				pl.Color      = RARITY_COLORS_DSM[b.rarity] or Color3.fromRGB(255, 255, 255)
				pl.Parent     = primaryPart

				-- BillboardGui
				local cfg = RarityConfig[b.rarity]
				local bb  = Instance.new("BillboardGui")
				bb.Size        = UDim2.new(0, 130, 0, 80)
				bb.StudsOffset = Vector3.new(0, 4, 0)
				bb.AlwaysOnTop = false
				bb.ResetOnSpawn = false
				bb.Parent      = primaryPart

				local el = Instance.new("TextLabel")
				el.Size                   = UDim2.new(1, 0, 0.40, 0)
				el.BackgroundTransparency = 1
				el.Text                   = b.emoji or "❓"
				el.TextScaled             = true
				el.Font                   = Enum.Font.GothamBold
				el.Parent                 = bb

				local nl = Instance.new("TextLabel")
				nl.Size                   = UDim2.new(1, 0, 0.32, 0)
				nl.Position               = UDim2.new(0, 0, 0.40, 0)
				nl.BackgroundTransparency = 1
				nl.Text                   = b.name
				nl.TextColor3             = Color3.fromRGB(255, 255, 255)
				nl.TextStrokeTransparency = 0
				nl.TextScaled             = true
				nl.Font                   = Enum.Font.GothamBold
				nl.Parent                 = bb

				local cps = b.cashPerSec or (cfg and cfg.cashPerSec) or 0
				local cl  = Instance.new("TextLabel")
				cl.Size                   = UDim2.new(1, 0, 0.28, 0)
				cl.Position               = UDim2.new(0, 0, 0.72, 0)
				cl.BackgroundTransparency = 1
				cl.Text                   = "+$" .. cps .. "/seg"
				cl.TextColor3             = Color3.fromRGB(100, 255, 100)
				cl.TextStrokeTransparency = 0
				cl.TextScaled             = true
				cl.Font                   = Enum.Font.Gotham
				cl.Parent                 = bb
			end

			model:SetAttribute("OwnerId",      player.UserId)
			model:SetAttribute("BrainrotName", b.name)
			model:SetAttribute("Rarity",       b.rarity)
			model.Name   = b.name .. "_" .. player.Name
			model.Parent = folder

			task.wait(0.05)
		end
	end)
end

-- ─── Remove all workspace objects belonging to a player ──────────────────────

local function clearPlayerParts(userId, playerName)
	if playerName then
		local folder = workspace:FindFirstChild("Brainrots_" .. playerName)
		if folder then folder:Destroy() end
	end
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

	-- FIX 7: UpdateAsync to avoid conflicts; pcall on all DataStore ops
	local ok, err = pcall(function()
		playerStore:UpdateAsync(tostring(player.UserId), function(old)
			return {
				cash         = data.cash,
				brainrots    = data.brainrots,
				rebirths     = data.rebirths,
				guardians    = data.guardians or 0,
				streak       = data.streak or 0,
				lastLoginDay = data.lastLoginDay or "",
			}
		end)
	end)

	if not ok then
		warn(("[DataStoreManager] Failed to save %s: %s"):format(player.Name, tostring(err)))
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
		BrainrotData.Restore(player.UserId, savedData)
		print(("[DataStoreManager] Loaded data for %s"):format(player.Name))
	elseif not ok then
		warn(("[DataStoreManager] Failed to load data for %s: %s"):format(player.Name, tostring(err)))
	end

	local data = BrainrotData.Get(player.UserId)

	-- ── Daily Streak Bonus ──
	local today    = os.date("*t")
	local todayStr = string.format("%04d-%02d-%02d", today.year, today.month, today.day)

	if data.lastLoginDay ~= todayStr then
		if data.lastLoginDay ~= "" then
			data.streak = (data.streak or 0) + 1
		else
			data.streak = 1
		end
		data.lastLoginDay = todayStr

		local streakBonus = math.min(data.streak, 7) * 500
		BrainrotData.AddCash(player.UserId, streakBonus)

		local RE = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if RE and RE:FindFirstChild("CodeResult") then
			task.delay(3, function()
				RE.CodeResult:FireClient(player, true,
					"🔥 ¡Día " .. data.streak .. " consecutivo! Bonus: $" .. streakBonus)
			end)
		end
	end

	-- 3. Create leaderstats
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

	-- 4. Create player base platform
	createPlayerBase(player)

	-- 5. Restore brainrot Parts if any saved
	if savedData and savedData.brainrots and #savedData.brainrots > 0 then
		task.wait(0.5)  -- wait for base to be fully in workspace
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
