-- StarterPlayerScripts/MissionUI.client.lua
-- Panel de misiones diarias con barras de progreso y reclamo

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local GetMissions     = RemoteEvents:WaitForChild("GetMissions")
local MissionsData    = RemoteEvents:WaitForChild("MissionsData")
local MissionProgress = RemoteEvents:WaitForChild("MissionProgress")
local ClaimMission    = RemoteEvents:WaitForChild("ClaimMission")
local MissionClaimed  = RemoteEvents:WaitForChild("MissionClaimed")

local missionData  = {}
local panelOpen    = false
local missionCards = {}

-- ── UI ────────────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "MissionGui"
screenGui.ResetOnSpawn   = false
screenGui.Enabled        = false
screenGui.Parent         = playerGui

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 500, 0, 450)
panel.Position         = UDim2.new(0.5, -250, 0.5, -225)
panel.BackgroundColor3 = Color3.fromRGB(10, 20, 30)
panel.BorderSizePixel  = 0
panel.Parent           = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)

local header = Instance.new("TextLabel")
header.Size   = UDim2.new(1, 0, 0, 50)
header.Text   = "📋 MISIONES DIARIAS"
header.TextColor3 = Color3.fromRGB(100, 200, 255)
header.TextScaled = true
header.Font   = Enum.Font.GothamBold
header.BackgroundColor3 = Color3.fromRGB(20, 40, 70)
header.BorderSizePixel = 0
header.Parent = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

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
		screenGui.Enabled = false
		panelOpen = false
	end)
end

local missionContainer = Instance.new("Frame")
missionContainer.Size  = UDim2.new(1, -20, 1, -60)
missionContainer.Position = UDim2.new(0, 10, 0, 55)
missionContainer.BackgroundTransparency = 1
missionContainer.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent  = missionContainer

-- ── Crear card de misión ───────────────────────────────────────────────────────
local function createMissionCard(index, entry)
	if not entry or not entry.mission then return end

	local mission  = entry.mission
	local progress = entry.progress or 0
	local target   = mission.target or 1
	local claimed  = entry.claimed

	local DIFF_COLORS = {
		easy   = Color3.fromRGB(50, 180, 80),
		medium = Color3.fromRGB(200, 160, 30),
		hard   = Color3.fromRGB(220, 60, 60),
	}

	local card = Instance.new("Frame")
	card.Name             = "MissionCard_" .. index
	card.Size             = UDim2.new(1, 0, 0, 115)
	card.BackgroundColor3 = claimed
		and Color3.fromRGB(20, 60, 20)
		or  Color3.fromRGB(20, 30, 50)
	card.BorderSizePixel  = 0
	card.Parent           = missionContainer
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

	-- Título
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size   = UDim2.new(0.75, 0, 0, 28)
	titleLbl.Position = UDim2.new(0, 10, 0, 5)
	titleLbl.Text   = "[" .. (mission.difficulty or ""):upper() .. "] " .. (mission.title or "")
	titleLbl.TextColor3 = DIFF_COLORS[mission.difficulty or "easy"] or Color3.fromRGB(200,200,200)
	titleLbl.TextScaled = true
	titleLbl.Font   = Enum.Font.GothamBold
	titleLbl.BackgroundTransparency = 1
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = card

	-- Descripción
	local descLbl = Instance.new("TextLabel")
	descLbl.Size   = UDim2.new(0.9, 0, 0, 22)
	descLbl.Position = UDim2.new(0, 10, 0, 33)
	descLbl.Text   = mission.description or ""
	descLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
	descLbl.TextScaled = true
	descLbl.Font   = Enum.Font.Gotham
	descLbl.BackgroundTransparency = 1
	descLbl.TextXAlignment = Enum.TextXAlignment.Left
	descLbl.Parent = card

	-- Barra de progreso
	local barBg = Instance.new("Frame")
	barBg.Size             = UDim2.new(0.85, 0, 0, 14)
	barBg.Position         = UDim2.new(0, 10, 0, 60)
	barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	barBg.BorderSizePixel  = 0
	barBg.Parent           = card
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 6)

	local pct = math.clamp(progress / target, 0, 1)
	local barFill = Instance.new("Frame")
	barFill.Name              = "Fill"
	barFill.Size              = UDim2.new(pct, 0, 1, 0)
	barFill.BackgroundColor3  = DIFF_COLORS[mission.difficulty or "easy"] or Color3.fromRGB(80,180,80)
	barFill.BorderSizePixel   = 0
	barFill.Parent            = barBg
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 6)

	local progLbl = Instance.new("TextLabel")
	progLbl.Name   = "ProgressLabel"
	progLbl.Size   = UDim2.new(0.85, 0, 0, 14)
	progLbl.Position = UDim2.new(0, 10, 0, 76)
	progLbl.Text   = progress .. " / " .. target
	progLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	progLbl.TextScaled = true
	progLbl.Font   = Enum.Font.Gotham
	progLbl.BackgroundTransparency = 1
	progLbl.TextXAlignment = Enum.TextXAlignment.Left
	progLbl.Parent = card

	-- Botón reclamar
	local claimBtn = Instance.new("TextButton")
	claimBtn.Name  = "ClaimBtn_" .. index
	claimBtn.Size  = UDim2.new(0, 100, 0, 32)
	claimBtn.Position = UDim2.new(1, -110, 0.5, -16)
	claimBtn.BorderSizePixel = 0
	claimBtn.Parent = card
	Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 8)

	if claimed then
		claimBtn.Text   = "✓ Reclamado"
		claimBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
		claimBtn.TextColor3 = Color3.fromRGB(150, 255, 150)
	elseif progress >= target then
		claimBtn.Text   = "Reclamar!"
		claimBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
		claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		if claimBtn then
			local capturedIndex = index
			claimBtn.MouseButton1Click:Connect(function()
				ClaimMission:FireServer(capturedIndex)
			end)
		end
	else
		claimBtn.Text   = "En progreso"
		claimBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		claimBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
	end

	return card
end

-- ── Renderizar misiones ────────────────────────────────────────────────────────
local function renderMissions()
	for _, child in ipairs(missionContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	missionCards = {}
	for i, entry in ipairs(missionData) do
		missionCards[i] = createMissionCard(i, entry)
	end
end

-- ── Eventos del servidor ──────────────────────────────────────────────────────
MissionsData.OnClientEvent:Connect(function(missions)
	missionData = missions or {}
	if panelOpen then renderMissions() end
end)

MissionProgress.OnClientEvent:Connect(function(index, progress, target)
	if missionData[index] then
		missionData[index].progress = progress
	end
	-- Actualizar barra en tiempo real
	local card = missionCards[index]
	if card then
		local barBg   = card:FindFirstChild("Fill") and card:FindFirstChild("Fill").Parent
		local fill    = barBg and barBg:FindFirstChild("Fill")
		local progLbl = card:FindFirstChild("ProgressLabel")
		if fill and target and target > 0 then
			local pct = math.clamp(progress / target, 0, 1)
			fill.Size = UDim2.new(pct, 0, 1, 0)
		end
		if progLbl then
			progLbl.Text = tostring(progress) .. " / " .. tostring(target or 1)
		end
	end
end)

MissionClaimed.OnClientEvent:Connect(function(index, reward)
	if missionData[index] then
		missionData[index].claimed = true
	end
	if panelOpen then renderMissions() end

	-- Celebración visual
	local hudGui = playerGui:FindFirstChild("HudGui")
	local notifFrame = hudGui and hudGui:FindFirstChild("NotifFrame", true)
	local notifLabel = notifFrame and notifFrame:FindFirstChild("NotifLabel")
	if notifLabel and notifFrame then
		notifLabel.Text    = "🎉 ¡Misión completada!"
		notifFrame.Visible = true
		task.delay(3, function()
			if notifFrame then notifFrame.Visible = false end
		end)
	end
end)

-- ── Botón de apertura ─────────────────────────────────────────────────────────
local openBtn = Instance.new("TextButton")
openBtn.Name  = "MissionOpenButton"
openBtn.Size  = UDim2.new(0, 100, 0, 40)
openBtn.Position = UDim2.new(0, 210, 1, -60)
openBtn.Text  = "📋 Misiones"
openBtn.TextColor3 = Color3.fromRGB(255,255,255)
openBtn.TextScaled = true
openBtn.Font  = Enum.Font.GothamBold
openBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 160)
openBtn.BorderSizePixel = 0
openBtn.ZIndex = 5
openBtn.Parent = playerGui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 10)

openBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	screenGui.Enabled = panelOpen
	if panelOpen then
		GetMissions:FireServer()
		renderMissions()
	end
end)
