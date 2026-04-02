-- LeaderboardUI (LocalScript)
-- StarterPlayerScripts/LeaderboardUI
-- 🏆 Two-tab leaderboard: 🌍 Global (OrderedDataStore) + 🏠 Servidor local.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local GetGlobalLB  = RemoteEvents:WaitForChild("GetGlobalLB")

-- ─── ScreenGui ────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "LeaderboardUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

-- ─── Toggle button (top-left) ─────────────────────────────────────────────────
local lbBtn = Instance.new("TextButton")
lbBtn.Name             = "LeaderboardBtn"
lbBtn.Size             = UDim2.new(0, 56, 0, 48)
lbBtn.Position         = UDim2.new(0, 16, 0, 74)
lbBtn.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
lbBtn.BorderSizePixel  = 0
lbBtn.Text             = "🏆"
lbBtn.TextScaled       = true
lbBtn.Font             = Enum.Font.GothamBold
lbBtn.AutoButtonColor  = false
lbBtn.Parent           = screenGui
Instance.new("UICorner", lbBtn).CornerRadius = UDim.new(0, 14)

local lbStroke = Instance.new("UIStroke")
lbStroke.Color     = Color3.fromRGB(255, 200, 30)
lbStroke.Thickness = 1.5
lbStroke.Parent    = lbBtn

lbBtn.MouseEnter:Connect(function()
	TweenService:Create(lbBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50, 40, 90)}):Play()
end)
lbBtn.MouseLeave:Connect(function()
	TweenService:Create(lbBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(25, 20, 45)}):Play()
end)

-- ─── Panel ────────────────────────────────────────────────────────────────────
local PANEL_W, PANEL_H = 290, 420

local panel = Instance.new("Frame")
panel.Size                   = UDim2.new(0, PANEL_W, 0, PANEL_H)
panel.Position               = UDim2.new(0, 16, 0, 130)
panel.BackgroundColor3       = Color3.fromRGB(10, 8, 22)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel        = 0
panel.Visible                = false
panel.ZIndex                 = 15
panel.Parent                 = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color     = Color3.fromRGB(255, 200, 30)
panelStroke.Thickness = 1.5
panelStroke.Parent    = panel

-- ─── Tabs ─────────────────────────────────────────────────────────────────────
local tabBar = Instance.new("Frame")
tabBar.Size             = UDim2.new(1, 0, 0, 44)
tabBar.BackgroundTransparency = 1
tabBar.ZIndex           = 16
tabBar.Parent           = panel

local tabGlobal = Instance.new("TextButton")
tabGlobal.Size             = UDim2.new(0.5, -2, 1, -6)
tabGlobal.Position         = UDim2.new(0, 6, 0, 4)
tabGlobal.BackgroundColor3 = Color3.fromRGB(255, 200, 30)
tabGlobal.BorderSizePixel  = 0
tabGlobal.Text             = "🌍 Global"
tabGlobal.TextColor3       = Color3.fromRGB(20, 16, 0)
tabGlobal.TextScaled       = true
tabGlobal.Font             = Enum.Font.GothamBold
tabGlobal.AutoButtonColor  = false
tabGlobal.ZIndex           = 17
tabGlobal.Parent           = tabBar
Instance.new("UICorner", tabGlobal).CornerRadius = UDim.new(0, 10)

local tabServer = Instance.new("TextButton")
tabServer.Size             = UDim2.new(0.5, -2, 1, -6)
tabServer.Position         = UDim2.new(0.5, -4, 0, 4)
tabServer.BackgroundColor3 = Color3.fromRGB(30, 26, 60)
tabServer.BorderSizePixel  = 0
tabServer.Text             = "🏠 Servidor"
tabServer.TextColor3       = Color3.fromRGB(180, 170, 220)
tabServer.TextScaled       = true
tabServer.Font             = Enum.Font.GothamBold
tabServer.AutoButtonColor  = false
tabServer.ZIndex           = 17
tabServer.Parent           = tabBar
Instance.new("UICorner", tabServer).CornerRadius = UDim.new(0, 10)

-- Divider
local divider = Instance.new("Frame")
divider.Size             = UDim2.new(1, -16, 0, 1)
divider.Position         = UDim2.new(0, 8, 0, 48)
divider.BackgroundColor3 = Color3.fromRGB(180, 145, 20)
divider.BorderSizePixel  = 0
divider.ZIndex           = 16
divider.Parent           = panel

-- ─── Row Container ────────────────────────────────────────────────────────────
local rowContainer = Instance.new("Frame")
rowContainer.Size                   = UDim2.new(1, -12, 1, -62)
rowContainer.Position               = UDim2.new(0, 6, 0, 56)
rowContainer.BackgroundTransparency = 1
rowContainer.ZIndex                 = 16
rowContainer.Parent                 = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding   = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent    = rowContainer

local RANK_COLORS = {
	[1] = Color3.fromRGB(255, 210, 40),
	[2] = Color3.fromRGB(200, 200, 200),
	[3] = Color3.fromRGB(205, 127, 50),
}

local rows = {}
for i = 1, 10 do
	local row = Instance.new("Frame")
	row.Name             = "Row" .. i
	row.Size             = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = Color3.fromRGB(20, 16, 40)
	row.BorderSizePixel  = 0
	row.LayoutOrder      = i
	row.ZIndex           = 17
	row.Visible          = false
	row.Parent           = rowContainer
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local rankLbl = Instance.new("TextLabel")
	rankLbl.Name                   = "Rank"
	rankLbl.Size                   = UDim2.new(0, 28, 1, 0)
	rankLbl.Position               = UDim2.new(0, 4, 0, 0)
	rankLbl.BackgroundTransparency = 1
	rankLbl.Text                   = "#" .. i
	rankLbl.TextScaled             = true
	rankLbl.Font                   = Enum.Font.GothamBold
	rankLbl.TextColor3             = RANK_COLORS[i] or Color3.fromRGB(160, 150, 200)
	rankLbl.ZIndex                 = 18
	rankLbl.Parent                 = row

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name                   = "PlayerName"
	nameLbl.Size                   = UDim2.new(0.55, -36, 1, 0)
	nameLbl.Position               = UDim2.new(0, 36, 0, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextScaled             = true
	nameLbl.Font                   = Enum.Font.Gotham
	nameLbl.TextColor3             = Color3.fromRGB(220, 215, 240)
	nameLbl.TextXAlignment         = Enum.TextXAlignment.Left
	nameLbl.ZIndex                 = 18
	nameLbl.Parent                 = row

	local scoreLbl = Instance.new("TextLabel")
	scoreLbl.Name                   = "Score"
	scoreLbl.Size                   = UDim2.new(0.42, 0, 1, 0)
	scoreLbl.Position               = UDim2.new(0.58, 0, 0, 0)
	scoreLbl.BackgroundTransparency = 1
	scoreLbl.TextScaled             = true
	scoreLbl.Font                   = Enum.Font.GothamBold
	scoreLbl.TextColor3             = Color3.fromRGB(100, 230, 120)
	scoreLbl.TextXAlignment         = Enum.TextXAlignment.Right
	scoreLbl.ZIndex                 = 18
	scoreLbl.Parent                 = row

	rows[i] = row
end

-- ─── Formatters ───────────────────────────────────────────────────────────────
local function fmt(n)
	if n >= 1e12 then return ("%.1fT"):format(n/1e12)
	elseif n >= 1e9  then return ("%.1fB"):format(n/1e9)
	elseif n >= 1e6  then return ("%.1fM"):format(n/1e6)
	elseif n >= 1e3  then return ("%.1fK"):format(n/1e3)
	else return tostring(math.floor(n)) end
end

-- ─── Populate rows ────────────────────────────────────────────────────────────
local function populateRows(entries, isGlobal)
	for i, row in ipairs(rows) do
		local e = entries[i]
		if e then
			row.Visible = true
			row.PlayerName.Text = e.name
			row.Score.Text      = "$" .. fmt(isGlobal and e.score or e.cash)

			local isMe = (e.name == player.Name)
			row.BackgroundColor3 = isMe and Color3.fromRGB(50, 38, 10) or Color3.fromRGB(20, 16, 40)
			row.PlayerName.TextColor3 = isMe and Color3.fromRGB(255, 220, 60) or Color3.fromRGB(220, 215, 240)
		else
			row.Visible = false
		end
	end
end

-- ─── Tab Logic ────────────────────────────────────────────────────────────────
local currentTab = "server"
local globalCache = {}

local function refreshServer()
	local entries = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local ls = p:FindFirstChild("leaderstats")
		local cv = ls and ls:FindFirstChild("Cash")
		table.insert(entries, { name = p.Name, cash = cv and cv.Value or 0 })
	end
	table.sort(entries, function(a, b) return a.cash > b.cash end)
	populateRows(entries, false)
end

local function setTab(tab)
	currentTab = tab
	if tab == "global" then
		tabGlobal.BackgroundColor3 = Color3.fromRGB(255, 200, 30)
		tabGlobal.TextColor3       = Color3.fromRGB(20, 16, 0)
		tabServer.BackgroundColor3 = Color3.fromRGB(30, 26, 60)
		tabServer.TextColor3       = Color3.fromRGB(180, 170, 220)
		GetGlobalLB:FireServer()
	else
		tabServer.BackgroundColor3 = Color3.fromRGB(255, 200, 30)
		tabServer.TextColor3       = Color3.fromRGB(20, 16, 0)
		tabGlobal.BackgroundColor3 = Color3.fromRGB(30, 26, 60)
		tabGlobal.TextColor3       = Color3.fromRGB(180, 170, 220)
		refreshServer()
	end
end

tabGlobal.MouseButton1Click:Connect(function() setTab("global") end)
tabServer.MouseButton1Click:Connect(function() setTab("server") end)

GetGlobalLB.OnClientEvent:Connect(function(entries)
	globalCache = entries or {}
	if currentTab == "global" then
		populateRows(globalCache, true)
	end
end)

-- ─── Toggle & auto-refresh ────────────────────────────────────────────────────
local panelOpen = false

lbBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	if panelOpen then
		panel.Visible = true
		panel.Size = UDim2.new(0, PANEL_W, 0, 0)
		setTab("server")
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

task.spawn(function()
	while true do
		task.wait(30)
		if panelOpen then
			if currentTab == "server" then refreshServer()
			else GetGlobalLB:FireServer() end
		end
	end
end)
