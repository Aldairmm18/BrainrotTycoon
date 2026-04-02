-- GachaUI (LocalScript)
-- StarterPlayerScripts/GachaUI
-- Egg buy button, opening animation, and result panel.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local BuyEgg       = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("BuyEgg")
local RarityConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RarityConfig"))

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─── Build ScreenGui ────────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "GachaUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.Parent         = playerGui

-- ── Buy Button ──────────────────────────────────────────────────────────────

local buyBtn = Instance.new("TextButton")
buyBtn.Name             = "BuyEggButton"
buyBtn.Size             = UDim2.new(0, 200, 0, 60)
buyBtn.Position         = UDim2.new(0.5, -100, 1, -82)
buyBtn.BackgroundColor3 = Color3.fromRGB(255, 190, 30)
buyBtn.Text             = "🥚 Buy Egg  $500"
buyBtn.TextColor3       = Color3.fromRGB(30, 20, 0)
buyBtn.TextScaled       = true
buyBtn.Font             = Enum.Font.GothamBold
buyBtn.BorderSizePixel  = 0
buyBtn.Parent           = screenGui

local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, 16)
buyCorner.Parent       = buyBtn

-- ── Result Panel (hidden by default) ────────────────────────────────────────

local panel = Instance.new("Frame")
panel.Name              = "ResultPanel"
panel.Size              = UDim2.new(0, 320, 0, 200)
panel.Position          = UDim2.new(0.5, -160, 0.5, -100)
panel.BackgroundColor3  = Color3.fromRGB(18, 14, 32)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel   = 0
panel.Visible           = false
panel.ZIndex            = 10
panel.Parent            = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 22)
panelCorner.Parent       = panel

local emojiLabel = Instance.new("TextLabel")
emojiLabel.Name                  = "EmojiLabel"
emojiLabel.Size                  = UDim2.new(1, 0, 0, 70)
emojiLabel.Position              = UDim2.new(0, 0, 0, 10)
emojiLabel.BackgroundTransparency= 1
emojiLabel.Text                  = "🥚"
emojiLabel.TextScaled            = true
emojiLabel.Font                  = Enum.Font.GothamBold
emojiLabel.ZIndex                = 11
emojiLabel.Parent                = panel

local resultTitle = Instance.new("TextLabel")
resultTitle.Name                  = "ResultTitle"
resultTitle.Size                  = UDim2.new(1, -20, 0, 30)
resultTitle.Position              = UDim2.new(0, 10, 0, 85)
resultTitle.BackgroundTransparency= 1
resultTitle.Text                  = "¡Obtuviste ?"
resultTitle.TextColor3            = Color3.fromRGB(255, 255, 255)
resultTitle.TextScaled            = true
resultTitle.Font                  = Enum.Font.GothamBold
resultTitle.ZIndex                = 11
resultTitle.Parent                = panel

local rarityLabel = Instance.new("TextLabel")
rarityLabel.Name                  = "RarityLabel"
rarityLabel.Size                  = UDim2.new(1, -20, 0, 28)
rarityLabel.Position              = UDim2.new(0, 10, 0, 118)
rarityLabel.BackgroundTransparency= 1
rarityLabel.Text                  = "Common"
rarityLabel.TextColor3            = Color3.fromRGB(180, 180, 180)
rarityLabel.TextScaled            = true
rarityLabel.Font                  = Enum.Font.Gotham
rarityLabel.ZIndex                = 11
rarityLabel.Parent                = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Name             = "CloseButton"
closeBtn.Size             = UDim2.new(0, 100, 0, 34)
closeBtn.Position         = UDim2.new(0.5, -50, 1, -46)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text             = "✕ Close"
closeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled       = true
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.BorderSizePixel  = 0
closeBtn.ZIndex           = 11
closeBtn.Parent           = panel

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 10)
closeBtnCorner.Parent       = closeBtn

-- ─── Animation Helpers ───────────────────────────────────────────────────────

local function punchButton(btn)
	local tweenIn = TweenService:Create(btn,
		TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 180, 0, 54) }
	)
	local tweenOut = TweenService:Create(btn,
		TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 200, 0, 60) }
	)
	tweenIn:Play()
	tweenIn.Completed:Wait()
	tweenOut:Play()
end

local function showResult(brainrot)
	local rarData = RarityConfig[brainrot.rarity] or {}

	emojiLabel.Text       = brainrot.emoji or "❓"
	resultTitle.Text      = "¡Obtuviste " .. (brainrot.name or "?") .. "!"
	rarityLabel.Text      = "✦ " .. (brainrot.rarity or "Unknown")
	rarityLabel.TextColor3= rarData.color or Color3.fromRGB(255,255,255)

	panel.Size    = UDim2.new(0, 0, 0, 0)
	panel.Position= UDim2.new(0.5, 0, 0.5, 0)
	panel.Visible = true

	TweenService:Create(panel,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Size     = UDim2.new(0, 320, 0, 200),
			Position = UDim2.new(0.5, -160, 0.5, -100),
		}
	):Play()

	-- Auto-close after 3 seconds
	task.delay(3, function()
		if panel.Visible then
			panel.Visible = false
		end
	end)
end

local function showError(reason)
	local msg = reason == "not_enough_cash" and "😢 Not enough cash!" or
	            reason == "inventory_full"   and "📦 Inventory full! (max 10)" or
	            "Something went wrong."

	emojiLabel.Text       = "❌"
	resultTitle.Text      = msg
	rarityLabel.Text      = ""
	panel.Size    = UDim2.new(0, 320, 0, 200)
	panel.Position= UDim2.new(0.5, -160, 0.5, -100)
	panel.Visible = true

	task.delay(2.5, function()
		if panel.Visible then panel.Visible = false end
	end)
end

-- ─── Button Logic ────────────────────────────────────────────────────────────

local canBuy = true

buyBtn.MouseButton1Click:Connect(function()
	if not canBuy then return end
	canBuy = false

	task.spawn(punchButton, buyBtn)
	BuyEgg:FireServer(false, nil)  -- gacha roll

	task.delay(0.5, function()
		canBuy = true
	end)
end)

closeBtn.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

-- ─── Server Response ─────────────────────────────────────────────────────────

BuyEgg.OnClientEvent:Connect(function(brainrot, status)
	if status == "success" and brainrot then
		showResult(brainrot)
	else
		showError(status)
	end
end)
