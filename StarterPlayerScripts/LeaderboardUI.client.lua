-- StarterPlayerScripts/LeaderboardUI.client.lua
-- 4 tabs: Velocidad, Nivel, Supervivencia, Kills

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local GetLeaderboard  = RemoteEvents:WaitForChild("GetLeaderboard")
local LeaderboardData = RemoteEvents:WaitForChild("LeaderboardData")

local panelOpen   = false
local activeTab   = "Level"

local TABS = {
	{id="Speed",    label="⚡ Velocidad"},
	{id="Level",    label="📈 Nivel"},
	{id="Survival", label="⏱ Supervivencia"},
	{id="Kills",    label="💀 Kills"},
}

-- ── UI ────────────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "LeaderboardGui"
screenGui.ResetOnSpawn   = false
screenGui.Enabled        = false
screenGui.Parent         = playerGui

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 520, 0, 530)
panel.Position         = UDim2.new(0.5, -260, 0.5, -265)
panel.BackgroundColor3 = Color3.fromRGB(8, 12, 25)
panel.BorderSizePixel  = 0
panel.Parent           = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)

local header = Instance.new("TextLabel")
header.Size   = UDim2.new(1, 0, 0, 50)
header.Text   = "🏆 LEADERBOARD"
header.TextColor3 = Color3.fromRGB(255, 210, 50)
header.TextScaled = true
header.Font   = Enum.Font.GothamBold
header.BackgroundColor3 = Color3.fromRGB(30, 25, 10)
header.BorderSizePixel = 0
header.Parent = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 18)

local closeBtn = Instance.new("TextButton")
closeBtn.Size   = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 5)
closeBtn.Text   = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.TextScaled = true
closeBtn.Font   = Enum.Font.GothamBold
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
if closeBtn then
	closeBtn.MouseButton1Click:Connect(function()
		screenGui.Enabled = false; panelOpen = false
	end)
end

-- Tabs
local tabContainer = Instance.new("Frame")
tabContainer.Size   = UDim2.new(1, -20, 0, 40)
tabContainer.Position = UDim2.new(0, 10, 0, 53)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 5)
tabLayout.Parent  = tabContainer

local tabButtons = {}
local function updateTabVisuals()
	for _, tab in ipairs(TABS) do
		local btn = tabButtons[tab.id]
		if btn then
			btn.BackgroundColor3 = tab.id == activeTab
				and Color3.fromRGB(50, 100, 200)
				or  Color3.fromRGB(25, 35, 60)
		end
	end
end

for _, tab in ipairs(TABS) do
	local btn = Instance.new("TextButton")
	btn.Name  = "Tab_" .. tab.id
	btn.Size  = UDim2.new(0, 110, 0, 35)
	btn.Text  = tab.label
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.TextScaled = true
	btn.Font  = Enum.Font.Gotham
	btn.BackgroundColor3 = Color3.fromRGB(25, 35, 60)
	btn.BorderSizePixel = 0
	btn.Parent = tabContainer
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	tabButtons[tab.id] = btn

	local capturedId = tab.id
	if btn then
		btn.MouseButton1Click:Connect(function()
			activeTab = capturedId
			updateTabVisuals()
			GetLeaderboard:FireServer(capturedId)
		end)
	end
end
updateTabVisuals()

-- Lista del top 10
local listContainer = Instance.new("Frame")
listContainer.Size   = UDim2.new(0.95, 0, 0, 380)
listContainer.Position = UDim2.new(0.025, 0, 0, 100)
listContainer.BackgroundTransparency = 1
listContainer.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent  = listContainer

local function buildLeaderboard(lbType, entries)
	for _, child in ipairs(listContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local localUserId = tostring(player.UserId)

	for i, entry in ipairs(entries or {}) do
		local isPlayer = entry.userId == localUserId
		local rankColor = i == 1 and Color3.fromRGB(255, 200, 0)
					or i == 2 and Color3.fromRGB(192, 192, 192)
					or i == 3 and Color3.fromRGB(180, 100, 40)
					or             Color3.fromRGB(100, 100, 130)

		local row = Instance.new("Frame")
		row.Size             = UDim2.new(1, 0, 0, 33)
		row.BackgroundColor3 = isPlayer
			and Color3.fromRGB(30, 60, 30)
			or  Color3.fromRGB(18, 25, 45)
		row.BorderSizePixel  = 0
		row.Parent           = listContainer
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

		local rankLbl = Instance.new("TextLabel")
		rankLbl.Size   = UDim2.new(0.1, 0, 1, 0)
		rankLbl.Text   = "#" .. i
		rankLbl.TextColor3 = rankColor
		rankLbl.TextScaled = true
		rankLbl.Font   = Enum.Font.GothamBold
		rankLbl.BackgroundTransparency = 1
		rankLbl.Parent = row

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size   = UDim2.new(0.55, 0, 1, 0)
		nameLbl.Position = UDim2.new(0.12, 0, 0, 0)
		nameLbl.Text   = (isPlayer and "🟢 " or "") .. (entry.name or "?")
		nameLbl.TextColor3 = isPlayer and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(220, 220, 220)
		nameLbl.TextScaled = true
		nameLbl.Font   = Enum.Font.Gotham
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.BackgroundTransparency = 1
		nameLbl.Parent = row

		local valueLbl = Instance.new("TextLabel")
		valueLbl.Size   = UDim2.new(0.3, 0, 1, 0)
		valueLbl.Position = UDim2.new(0.7, 0, 0, 0)
		local value = entry.value or 0
		-- Formatear según tipo
		if lbType == "Survival" then
			value = string.format("%02d:%02d", math.floor(value/60), value%60)
		end
		valueLbl.Text   = tostring(value)
		valueLbl.TextColor3 = Color3.fromRGB(200, 200, 255)
		valueLbl.TextScaled = true
		valueLbl.Font   = Enum.Font.GothamBold
		valueLbl.TextXAlignment = Enum.TextXAlignment.Right
		valueLbl.BackgroundTransparency = 1
		valueLbl.Parent = row
	end
end

LeaderboardData.OnClientEvent:Connect(function(lbType, entries)
	buildLeaderboard(lbType, entries)
end)

-- ── Botón de apertura ─────────────────────────────────────────────────────────
local openBtn = Instance.new("TextButton")
openBtn.Name  = "LBOpenBtn"
openBtn.Size  = UDim2.new(0, 80, 0, 40)
openBtn.Position = UDim2.new(1, -90, 0, 10)
openBtn.Text  = "🏆 Top"
openBtn.TextColor3 = Color3.fromRGB(255,255,255)
openBtn.TextScaled = true
openBtn.Font  = Enum.Font.GothamBold
openBtn.BackgroundColor3 = Color3.fromRGB(140, 100, 20)
openBtn.BorderSizePixel = 0
openBtn.ZIndex = 5
openBtn.Parent = playerGui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 10)

openBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	screenGui.Enabled = panelOpen
	if panelOpen then
		GetLeaderboard:FireServer(activeTab)
		updateTabVisuals()
	end
end)
