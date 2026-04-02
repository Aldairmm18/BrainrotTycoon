-- CashDisplay (LocalScript)
-- StarterPlayerScripts/CashDisplay
-- Shows a floating ScreenGui HUD label with the player's formatted cash.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpdateCash = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UpdateCash")

local player = Players.LocalPlayer

-- ─── Number Formatter ───────────────────────────────────────────────────────

local suffixes = {
	{ 1e12, "T" },
	{ 1e9,  "B" },
	{ 1e6,  "M" },
	{ 1e3,  "K" },
}

local function formatCash(n)
	for _, pair in ipairs(suffixes) do
		if n >= pair[1] then
			local val = n / pair[1]
			-- Show one decimal if < 10, otherwise whole number
			if val < 10 then
				return string.format("%.1f%s", val, pair[2])
			else
				return string.format("%d%s", math.floor(val), pair[2])
			end
		end
	end
	return tostring(math.floor(n))
end

-- ─── Build ScreenGui ────────────────────────────────────────────────────────

local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "CashDisplay"
screenGui.ResetOnSpawn    = false
screenGui.IgnoreGuiInset  = true
screenGui.Parent          = playerGui

-- Background frame (top-center HUD)
local frame = Instance.new("Frame")
frame.Name              = "CashFrame"
frame.Size              = UDim2.new(0, 220, 0, 54)
frame.Position          = UDim2.new(0.5, -110, 0, 12)
frame.BackgroundColor3  = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.25
frame.BorderSizePixel   = 0
frame.Parent            = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent       = frame

-- Coin icon label
local icon = Instance.new("TextLabel")
icon.Size                  = UDim2.new(0, 40, 1, 0)
icon.Position              = UDim2.new(0, 0, 0, 0)
icon.BackgroundTransparency= 1
icon.Text                  = "💰"
icon.TextScaled            = true
icon.Font                  = Enum.Font.GothamBold
icon.Parent                = frame

-- Cash text label
local cashLabel = Instance.new("TextLabel")
cashLabel.Name                  = "CashLabel"
cashLabel.Size                  = UDim2.new(1, -45, 1, 0)
cashLabel.Position              = UDim2.new(0, 42, 0, 0)
cashLabel.BackgroundTransparency= 1
cashLabel.Text                  = "$0"
cashLabel.TextColor3            = Color3.fromRGB(255, 220, 60)
cashLabel.TextScaled            = true
cashLabel.Font                  = Enum.Font.GothamBold
cashLabel.TextXAlignment        = Enum.TextXAlignment.Left
cashLabel.Parent                = frame

-- ─── Update on RemoteEvent ──────────────────────────────────────────────────

UpdateCash.OnClientEvent:Connect(function(newCash)
	cashLabel.Text = "$" .. formatCash(newCash)
end)
