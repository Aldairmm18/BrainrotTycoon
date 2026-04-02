-- CodesUI (LocalScript)
-- StarterPlayerScripts/CodesUI
-- 🎁 Código button (bottom-left) + code input panel + result toast.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RedeemCode   = RemoteEvents:WaitForChild("RedeemCode")
local CodeResult   = RemoteEvents:WaitForChild("CodeResult")

-- ── ScreenGui ────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name          = "CodesUI"
screenGui.ResetOnSpawn  = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent        = playerGui

-- ── 🎁 Código Button (bottom-left) ───────────────────────────────────────────
local codeBtn = Instance.new("TextButton")
codeBtn.Name             = "CodeButton"
codeBtn.Size             = UDim2.new(0, 130, 0, 50)
codeBtn.Position         = UDim2.new(0, 16, 1, -66)
codeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
codeBtn.BorderSizePixel  = 0
codeBtn.Text             = "🎁 Código"
codeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
codeBtn.TextScaled       = true
codeBtn.Font             = Enum.Font.GothamBold
codeBtn.AutoButtonColor  = false
codeBtn.Parent           = screenGui
Instance.new("UICorner", codeBtn).CornerRadius = UDim.new(0, 18)

local codeBtnStroke = Instance.new("UIStroke")
codeBtnStroke.Color     = Color3.fromRGB(120, 80, 255)
codeBtnStroke.Thickness = 1.5
codeBtnStroke.Parent    = codeBtn

codeBtn.MouseEnter:Connect(function()
	TweenService:Create(codeBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(65, 55, 100)}):Play()
end)
codeBtn.MouseLeave:Connect(function()
	TweenService:Create(codeBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 40, 60)}):Play()
end)

-- ── Input Panel ───────────────────────────────────────────────────────────────
local inputPanel = Instance.new("Frame")
inputPanel.Name                  = "InputPanel"
inputPanel.Size                  = UDim2.new(0, 320, 0, 160)
inputPanel.Position              = UDim2.new(0, 16, 1, -230)
inputPanel.BackgroundColor3      = Color3.fromRGB(15, 15, 28)
inputPanel.BackgroundTransparency = 0.08
inputPanel.BorderSizePixel       = 0
inputPanel.Visible               = false
inputPanel.ZIndex                = 20
inputPanel.Parent                = screenGui
Instance.new("UICorner", inputPanel).CornerRadius = UDim.new(0, 16)

local inputStroke = Instance.new("UIStroke")
inputStroke.Color     = Color3.fromRGB(120, 80, 255)
inputStroke.Thickness = 1.5
inputStroke.Parent    = inputPanel

local titleLabel = Instance.new("TextLabel")
titleLabel.Size                  = UDim2.new(1, -20, 0, 36)
titleLabel.Position              = UDim2.new(0, 10, 0, 8)
titleLabel.BackgroundTransparency = 1
titleLabel.Text                  = "🎁 Canjear Código"
titleLabel.TextColor3            = Color3.fromRGB(220, 200, 255)
titleLabel.TextScaled            = true
titleLabel.Font                  = Enum.Font.GothamBold
titleLabel.ZIndex                = 21
titleLabel.Parent                = inputPanel

local textBox = Instance.new("TextBox")
textBox.Name                   = "CodeInput"
textBox.Size                   = UDim2.new(1, -20, 0, 42)
textBox.Position               = UDim2.new(0, 10, 0, 52)
textBox.BackgroundColor3       = Color3.fromRGB(30, 30, 50)
textBox.BorderSizePixel        = 0
textBox.Text                   = ""
textBox.PlaceholderText        = "Ingresa tu código..."
textBox.PlaceholderColor3      = Color3.fromRGB(120, 120, 160)
textBox.TextColor3             = Color3.fromRGB(255, 255, 255)
textBox.TextScaled             = true
textBox.Font                   = Enum.Font.Gotham
textBox.ClearTextOnFocus       = false
textBox.ZIndex                 = 21
textBox.Parent                 = inputPanel
Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 10)

local redeemBtn = Instance.new("TextButton")
redeemBtn.Name             = "RedeemBtn"
redeemBtn.Size             = UDim2.new(1, -20, 0, 42)
redeemBtn.Position         = UDim2.new(0, 10, 0, 104)
redeemBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
redeemBtn.BorderSizePixel  = 0
redeemBtn.Text             = "Canjear"
redeemBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
redeemBtn.TextScaled       = true
redeemBtn.Font             = Enum.Font.GothamBold
redeemBtn.AutoButtonColor  = false
redeemBtn.ZIndex           = 21
redeemBtn.Parent           = inputPanel
Instance.new("UICorner", redeemBtn).CornerRadius = UDim.new(0, 10)

redeemBtn.MouseEnter:Connect(function()
	TweenService:Create(redeemBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(150, 110, 255)}):Play()
end)
redeemBtn.MouseLeave:Connect(function()
	TweenService:Create(redeemBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(120, 80, 255)}):Play()
end)

-- ── Toggle Panel ─────────────────────────────────────────────────────────────
local panelOpen = false

codeBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	inputPanel.Visible = panelOpen
	if panelOpen then
		inputPanel.Size = UDim2.new(0, 0, 0, 0)
		inputPanel.Position = UDim2.new(0, 16, 1, -160)
		TweenService:Create(inputPanel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size     = UDim2.new(0, 320, 0, 160),
			Position = UDim2.new(0, 16, 1, -230),
		}):Play()
		textBox:CaptureFocus()
	end
end)

-- ── Redeem Logic ─────────────────────────────────────────────────────────────
local function doRedeem()
	local code = textBox.Text
	if code == "" then return end
	redeemBtn.Text   = "⏳"
	redeemBtn.Active = false
	RedeemCode:FireServer(code)
end

redeemBtn.MouseButton1Click:Connect(doRedeem)

textBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then doRedeem() end
end)

-- ── Toast Notification ────────────────────────────────────────────────────────
local toast = Instance.new("Frame")
toast.Name                   = "Toast"
toast.Size                   = UDim2.new(0, 280, 0, 52)
toast.Position               = UDim2.new(0.5, -140, 0, -60)   -- starts hidden above screen
toast.BackgroundColor3       = Color3.fromRGB(20, 20, 30)
toast.BackgroundTransparency = 0.1
toast.BorderSizePixel        = 0
toast.ZIndex                 = 30
toast.Parent                 = screenGui
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 14)

local toastLabel = Instance.new("TextLabel")
toastLabel.Size                  = UDim2.new(1, -16, 1, 0)
toastLabel.Position              = UDim2.new(0, 8, 0, 0)
toastLabel.BackgroundTransparency = 1
toastLabel.Text                  = ""
toastLabel.TextColor3            = Color3.fromRGB(255, 255, 255)
toastLabel.TextScaled            = true
toastLabel.Font                  = Enum.Font.GothamBold
toastLabel.ZIndex                = 31
toastLabel.Parent                = toast

local toastStroke = Instance.new("UIStroke")
toastStroke.Thickness = 1.5
toastStroke.Parent    = toast

local toastVisible = false

local function showToast(success, message)
	if toastVisible then return end
	toastVisible       = true
	toastLabel.Text    = message
	toastStroke.Color  = success and Color3.fromRGB(60, 220, 100) or Color3.fromRGB(220, 60, 60)

	-- Slide in from top
	TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -140, 0, 14)
	}):Play()

	task.wait(3)

	-- Slide out
	TweenService:Create(toast, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -140, 0, -60)
	}):Play()
	task.wait(0.2)
	toastVisible = false
end

-- ── CodeResult ───────────────────────────────────────────────────────────────
CodeResult.OnClientEvent:Connect(function(success, message)
	redeemBtn.Text   = "Canjear"
	redeemBtn.Active = true

	if success then
		textBox.Text   = ""
		inputPanel.Visible = false
		panelOpen = false
	end

	task.spawn(showToast, success, message)
end)
