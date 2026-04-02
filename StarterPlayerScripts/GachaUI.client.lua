-- GachaUI (LocalScript)
-- StarterPlayerScripts/GachaUI
-- Buy Egg button + gacha result panel + cash display (centre top).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── RemoteEvents ──────────────────────────────────────────────────────────────
local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local BuyEggEvent     = RemoteEvents:WaitForChild("BuyEgg")
local GachaResultEvent = RemoteEvents:WaitForChild("GachaResult")
local UpdateCashEvent = RemoteEvents:WaitForChild("UpdateCash")

-- ── ScreenGui ────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name          = "GachaUI"
screenGui.ResetOnSpawn  = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent        = playerGui

-- ── Cash Display (centre top) ─────────────────────────────────────────────────
local cashFrame = Instance.new("Frame")
cashFrame.Size                  = UDim2.new(0, 200, 0, 50)
cashFrame.Position              = UDim2.new(0.5, -100, 0, 10)
cashFrame.BackgroundColor3      = Color3.fromRGB(0, 0, 0)
cashFrame.BackgroundTransparency = 0.4
cashFrame.BorderSizePixel       = 0
cashFrame.Parent                = screenGui
Instance.new("UICorner", cashFrame).CornerRadius = UDim.new(0, 12)

local cashLabel = Instance.new("TextLabel")
cashLabel.Size                  = UDim2.new(1, 0, 1, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.Text                  = "💰 $0"
cashLabel.TextColor3            = Color3.fromRGB(255, 220, 50)
cashLabel.TextScaled            = true
cashLabel.Font                  = Enum.Font.GothamBold
cashLabel.Parent                = cashFrame

-- ── Buy Egg Button (bottom centre) ───────────────────────────────────────────
local buyBtn = Instance.new("TextButton")
buyBtn.Name             = "BuyEggButton"
buyBtn.Size             = UDim2.new(0, 220, 0, 60)
buyBtn.Position         = UDim2.new(0.5, -110, 1, -80)
buyBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
buyBtn.BorderSizePixel  = 0
buyBtn.Text             = "🥚 Buy Egg  $500"
buyBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
buyBtn.TextScaled       = true
buyBtn.Font             = Enum.Font.GothamBold
buyBtn.AutoButtonColor  = false
buyBtn.Parent           = screenGui
Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 16)

-- Hover animations
buyBtn.MouseEnter:Connect(function()
	TweenService:Create(buyBtn, TweenInfo.new(0.1), {
		BackgroundColor3 = Color3.fromRGB(255, 170, 0)
	}):Play()
end)
buyBtn.MouseLeave:Connect(function()
	TweenService:Create(buyBtn, TweenInfo.new(0.1), {
		BackgroundColor3 = Color3.fromRGB(255, 140, 0)
	}):Play()
end)

-- ── BUY EGG CLICK ─────────────────────────────────────────────────────────────
buyBtn.MouseButton1Click:Connect(function()
	buyBtn.Text   = "⏳ Abriendo..."
	buyBtn.Active = false
	BuyEggEvent:FireServer()
	task.wait(1)
	buyBtn.Text   = "🥚 Buy Egg  $500"
	buyBtn.Active = true
end)

-- ── Gacha Result Panel ────────────────────────────────────────────────────────
local resultPanel = Instance.new("Frame")
resultPanel.Name                  = "ResultPanel"
resultPanel.Size                  = UDim2.new(0, 300, 0, 320)
resultPanel.Position              = UDim2.new(0.5, -150, 0.5, -160)
resultPanel.BackgroundColor3      = Color3.fromRGB(20, 20, 30)
resultPanel.BackgroundTransparency = 0.1
resultPanel.BorderSizePixel       = 0
resultPanel.Visible               = false
resultPanel.ZIndex                = 10
resultPanel.Parent                = screenGui
Instance.new("UICorner", resultPanel).CornerRadius = UDim.new(0, 20)

local resultStroke = Instance.new("UIStroke")
resultStroke.Thickness = 2
resultStroke.Color     = Color3.fromRGB(255, 200, 50)
resultStroke.Parent    = resultPanel

local emojiLabel = Instance.new("TextLabel")
emojiLabel.Size                  = UDim2.new(1, 0, 0.30, 0)
emojiLabel.Position              = UDim2.new(0, 0, 0.05, 0)
emojiLabel.BackgroundTransparency = 1
emojiLabel.Text                  = "🐟"
emojiLabel.TextScaled            = true
emojiLabel.ZIndex                = 11
emojiLabel.Parent                = resultPanel

local nameLabel = Instance.new("TextLabel")
nameLabel.Size                   = UDim2.new(1, -20, 0, 40)
nameLabel.Position               = UDim2.new(0, 10, 0.38, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Text                   = "Tralalero Tralala"
nameLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
nameLabel.TextScaled             = true
nameLabel.Font                   = Enum.Font.GothamBold
nameLabel.ZIndex                 = 11
nameLabel.Parent                 = resultPanel

local rarityLabel = Instance.new("TextLabel")
rarityLabel.Size                  = UDim2.new(1, -20, 0, 30)
rarityLabel.Position              = UDim2.new(0, 10, 0.55, 0)
rarityLabel.BackgroundTransparency = 1
rarityLabel.Text                  = "⭐ Common"
rarityLabel.TextColor3            = Color3.fromRGB(180, 180, 180)
rarityLabel.TextScaled            = true
rarityLabel.Font                  = Enum.Font.Gotham
rarityLabel.ZIndex                = 11
rarityLabel.Parent                = resultPanel

local cashPerSecLabel = Instance.new("TextLabel")
cashPerSecLabel.Size                  = UDim2.new(1, -20, 0, 30)
cashPerSecLabel.Position              = UDim2.new(0, 10, 0.68, 0)
cashPerSecLabel.BackgroundTransparency = 1
cashPerSecLabel.Text                  = "+$5/seg"
cashPerSecLabel.TextColor3            = Color3.fromRGB(100, 255, 100)
cashPerSecLabel.TextScaled            = true
cashPerSecLabel.Font                  = Enum.Font.GothamBold
cashPerSecLabel.ZIndex                = 11
cashPerSecLabel.Parent                = resultPanel

local closeBtn = Instance.new("TextButton")
closeBtn.Name             = "CloseResultBtn"
closeBtn.Size             = UDim2.new(0.6, 0, 0, 44)
closeBtn.Position         = UDim2.new(0.2, 0, 0.82, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
closeBtn.BorderSizePixel  = 0
closeBtn.Text             = "¡Genial!"
closeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled       = true
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.ZIndex           = 12
closeBtn.Parent           = resultPanel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 12)

-- ── Rarity colour table ───────────────────────────────────────────────────────
local rarityColors = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(100, 160, 255),
	Rare      = Color3.fromRGB(50,  200, 120),
	Epic      = Color3.fromRGB(160, 100, 255),
	Legendary = Color3.fromRGB(255, 180, 0),
	Mythic    = Color3.fromRGB(255, 80,  40),
	Secret    = Color3.fromRGB(255, 50,  50),
}

-- ── Number formatter ─────────────────────────────────────────────────────────
local function formatNumber(n)
	if n >= 1e12 then return string.format("%.1fT", n / 1e12)
	elseif n >= 1e9  then return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6  then return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3  then return string.format("%.1fK", n / 1e3)
	else return tostring(math.floor(n)) end
end

-- ── Show Result ───────────────────────────────────────────────────────────────
local function showResult(data)
	emojiLabel.Text      = data.emoji   or "🐟"
	nameLabel.Text       = data.name    or "Brainrot"
	rarityLabel.Text     = "⭐ " .. (data.rarity or "Common")
	rarityLabel.TextColor3 = rarityColors[data.rarity] or rarityColors.Common
	cashPerSecLabel.Text = "+$" .. formatNumber(data.cashPerSec or 0) .. "/seg"

	-- Colour stroke to match rarity
	resultStroke.Color = rarityColors[data.rarity] or Color3.fromRGB(255, 200, 50)

	-- Animate: scale 0 → full size (Back easing gives the 1.1 bounce naturally)
	resultPanel.Size     = UDim2.new(0, 0, 0, 0)
	resultPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	resultPanel.Visible  = true

	TweenService:Create(resultPanel,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 300, 0, 320), Position = UDim2.new(0.5, -150, 0.5, -160) }
	):Play()

	-- Auto-close after 4 seconds
	task.delay(4, function()
		if resultPanel.Visible then
			resultPanel.Visible = false
		end
	end)
end

closeBtn.MouseButton1Click:Connect(function()
	resultPanel.Visible = false
end)

GachaResultEvent.OnClientEvent:Connect(showResult)

-- ── Update Cash ───────────────────────────────────────────────────────────────
UpdateCashEvent.OnClientEvent:Connect(function(cash)
	cashLabel.Text = "💰 $" .. formatNumber(cash)
	-- Subtle flash animation
	TweenService:Create(cashLabel, TweenInfo.new(0.15), {
		TextColor3 = Color3.fromRGB(255, 255, 100)
	}):Play()
	task.wait(0.15)
	TweenService:Create(cashLabel, TweenInfo.new(0.15), {
		TextColor3 = Color3.fromRGB(255, 220, 50)
	}):Play()
end)

-- Populate cash from leaderstats on first load
task.spawn(function()
	local ls = player:WaitForChild("leaderstats", 10)
	if ls then
		local cashVal = ls:WaitForChild("Cash", 5)
		if cashVal then
			cashLabel.Text = "💰 $" .. formatNumber(cashVal.Value)
		end
	end
end)
