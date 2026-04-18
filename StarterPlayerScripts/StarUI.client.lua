-- StarterPlayerScripts/StarUI.client.lua
-- Animación de estrellas al final de sesión con criterios visuales

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local SessionEnd   = RemoteEvents:WaitForChild("SessionEnd")

-- ── UI ────────────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "StarGui"
screenGui.ResetOnSpawn   = false
screenGui.Enabled        = false
screenGui.Parent         = playerGui

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 500, 0, 420)
panel.Position         = UDim2.new(0.5, -250, 0.5, -210)
panel.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
panel.BorderSizePixel  = 0
panel.Parent           = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 20)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size   = UDim2.new(1, 0, 0, 55)
titleLbl.Text   = "🌟 EVALUACIÓN DE SESIÓN"
titleLbl.TextColor3 = Color3.fromRGB(255, 220, 50)
titleLbl.TextScaled = true
titleLbl.Font   = Enum.Font.GothamBold
titleLbl.BackgroundColor3 = Color3.fromRGB(30, 25, 60)
titleLbl.BorderSizePixel = 0
titleLbl.Parent = panel
Instance.new("UICorner", titleLbl).CornerRadius = UDim.new(0, 20)

-- Estrellas animadas
local starContainer = Instance.new("Frame")
starContainer.Size              = UDim2.new(0.8, 0, 0, 70)
starContainer.Position          = UDim2.new(0.1, 0, 0, 60)
starContainer.BackgroundTransparency = 1
starContainer.Parent            = panel

local starLabels = {}
local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = starContainer

for i = 1, 5 do
	local star = Instance.new("TextLabel")
	star.Name        = "Star" .. i
	star.Size        = UDim2.new(0, 55, 0, 55)
	star.Text        = "☆"
	star.TextColor3  = Color3.fromRGB(100, 100, 100)
	star.TextScaled  = true
	star.Font        = Enum.Font.GothamBold
	star.BackgroundTransparency = 1
	star.TextTransparency = 0
	star.Parent      = starContainer
	table.insert(starLabels, star)
end

-- Criterios
local criteriaContainer = Instance.new("Frame")
criteriaContainer.Size   = UDim2.new(0.9, 0, 0, 180)
criteriaContainer.Position = UDim2.new(0.05, 0, 0, 140)
criteriaContainer.BackgroundTransparency = 1
criteriaContainer.Parent = panel

local criteriaLayout = Instance.new("UIListLayout")
criteriaLayout.Padding = UDim.new(0, 6)
criteriaLayout.Parent  = criteriaContainer

local CRITERIA_DESCS = {
	"⏱ Sobrevivir más de 5 minutos",
	"💀 Matar 20 o más enemigos",
	"❤ Sin morir en la sesión",
	"📋 Completar una misión",
	"⚡ Usar habilidad 5+ veces",
}

local criteriaLabels = {}

for _, desc in ipairs(CRITERIA_DESCS) do
	local lbl = Instance.new("TextLabel")
	lbl.Size             = UDim2.new(1, 0, 0, 28)
	lbl.Text             = desc
	lbl.TextColor3       = Color3.fromRGB(160, 160, 160)
	lbl.TextScaled       = true
	lbl.Font             = Enum.Font.Gotham
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment   = Enum.TextXAlignment.Left
	lbl.Parent           = criteriaContainer
	table.insert(criteriaLabels, lbl)
end

-- Totales
local totalLbl = Instance.new("TextLabel")
totalLbl.Name   = "TotalLbl"
totalLbl.Size   = UDim2.new(1, 0, 0, 35)
totalLbl.Position = UDim2.new(0, 0, 1, -90)
totalLbl.Text   = "Total acumulado: ⭐ 0 | Rango: Bronze"
totalLbl.TextColor3 = Color3.fromRGB(200, 200, 255)
totalLbl.TextScaled = true
totalLbl.Font   = Enum.Font.GothamBold
totalLbl.BackgroundTransparency = 1
totalLbl.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Size   = UDim2.new(0, 150, 0, 40)
closeBtn.Position = UDim2.new(0.5, -75, 1, -50)
closeBtn.Text   = "OK"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.TextScaled = true
closeBtn.Font   = Enum.Font.GothamBold
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

if closeBtn then
	closeBtn.MouseButton1Click:Connect(function()
		screenGui.Enabled = false
	end)
end

-- ── Animación de estrellas ────────────────────────────────────────────────────
local function animateStars(count, results, totalStars, rank)
	screenGui.Enabled = true

	-- Reset
	for _, lbl in ipairs(starLabels) do
		if lbl then
			lbl.Text      = "☆"
			lbl.TextColor3 = Color3.fromRGB(100, 100, 100)
		end
	end
	for i, lbl in ipairs(criteriaLabels) do
		if lbl and results and results[i] then
			lbl.TextColor3 = results[i].passed
				and Color3.fromRGB(100, 255, 100)
				or  Color3.fromRGB(160, 80, 80)
			lbl.Text = (results[i].passed and "✅ " or "❌ ") .. CRITERIA_DESCS[i]
		end
	end

	-- Animar estrellas una a una
	for i = 1, math.min(count, 5) do
		task.wait(0.35)
		local lbl = starLabels[i]
		if lbl then
			lbl.Text       = "⭐"
			lbl.TextColor3 = Color3.fromRGB(255, 220, 50)
			-- Efecto de bounce
			lbl.TextTransparency = 1
			TweenService:Create(lbl, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				TextTransparency = 0,
			}):Play()
		end
	end

	if totalLbl then
		totalLbl.Text = string.format("Total acumulado: ⭐ %d | Rango: %s", totalStars or 0, rank or "Bronze")
	end
end

SessionEnd.OnClientEvent:Connect(function(results)
	if not results then return end
	-- El StarUI muestra las estrellas directamente desde los resultados del SessionEnd
	local stars   = results.stars or 0
	animateStars(stars, nil, 0, "Bronze")
end)
