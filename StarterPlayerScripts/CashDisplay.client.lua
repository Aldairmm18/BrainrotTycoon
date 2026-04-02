-- CashDisplay (LocalScript)
-- StarterPlayerScripts/CashDisplay
-- Shows current cash in the top-left corner with K/M/B/T formatting and a subtle scale animation.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player     = Players.LocalPlayer
local UpdateCash = ReplicatedStorage.RemoteEvents.UpdateCash

-- ─── Number Formatter ─────────────────────────────────────────────────────────

local SUFFIXES = {
	{ 1e12, "T" },
	{ 1e9,  "B" },
	{ 1e6,  "M" },
	{ 1e3,  "K" },
}

local function formatCash(n)
	n = math.floor(n)
	for _, entry in ipairs(SUFFIXES) do
		local threshold, suffix = entry[1], entry[2]
		if n >= threshold then
			local value = n / threshold
			-- Show one decimal if not whole number
			if value ~= math.floor(value) then
				return ("%.1f%s"):format(value, suffix)
			else
				return ("%d%s"):format(value, suffix)
			end
		end
	end
	return tostring(n)
end

-- ─── Build UI ─────────────────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "CashDisplayGui"
screenGui.ResetOnSpawn    = false
screenGui.IgnoreGuiInset  = true
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = player.PlayerGui

-- Background pill
local frame = Instance.new("Frame")
frame.Name              = "CashFrame"
frame.Size              = UDim2.new(0, 180, 0, 48)
frame.Position          = UDim2.new(0, 16, 0, 16)
frame.BackgroundColor3  = Color3.fromRGB(15, 15, 25)
frame.BackgroundTransparency = 0.25
frame.BorderSizePixel   = 0
frame.Parent            = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 24)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color       = Color3.fromRGB(255, 215, 0)
stroke.Thickness   = 1.5
stroke.Transparency = 0.4
stroke.Parent      = frame

local cashLabel = Instance.new("TextLabel")
cashLabel.Name               = "CashLabel"
cashLabel.Size               = UDim2.new(1, 0, 1, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.Text               = "💰 $0"
cashLabel.Font               = Enum.Font.GothamBold
cashLabel.TextSize           = 22
cashLabel.TextColor3         = Color3.fromRGB(255, 225, 80)
cashLabel.TextXAlignment     = Enum.TextXAlignment.Center
cashLabel.TextYAlignment     = Enum.TextYAlignment.Center
cashLabel.Parent             = frame

-- ─── Update + Animation ───────────────────────────────────────────────────────

local function animatePop()
	local tweenIn = TweenService:Create(frame, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 196, 0, 54)
	})
	local tweenOut = TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 180, 0, 48)
	})
	tweenIn:Play()
	tweenIn.Completed:Connect(function()
		tweenOut:Play()
	end)
end

local function updateDisplay(cashAmount)
	cashLabel.Text = "💰 $" .. formatCash(cashAmount)
	animatePop()
end

-- ─── Events ───────────────────────────────────────────────────────────────────

UpdateCash.OnClientEvent:Connect(updateDisplay)

-- Also read from leaderstats immediately if available
local function initFromLeaderstats()
	local ls = player:WaitForChild("leaderstats", 10)
	if ls then
		local cashVal = ls:WaitForChild("Cash", 5)
		if cashVal then
			updateDisplay(cashVal.Value)
		end
	end
end

task.spawn(initFromLeaderstats)
