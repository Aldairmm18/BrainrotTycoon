-- MissionsUI (LocalScript)
-- StarterPlayerScripts/MissionsUI
-- 📋 Missions panel with progress bars and claim button.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local SoundService      = game:GetService("SoundService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local GetMissions   = RemoteEvents:WaitForChild("GetMissions")
local MissionUpdate = RemoteEvents:WaitForChild("MissionUpdate")
local ClaimMission  = RemoteEvents:WaitForChild("ClaimMission")

-- ─── ScreenGui ────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "MissionsUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

-- ─── 📋 Toggle Button ────────────────────────────────────────────────────────
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name             = "MissionsToggle"
toggleBtn.Size             = UDim2.new(0, 130, 0, 50)
toggleBtn.Position         = UDim2.new(0.5, -65, 0, 12)  -- centre top (shares row with cash but slightly left)
toggleBtn.AnchorPoint      = Vector2.new(0.5, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 18, 55)
toggleBtn.BorderSizePixel  = 0
toggleBtn.Text             = "📋 Misiones"
toggleBtn.TextColor3       = Color3.fromRGB(200, 185, 255)
toggleBtn.TextScaled       = true
toggleBtn.Font             = Enum.Font.GothamBold
toggleBtn.AutoButtonColor  = false
-- Push to right of cash frame at centre top
toggleBtn.Position         = UDim2.new(0.5, 110, 0, 14)
toggleBtn.Parent           = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 14)

local tgStroke = Instance.new("UIStroke")
tgStroke.Color     = Color3.fromRGB(130, 80, 255)
tgStroke.Thickness = 1.5
tgStroke.Parent    = toggleBtn

toggleBtn.MouseEnter:Connect(function()
	TweenService:Create(toggleBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(45, 32, 90)}):Play()
end)
toggleBtn.MouseLeave:Connect(function()
	TweenService:Create(toggleBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(25, 18, 55)}):Play()
end)

-- ─── Panel ────────────────────────────────────────────────────────────────────
local PANEL_W, PANEL_H = 360, 420

local panel = Instance.new("Frame")
panel.Name                   = "MissionsPanel"
panel.Size                   = UDim2.new(0, PANEL_W, 0, PANEL_H)
panel.Position               = UDim2.new(0.5, -PANEL_W/2, 0, 72)
panel.BackgroundColor3       = Color3.fromRGB(10, 7, 25)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel        = 0
panel.Visible                = false
panel.ZIndex                 = 20
panel.Parent                 = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color     = Color3.fromRGB(130, 80, 255)
panelStroke.Thickness = 2
panelStroke.Parent    = panel

local titleLbl = Instance.new("TextLabel")
titleLbl.Size                  = UDim2.new(1, -16, 0, 44)
titleLbl.Position              = UDim2.new(0, 8, 0, 6)
titleLbl.BackgroundTransparency = 1
titleLbl.Text                  = "📋  Misiones Diarias"
titleLbl.TextColor3            = Color3.fromRGB(200, 185, 255)
titleLbl.TextScaled            = true
titleLbl.Font                  = Enum.Font.GothamBold
titleLbl.ZIndex                = 21
titleLbl.Parent                = panel

local divider = Instance.new("Frame")
divider.Size             = UDim2.new(1, -16, 0, 1)
divider.Position         = UDim2.new(0, 8, 0, 54)
divider.BackgroundColor3 = Color3.fromRGB(100, 60, 200)
divider.BorderSizePixel  = 0
divider.ZIndex           = 21
divider.Parent           = panel

-- ─── Mission Card Builder ─────────────────────────────────────────────────────
local missionCards = {}

local function formatNum(n)
	if n >= 1e6 then return ("%.1fM"):format(n/1e6)
	elseif n >= 1e3 then return ("%.1fK"):format(n/1e3)
	else return tostring(math.floor(n)) end
end

local function buildCards()
	for _, c in ipairs(missionCards) do c:Destroy() end
	missionCards = {}

	for i = 1, 3 do
		local y = 62 + (i - 1) * 114

		local card = Instance.new("Frame")
		card.Name             = "MissionCard" .. i
		card.Size             = UDim2.new(1, -20, 0, 106)
		card.Position         = UDim2.new(0, 10, 0, y)
		card.BackgroundColor3 = Color3.fromRGB(20, 14, 48)
		card.BorderSizePixel  = 0
		card.ZIndex           = 22
		card.Parent           = panel
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

		local descLbl = Instance.new("TextLabel")
		descLbl.Name                   = "Desc"
		descLbl.Size                   = UDim2.new(1, -110, 0, 30)
		descLbl.Position               = UDim2.new(0, 10, 0, 8)
		descLbl.BackgroundTransparency = 1
		descLbl.Text                   = "..."
		descLbl.TextColor3             = Color3.fromRGB(220, 215, 255)
		descLbl.TextScaled             = true
		descLbl.Font                   = Enum.Font.GothamBold
		descLbl.TextXAlignment         = Enum.TextXAlignment.Left
		descLbl.ZIndex                 = 23
		descLbl.Parent                 = card

		local rewardLbl = Instance.new("TextLabel")
		rewardLbl.Name                   = "Reward"
		rewardLbl.Size                   = UDim2.new(0, 90, 0, 28)
		rewardLbl.Position               = UDim2.new(1, -100, 0, 10)
		rewardLbl.BackgroundTransparency = 1
		rewardLbl.Text                   = "$0"
		rewardLbl.TextColor3             = Color3.fromRGB(100, 240, 130)
		rewardLbl.TextScaled             = true
		rewardLbl.Font                   = Enum.Font.GothamBold
		rewardLbl.TextXAlignment         = Enum.TextXAlignment.Right
		rewardLbl.ZIndex                 = 23
		rewardLbl.Parent                 = card

		-- Progress bar track
		local track = Instance.new("Frame")
		track.Name             = "Track"
		track.Size             = UDim2.new(1, -110, 0, 14)
		track.Position         = UDim2.new(0, 10, 0, 44)
		track.BackgroundColor3 = Color3.fromRGB(35, 28, 70)
		track.BorderSizePixel  = 0
		track.ZIndex           = 23
		track.Parent           = card
		Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

		local fill = Instance.new("Frame")
		fill.Name             = "Fill"
		fill.Size             = UDim2.new(0, 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
		fill.BorderSizePixel  = 0
		fill.ZIndex           = 24
		fill.Parent           = track
		Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

		local progressLbl = Instance.new("TextLabel")
		progressLbl.Name                   = "Progress"
		progressLbl.Size                   = UDim2.new(1, -110, 0, 22)
		progressLbl.Position               = UDim2.new(0, 10, 0, 62)
		progressLbl.BackgroundTransparency = 1
		progressLbl.Text                   = "0 / 0"
		progressLbl.TextColor3             = Color3.fromRGB(160, 150, 200)
		progressLbl.TextScaled             = true
		progressLbl.Font                   = Enum.Font.Gotham
		progressLbl.TextXAlignment         = Enum.TextXAlignment.Left
		progressLbl.ZIndex                 = 23
		progressLbl.Parent                 = card

		local claimBtn = Instance.new("TextButton")
		claimBtn.Name             = "ClaimBtn"
		claimBtn.Size             = UDim2.new(0, 90, 0, 76)
		claimBtn.Position         = UDim2.new(1, -100, 0, 8)
		claimBtn.BackgroundColor3 = Color3.fromRGB(50, 45, 90)
		claimBtn.BorderSizePixel  = 0
		claimBtn.Text             = "🔒"
		claimBtn.TextColor3       = Color3.fromRGB(150, 140, 200)
		claimBtn.TextScaled       = true
		claimBtn.Font             = Enum.Font.GothamBold
		claimBtn.AutoButtonColor  = false
		claimBtn.ZIndex           = 24
		claimBtn.Parent           = card
		Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 10)

		table.insert(missionCards, card)
	end
end

buildCards()

-- ─── Confetti burst ───────────────────────────────────────────────────────────
local function confetti()
	local colors = {
		Color3.fromRGB(255, 80, 80),
		Color3.fromRGB(80, 200, 255),
		Color3.fromRGB(255, 220, 40),
		Color3.fromRGB(120, 255, 100),
		Color3.fromRGB(200, 80, 255),
	}
	for _ = 1, 30 do
		local piece = Instance.new("Frame")
		piece.Size             = UDim2.new(0, math.random(8, 16), 0, math.random(8, 16))
		piece.Position         = UDim2.new(math.random(20, 80)/100, 0, 0.4, 0)
		piece.BackgroundColor3 = colors[math.random(1, #colors)]
		piece.BorderSizePixel  = 0
		piece.ZIndex           = 60
		piece.Rotation         = math.random(0, 360)
		piece.Parent           = screenGui
		Instance.new("UICorner", piece).CornerRadius = UDim.new(0, 3)

		TweenService:Create(piece, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(piece.Position.X.Scale, 0, 1.1, 0),
			Rotation = piece.Rotation + math.random(-180, 180),
			BackgroundTransparency = 1,
		}):Play()
		game:GetService("Debris"):AddItem(piece, 1.6)

		task.wait(0.02)
	end
end

-- ─── Update Cards ─────────────────────────────────────────────────────────────
local _currentMissions = {}

local function updateCards(missions)
	_currentMissions = missions or {}
	for i, card in ipairs(missionCards) do
		local m = missions and missions[i]
		if not m then continue end

		card.Desc.Text    = m.desc
		card.Reward.Text  = "+$" .. formatNum(m.reward)
		card.Progress.Text = formatNum(m.progress) .. " / " .. formatNum(m.goal)

		local pct = math.clamp(m.progress / m.goal, 0, 1)
		TweenService:Create(card.Track.Fill, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
			Size = UDim2.new(pct, 0, 1, 0),
		}):Play()

		local btn = card.ClaimBtn
		if m.claimed then
			btn.Text             = "✅"
			btn.BackgroundColor3 = Color3.fromRGB(30, 80, 40)
			btn.Active           = false
		elseif m.progress >= m.goal then
			btn.Text             = "Reclamar"
			btn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
			btn.TextColor3       = Color3.fromRGB(10, 40, 10)
			btn.Active           = true

			-- Wire claim once
			if not btn:GetAttribute("Wired") then
				btn:SetAttribute("Wired", true)
				btn.MouseButton1Click:Connect(function()
					ClaimMission:FireServer(m.id)
					task.spawn(confetti)
					-- Optimistic UI
					btn.Text   = "⏳"
					btn.Active = false
				end)
			end
		else
			btn.Text             = "🔒"
			btn.BackgroundColor3 = Color3.fromRGB(50, 45, 90)
			btn.TextColor3       = Color3.fromRGB(150, 140, 200)
			btn.Active           = false
		end
	end
end

MissionUpdate.OnClientEvent:Connect(updateCards)

-- ─── Toggle ───────────────────────────────────────────────────────────────────
local panelOpen = false

toggleBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	if panelOpen then
		panel.Visible = true
		panel.Size = UDim2.new(0, PANEL_W, 0, 0)
		GetMissions:FireServer()
		TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
		}):Play()
	else
		TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, PANEL_W, 0, 0)
		}):Play()
		task.delay(0.2, function() panel.Visible = false end)
	end
end)
