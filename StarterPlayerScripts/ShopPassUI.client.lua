-- ShopPassUI (LocalScript)
-- StarterPlayerScripts/ShopPassUI
-- 👑 VIP button (top-right) + Game Pass shop panel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local BuyPass     = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("BuyPass")
local BuyGuardian = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("BuyGuardian")
local CodeResult  = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CodeResult")

-- ─── Pass Definitions (IDs updated after publishing) ─────────────────────────
local PASSES = {
	{ name = "2x Cash",       desc = "Duplica tu cash por segundo",  price = "99 R$",  passKey = "DOUBLE_CASH",  passId = 0, emoji = "💰" },
	{ name = "Auto Collect",  desc = "Recolecta automáticamente",    price = "149 R$", passKey = "AUTO_COLLECT", passId = 0, emoji = "🤖" },
	{ name = "Lucky Egg",     desc = "Mayor chance de rarezas",      price = "199 R$", passKey = "LUCKY_EGG",   passId = 0, emoji = "🍀" },
	{ name = "VIP Pack",      desc = "Zona VIP + título especial",   price = "299 R$", passKey = "VIP",         passId = 0, emoji = "👑" },
	{ name = "Starter Pack",  desc = "5 000 coins gratis al unirse", price = "49 R$",  passKey = "STARTER_PACK",passId = 0, emoji = "🎁" },
}

-- ─── ScreenGui ────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ShopPassUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

-- ─── 👑 VIP Button (top-right) ───────────────────────────────────────────────
local vipBtn = Instance.new("TextButton")
vipBtn.Name             = "VIPButton"
vipBtn.Size             = UDim2.new(0, 110, 0, 44)
vipBtn.Position         = UDim2.new(1, -126, 0, 12)
vipBtn.BorderSizePixel  = 0
vipBtn.Text             = "👑 VIP"
vipBtn.TextColor3       = Color3.fromRGB(255, 235, 100)
vipBtn.TextScaled       = true
vipBtn.Font             = Enum.Font.GothamBold
vipBtn.AutoButtonColor  = false
vipBtn.BackgroundColor3 = Color3.fromRGB(28, 18, 50)
vipBtn.Parent           = screenGui
Instance.new("UICorner", vipBtn).CornerRadius = UDim.new(0, 14)

local vipStroke = Instance.new("UIStroke")
vipStroke.Color     = Color3.fromRGB(255, 200, 30)
vipStroke.Thickness = 2
vipStroke.Parent    = vipBtn

local vipGradient = Instance.new("UIGradient")
vipGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 30, 100)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 10, 45)),
})
vipGradient.Rotation = 90
vipGradient.Parent = vipBtn

vipBtn.MouseEnter:Connect(function()
	TweenService:Create(vipBtn, TweenInfo.new(0.1), {
		BackgroundColor3 = Color3.fromRGB(60, 40, 120)
	}):Play()
end)
vipBtn.MouseLeave:Connect(function()
	TweenService:Create(vipBtn, TweenInfo.new(0.1), {
		BackgroundColor3 = Color3.fromRGB(28, 18, 50)
	}):Play()
end)

-- ─── Pass Panel ───────────────────────────────────────────────────────────────
local PANEL_W, PANEL_H = 380, 520

local panel = Instance.new("Frame")
panel.Name                   = "PassPanel"
panel.Size                   = UDim2.new(0, PANEL_W, 0, PANEL_H)
panel.Position               = UDim2.new(1, -(PANEL_W + 16), 0, 64)
panel.BackgroundColor3       = Color3.fromRGB(12, 8, 28)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel        = 0
panel.Visible                = false
panel.ZIndex                 = 15
panel.Parent                 = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color     = Color3.fromRGB(200, 160, 20)
panelStroke.Thickness = 2
panelStroke.Parent    = panel

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size                  = UDim2.new(1, -20, 0, 44)
titleLabel.Position              = UDim2.new(0, 10, 0, 8)
titleLabel.BackgroundTransparency = 1
titleLabel.Text                  = "👑  Game Passes"
titleLabel.TextColor3            = Color3.fromRGB(255, 225, 80)
titleLabel.TextScaled            = true
titleLabel.Font                  = Enum.Font.GothamBold
titleLabel.ZIndex                = 16
titleLabel.Parent                = panel

-- Divider
local divider = Instance.new("Frame")
divider.Size             = UDim2.new(1, -20, 0, 1)
divider.Position         = UDim2.new(0, 10, 0, 56)
divider.BackgroundColor3 = Color3.fromRGB(180, 140, 20)
divider.BorderSizePixel  = 0
divider.ZIndex           = 16
divider.Parent           = panel

-- Scroll frame for pass cards
local scroll = Instance.new("ScrollingFrame")
scroll.Size                   = UDim2.new(1, -10, 1, -70)
scroll.Position               = UDim2.new(0, 5, 0, 62)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel        = 0
scroll.ScrollBarThickness     = 4
scroll.ScrollBarImageColor3   = Color3.fromRGB(200, 160, 20)
scroll.ZIndex                 = 16
scroll.Parent                 = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding      = UDim.new(0, 8)
listLayout.SortOrder    = Enum.SortOrder.LayoutOrder
listLayout.Parent       = scroll

local listPad = Instance.new("UIPadding")
listPad.PaddingTop    = UDim.new(0, 6)
listPad.PaddingBottom = UDim.new(0, 6)
listPad.PaddingLeft   = UDim.new(0, 4)
listPad.PaddingRight  = UDim.new(0, 4)
listPad.Parent        = scroll

-- ─── Build Pass Cards ─────────────────────────────────────────────────────────
local CARD_H = 80

for i, passData in ipairs(PASSES) do
	local card = Instance.new("Frame")
	card.Name             = passData.passKey
	card.Size             = UDim2.new(1, 0, 0, CARD_H)
	card.BackgroundColor3 = Color3.fromRGB(22, 14, 50)
	card.BorderSizePixel  = 0
	card.LayoutOrder      = i
	card.ZIndex           = 17
	card.Parent           = scroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color     = Color3.fromRGB(90, 60, 160)
	cardStroke.Thickness = 1
	cardStroke.Parent    = card

	-- Emoji
	local emojiLbl = Instance.new("TextLabel")
	emojiLbl.Size                   = UDim2.new(0, 56, 1, 0)
	emojiLbl.Position               = UDim2.new(0, 6, 0, 0)
	emojiLbl.BackgroundTransparency = 1
	emojiLbl.Text                   = passData.emoji
	emojiLbl.TextScaled             = true
	emojiLbl.ZIndex                 = 18
	emojiLbl.Parent                 = card

	-- Name
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size                   = UDim2.new(0.5, -60, 0, 28)
	nameLbl.Position               = UDim2.new(0, 66, 0, 10)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text                   = passData.name
	nameLbl.TextColor3             = Color3.fromRGB(255, 235, 100)
	nameLbl.TextScaled             = true
	nameLbl.Font                   = Enum.Font.GothamBold
	nameLbl.TextXAlignment         = Enum.TextXAlignment.Left
	nameLbl.ZIndex                 = 18
	nameLbl.Parent                 = card

	-- Description
	local descLbl = Instance.new("TextLabel")
	descLbl.Size                   = UDim2.new(0.6, -60, 0, 22)
	descLbl.Position               = UDim2.new(0, 66, 0, 40)
	descLbl.BackgroundTransparency = 1
	descLbl.Text                   = passData.desc
	descLbl.TextColor3             = Color3.fromRGB(180, 170, 210)
	descLbl.TextScaled             = true
	descLbl.Font                   = Enum.Font.Gotham
	descLbl.TextXAlignment         = Enum.TextXAlignment.Left
	descLbl.ZIndex                 = 18
	descLbl.Parent                 = card

	-- Buy button
	local buyPassBtn = Instance.new("TextButton")
	buyPassBtn.Name             = "BuyPassBtn_" .. passData.passKey
	buyPassBtn.Size             = UDim2.new(0, 100, 0, 38)
	buyPassBtn.Position         = UDim2.new(1, -108, 0.5, -19)
	buyPassBtn.BackgroundColor3 = Color3.fromRGB(220, 165, 0)
	buyPassBtn.BorderSizePixel  = 0
	buyPassBtn.Text             = passData.price
	buyPassBtn.TextColor3       = Color3.fromRGB(20, 14, 0)
	buyPassBtn.TextScaled       = true
	buyPassBtn.Font             = Enum.Font.GothamBold
	buyPassBtn.AutoButtonColor  = false
	buyPassBtn.ZIndex           = 19
	buyPassBtn.Parent           = card
	Instance.new("UICorner", buyPassBtn).CornerRadius = UDim.new(0, 10)

	buyPassBtn.MouseEnter:Connect(function()
		TweenService:Create(buyPassBtn, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.fromRGB(255, 200, 20)
		}):Play()
	end)
	buyPassBtn.MouseLeave:Connect(function()
		TweenService:Create(buyPassBtn, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.fromRGB(220, 165, 0)
		}):Play()
	end)

	-- Capture passId in closure
	local pid = passData.passId
	buyPassBtn.MouseButton1Click:Connect(function()
		if pid > 0 then
			BuyPass:FireServer(pid)
		else
			-- Pass not yet live — show placeholder message
			buyPassBtn.Text = "🔜 Soon!"
			task.wait(2)
			buyPassBtn.Text = passData.price
		end
	end)
end

-- Update canvas size
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 12)
end)

-- ─── Guardian Card (in-game cash purchase) ────────────────────────────────────────

local guardianSep = Instance.new("Frame")
guardianSep.Name             = "GuardianSeparator"
guardianSep.Size             = UDim2.new(1, 0, 0, 1)
guardianSep.BackgroundColor3 = Color3.fromRGB(100, 80, 160)
guardianSep.BorderSizePixel  = 0
guardianSep.LayoutOrder      = 10
guardianSep.ZIndex           = 17
guardianSep.Parent           = scroll

local guardianHeader = Instance.new("TextLabel")
guardianHeader.Name                   = "GuardianHeader"
guardianHeader.Size                   = UDim2.new(1, 0, 0, 28)
guardianHeader.BackgroundTransparency = 1
guardianHeader.Text                   = "🛡️  Tienda en Juego"
guardianHeader.TextColor3             = Color3.fromRGB(180, 160, 255)
guardianHeader.TextScaled             = true
guardianHeader.Font                   = Enum.Font.GothamBold
guardianHeader.TextXAlignment         = Enum.TextXAlignment.Left
guardianHeader.LayoutOrder            = 11
guardianHeader.ZIndex                 = 17
guardianHeader.Parent                 = scroll

local guardianCard = Instance.new("Frame")
guardianCard.Name             = "GuardianCard"
guardianCard.Size             = UDim2.new(1, 0, 0, CARD_H)
guardianCard.BackgroundColor3 = Color3.fromRGB(18, 14, 40)
guardianCard.BorderSizePixel  = 0
guardianCard.LayoutOrder      = 12
guardianCard.ZIndex           = 17
guardianCard.Parent           = scroll
Instance.new("UICorner", guardianCard).CornerRadius = UDim.new(0, 12)

local gcStroke = Instance.new("UIStroke")
gcStroke.Color     = Color3.fromRGB(100, 80, 200)
gcStroke.Thickness = 1
gcStroke.Parent    = guardianCard

local gcEmoji = Instance.new("TextLabel")
gcEmoji.Size                   = UDim2.new(0, 56, 1, 0)
gcEmoji.Position               = UDim2.new(0, 6, 0, 0)
gcEmoji.BackgroundTransparency = 1
gcEmoji.Text                   = "🛡️"
gcEmoji.TextScaled             = true
gcEmoji.ZIndex                 = 18
gcEmoji.Parent                 = guardianCard

local gcName = Instance.new("TextLabel")
gcName.Size                   = UDim2.new(0.5, -60, 0, 28)
gcName.Position               = UDim2.new(0, 66, 0, 10)
gcName.BackgroundTransparency = 1
gcName.Text                   = "Guardián"
gcName.TextColor3             = Color3.fromRGB(200, 180, 255)
gcName.TextScaled             = true
gcName.Font                   = Enum.Font.GothamBold
gcName.TextXAlignment         = Enum.TextXAlignment.Left
gcName.ZIndex                 = 18
gcName.Parent                 = guardianCard

local gcDesc = Instance.new("TextLabel")
gcDesc.Size                   = UDim2.new(0.6, -60, 0, 22)
gcDesc.Position               = UDim2.new(0, 66, 0, 40)
gcDesc.BackgroundTransparency = 1
gcDesc.Text                   = "-10% chance de robo (máx 3)"
gcDesc.TextColor3             = Color3.fromRGB(160, 150, 200)
gcDesc.TextScaled             = true
gcDesc.Font                   = Enum.Font.Gotham
gcDesc.TextXAlignment         = Enum.TextXAlignment.Left
gcDesc.ZIndex                 = 18
gcDesc.Parent                 = guardianCard

local gcBuyBtn = Instance.new("TextButton")
gcBuyBtn.Name             = "BuyGuardianBtn"
gcBuyBtn.Size             = UDim2.new(0, 110, 0, 38)
gcBuyBtn.Position         = UDim2.new(1, -118, 0.5, -19)
gcBuyBtn.BackgroundColor3 = Color3.fromRGB(90, 60, 200)
gcBuyBtn.BorderSizePixel  = 0
gcBuyBtn.Text             = "🛡️ $5,000"
gcBuyBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
gcBuyBtn.TextScaled       = true
gcBuyBtn.Font             = Enum.Font.GothamBold
gcBuyBtn.AutoButtonColor  = false
gcBuyBtn.ZIndex           = 19
gcBuyBtn.Parent           = guardianCard
Instance.new("UICorner", gcBuyBtn).CornerRadius = UDim.new(0, 10)

gcBuyBtn.MouseEnter:Connect(function()
	TweenService:Create(gcBuyBtn, TweenInfo.new(0.1), {
		BackgroundColor3 = Color3.fromRGB(120, 90, 240)
	}):Play()
end)
gcBuyBtn.MouseLeave:Connect(function()
	TweenService:Create(gcBuyBtn, TweenInfo.new(0.1), {
		BackgroundColor3 = Color3.fromRGB(90, 60, 200)
	}):Play()
end)

gcBuyBtn.MouseButton1Click:Connect(function()
	BuyGuardian:FireServer()
end)

-- CodeResult feedback for guardian (and codes)
CodeResult.OnClientEvent:Connect(function(success, message)
	-- Reuse a simple toast effect on the panel title area
	local toastColor = success
		and Color3.fromRGB(100, 255, 130)
		or  Color3.fromRGB(255, 100, 100)
	local icon = success and "✅ " or "❌ "

	local flash = Instance.new("TextLabel")
	flash.Size                   = UDim2.new(0, 320, 0, 60)
	flash.Position               = UDim2.new(0.5, -160, 1, -80)
	flash.BackgroundColor3       = Color3.fromRGB(16, 8, 28)
	flash.BackgroundTransparency = 0.1
	flash.BorderSizePixel        = 0
	flash.Text                   = icon .. (message or "")
	flash.TextColor3             = toastColor
	flash.TextScaled             = true
	flash.Font                   = Enum.Font.GothamBold
	flash.TextWrapped            = true
	flash.ZIndex                 = 50
	flash.Parent                 = screenGui
	Instance.new("UICorner", flash).CornerRadius = UDim.new(0, 14)

	task.delay(3, function()
		flash:Destroy()
	end)
end)

-- ─── Toggle Panel ─────────────────────────────────────────────────────────────
local panelOpen = false

vipBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	if panelOpen then
		panel.Visible = true
		panel.Size     = UDim2.new(0, PANEL_W, 0, 0)
		TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
		}):Play()
	else
		TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, PANEL_W, 0, 0)
		}):Play()
		task.delay(0.2, function()
			panel.Visible = false
		end)
	end
end)
