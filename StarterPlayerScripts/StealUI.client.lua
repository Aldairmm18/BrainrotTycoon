-- StealUI (LocalScript)
-- StarterPlayerScripts/StealUI
-- Client-side UI for the player-vs-player steal mechanic.
-- The server decides every steal outcome — this script only displays results.

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RE          = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local StealAttempt = RE:WaitForChild("StealAttempt")
local StealResult  = RE:WaitForChild("StealResult")

-- ─── ScreenGui ────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name           = "StealUI"
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = playerGui

-- ─── Main "🗡️ Robar" Button ──────────────────────────────────────────────────
local stealBtn = Instance.new("TextButton")
stealBtn.Name            = "StealButton"
stealBtn.Size            = UDim2.new(0, 120, 0, 48)
stealBtn.Position        = UDim2.new(0, 10, 0.5, -24)
stealBtn.BackgroundColor3= Color3.fromRGB(160, 20, 20)
stealBtn.BorderSizePixel = 0
stealBtn.Text            = "🗡️ Robar"
stealBtn.TextColor3      = Color3.fromRGB(255, 220, 220)
stealBtn.TextScaled      = true
stealBtn.Font            = Enum.Font.GothamBold
stealBtn.AutoButtonColor = false
stealBtn.Parent          = gui
Instance.new("UICorner", stealBtn).CornerRadius = UDim.new(0, 14)

local btnStroke = Instance.new("UIStroke")
btnStroke.Color     = Color3.fromRGB(255, 80, 80)
btnStroke.Thickness = 2
btnStroke.Parent    = stealBtn

-- Hover glow
stealBtn.MouseEnter:Connect(function()
	TweenService:Create(stealBtn, TweenInfo.new(0.12), {
		BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	}):Play()
end)
stealBtn.MouseLeave:Connect(function()
	TweenService:Create(stealBtn, TweenInfo.new(0.12), {
		BackgroundColor3 = Color3.fromRGB(160, 20, 20)
	}):Play()
end)

-- ─── Victim-selection Panel ───────────────────────────────────────────────────
local panel = Instance.new("Frame")
panel.Name                   = "StealPanel"
panel.Size                   = UDim2.new(0, 270, 0, 320)
panel.Position               = UDim2.new(0, 140, 0.5, -160)
panel.BackgroundColor3       = Color3.fromRGB(16, 8, 8)
panel.BackgroundTransparency = 0.06
panel.BorderSizePixel        = 0
panel.Visible                = false
panel.ZIndex                 = 20
panel.Parent                 = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color     = Color3.fromRGB(200, 40, 40)
panelStroke.Thickness = 2
panelStroke.Parent    = panel

-- Panel title
local panelTitle = Instance.new("TextLabel")
panelTitle.Size                   = UDim2.new(1, -50, 0, 42)
panelTitle.Position               = UDim2.new(0, 10, 0, 6)
panelTitle.BackgroundTransparency = 1
panelTitle.Text                   = "🗡️ Elige a tu víctima"
panelTitle.TextColor3             = Color3.fromRGB(255, 80, 80)
panelTitle.TextScaled             = true
panelTitle.Font                   = Enum.Font.GothamBold
panelTitle.TextXAlignment         = Enum.TextXAlignment.Left
panelTitle.ZIndex                 = 21
panelTitle.Parent                 = panel

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size                   = UDim2.new(0, 32, 0, 32)
closeBtn.Position               = UDim2.new(1, -38, 0, 6)
closeBtn.BackgroundTransparency = 1
closeBtn.Text                   = "✕"
closeBtn.TextColor3             = Color3.fromRGB(200, 150, 150)
closeBtn.TextScaled             = true
closeBtn.Font                   = Enum.Font.GothamBold
closeBtn.ZIndex                 = 21
closeBtn.Parent                 = panel

-- Divider
local divider = Instance.new("Frame")
divider.Size             = UDim2.new(1, -20, 0, 1)
divider.Position         = UDim2.new(0, 10, 0, 52)
divider.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
divider.BackgroundTransparency = 0.5
divider.BorderSizePixel  = 0
divider.ZIndex           = 21
divider.Parent           = panel

-- Player list scroll
local playerList = Instance.new("ScrollingFrame")
playerList.Name                 = "PlayerList"
playerList.Size                 = UDim2.new(1, -16, 1, -62)
playerList.Position             = UDim2.new(0, 8, 0, 58)
playerList.BackgroundTransparency = 1
playerList.BorderSizePixel      = 0
playerList.ScrollBarThickness   = 4
playerList.ScrollBarImageColor3 = Color3.fromRGB(200, 40, 40)
playerList.ZIndex               = 21
playerList.Parent               = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding   = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent    = playerList

local listPad = Instance.new("UIPadding")
listPad.PaddingTop   = UDim.new(0, 4)
listPad.PaddingLeft  = UDim.new(0, 2)
listPad.PaddingRight = UDim.new(0, 2)
listPad.Parent       = playerList

-- Empty-state label
local emptyLabel = Instance.new("TextLabel")
emptyLabel.Name                   = "EmptyLabel"
emptyLabel.Size                   = UDim2.new(1, 0, 0, 44)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Text                   = "No hay otros jugadores"
emptyLabel.TextColor3             = Color3.fromRGB(150, 100, 100)
emptyLabel.TextScaled             = true
emptyLabel.Font                   = Enum.Font.Gotham
emptyLabel.ZIndex                 = 22
emptyLabel.Visible                = false
emptyLabel.Parent                 = playerList

-- ─── Result toast ─────────────────────────────────────────────────────────────
local toastFrame = Instance.new("Frame")
toastFrame.Name                   = "StealToast"
toastFrame.Size                   = UDim2.new(0, 320, 0, 110)
toastFrame.Position               = UDim2.new(0.5, -160, 0.5, -55)
toastFrame.BackgroundColor3       = Color3.fromRGB(16, 8, 8)
toastFrame.BackgroundTransparency = 0.10
toastFrame.BorderSizePixel        = 0
toastFrame.Visible                = false
toastFrame.ZIndex                 = 40
toastFrame.Parent                 = gui
Instance.new("UICorner", toastFrame).CornerRadius = UDim.new(0, 18)

local toastStroke = Instance.new("UIStroke")
toastStroke.Color     = Color3.fromRGB(255, 80, 80)
toastStroke.Thickness = 2
toastStroke.Parent    = toastFrame

local toastLabel = Instance.new("TextLabel")
toastLabel.Size                   = UDim2.new(1, -20, 1, -16)
toastLabel.Position               = UDim2.new(0, 10, 0, 8)
toastLabel.BackgroundTransparency = 1
toastLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
toastLabel.TextScaled             = true
toastLabel.Font                   = Enum.Font.GothamBold
toastLabel.TextWrapped            = true
toastLabel.ZIndex                 = 41
toastLabel.Parent                 = toastFrame

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local cooldownActive = false

local function showToast(success, message)
	toastLabel.Text      = (success and "✅ " or "❌ ") .. (message or "")
	toastLabel.TextColor3= success
		and Color3.fromRGB(100, 255, 130)
		or  Color3.fromRGB(255, 100, 100)
	toastStroke.Color    = success
		and Color3.fromRGB(60, 220, 100)
		or  Color3.fromRGB(255, 60, 60)

	-- Pop-in
	toastFrame.Size     = UDim2.new(0, 0, 0, 0)
	toastFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	toastFrame.Visible  = true
	TweenService:Create(toastFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 320, 0, 110), Position = UDim2.new(0.5, -160, 0.5, -55) }
	):Play()

	task.delay(3.5, function()
		TweenService:Create(toastFrame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }
		):Play()
		task.wait(0.25)
		toastFrame.Visible = false
	end)
end

local function refreshPlayerList()
	-- Clear existing player buttons
	for _, child in ipairs(playerList:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	local otherPlayers = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			table.insert(otherPlayers, p)
		end
	end

	emptyLabel.Visible = (#otherPlayers == 0)

	for i, p in ipairs(otherPlayers) do
		local btn = Instance.new("TextButton")
		btn.Name             = "Target_" .. p.Name
		btn.Size             = UDim2.new(1, 0, 0, 46)
		btn.BackgroundColor3 = Color3.fromRGB(50, 16, 16)
		btn.BorderSizePixel  = 0
		btn.Text             = "🗡️  " .. p.Name
		btn.TextColor3       = Color3.fromRGB(255, 200, 200)
		btn.TextScaled       = true
		btn.Font             = Enum.Font.Gotham
		btn.LayoutOrder      = i
		btn.ZIndex           = 22
		btn.Parent           = playerList
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

		-- Hover
		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.1), {
				BackgroundColor3 = Color3.fromRGB(90, 24, 24)
			}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.1), {
				BackgroundColor3 = Color3.fromRGB(50, 16, 16)
			}):Play()
		end)

		local targetName = p.Name
		btn.MouseButton1Click:Connect(function()
			if cooldownActive then return end
			panel.Visible = false

			-- Fire to server (server decides the result)
			StealAttempt:FireServer(targetName)

			-- Visual cooldown on button (30 s to match server STEAL_COOLDOWN)
			cooldownActive         = true
			stealBtn.Text          = "⏳ 30s"
			stealBtn.Active        = false

			local countdown = 30
			task.spawn(function()
				while countdown > 0 do
					task.wait(1)
					countdown = countdown - 1
					stealBtn.Text = "⏳ " .. countdown .. "s"
				end
				stealBtn.Text   = "🗡️ Robar"
				stealBtn.Active = true
				cooldownActive  = false
			end)
		end)
	end

	-- Update scroll canvas height
	playerList.CanvasSize = UDim2.new(0, 0, 0,
		math.max(0, #otherPlayers) * 52 + 8)
end

local panelOpen = false

local function togglePanel()
	panelOpen = not panelOpen
	if panelOpen then
		refreshPlayerList()
		panel.Visible = true
		panel.Size    = UDim2.new(0, 270, 0, 0)
		TweenService:Create(panel,
			TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = UDim2.new(0, 270, 0, 320) }
		):Play()
	else
		TweenService:Create(panel,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Size = UDim2.new(0, 270, 0, 0) }
		):Play()
		task.delay(0.2, function()
			panel.Visible = false
		end)
	end
end

-- ─── Wire up controls ─────────────────────────────────────────────────────────
stealBtn.MouseButton1Click:Connect(togglePanel)
closeBtn.MouseButton1Click:Connect(function()
	if panelOpen then togglePanel() end
end)

-- ─── Receive result from server ───────────────────────────────────────────────
StealResult.OnClientEvent:Connect(function(success, message, _stolen)
	if message then
		showToast(success == true, message)
	end
end)
