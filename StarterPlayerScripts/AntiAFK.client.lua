-- AntiAFK (LocalScript)
-- StarterPlayerScripts/AntiAFK
-- Every 3 minutes shows a clickable bonus prompt. Rewards income×30 seconds on click.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ActivityBonus = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ActivityBonus")

-- ─── ScreenGui ────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "AntiAFKGui"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

-- ─── Bonus Card ───────────────────────────────────────────────────────────────
local card = Instance.new("TextButton")
card.Name                   = "BonusCard"
card.Size                   = UDim2.new(0, 300, 0, 90)
card.Position               = UDim2.new(0.5, -150, 1, 110)  -- starts below screen
card.BackgroundColor3       = Color3.fromRGB(14, 10, 38)
card.BackgroundTransparency = 0.08
card.BorderSizePixel        = 0
card.Text                   = ""
card.AutoButtonColor        = false
card.ZIndex                 = 35
card.Parent                 = screenGui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)

local cardStroke = Instance.new("UIStroke")
cardStroke.Color     = Color3.fromRGB(80, 220, 150)
cardStroke.Thickness = 2
cardStroke.Parent    = card

local iconLbl = Instance.new("TextLabel")
iconLbl.Size                   = UDim2.new(0, 70, 1, 0)
iconLbl.BackgroundTransparency = 1
iconLbl.Text                   = "🎁"
iconLbl.TextScaled             = true
iconLbl.ZIndex                 = 36
iconLbl.Parent                 = card

local textLbl = Instance.new("TextLabel")
textLbl.Size                   = UDim2.new(1, -80, 0.6, 0)
textLbl.Position               = UDim2.new(0, 72, 0, 8)
textLbl.BackgroundTransparency = 1
textLbl.Text                   = "¡Toca para tu bonus de actividad!"
textLbl.TextColor3             = Color3.fromRGB(200, 255, 200)
textLbl.TextScaled             = true
textLbl.Font                   = Enum.Font.GothamBold
textLbl.TextXAlignment         = Enum.TextXAlignment.Left
textLbl.ZIndex                 = 36
textLbl.Parent                 = card

local timerLbl = Instance.new("TextLabel")
timerLbl.Name                   = "Timer"
timerLbl.Size                   = UDim2.new(1, -80, 0.35, 0)
timerLbl.Position               = UDim2.new(0, 72, 0.62, 0)
timerLbl.BackgroundTransparency = 1
timerLbl.Text                   = "30s restantes"
timerLbl.TextColor3             = Color3.fromRGB(160, 200, 160)
timerLbl.TextScaled             = true
timerLbl.Font                   = Enum.Font.Gotham
timerLbl.TextXAlignment         = Enum.TextXAlignment.Left
timerLbl.ZIndex                 = 36
timerLbl.Parent                 = card

-- ─── Show / Hide ──────────────────────────────────────────────────────────────
local showing = false

local function hideCard()
	showing = false
	TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -150, 1, 110),
	}):Play()
end

local function showCard()
	showing = true
	TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -150, 1, -106),
	}):Play()

	-- Countdown timer
	local countdown = 30
	task.spawn(function()
		while countdown > 0 and showing do
			timerLbl.Text = tostring(countdown) .. "s restantes"
			task.wait(1)
			countdown = countdown - 1
		end
		if showing then hideCard() end
	end)
end

card.MouseButton1Click:Connect(function()
	if not showing then return end
	hideCard()
	ActivityBonus:FireServer()

	-- Visual feedback
	local flash = Instance.new("TextLabel")
	flash.Size                   = UDim2.new(0, 260, 0, 50)
	flash.Position               = UDim2.new(0.5, -130, 0.5, -25)
	flash.BackgroundColor3       = Color3.fromRGB(14, 10, 38)
	flash.BackgroundTransparency = 0.1
	flash.Text                   = "💰 ¡Bonus reclamado!"
	flash.TextColor3             = Color3.fromRGB(100, 255, 140)
	flash.TextScaled             = true
	flash.Font                   = Enum.Font.GothamBold
	flash.ZIndex                 = 50
	flash.Parent                 = screenGui
	Instance.new("UICorner", flash).CornerRadius = UDim.new(0, 14)

	TweenService:Create(flash, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -130, 0.4, -25),
		TextTransparency = 1,
		BackgroundTransparency = 1,
	}):Play()
	game:GetService("Debris"):AddItem(flash, 1.6)
end)

-- ─── Main Loop ───────────────────────────────────────────────────────────────
task.spawn(function()
	while true do
		task.wait(180)   -- every 3 minutes
		showCard()
	end
end)
