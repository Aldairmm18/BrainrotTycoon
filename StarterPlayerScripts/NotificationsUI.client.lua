-- NotificationsUI (LocalScript)
-- StarterPlayerScripts/NotificationsUI
-- Slide-in toast notifications (top-right). Handles GlobalNotification events.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GlobalNotification = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GlobalNotification")

-- ─── ScreenGui ────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "NotificationsUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

-- ─── Toast Queue ─────────────────────────────────────────────────────────────
local TOAST_W    = 320
local TOAST_H    = 56
local TOAST_PAD  = 8
local MAX_TOASTS = 3

local activeToasts = {}

local COLOR_MAP = {
	gold    = Color3.fromRGB(255, 210, 30),
	green   = Color3.fromRGB(50, 220, 100),
	purple  = Color3.fromRGB(160, 80, 255),
	red     = Color3.fromRGB(220, 60, 60),
	default = Color3.fromRGB(100, 140, 255),
}

local function repositionToasts()
	for i, toast in ipairs(activeToasts) do
		local targetY = 14 + (i - 1) * (TOAST_H + TOAST_PAD)
		TweenService:Create(toast, TweenInfo.new(0.2), {
			Position = UDim2.new(1, -(TOAST_W + 14), 0, targetY),
		}):Play()
	end
end

local function removeToast(toast)
	for i, t in ipairs(activeToasts) do
		if t == toast then
			table.remove(activeToasts, i)
			break
		end
	end
	TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(1, 14, toast.Position.Y.Scale, toast.Position.Y.Offset),
		BackgroundTransparency = 1,
	}):Play()
	task.wait(0.26)
	toast:Destroy()
	repositionToasts()
end

local function showNotification(data)
	-- Max 3 at a time: evict oldest
	if #activeToasts >= MAX_TOASTS then
		task.spawn(removeToast, activeToasts[1])
		task.wait(0.1)
	end

	local accentColor = COLOR_MAP[data.color] or COLOR_MAP.default

	local toast = Instance.new("Frame")
	toast.Name                   = "Toast"
	toast.Size                   = UDim2.new(0, TOAST_W, 0, TOAST_H)
	toast.Position               = UDim2.new(1, 14, 0, 14)  -- starts off-screen right
	toast.BackgroundColor3       = Color3.fromRGB(12, 10, 28)
	toast.BackgroundTransparency = 0.1
	toast.BorderSizePixel        = 0
	toast.ZIndex                 = 40
	toast.Parent                 = screenGui
	Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 14)

	local stroke = Instance.new("UIStroke")
	stroke.Color     = accentColor
	stroke.Thickness = 1.5
	stroke.Parent    = toast

	-- Accent bar on left
	local bar = Instance.new("Frame")
	bar.Size             = UDim2.new(0, 4, 1, -8)
	bar.Position         = UDim2.new(0, 6, 0, 4)
	bar.BackgroundColor3 = accentColor
	bar.BorderSizePixel  = 0
	bar.ZIndex           = 41
	bar.Parent           = toast
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, -20, 1, 0)
	lbl.Position               = UDim2.new(0, 16, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = data.msg or ""
	lbl.TextColor3             = Color3.fromRGB(230, 225, 255)
	lbl.TextScaled             = true
	lbl.Font                   = Enum.Font.Gotham
	lbl.TextXAlignment         = Enum.TextXAlignment.Left
	lbl.ZIndex                 = 41
	lbl.Parent                 = toast

	table.insert(activeToasts, toast)
	repositionToasts()

	-- Slide in
	local targetY = 14 + (#activeToasts - 1) * (TOAST_H + TOAST_PAD)
	TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -(TOAST_W + 14), 0, targetY),
	}):Play()

	-- Auto-dismiss after 4 seconds
	task.delay(4, function()
		if toast and toast.Parent then
			task.spawn(removeToast, toast)
		end
	end)
end

GlobalNotification.OnClientEvent:Connect(function(data)
	task.spawn(showNotification, data)
end)
