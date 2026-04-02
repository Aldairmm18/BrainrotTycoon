-- AuraServer (Script)
-- ServerScriptService/AuraServer
-- Applies a glowing Neon aura + floating title billboard to every character.
-- Aura size/colour reflects the player's highest-rarity Brainrot.
-- Title reflects total rebirth count.

local Players     = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local BrainrotData = require(script.Parent.BrainrotData)

-- ─── Title config (key = minimum rebirths required) ──────────────────────────
local TITLES = {
	[0]  = { title = "Novato Brainrot",  color = Color3.fromRGB(180, 180, 180) },
	[1]  = { title = "Coleccionista",    color = Color3.fromRGB(100, 160, 255) },
	[3]  = { title = "Maestro Brainrot", color = Color3.fromRGB(50,  200, 120) },
	[6]  = { title = "Leyenda Brainrot", color = Color3.fromRGB(160, 100, 255) },
	[11] = { title = "Místico Brainrot", color = Color3.fromRGB(255, 180, 0)   },
	[21] = { title = "DIOS BRAINROT 👑", color = Color3.fromRGB(255, 50,  50)  },
}

-- ─── Aura config per rarity ───────────────────────────────────────────────────
local AURA_CONFIG = {
	Common    = { color = Color3.fromRGB(180, 180, 180), size = 3,  speed = 3.0 },
	Uncommon  = { color = Color3.fromRGB(100, 160, 255), size = 4,  speed = 2.5 },
	Rare      = { color = Color3.fromRGB(50,  200, 120), size = 5,  speed = 2.0 },
	Epic      = { color = Color3.fromRGB(160, 100, 255), size = 6,  speed = 1.5 },
	Legendary = { color = Color3.fromRGB(255, 180, 0),   size = 8,  speed = 1.0 },
	Mythic    = { color = Color3.fromRGB(255, 80,  40),  size = 10, speed = 0.8 },
	Secret    = { color = Color3.fromRGB(255, 50,  255), size = 12, speed = 0.5 },
}

local RARITY_ORDER = {
	Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6, Secret=7
}

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function getHighestRarity(brainrots)
	local highest = "Common"
	for _, b in ipairs(brainrots) do
		if (RARITY_ORDER[b.rarity] or 0) > (RARITY_ORDER[highest] or 0) then
			highest = b.rarity
		end
	end
	return highest
end

local function getTitleForRebirths(rebirths)
	local bestMin  = -1
	local bestData = TITLES[0]
	for minR, tData in pairs(TITLES) do
		if rebirths >= minR and minR > bestMin then
			bestMin  = minR
			bestData = tData
		end
	end
	return bestData
end

-- ─── Core: apply aura + title to a character ──────────────────────────────────

local function applyAuraAndTitle(player, character)
	local data = BrainrotData.Get(player.UserId)
	if not data then return end

	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end

	-- Remove stale aura/title from previous spawn
	for _, child in ipairs(character:GetChildren()) do
		if child.Name == "PlayerAura" or child.Name == "TitleBillboard" then
			child:Destroy()
		end
	end

	-- ── Aura ────────────────────────────────────────────────────────────────
	local highestRarity = getHighestRarity(data.brainrots or {})
	local auraCfg       = AURA_CONFIG[highestRarity] or AURA_CONFIG.Common

	local aura = Instance.new("Part")
	aura.Name        = "PlayerAura"
	aura.Size        = Vector3.new(auraCfg.size, auraCfg.size, auraCfg.size)
	aura.Shape       = Enum.PartType.Ball
	aura.Material    = Enum.Material.Neon
	aura.Color       = auraCfg.color
	aura.Transparency = 0.70
	aura.CanCollide  = false
	aura.Anchored    = false
	aura.CastShadow  = false
	aura.Parent      = character

	local weld  = Instance.new("WeldConstraint")
	weld.Part0  = hrp
	weld.Part1  = aura
	weld.Parent = aura

	-- Pulsing tween loop
	task.spawn(function()
		while aura.Parent do
			local t = TweenService:Create(
				aura,
				TweenInfo.new(auraCfg.speed, Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut, -1, true),
				{ Transparency = 0.88 }
			)
			t:Play()
			-- Wait for two full periods before re-creating the tween
			task.wait(auraCfg.speed * 2 + 0.1)
			t:Cancel()
		end
	end)

	-- ── Title billboard ──────────────────────────────────────────────────────
	local titleData = getTitleForRebirths(data.rebirths or 0)

	local billboard = Instance.new("BillboardGui")
	billboard.Name         = "TitleBillboard"
	billboard.Size         = UDim2.new(0, 210, 0, 54)
	billboard.StudsOffset  = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop  = false
	billboard.ResetOnSpawn = false
	billboard.Parent       = hrp

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size                   = UDim2.new(1, 0, 0.58, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text                   = titleData.title
	titleLabel.TextColor3             = titleData.color
	titleLabel.TextStrokeTransparency = 0
	titleLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
	titleLabel.TextScaled             = true
	titleLabel.Font                   = Enum.Font.GothamBold
	titleLabel.Parent                 = billboard

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size                   = UDim2.new(1, 0, 0.42, 0)
	nameLabel.Position               = UDim2.new(0, 0, 0.58, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text                   = player.Name
	nameLabel.TextColor3             = Color3.fromRGB(230, 230, 230)
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.TextScaled             = true
	nameLabel.Font                   = Enum.Font.Gotham
	nameLabel.Parent                 = billboard
end

-- ─── Auto-refresh every 30 s while player is in game ─────────────────────────

local function startRefreshLoop(player)
	task.spawn(function()
		while player.Parent do
			task.wait(30)
			if player.Character then
				applyAuraAndTitle(player, player.Character)
			end
		end
	end)
end

-- ─── Wire up player events ────────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(1)  -- wait for character to fully load
		applyAuraAndTitle(player, character)
	end)
	startRefreshLoop(player)
end)

-- Refresh on rebirth
local RE = game.ReplicatedStorage:WaitForChild("RemoteEvents")
RE:WaitForChild("RebornResult").OnServerEvent:Connect(function(player)
	if player.Character then
		applyAuraAndTitle(player, player.Character)
	end
end)

-- Handle players already in-game (Studio play test)
for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		task.spawn(applyAuraAndTitle, player, player.Character)
	end
	startRefreshLoop(player)
end
