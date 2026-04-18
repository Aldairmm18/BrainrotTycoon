-- StarterPlayerScripts/GameModeUI.client.lua
-- Portal de modos de juego con descripciones hover

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents     = ReplicatedStorage:WaitForChild("RemoteEvents")
local SelectGameMode   = RemoteEvents:WaitForChild("SelectGameMode")
local GameModeStarted  = RemoteEvents:WaitForChild("GameModeStarted")

local panelOpen = false

local MODES = {
	{id="Survival",  name="Supervivencia",  icon="⚔",  color=Color3.fromRGB(40, 140, 80),  desc="Modo normal. Mata enemigos, sube de nivel, sobrevive."},
	{id="Creative",  name="Creativo",       icon="🏗",  color=Color3.fromRGB(40, 100, 180), desc="Sin enemigos, sin XP ni monedas. Explora el mapa libremente."},
	{id="PvP",       name="PvP Arena",      icon="🏆",  color=Color3.fromRGB(160, 30, 30),  desc="Combate contra otros jugadores. Stats igualados."},
	{id="BloodMoon", name="Blood Moon",     icon="🌕",  color=Color3.fromRGB(120, 0, 20),   desc="Solo viernes/sábados. Enemigos 3x más peligrosos. Recompensas épicas."},
	{id="Coop",      name="Co-op",          icon="🤝",  color=Color3.fromRGB(80, 40, 160),  desc="Hasta 4 jugadores juntos. Monedas x1.5."},
}

-- ── UI ────────────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "GameModeGui"
screenGui.ResetOnSpawn   = false
screenGui.Enabled        = false
screenGui.Parent         = playerGui

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 520, 0, 480)
panel.Position         = UDim2.new(0.5, -260, 0.5, -240)
panel.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
panel.BorderSizePixel  = 0
panel.Parent           = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 20)

local header = Instance.new("TextLabel")
header.Size   = UDim2.new(1, 0, 0, 55)
header.Text   = "🌀 MODO DE JUEGO"
header.TextColor3 = Color3.fromRGB(150, 200, 255)
header.TextScaled = true
header.Font   = Enum.Font.GothamBold
header.BackgroundColor3 = Color3.fromRGB(20, 40, 80)
header.BorderSizePixel = 0
header.Parent = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 20)

local closeBtn = Instance.new("TextButton")
closeBtn.Size   = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 7)
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

local descLabel = Instance.new("TextLabel")
descLabel.Name   = "DescLabel"
descLabel.Size   = UDim2.new(0.9, 0, 0, 50)
descLabel.Position = UDim2.new(0.05, 0, 0, 58)
descLabel.Text   = "Pon el cursor sobre un modo para ver la descripción."
descLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
descLabel.TextScaled = true
descLabel.Font   = Enum.Font.Gotham
descLabel.TextWrapped = true
descLabel.BackgroundTransparency = 1
descLabel.Parent = panel

-- Grid de botones de modo
local modeContainer = Instance.new("Frame")
modeContainer.Size   = UDim2.new(0.9, 0, 0, 340)
modeContainer.Position = UDim2.new(0.05, 0, 0, 115)
modeContainer.BackgroundTransparency = 1
modeContainer.Parent = panel

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize    = UDim2.new(0, 140, 0, 155)
gridLayout.CellPaddingX = UDim.new(0, 10)
gridLayout.CellPaddingY = UDim.new(0, 10)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.Parent      = modeContainer

local statusLbl = Instance.new("TextLabel")
statusLbl.Name  = "StatusLbl"
statusLbl.Size  = UDim2.new(1, 0, 0, 40)
statusLbl.Position = UDim2.new(0, 0, 1, -50)
statusLbl.Text  = "Modo actual: Supervivencia"
statusLbl.TextColor3 = Color3.fromRGB(100, 255, 150)
statusLbl.TextScaled = true
statusLbl.Font  = Enum.Font.GothamBold
statusLbl.BackgroundTransparency = 1
statusLbl.Parent = panel

-- Crear botones de modo
for _, mode in ipairs(MODES) do
	local btn = Instance.new("TextButton")
	btn.Name  = mode.id
	btn.Text  = mode.icon .. "\n" .. mode.name
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.TextScaled = true
	btn.Font  = Enum.Font.GothamBold
	btn.BackgroundColor3 = mode.color
	btn.BorderSizePixel = 0
	btn.Parent = modeContainer
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)

	-- Hover: mostrar descripción
	btn.MouseEnter:Connect(function()
		if descLabel then descLabel.Text = mode.desc end
	end)
	btn.MouseLeave:Connect(function()
		if descLabel then descLabel.Text = "Pon el cursor sobre un modo para ver la descripción." end
	end)

	local capturedMode = mode
	if btn then
		btn.MouseButton1Click:Connect(function()
			SelectGameMode:FireServer(capturedMode.id)
		end)
	end
end

GameModeStarted.OnClientEvent:Connect(function(mode, msg)
	if statusLbl then
		if mode then
			local modeName = mode
			for _, m in ipairs(MODES) do
				if m.id == mode then modeName = m.name break end
			end
			statusLbl.Text = "Modo actual: " .. modeName
		end
	end
	if msg then
		if descLabel then descLabel.Text = msg end
	end
end)

-- ── Botón de apertura ─────────────────────────────────────────────────────────
local openBtn = Instance.new("TextButton")
openBtn.Name  = "GameModeBtn"
openBtn.Size  = UDim2.new(0, 80, 0, 40)
openBtn.Position = UDim2.new(0, 410, 1, -60)
openBtn.Text  = "🌀 Modo"
openBtn.TextColor3 = Color3.fromRGB(255,255,255)
openBtn.TextScaled = true
openBtn.Font  = Enum.Font.GothamBold
openBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
openBtn.BorderSizePixel = 0
openBtn.ZIndex = 5
openBtn.Parent = playerGui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 10)

openBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	screenGui.Enabled = panelOpen
end)
