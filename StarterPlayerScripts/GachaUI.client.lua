-- GachaUI (LocalScript)
-- StarterPlayerScripts/GachaUI
-- Main gameplay UI: Buy Egg button, gacha result panel, Shop button.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player       = Players.LocalPlayer
local RemoteEvents = ReplicatedStorage.RemoteEvents
local BuyEgg       = RemoteEvents.BuyEgg
local GachaResult  = RemoteEvents.GachaResult
local UpdateCash   = RemoteEvents.UpdateCash

-- ─── Rarity Colors ────────────────────────────────────────────────────────────

local RARITY_COLORS = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(100, 160, 255),
	Rare      = Color3.fromRGB(50,  200, 120),
	Epic      = Color3.fromRGB(160, 100, 255),
	Legendary = Color3.fromRGB(255, 180, 0),
	Mythic    = Color3.fromRGB(255, 80,  40),
	Secret    = Color3.fromRGB(255, 50,  50),
}

local function rarityColorHex(rarity)
	local c = RARITY_COLORS[rarity] or Color3.fromRGB(200, 200, 200)
	return ("#%02X%02X%02X"):format(
		math.floor(c.R * 255),
		math.floor(c.G * 255),
		math.floor(c.B * 255)
	)
end

-- ─── Build UI ─────────────────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "GachaUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = player.PlayerGui

-- ── Buy Egg Button (centre) ──────────────────────────────────────────────────

local buyButton = Instance.new("TextButton")
buyButton.Name              = "BuyEggButton"
buyButton.Size              = UDim2.new(0, 240, 0, 64)
buyButton.Position          = UDim2.new(0.5, -120, 0.78, 0)
buyButton.BackgroundColor3  = Color3.fromRGB(255, 185, 15)
buyButton.BorderSizePixel   = 0
buyButton.Text              = "🥚 Buy Egg  $500"
buyButton.Font              = Enum.Font.GothamBold
buyButton.TextSize          = 22
buyButton.TextColor3        = Color3.fromRGB(30, 20, 0)
buyButton.AutoButtonColor   = false
buyButton.Parent            = screenGui

local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, 32)
buyCorner.Parent = buyButton

local buyGradient = Instance.new("UIGradient")
buyGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 210, 50)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 0)),
})
buyGradient.Rotation = 90
buyGradient.Parent = buyButton

-- Hover / Press animations
local function tweenBuy(size, color)
	TweenService:Create(buyButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
		Size = size,
		BackgroundColor3 = color,
	}):Play()
end

buyButton.MouseEnter:Connect(function()
	tweenBuy(UDim2.new(0, 252, 0, 68), Color3.fromRGB(255, 200, 30))
end)
buyButton.MouseLeave:Connect(function()
	tweenBuy(UDim2.new(0, 240, 0, 64), Color3.fromRGB(255, 185, 15))
end)
buyButton.MouseButton1Down:Connect(function()
	tweenBuy(UDim2.new(0, 232, 0, 60), Color3.fromRGB(220, 140, 0))
end)

-- ── Shop Button (bottom-right) ───────────────────────────────────────────────

local shopButton = Instance.new("TextButton")
shopButton.Name             = "ShopButton"
shopButton.Size             = UDim2.new(0, 120, 0, 50)
shopButton.Position         = UDim2.new(1, -136, 1, -66)
shopButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
shopButton.BorderSizePixel  = 0
shopButton.Text             = "🛒 Shop"
shopButton.Font             = Enum.Font.GothamBold
shopButton.TextSize         = 18
shopButton.TextColor3       = Color3.fromRGB(255, 255, 255)
shopButton.AutoButtonColor  = false
shopButton.Parent           = screenGui

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 20)
shopCorner.Parent = shopButton

local shopStroke = Instance.new("UIStroke")
shopStroke.Color       = Color3.fromRGB(100, 100, 180)
shopStroke.Thickness   = 1.5
shopStroke.Parent      = shopButton

shopButton.MouseEnter:Connect(function()
	TweenService:Create(shopButton, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60, 60, 100)}):Play()
end)
shopButton.MouseLeave:Connect(function()
	TweenService:Create(shopButton, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 40, 60)}):Play()
end)

-- ─── Gacha Result Panel ───────────────────────────────────────────────────────

local function createResultPanel(resultData)
	-- Dim overlay
	local overlay = Instance.new("Frame")
	overlay.Name                 = "ResultOverlay"
	overlay.Size                 = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3     = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.45
	overlay.BorderSizePixel      = 0
	overlay.ZIndex               = 10
	overlay.Parent               = screenGui

	-- Panel card
	local card = Instance.new("Frame")
	card.Name               = "ResultCard"
	card.Size               = UDim2.new(0, 340, 0, 380)
	card.Position           = UDim2.new(0.5, -170, 0.5, -190)
	card.BackgroundColor3   = Color3.fromRGB(18, 18, 30)
	card.BorderSizePixel    = 0
	card.ZIndex             = 11
	card.Parent             = overlay

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 20)
	cardCorner.Parent = card

	-- Rarity-coloured glow stroke
	local rarityColor = RARITY_COLORS[resultData.rarity] or Color3.fromRGB(200, 200, 200)
	local cardStroke  = Instance.new("UIStroke")
	cardStroke.Color     = rarityColor
	cardStroke.Thickness = 3
	cardStroke.Parent    = card

	-- Emoji label (big)
	local emojiLabel = Instance.new("TextLabel")
	emojiLabel.Size                    = UDim2.new(1, 0, 0, 120)
	emojiLabel.Position                = UDim2.new(0, 0, 0, 24)
	emojiLabel.BackgroundTransparency  = 1
	emojiLabel.Text                    = resultData.emoji or "❓"
	emojiLabel.TextSize                = 72
	emojiLabel.Font                    = Enum.Font.GothamBold
	emojiLabel.TextColor3              = Color3.fromRGB(255, 255, 255)
	emojiLabel.ZIndex                  = 12
	emojiLabel.Parent                  = card

	-- Brainrot Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size                   = UDim2.new(1, -24, 0, 40)
	nameLabel.Position               = UDim2.new(0, 12, 0, 150)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text                   = resultData.name
	nameLabel.Font                   = Enum.Font.GothamBold
	nameLabel.TextSize               = 24
	nameLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
	nameLabel.TextXAlignment         = Enum.TextXAlignment.Center
	nameLabel.ZIndex                  = 12
	nameLabel.Parent                 = card

	-- Rarity label
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size                  = UDim2.new(1, -24, 0, 32)
	rarityLabel.Position              = UDim2.new(0, 12, 0, 195)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text                  = "✨ " .. (resultData.rarity or "?")
	rarityLabel.Font                  = Enum.Font.GothamBold
	rarityLabel.TextSize              = 20
	rarityLabel.TextColor3            = rarityColor
	rarityLabel.TextXAlignment        = Enum.TextXAlignment.Center
	rarityLabel.ZIndex                 = 12
	rarityLabel.Parent                = card

	-- Cash per second label
	local function formatNum(n)
		if n >= 1e12 then return ("%.1fT"):format(n/1e12)
		elseif n >= 1e9 then return ("%.1fB"):format(n/1e9)
		elseif n >= 1e6 then return ("%.1fM"):format(n/1e6)
		elseif n >= 1e3 then return ("%.1fK"):format(n/1e3)
		else return tostring(math.floor(n)) end
	end

	local cpsLabel = Instance.new("TextLabel")
	cpsLabel.Size                   = UDim2.new(1, -24, 0, 32)
	cpsLabel.Position               = UDim2.new(0, 12, 0, 234)
	cpsLabel.BackgroundTransparency = 1
	cpsLabel.Text                   = "💵 $" .. formatNum(resultData.cashPerSec or 0) .. "/seg"
	cpsLabel.Font                   = Enum.Font.Gotham
	cpsLabel.TextSize               = 18
	cpsLabel.TextColor3             = Color3.fromRGB(130, 230, 130)
	cpsLabel.TextXAlignment         = Enum.TextXAlignment.Center
	cpsLabel.ZIndex                  = 12
	cpsLabel.Parent                 = card

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name             = "CloseButton"
	closeBtn.Size             = UDim2.new(0, 180, 0, 48)
	closeBtn.Position         = UDim2.new(0.5, -90, 0, 306)
	closeBtn.BackgroundColor3 = rarityColor
	closeBtn.BorderSizePixel  = 0
	closeBtn.Text             = "¡Genial!"
	closeBtn.Font             = Enum.Font.GothamBold
	closeBtn.TextSize         = 20
	closeBtn.TextColor3       = Color3.fromRGB(10, 10, 10)
	closeBtn.ZIndex            = 12
	closeBtn.Parent           = card

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 24)
	closeBtnCorner.Parent = closeBtn

	-- Entry animation: scale 0 → 1 → 1.1 → 1
	card.Size = UDim2.new(0, 1, 0, 1)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)

	local tweenOpen = TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size     = UDim2.new(0, 354, 0, 394),
		Position = UDim2.new(0.5, -177, 0.5, -197),
	})
	tweenOpen:Play()
	tweenOpen.Completed:Connect(function()
		local tweenBounce = TweenService:Create(card, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size     = UDim2.new(0, 340, 0, 380),
			Position = UDim2.new(0.5, -170, 0.5, -190),
		})
		tweenBounce:Play()
	end)

	local function closePanel()
		local tweenClose = TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 1})
		local tweenCardClose = TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size     = UDim2.new(0, 1, 0, 1),
			Position = UDim2.new(0.5, 0, 0.5, 0),
		})
		tweenClose:Play()
		tweenCardClose:Play()
		tweenClose.Completed:Connect(function()
			overlay:Destroy()
		end)
	end

	closeBtn.MouseButton1Click:Connect(closePanel)
	overlay.MouseButton1Click:Connect(closePanel)

	-- Auto-close after 4 seconds
	task.delay(4, function()
		if overlay and overlay.Parent then
			closePanel()
		end
	end)
end

-- ─── Wire Events ──────────────────────────────────────────────────────────────

buyButton.MouseButton1Up:Connect(function()
	tweenBuy(UDim2.new(0, 240, 0, 64), Color3.fromRGB(255, 185, 15))
	BuyEgg:FireServer()
end)

GachaResult.OnClientEvent:Connect(function(resultData)
	createResultPanel(resultData)
end)

-- Shop button placeholder (ShopUI handles it separately)
shopButton.MouseButton1Click:Connect(function()
	local shopGui = player.PlayerGui:FindFirstChild("ShopUI")
	if shopGui then
		local frame = shopGui:FindFirstChildWhichIsA("Frame", true)
		if frame then frame.Visible = not frame.Visible end
	end
end)
