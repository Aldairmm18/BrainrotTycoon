-- LeaderboardUI (LocalScript)
-- StarterPlayerScripts/LeaderboardUI
-- 🏆 button (top-left, below cash pill) showing top-10 players by Cash.

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─── ScreenGui ────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "LeaderboardUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

-- ─── 🏆 Toggle Button ────────────────────────────────────────────────────────
local lbBtn = Instance.new("TextButton")
lbBtn.Name             = "LeaderboardBtn"
lbBtn.Size             = UDim2.new(0, 56, 0, 48)
lbBtn.Position         = UDim2.new(0, 16, 0, 74)  -- below cash pill at top-left
lbBtn.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
lbBtn.BorderSizePixel  = 0
lbBtn.Text             = "🏆"
lbBtn.TextScaled       = true
lbBtn.Font             = Enum.Font.GothamBold
lbBtn.AutoButtonColor  = false
lbBtn.Parent           = screenGui
Instance.new("UICorner", lbBtn).CornerRadius = UDim.new(0, 14)

local lbBtnStroke = Instance.new("UIStroke")
lbBtnStroke.Color     = Color3.fromRGB(255, 200, 30)
lbBtnStroke.Thickness = 1.5
lbBtnStroke.Parent    = lbBtn

lbBtn.MouseEnter:Connect(function()
	TweenService:Create(lbBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50, 40, 90)}):Play()
end)
lbBtn.MouseLeave:Connect(function()
	TweenService:Create(lbBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(25, 20, 45)}):Play()
end)

-- ─── Leaderboard Panel ────────────────────────────────────────────────────────
local PANEL_W, PANEL_H = 280, 380

local panel = Instance.new("Frame")
panel.Name                   = "LeaderboardPanel"
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

-- Title
local titleLbl = Instance.new("TextLabel")
titleLbl.Size                  = UDim2.new(1, -10, 0, 40)
titleLbl.Position              = UDim2.new(0, 5, 0, 4)
titleLbl.BackgroundTransparency = 1
titleLbl.Text                  = "🏆  Leaderboard"
titleLbl.TextColor3            = Color3.fromRGB(255, 215, 50)
titleLbl.TextScaled            = true
titleLbl.Font                  = Enum.Font.GothamBold
titleLbl.ZIndex                = 16
titleLbl.Parent                = panel

local divider = Instance.new("Frame")
divider.Size             = UDim2.new(1, -16, 0, 1)
divider.Position         = UDim2.new(0, 8, 0, 48)
divider.BackgroundColor3 = Color3.fromRGB(180, 145, 20)
divider.BorderSizePixel  = 0
divider.ZIndex           = 16
divider.Parent           = panel

-- Row container
local rowContainer = Instance.new("Frame")
rowContainer.Size                   = UDim2.new(1, -12, 1, -58)
rowContainer.Position               = UDim2.new(0, 6, 0, 54)
rowContainer.BackgroundTransparency = 1
rowContainer.ZIndex                 = 16
rowContainer.Parent                 = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding   = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent    = rowContainer

-- Reusable row pool (10 rows)
local rows = {}
local RANK_COLORS = {
	[1] = Color3.fromRGB(255, 210, 40),   -- gold
	[2] = Color3.fromRGB(200, 200, 200),  -- silver
	[3] = Color3.fromRGB(205, 127, 50),   -- bronze
}

local function makeRow(index)
	local row = Instance.new("Frame")
	row.Name             = "Row" .. index
	row.Size             = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = Color3.fromRGB(20, 16, 40)
	row.BorderSizePixel  = 0
	row.LayoutOrder      = index
	row.ZIndex           = 17
	row.Visible          = false
	row.Parent           = rowContainer
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local rankLbl = Instance.new("TextLabel")
	rankLbl.Name                   = "Rank"
	rankLbl.Size                   = UDim2.new(0, 28, 1, 0)
	rankLbl.Position               = UDim2.new(0, 4, 0, 0)
	rankLbl.BackgroundTransparency = 1
	rankLbl.Text                   = "#" .. index
	rankLbl.TextScaled             = true
	rankLbl.Font                   = Enum.Font.GothamBold
	rankLbl.TextColor3             = RANK_COLORS[index] or Color3.fromRGB(160, 150, 200)
	rankLbl.ZIndex                 = 18
	rankLbl.Parent                 = row

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name                   = "PlayerName"
	nameLbl.Size                   = UDim2.new(0.55, -36, 1, 0)
	nameLbl.Position               = UDim2.new(0, 36, 0, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text                   = ""
	nameLbl.TextScaled             = true
	nameLbl.Font                   = Enum.Font.Gotham
	nameLbl.TextColor3             = Color3.fromRGB(220, 215, 240)
	nameLbl.TextXAlignment         = Enum.TextXAlignment.Left
	nameLbl.ZIndex                 = 18
	nameLbl.Parent                 = row

	local cashLbl = Instance.new("TextLabel")
	cashLbl.Name                   = "Cash"
	cashLbl.Size                   = UDim2.new(0.42, 0, 1, 0)
	cashLbl.Position               = UDim2.new(0.58, 0, 0, 0)
	cashLbl.BackgroundTransparency = 1
	cashLbl.Text                   = "$0"
	cashLbl.TextScaled             = true
	cashLbl.Font                   = Enum.Font.GothamBold
	cashLbl.TextColor3             = Color3.fromRGB(100, 230, 120)
	cashLbl.TextXAlignment         = Enum.TextXAlignment.Right
	cashLbl.ZIndex                 = 18
	cashLbl.Parent                 = row

	return row
end

for i = 1, 10 do
	rows[i] = makeRow(i)
end

-- ─── Number formatter ─────────────────────────────────────────────────────────
local function fmt(n)
	if n >= 1e12 then return ("%.1fT"):format(n/1e12)
	elseif n >= 1e9  then return ("%.1fB"):format(n/1e9)
	elseif n >= 1e6  then return ("%.1fM"):format(n/1e6)
	elseif n >= 1e3  then return ("%.1fK"):format(n/1e3)
	else return tostring(math.floor(n)) end
end

-- ─── Refresh Leaderboard ──────────────────────────────────────────────────────
local function refresh()
	local entries = {}

	for _, p in ipairs(Players:GetPlayers()) do
		local ls = p:FindFirstChild("leaderstats")
		local cashVal = ls and ls:FindFirstChild("Cash")
		table.insert(entries, {
			name  = p.Name,
			cash  = cashVal and cashVal.Value or 0,
			isMe  = (p == player),
		})
	end

	-- Sort descending by cash
	table.sort(entries, function(a, b) return a.cash > b.cash end)

	for i, row in ipairs(rows) do
		local entry = entries[i]
		if entry then
			row.Visible = true
			row.PlayerName.Text      = entry.name
			row.Cash.Text            = "$" .. fmt(entry.cash)
			-- Highlight self in gold
			if entry.isMe then
				row.BackgroundColor3    = Color3.fromRGB(50, 38, 10)
				row.PlayerName.TextColor3 = Color3.fromRGB(255, 220, 60)
			else
				row.BackgroundColor3    = Color3.fromRGB(20, 16, 40)
				row.PlayerName.TextColor3 = Color3.fromRGB(220, 215, 240)
			end
		else
			row.Visible = false
		end
	end
end

-- ─── Toggle Panel ─────────────────────────────────────────────────────────────
local panelOpen = false

lbBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	if panelOpen then
		panel.Visible = true
		panel.Size = UDim2.new(0, PANEL_W, 0, 0)
		refresh()
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

-- ─── Auto-refresh every 5 seconds while open ──────────────────────────────────
task.spawn(function()
	while true do
		task.wait(5)
		if panelOpen then
			refresh()
		end
	end
end)
