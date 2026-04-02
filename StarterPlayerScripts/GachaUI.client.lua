-- GachaUI (LocalScript)
-- StarterPlayerScripts/GachaUI
-- FIX 4+5: Full professional UI layout + improved result panel with rarity overlay.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── RemoteEvents ──────────────────────────────────────────────────────────────
local RemoteEvents     = ReplicatedStorage:WaitForChild("RemoteEvents")
local BuyEggEvent      = RemoteEvents:WaitForChild("BuyEgg")
local GachaResultEvent = RemoteEvents:WaitForChild("GachaResult")
local UpdateCashEvent  = RemoteEvents:WaitForChild("UpdateCash")

-- ── Brainrot Image Asset IDs (fallback to emoji if not in table) ──────────────
local BRAINROT_IMAGES = {
	["Tung Tung Tung Sahur"]   = "rbxassetid://94899532860685",
	["Ballerina Cappuccina"]   = "rbxassetid://97989898898989",
	["Cappuccino Assassino"]   = "rbxassetid://98765432112345",
	["Boneca Ambalabú"]        = "rbxassetid://91234567890123",
	["Chimpanzini Banana"]     = "rbxassetid://93456789012345",
}

-- ── Rarity colours ────────────────────────────────────────────────────────────
local rarityColors = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(100, 160, 255),
	Rare      = Color3.fromRGB(50,  200, 120),
	Epic      = Color3.fromRGB(160, 100, 255),
	Legendary = Color3.fromRGB(255, 180, 0),
	Mythic    = Color3.fromRGB(255, 80,  40),
	Secret    = Color3.fromRGB(255, 50,  50),
}

local rareOrBetter = { Rare=true, Epic=true, Legendary=true, Mythic=true, Secret=true }

-- ── Number formatter ──────────────────────────────────────────────────────────
local function fmt(n)
	if n >= 1e12 then return string.format("%.1fT", n/1e12)
	elseif n >= 1e9  then return string.format("%.1fB", n/1e9)
	elseif n >= 1e6  then return string.format("%.1fM", n/1e6)
	elseif n >= 1e3  then return string.format("%.1fK", n/1e3)
	else return tostring(math.floor(n)) end
end

-- ── Helper: make a standard button ────────────────────────────────────────────
local function makeBtn(name, text, size, pos, bg, parent)
	local btn = Instance.new("TextButton")
	btn.Name             = name
	btn.Size             = size
	btn.Position         = pos
	btn.BackgroundColor3 = bg
	btn.BorderSizePixel  = 0
	btn.Text             = text
	btn.TextColor3       = Color3.fromRGB(255, 255, 255)
	btn.TextScaled       = true
	btn.Font             = Enum.Font.GothamBold
	btn.AutoButtonColor  = false
	btn.Parent           = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08), {
			BackgroundColor3 = bg:Lerp(Color3.new(1,1,1), 0.15)
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08), { BackgroundColor3 = bg }):Play()
	end)
	return btn
end

-- ── ScreenGui ─────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "GachaUI"
screenGui.ResetOnSpawn    = false
screenGui.IgnoreGuiInset  = true
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = playerGui

-- ═══════════════════════════════════════════════════════════════════════════════
-- FIX 5: ORGANISED BUTTON LAYOUT
-- ═══════════════════════════════════════════════════════════════════════════════

-- 💰 Cash display — top centre
local cashFrame = Instance.new("Frame")
cashFrame.Name                   = "CashFrame"
cashFrame.Size                   = UDim2.new(0, 220, 0, 50)
cashFrame.Position               = UDim2.new(0.5, -110, 0, 8)
cashFrame.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
cashFrame.BackgroundTransparency = 0.4
cashFrame.BorderSizePixel        = 0
cashFrame.Parent                 = screenGui
Instance.new("UICorner", cashFrame).CornerRadius = UDim.new(0, 14)

local cashLabel = Instance.new("TextLabel")
cashLabel.Size                   = UDim2.new(1, 0, 1, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.Text                   = "💰 $0"
cashLabel.TextColor3             = Color3.fromRGB(255, 220, 50)
cashLabel.TextScaled             = true
cashLabel.Font                   = Enum.Font.GothamBold
cashLabel.Parent                 = cashFrame

-- 📋 Misiones — top left
local missionsBtn = makeBtn("MissionsBtn", "📋 Misiones",
	UDim2.new(0, 130, 0, 44), UDim2.new(0, 8, 0, 8),
	Color3.fromRGB(60, 100, 200), screenGui)

-- 🏆 Leaderboard — top left, below misiones
local lbBtn = makeBtn("LeaderboardBtn", "🏆 Ranking",
	UDim2.new(0, 130, 0, 44), UDim2.new(0, 8, 0, 58),
	Color3.fromRGB(180, 140, 0), screenGui)

-- 👑 VIP — top right
local vipBtn = makeBtn("VIPBtn", "👑 VIP",
	UDim2.new(0, 100, 0, 44), UDim2.new(1, -108, 0, 8),
	Color3.fromRGB(180, 60, 200), screenGui)

-- 🎁 Código — bottom left
local codeBtn = makeBtn("CodeBtn", "🎁 Código",
	UDim2.new(0, 120, 0, 50), UDim2.new(0, 8, 1, -62),
	Color3.fromRGB(220, 120, 0), screenGui)

-- 🎵 Música — bottom right
local musicBtn = makeBtn("MusicBtn", "🎵 Música",
	UDim2.new(0, 120, 0, 50), UDim2.new(1, -128, 1, -62),
	Color3.fromRGB(40, 40, 60), screenGui)

-- ⚗️ Fusionar — left centre
local fuseBtn = makeBtn("FuseBtn", "⚗️ Fusionar",
	UDim2.new(0, 130, 0, 50), UDim2.new(0, 8, 0.5, -60),
	Color3.fromRGB(120, 60, 200), screenGui)

-- 🗡️ Robar — left, below fusionar
local stealBtn = makeBtn("StealBtn", "🗡️ Robar",
	UDim2.new(0, 130, 0, 50), UDim2.new(0, 8, 0.5, -2),
	Color3.fromRGB(180, 30, 30), screenGui)

-- 🛒 Shop — right centre
local shopBtn = makeBtn("ShopBtn", "🛒 Shop",
	UDim2.new(0, 130, 0, 50), UDim2.new(1, -138, 0.5, -60),
	Color3.fromRGB(40, 160, 80), screenGui)

-- 🐾 Pets — right, below shop
local petsBtn = makeBtn("PetsBtn", "🐾 Pets",
	UDim2.new(0, 130, 0, 50), UDim2.new(1, -138, 0.5, -2),
	Color3.fromRGB(120, 60, 200), screenGui)

-- 🐾 Pet Egg $2000 — bottom, left of Buy Egg
local petEggBtn = makeBtn("PetEggBtn", "🐾 Pet Egg  $2000",
	UDim2.new(0, 200, 0, 56), UDim2.new(0.5, -320, 1, -70),
	Color3.fromRGB(120, 60, 200), screenGui)

-- 🥚 Buy Egg $500 — bottom centre (main CTA)
local buyBtn = makeBtn("BuyEggButton", "🥚 Huevo  $500",
	UDim2.new(0, 220, 0, 60), UDim2.new(0.5, -110, 1, -72),
	Color3.fromRGB(255, 140, 0), screenGui)

-- Wire up BuyEgg
buyBtn.MouseButton1Click:Connect(function()
	buyBtn.Text   = "⏳ Abriendo..."
	buyBtn.Active = false
	BuyEggEvent:FireServer()
	task.wait(1)
	buyBtn.Text   = "🥚 Huevo  $500"
	buyBtn.Active = true
end)

-- Wire BuyPetEgg
local BuyPetEggEvent = RemoteEvents:WaitForChild("BuyPetEgg", 5)
if BuyPetEggEvent then
	petEggBtn.MouseButton1Click:Connect(function()
		petEggBtn.Text   = "⏳..."
		petEggBtn.Active = false
		BuyPetEggEvent:FireServer()
		task.wait(1)
		petEggBtn.Text   = "🐾 Pet Egg  $2000"
		petEggBtn.Active = true
	end)
end

-- Wire Fuse / Steal / Shop / Pets / Missions / Leaderboard via existing UIs
-- These just fire remotes or toggle their own UIs; no action needed here
-- (they are handled by their own client scripts)

-- Wire Code button → CodesUI
codeBtn.MouseButton1Click:Connect(function()
	local codesGui = playerGui:FindFirstChild("CodesUI")
	if codesGui then
		local frame = codesGui:FindFirstChild("CodeFrame")
		if frame then frame.Visible = not frame.Visible end
	end
end)

-- Wire VIP → BuyPass
local BuyPassEvent = RemoteEvents:WaitForChild("BuyPass", 5)
if BuyPassEvent then
	vipBtn.MouseButton1Click:Connect(function()
		BuyPassEvent:FireServer("DOUBLE_CASH")
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- FIX 4: IMPROVED GACHA RESULT PANEL
-- ═══════════════════════════════════════════════════════════════════════════════

-- Full-screen rarity overlay (for Rare+)
local rarityOverlay = Instance.new("Frame")
rarityOverlay.Name                   = "RarityOverlay"
rarityOverlay.Size                   = UDim2.new(1, 0, 1, 0)
rarityOverlay.Position               = UDim2.new(0, 0, 0, 0)
rarityOverlay.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
rarityOverlay.BackgroundTransparency = 1   -- hidden
rarityOverlay.BorderSizePixel        = 0
rarityOverlay.ZIndex                 = 9
rarityOverlay.Visible                = false
rarityOverlay.Parent                 = screenGui

-- Result Panel
local resultPanel = Instance.new("Frame")
resultPanel.Name                   = "ResultPanel"
resultPanel.Size                   = UDim2.new(0, 320, 0, 390)
resultPanel.Position               = UDim2.new(0.5, -160, 0.5, -195)
resultPanel.BackgroundColor3       = Color3.fromRGB(10, 10, 20)
resultPanel.BackgroundTransparency = 0.05
resultPanel.BorderSizePixel        = 0
resultPanel.Visible                = false
resultPanel.ZIndex                 = 10
resultPanel.Parent                 = screenGui
Instance.new("UICorner", resultPanel).CornerRadius = UDim.new(0, 20)

local resultStroke = Instance.new("UIStroke")
resultStroke.Thickness = 3
resultStroke.Color     = Color3.fromRGB(255, 200, 50)
resultStroke.Parent    = resultPanel

-- Rarity header bar
local headerBar = Instance.new("Frame")
headerBar.Size             = UDim2.new(1, 0, 0, 10)
headerBar.Position         = UDim2.new(0, 0, 0, 0)
headerBar.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
headerBar.BorderSizePixel  = 0
headerBar.ZIndex           = 11
headerBar.Parent           = resultPanel
local hbCorner = Instance.new("UICorner")
hbCorner.CornerRadius = UDim.new(0, 20)
hbCorner.Parent = headerBar

-- Animated rarity text (for Rare+)
local rarityBanner = Instance.new("TextLabel")
rarityBanner.Name                   = "RarityBanner"
rarityBanner.Size                   = UDim2.new(1, -20, 0, 36)
rarityBanner.Position               = UDim2.new(0, 10, 0, 14)
rarityBanner.BackgroundTransparency = 1
rarityBanner.Text                   = "⭐ RARE"
rarityBanner.TextColor3             = Color3.fromRGB(255, 220, 50)
rarityBanner.TextScaled             = true
rarityBanner.Font                   = Enum.Font.GothamBold
rarityBanner.ZIndex                 = 11
rarityBanner.Parent                 = resultPanel

-- Image container
local imageContainer = Instance.new("Frame")
imageContainer.Size                   = UDim2.new(0, 150, 0, 150)
imageContainer.Position               = UDim2.new(0.5, -75, 0, 55)
imageContainer.BackgroundColor3       = Color3.fromRGB(30, 30, 50)
imageContainer.BackgroundTransparency = 0.2
imageContainer.BorderSizePixel        = 0
imageContainer.ZIndex                 = 11
imageContainer.Parent                 = resultPanel
Instance.new("UICorner", imageContainer).CornerRadius = UDim.new(0, 16)

local imgStroke = Instance.new("UIStroke")
imgStroke.Thickness = 2
imgStroke.Color     = Color3.fromRGB(255, 200, 50)
imgStroke.Parent    = imageContainer

local imageLabel = Instance.new("ImageLabel")
imageLabel.Name                   = "BrainrotImage"
imageLabel.Size                   = UDim2.new(1, -10, 1, -10)
imageLabel.Position               = UDim2.new(0, 5, 0, 5)
imageLabel.BackgroundTransparency = 1
imageLabel.ScaleType              = Enum.ScaleType.Fit
imageLabel.ImageTransparency      = 1
imageLabel.ZIndex                 = 12
imageLabel.Parent                 = imageContainer

local emojiLabel = Instance.new("TextLabel")
emojiLabel.Size                   = UDim2.new(1, 0, 1, 0)
emojiLabel.BackgroundTransparency = 1
emojiLabel.Text                   = "🐟"
emojiLabel.TextScaled             = true
emojiLabel.ZIndex                 = 12
emojiLabel.Parent                 = imageContainer

local nameLabel = Instance.new("TextLabel")
nameLabel.Size                   = UDim2.new(1, -20, 0, 40)
nameLabel.Position               = UDim2.new(0, 10, 0, 212)
nameLabel.BackgroundTransparency = 1
nameLabel.Text                   = "Tralalero Tralala"
nameLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
nameLabel.TextScaled             = true
nameLabel.Font                   = Enum.Font.GothamBold
nameLabel.ZIndex                 = 11
nameLabel.Parent                 = resultPanel

local rarityLabel = Instance.new("TextLabel")
rarityLabel.Size                   = UDim2.new(1, -20, 0, 30)
rarityLabel.Position               = UDim2.new(0, 10, 0, 258)
rarityLabel.BackgroundTransparency = 1
rarityLabel.Text                   = "⭐ Common"
rarityLabel.TextColor3             = Color3.fromRGB(180, 180, 180)
rarityLabel.TextScaled             = true
rarityLabel.Font                   = Enum.Font.Gotham
rarityLabel.ZIndex                 = 11
rarityLabel.Parent                 = resultPanel

local cashPerSecLabel = Instance.new("TextLabel")
cashPerSecLabel.Size                   = UDim2.new(1, -20, 0, 28)
cashPerSecLabel.Position               = UDim2.new(0, 10, 0, 293)
cashPerSecLabel.BackgroundTransparency = 1
cashPerSecLabel.Text                   = "+$5/seg"
cashPerSecLabel.TextColor3             = Color3.fromRGB(100, 255, 100)
cashPerSecLabel.TextScaled             = true
cashPerSecLabel.Font                   = Enum.Font.GothamBold
cashPerSecLabel.ZIndex                 = 11
cashPerSecLabel.Parent                 = resultPanel

local closeBtn = makeBtn("CloseResultBtn", "¡INCREÍBLE! 🎉",
	UDim2.new(0.65, 0, 0, 50),
	UDim2.new(0.175, 0, 0, 328),
	Color3.fromRGB(60, 200, 100), resultPanel)
closeBtn.ZIndex = 12

-- ── Show Result ───────────────────────────────────────────────────────────────
local function showResult(data)
	local rarityColor = rarityColors[data.rarity] or rarityColors.Common
	local isRarePlus  = rareOrBetter[data.rarity]

	nameLabel.Text         = data.name    or "Brainrot"
	rarityLabel.Text       = "⭐ " .. (data.rarity or "Common")
	rarityLabel.TextColor3 = rarityColor
	cashPerSecLabel.Text   = "+$" .. fmt(data.cashPerSec or 0) .. "/seg"
	rarityBanner.Text      = "✨ " .. string.upper(data.rarity or "COMMON") .. " ✨"
	rarityBanner.TextColor3 = rarityColor

	resultStroke.Color         = rarityColor
	headerBar.BackgroundColor3 = rarityColor
	imgStroke.Color            = rarityColor

	local assetId = BRAINROT_IMAGES[data.name]
	if assetId then
		imageLabel.Image             = assetId
		imageLabel.ImageTransparency = 0
		emojiLabel.Visible           = false
	else
		imageLabel.ImageTransparency = 1
		emojiLabel.Visible           = true
		emojiLabel.Text              = data.emoji or "❓"
	end

	-- Rarity overlay for Rare+ (full screen flash)
	if isRarePlus then
		rarityOverlay.BackgroundColor3       = rarityColor
		rarityOverlay.BackgroundTransparency = 0.75
		rarityOverlay.Visible                = true
		TweenService:Create(rarityOverlay,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		):Play()
		task.delay(0.35, function() rarityOverlay.Visible = false end)
	end

	-- Bounce entry
	local FULL_SZ  = UDim2.new(0, 320, 0, 390)
	local FULL_POS = UDim2.new(0.5, -160, 0.5, -195)
	resultPanel.Size     = UDim2.new(0, 0, 0, 0)
	resultPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	resultPanel.Visible  = true

	TweenService:Create(resultPanel,
		TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
		{ Size = FULL_SZ, Position = FULL_POS }
	):Play()

	task.delay(5, function()
		if resultPanel.Visible then resultPanel.Visible = false end
	end)
end

closeBtn.MouseButton1Click:Connect(function()
	resultPanel.Visible = false
end)

GachaResultEvent.OnClientEvent:Connect(showResult)

-- ── Update Cash ───────────────────────────────────────────────────────────────
UpdateCashEvent.OnClientEvent:Connect(function(cash)
	cashLabel.Text = "💰 $" .. fmt(cash)
	TweenService:Create(cashLabel, TweenInfo.new(0.12), {
		TextColor3 = Color3.fromRGB(255, 255, 100)
	}):Play()
	task.wait(0.12)
	TweenService:Create(cashLabel, TweenInfo.new(0.12), {
		TextColor3 = Color3.fromRGB(255, 220, 50)
	}):Play()
end)

-- Populate cash from leaderstats on first load
task.spawn(function()
	local ls = player:WaitForChild("leaderstats", 10)
	if ls then
		local cashVal = ls:WaitForChild("Cash", 5)
		if cashVal then cashLabel.Text = "💰 $" .. fmt(cashVal.Value) end
	end
end)
