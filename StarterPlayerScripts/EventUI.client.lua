-- EventUI (LocalScript)
-- StarterPlayerScripts/EventUI
-- Displays the top-center event banner with server-synced countdown
-- and a one-tap buy button for event eggs.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player       = Players.LocalPlayer
local playerGui    = player:WaitForChild("PlayerGui")

local RE          = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateEvent = RE:WaitForChild("UpdateEvent")
local BuyEventEgg = RE:WaitForChild("BuyEventEgg")

-- ─── ScreenGui ────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name           = "EventUI"
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = playerGui

-- ─── Event banner (top-centre) ────────────────────────────────────────────────
local banner = Instance.new("Frame")
banner.Name                   = "EventBanner"
banner.Size                   = UDim2.new(0, 340, 0, 72)
banner.Position               = UDim2.new(0.5, -170, 0, 56)
banner.BackgroundColor3       = Color3.fromRGB(12, 4, 28)
banner.BackgroundTransparency = 0.08
banner.BorderSizePixel        = 0
banner.Visible                = false
banner.ZIndex                 = 10
banner.Parent                 = gui
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 14)

local bannerStroke = Instance.new("UIStroke")
bannerStroke.Color     = Color3.fromRGB(255, 180, 0)
bannerStroke.Thickness = 2
bannerStroke.Parent    = banner

-- Gradient shimmer
local bannerGrad = Instance.new("UIGradient")
bannerGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0,   Color3.fromRGB(30, 10, 60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 6,  40)),
	ColorSequenceKeypoint.new(1,   Color3.fromRGB(30, 10, 60)),
})
bannerGrad.Rotation = 90
bannerGrad.Parent   = banner

-- Event name label
local eventName = Instance.new("TextLabel")
eventName.Name                   = "EventName"
eventName.Size                   = UDim2.new(0.62, -8, 0.52, 0)
eventName.Position               = UDim2.new(0, 8, 0, 4)
eventName.BackgroundTransparency = 1
eventName.Text                   = ""
eventName.TextColor3             = Color3.fromRGB(255, 220, 50)
eventName.TextStrokeTransparency = 0
eventName.TextScaled             = true
eventName.Font                   = Enum.Font.GothamBold
eventName.TextXAlignment         = Enum.TextXAlignment.Left
eventName.ZIndex                 = 11
eventName.Parent                 = banner

-- Countdown label
local timerLabel = Instance.new("TextLabel")
timerLabel.Name                   = "Timer"
timerLabel.Size                   = UDim2.new(0.62, -8, 0.42, 0)
timerLabel.Position               = UDim2.new(0, 8, 0.54, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Text                   = ""
timerLabel.TextColor3             = Color3.fromRGB(255, 100, 100)
timerLabel.TextStrokeTransparency = 0
timerLabel.TextScaled             = true
timerLabel.Font                   = Enum.Font.GothamBold
timerLabel.TextXAlignment         = Enum.TextXAlignment.Left
timerLabel.ZIndex                 = 11
timerLabel.Parent                 = banner

-- Buy button
local eventBtn = Instance.new("TextButton")
eventBtn.Name             = "BuyEventBtn"
eventBtn.Size             = UDim2.new(0.35, -4, 0.62, 0)
eventBtn.Position         = UDim2.new(0.65, 0, 0.19, 0)
eventBtn.BackgroundColor3 = Color3.fromRGB(220, 120, 0)
eventBtn.BorderSizePixel  = 0
eventBtn.Text             = "🥚 $?"
eventBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
eventBtn.TextScaled       = true
eventBtn.Font             = Enum.Font.GothamBold
eventBtn.AutoButtonColor  = false
eventBtn.ZIndex           = 12
eventBtn.Parent           = banner
Instance.new("UICorner", eventBtn).CornerRadius = UDim.new(0, 10)

eventBtn.MouseEnter:Connect(function()
	TweenService:Create(eventBtn, TweenInfo.new(0.1),
		{ BackgroundColor3 = Color3.fromRGB(255, 150, 20) }):Play()
end)
eventBtn.MouseLeave:Connect(function()
	TweenService:Create(eventBtn, TweenInfo.new(0.1),
		{ BackgroundColor3 = Color3.fromRGB(220, 120, 0) }):Play()
end)

-- ─── Time formatter ───────────────────────────────────────────────────────────
local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

-- ─── Local countdown state (authoritative value from server every 5 s) ────────
local localRemaining = 0

local function showBanner()
	if not banner.Visible then
		banner.Visible  = true
		banner.Size     = UDim2.new(0, 340, 0, 0)
		banner.Position = UDim2.new(0.5, -170, 0, 56)
		TweenService:Create(banner,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = UDim2.new(0, 340, 0, 72) }
		):Play()
	end
end

local function hideBanner()
	TweenService:Create(banner,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Size = UDim2.new(0, 340, 0, 0) }
	):Play()
	task.delay(0.22, function() banner.Visible = false end)
end

-- Receive authoritative time from server
UpdateEvent.OnClientEvent:Connect(function(eventData)
	if not eventData then
		hideBanner()
		localRemaining = 0
		return
	end
	localRemaining       = eventData.remaining
	eventName.Text       = eventData.name
	timerLabel.Text      = "⏰ " .. formatTime(localRemaining)
	eventBtn.Text        = "🥚 $" .. eventData.eggCost
	showBanner()
end)

-- Decrement locally every second so the display stays smooth
task.spawn(function()
	while true do
		task.wait(1)
		if localRemaining > 0 then
			localRemaining = localRemaining - 1
			timerLabel.Text = "⏰ " .. formatTime(localRemaining)
			if localRemaining <= 0 then
				hideBanner()
			end
		end
	end
end)

-- Buy button
eventBtn.MouseButton1Click:Connect(function()
	BuyEventEgg:FireServer()
end)
