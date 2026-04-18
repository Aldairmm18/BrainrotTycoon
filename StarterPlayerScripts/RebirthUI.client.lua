-- StarterPlayerScripts/RebirthUI.client.lua
-- Solo visible en nivel 60. Confirmación de 2 pasos para renacer.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents   = ReplicatedStorage:WaitForChild("RemoteEvents")
local RequestRebirth = RemoteEvents:WaitForChild("RequestRebirth")
local RebirthResult  = RemoteEvents:WaitForChild("RebirthResult")
local UpdateXP       = RemoteEvents:WaitForChild("UpdateXP")

local currentLevel  = 1
local panelOpen     = false
local confirmStep   = 0

-- ── UI ────────────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "RebirthGui"
screenGui.ResetOnSpawn   = false
screenGui.Enabled        = false
screenGui.Parent         = playerGui

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 480, 0, 420)
panel.Position         = UDim2.new(0.5, -240, 0.5, -210)
panel.BackgroundColor3 = Color3.fromRGB(15, 5, 30)
panel.BorderSizePixel  = 0
panel.Parent           = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 20)

local header = Instance.new("TextLabel")
header.Size   = UDim2.new(1, 0, 0, 60)
header.Text   = "♻ REBIRTH"
header.TextColor3 = Color3.fromRGB(255, 100, 200)
header.TextScaled = true
header.Font   = Enum.Font.GothamBold
header.BackgroundColor3 = Color3.fromRGB(40, 10, 60)
header.BorderSizePixel = 0
header.Parent = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 20)

local closeBtn = Instance.new("TextButton")
closeBtn.Size   = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 10)
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
		confirmStep = 0
	end)
end

-- Conservado / Reiniciado
local conservedLbl = Instance.new("TextLabel")
conservedLbl.Size   = UDim2.new(0.45, 0, 0, 160)
conservedLbl.Position = UDim2.new(0.03, 0, 0, 65)
conservedLbl.Text   = "✅ SE CONSERVA:\n• Monedas\n• Armas\n• Skins\n• Estrellas\n• Kills totales"
conservedLbl.TextColor3 = Color3.fromRGB(100, 255, 150)
conservedLbl.TextScaled = true
conservedLbl.Font   = Enum.Font.Gotham
conservedLbl.TextWrapped = true
conservedLbl.BackgroundColor3 = Color3.fromRGB(15, 40, 20)
conservedLbl.BorderSizePixel = 0
conservedLbl.TextXAlignment = Enum.TextXAlignment.Left
conservedLbl.Parent = panel
Instance.new("UICorner", conservedLbl).CornerRadius = UDim.new(0, 10)

local resetLbl = Instance.new("TextLabel")
resetLbl.Size   = UDim2.new(0.45, 0, 0, 160)
resetLbl.Position = UDim2.new(0.52, 0, 0, 65)
resetLbl.Text   = "❌ SE REINICIA:\n• Nivel → 1\n• XP → 0\n• Zonas → Solo Zona 1"
resetLbl.TextColor3 = Color3.fromRGB(255, 150, 100)
resetLbl.TextScaled = true
resetLbl.Font   = Enum.Font.Gotham
resetLbl.TextWrapped = true
resetLbl.BackgroundColor3 = Color3.fromRGB(40, 15, 15)
resetLbl.BorderSizePixel = 0
resetLbl.TextXAlignment = Enum.TextXAlignment.Left
resetLbl.Parent = panel
Instance.new("UICorner", resetLbl).CornerRadius = UDim.new(0, 10)

local bonusLbl = Instance.new("TextLabel")
bonusLbl.Name   = "BonusLbl"
bonusLbl.Size   = UDim2.new(0.94, 0, 0, 55)
bonusLbl.Position = UDim2.new(0.03, 0, 0, 235)
bonusLbl.Text   = "🎁 Próximo bonus: +20% monedas • Desbloqueas Zona 4 (El Void)"
bonusLbl.TextColor3 = Color3.fromRGB(255, 220, 50)
bonusLbl.TextScaled = true
bonusLbl.Font   = Enum.Font.GothamBold
bonusLbl.TextWrapped = true
bonusLbl.BackgroundColor3 = Color3.fromRGB(40, 30, 10)
bonusLbl.BorderSizePixel = 0
bonusLbl.Parent = panel
Instance.new("UICorner", bonusLbl).CornerRadius = UDim.new(0, 10)

local rebirthBtn = Instance.new("TextButton")
rebirthBtn.Name  = "RebirthBtn"
rebirthBtn.Size  = UDim2.new(0, 220, 0, 50)
rebirthBtn.Position = UDim2.new(0.5, -110, 0, 302)
rebirthBtn.Text  = "♻ RENACER"
rebirthBtn.TextColor3 = Color3.fromRGB(255,255,255)
rebirthBtn.TextScaled = true
rebirthBtn.Font  = Enum.Font.GothamBold
rebirthBtn.BackgroundColor3 = Color3.fromRGB(160, 30, 200)
rebirthBtn.BorderSizePixel = 0
rebirthBtn.Parent = panel
Instance.new("UICorner", rebirthBtn).CornerRadius = UDim.new(0, 14)

local statusLbl = Instance.new("TextLabel")
statusLbl.Name  = "StatusLbl"
statusLbl.Size  = UDim2.new(1, 0, 0, 30)
statusLbl.Position = UDim2.new(0, 0, 0, 360)
statusLbl.Text  = ""
statusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLbl.TextScaled = true
statusLbl.Font  = Enum.Font.Gotham
statusLbl.BackgroundTransparency = 1
statusLbl.Parent = panel

-- ── Lógica de 2 pasos ─────────────────────────────────────────────────────────
if rebirthBtn then
	rebirthBtn.MouseButton1Click:Connect(function()
		confirmStep += 1
		if confirmStep == 1 then
			rebirthBtn.Text             = "⚠ ¿SEGURO? Haz clic de nuevo"
			rebirthBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 20)
			if statusLbl then statusLbl.Text = "Paso 1/2: Confirma el rebirth." end
		elseif confirmStep >= 2 then
			RequestRebirth:FireServer()
			confirmStep = 0
			rebirthBtn.Text             = "♻ RENACER"
			rebirthBtn.BackgroundColor3 = Color3.fromRGB(160, 30, 200)
			if statusLbl then statusLbl.Text = "Procesando rebirth..." end
		end
	end)
end

RebirthResult.OnClientEvent:Connect(function(success, rebirthNum, bonus)
	if success then
		if statusLbl then statusLbl.Text = "✅ ¡Renacido #" .. tostring(rebirthNum) .. "! Bienvenido de nuevo." end
		screenGui.Enabled = false
		panelOpen = false
	else
		if statusLbl then statusLbl.Text = "❌ No puedes renacer aún." end
	end
end)

-- Mostrar botón solo en nivel 60+
UpdateXP.OnClientEvent:Connect(function(xp, maxXP, level)
	currentLevel = level or 1
	local openBtn = playerGui:FindFirstChild("RebirthOpenBtn")
	if openBtn then
		openBtn.Visible = currentLevel >= 60
	end
end)

-- ── Botón de apertura (solo visible en nivel 60) ──────────────────────────────
local openBtn = Instance.new("TextButton")
openBtn.Name    = "RebirthOpenBtn"
openBtn.Size    = UDim2.new(0, 85, 0, 40)
openBtn.Position = UDim2.new(1, -175, 1, -60)
openBtn.Text    = "♻ Rebirth"
openBtn.TextColor3 = Color3.fromRGB(255,255,255)
openBtn.TextScaled = true
openBtn.Font    = Enum.Font.GothamBold
openBtn.BackgroundColor3 = Color3.fromRGB(130, 20, 180)
openBtn.BorderSizePixel = 0
openBtn.Visible = false  -- Solo se muestra en nivel 60
openBtn.ZIndex  = 5
openBtn.Parent  = playerGui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 10)

openBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	screenGui.Enabled = panelOpen
	confirmStep = 0
	if rebirthBtn then
		rebirthBtn.Text             = "♻ RENACER"
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(160, 30, 200)
	end
end)
