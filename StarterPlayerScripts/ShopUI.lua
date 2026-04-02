-- ShopUI (LocalScript)
-- StarterPlayerScripts/ShopUI
-- Lateral shop panel listing directly-purchasable Brainrots.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local BuyEgg       = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("BuyEgg")
local RarityConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RarityConfig"))
local BrainrotList = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("BrainrotList"))

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─── Build ScreenGui ────────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ShopUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.Parent         = playerGui

-- ── Toggle Button ────────────────────────────────────────────────────────────

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name             = "ShopToggle"
toggleBtn.Size             = UDim2.new(0, 60, 0, 140)
toggleBtn.Position         = UDim2.new(1, -64, 0.5, -70)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 120)
toggleBtn.Text             = "🛒\nShop"
toggleBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
toggleBtn.TextScaled       = true
toggleBtn.Font             = Enum.Font.GothamBold
toggleBtn.BorderSizePixel  = 0
toggleBtn.ZIndex           = 5
toggleBtn.Parent           = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 14)
toggleCorner.Parent       = toggleBtn

-- ── Shop Panel ───────────────────────────────────────────────────────────────

local panelWidth = 300

local panel = Instance.new("Frame")
panel.Name              = "ShopPanel"
panel.Size              = UDim2.new(0, panelWidth, 1, -20)
panel.Position          = UDim2.new(1, 10, 0, 10)   -- hidden off-screen
panel.BackgroundColor3  = Color3.fromRGB(16, 12, 28)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel   = 0
panel.ZIndex            = 4
panel.Parent            = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 18)
panelCorner.Parent       = panel

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size                  = UDim2.new(1, 0, 0, 50)
titleLabel.Position              = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency= 1
titleLabel.Text                  = "🛒 Direct Shop"
titleLabel.TextColor3            = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled            = true
titleLabel.Font                  = Enum.Font.GothamBold
titleLabel.ZIndex                = 5
titleLabel.Parent                = panel

-- Scroll frame for items
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name              = "ItemList"
scrollFrame.Size              = UDim2.new(1, -10, 1, -60)
scrollFrame.Position          = UDim2.new(0, 5, 0, 55)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness= 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
scrollFrame.ZIndex            = 5
scrollFrame.Parent            = panel

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder    = Enum.SortOrder.LayoutOrder
listLayout.Padding      = UDim.new(0, 6)
listLayout.Parent       = scrollFrame

-- ─── Populate Items ──────────────────────────────────────────────────────────

local purchasableRarities = { "Common", "Uncommon", "Rare", "Epic" }
local purchasableSet = {}
for _, r in ipairs(purchasableRarities) do purchasableSet[r] = true end

local itemHeight  = 64
local itemPadding = 6
local count       = 0

for _, brainrot in ipairs(BrainrotList) do
	if purchasableSet[brainrot.rarity] then
		count = count + 1
		local price     = RarityConfig.DirectPrice[brainrot.rarity]
		local rarData   = RarityConfig[brainrot.rarity]

		-- Item frame
		local itemFrame = Instance.new("Frame")
		itemFrame.Name              = "Item_" .. brainrot.name
		itemFrame.Size              = UDim2.new(1, -8, 0, itemHeight)
		itemFrame.BackgroundColor3  = Color3.fromRGB(28, 22, 44)
		itemFrame.BackgroundTransparency = 0.2
		itemFrame.BorderSizePixel   = 0
		itemFrame.LayoutOrder       = count
		itemFrame.ZIndex            = 6
		itemFrame.Parent            = scrollFrame

		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 12)
		itemCorner.Parent       = itemFrame

		-- Emoji
		local emojiLbl = Instance.new("TextLabel")
		emojiLbl.Size                  = UDim2.new(0, 50, 1, 0)
		emojiLbl.Position              = UDim2.new(0, 4, 0, 0)
		emojiLbl.BackgroundTransparency= 1
		emojiLbl.Text                  = brainrot.emoji
		emojiLbl.TextScaled            = true
		emojiLbl.Font                  = Enum.Font.GothamBold
		emojiLbl.ZIndex                = 7
		emojiLbl.Parent                = itemFrame

		-- Name + rarity
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size                  = UDim2.new(1, -120, 0, 32)
		nameLbl.Position              = UDim2.new(0, 56, 0, 6)
		nameLbl.BackgroundTransparency= 1
		nameLbl.Text                  = brainrot.name
		nameLbl.TextColor3            = Color3.fromRGB(240, 240, 255)
		nameLbl.TextScaled            = true
		nameLbl.Font                  = Enum.Font.GothamBold
		nameLbl.TextXAlignment        = Enum.TextXAlignment.Left
		nameLbl.ZIndex                = 7
		nameLbl.Parent                = itemFrame

		local rarityLbl = Instance.new("TextLabel")
		rarityLbl.Size                  = UDim2.new(1, -120, 0, 20)
		rarityLbl.Position              = UDim2.new(0, 56, 0, 38)
		rarityLbl.BackgroundTransparency= 1
		rarityLbl.Text                  = "✦ " .. brainrot.rarity
		rarityLbl.TextColor3            = rarData.color
		rarityLbl.TextScaled            = true
		rarityLbl.Font                  = Enum.Font.Gotham
		rarityLbl.TextXAlignment        = Enum.TextXAlignment.Left
		rarityLbl.ZIndex                = 7
		rarityLbl.Parent                = itemFrame

		-- Buy button
		local buyBtn = Instance.new("TextButton")
		buyBtn.Name             = "BuyDirect"
		buyBtn.Size             = UDim2.new(0, 80, 0, 36)
		buyBtn.Position         = UDim2.new(1, -90, 0.5, -18)
		buyBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 120)
		buyBtn.Text             = "$" .. tostring(price)
		buyBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
		buyBtn.TextScaled       = true
		buyBtn.Font             = Enum.Font.GothamBold
		buyBtn.BorderSizePixel  = 0
		buyBtn.ZIndex           = 7
		buyBtn.Parent           = itemFrame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 10)
		btnCorner.Parent       = buyBtn

		-- Capture for closure
		local capturedBrainrot = brainrot

		buyBtn.MouseButton1Click:Connect(function()
			-- Animate button
			local tweenIn = TweenService:Create(buyBtn,
				TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundColor3 = Color3.fromRGB(20, 150, 80) }
			)
			local tweenOut = TweenService:Create(buyBtn,
				TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundColor3 = Color3.fromRGB(40, 200, 120) }
			)
			tweenIn:Play()
			tweenIn.Completed:Wait()
			tweenOut:Play()

			-- Fire server: direct buy with specific brainrot name
			BuyEgg:FireServer(true, capturedBrainrot.name)
		end)
	end
end

-- Set canvas size based on item count
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, count * (itemHeight + itemPadding) + 10)

-- ─── Toggle Animation ────────────────────────────────────────────────────────

local panelOpen = false

local function openPanel()
	panel.Visible = true
	TweenService:Create(panel,
		TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.new(1, -(panelWidth + 72), 0, 10) }
	):Play()
	panelOpen = true
end

local function closePanel()
	local tween = TweenService:Create(panel,
		TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
		{ Position = UDim2.new(1, 10, 0, 10) }
	)
	tween:Play()
	tween.Completed:Connect(function()
		panel.Visible = false
	end)
	panelOpen = false
end

toggleBtn.MouseButton1Click:Connect(function()
	if panelOpen then
		closePanel()
	else
		openPanel()
	end
end)
