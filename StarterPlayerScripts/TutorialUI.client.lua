-- TutorialUI (LocalScript)
-- StarterPlayerScripts/TutorialUI
-- Shown only to new players (< 60 seconds played, first time).
-- 4-step arrow tutorial.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local DataStoreService  = game:GetService("DataStoreService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- We store completion state via a RemoteEvent to server (avoid client DataStore)
local TutorialDone = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("TutorialDone")

-- ─── ScreenGui ────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "TutorialUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

-- ─── Steps ────────────────────────────────────────────────────────────────────
local STEPS = {
	{
		arrow    = "👇",
		arrowPos = UDim2.new(0.5, -60, 1, -150),  -- near buy egg
		text     = "¡Compra tu primer Brainrot!",
		duration = 4,
	},
	{
		arrow    = "👆",
		arrowPos = UDim2.new(0.5, -60, 0, 70),    -- near cash frame
		text     = "Tu cash sube automáticamente",
		duration = 4,
	},
	{
		arrow    = "👉",
		arrowPos = UDim2.new(1, -200, 1, -120),   -- near shop
		text     = "Compra más en la tienda 🛒",
		duration = 4,
	},
	{
		arrow    = "🎉",
		arrowPos = UDim2.new(0.5, -100, 0.5, -40),
		text     = "¡Ya eres un Brainrot Master!",
		duration = 3,
	},
}

-- ─── Tutorial Elements ────────────────────────────────────────────────────────
local arrowLbl = Instance.new("TextLabel")
arrowLbl.Name                   = "Arrow"
arrowLbl.Size                   = UDim2.new(0, 60, 0, 60)
arrowLbl.BackgroundTransparency = 1
arrowLbl.Text                   = "👇"
arrowLbl.TextScaled             = true
arrowLbl.ZIndex                 = 55
arrowLbl.Visible                = false
arrowLbl.Parent                 = screenGui

local bubble = Instance.new("Frame")
bubble.Name                   = "Bubble"
bubble.Size                   = UDim2.new(0, 260, 0, 60)
bubble.BackgroundColor3       = Color3.fromRGB(14, 10, 38)
bubble.BackgroundTransparency = 0.1
bubble.BorderSizePixel        = 0
bubble.ZIndex                 = 55
bubble.Visible                = false
bubble.Parent                 = screenGui
Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 14)

local bubbleStroke = Instance.new("UIStroke")
bubbleStroke.Color     = Color3.fromRGB(120, 80, 255)
bubbleStroke.Thickness = 1.5
bubbleStroke.Parent    = bubble

local bubbleLbl = Instance.new("TextLabel")
bubbleLbl.Size                   = UDim2.new(1, -12, 1, 0)
bubbleLbl.Position               = UDim2.new(0, 6, 0, 0)
bubbleLbl.BackgroundTransparency = 1
bubbleLbl.TextColor3             = Color3.fromRGB(220, 210, 255)
bubbleLbl.TextScaled             = true
bubbleLbl.Font                   = Enum.Font.GothamBold
bubbleLbl.ZIndex                 = 56
bubbleLbl.Parent                 = bubble

-- ─── Run Tutorial ─────────────────────────────────────────────────────────────
local function runTutorial()
	task.wait(3)   -- let game load
	for _, step in ipairs(STEPS) do
		arrowLbl.Text     = step.arrow
		arrowLbl.Position = step.arrowPos
		arrowLbl.Visible  = true

		-- Bounce arrow
		TweenService:Create(arrowLbl, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Position = step.arrowPos + UDim2.new(0, 0, 0, -10),
		}):Play()

		bubble.Position = UDim2.new(step.arrowPos.X.Scale, step.arrowPos.X.Offset - 100,
			step.arrowPos.Y.Scale, step.arrowPos.Y.Offset + 64)
		bubbleLbl.Text  = step.text
		bubble.Visible  = true

		task.wait(step.duration)

		-- Fade out
		TweenService:Create(arrowLbl, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
		TweenService:Create(bubble, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		TweenService:Create(bubbleLbl, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
		task.wait(0.35)

		arrowLbl.Visible             = false
		arrowLbl.TextTransparency    = 0
		bubble.Visible               = false
		bubble.BackgroundTransparency = 0.1
		bubbleLbl.TextTransparency   = 0
	end

	TutorialDone:FireServer()
	screenGui:Destroy()
end

-- ─── Check if already completed (via RemoteEvent reply) ──────────────────────
local TutorialStatus = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("TutorialStatus")

TutorialStatus.OnClientEvent:Connect(function(done)
	if not done then
		task.spawn(runTutorial)
	else
		screenGui:Destroy()
	end
end)

-- Request status from server on join
TutorialDone:FireServer("check")
