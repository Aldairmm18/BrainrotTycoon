-- StarterPlayerScripts/TimerUI.client.lua
-- Display del timer de sesión y pantalla de resultados al final

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local SessionEnd    = RemoteEvents:WaitForChild("SessionEnd")
local RedeemTime    = RemoteEvents:WaitForChild("RedeemTime")
local TimeRedeemed  = RemoteEvents:WaitForChild("TimeRedeemed")

local function formatTime(secs)
	secs = math.max(0, math.floor(secs or 0))
	return string.format("%02d:%02d", math.floor(secs/60), secs % 60)
end

-- ── Pantalla de resultados ────────────────────────────────────────────────────
local resultGui = Instance.new("ScreenGui")
resultGui.Name           = "SessionResultGui"
resultGui.ResetOnSpawn   = false
resultGui.Enabled        = false
resultGui.Parent         = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size             = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(5, 5, 15)
backdrop.BackgroundTransparency = 0.15
backdrop.BorderSizePixel  = 0
backdrop.Parent           = resultGui

local panel = Instance.new("Frame")
panel.Size              = UDim2.new(0, 550, 0, 480)
panel.Position          = UDim2.new(0.5, -275, 0.5, -240)
panel.BackgroundColor3  = Color3.fromRGB(15, 20, 40)
panel.BorderSizePixel   = 0
panel.Parent            = backdrop
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 20)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size    = UDim2.new(1, 0, 0, 60)
titleLbl.Text    = "📊 RESULTADOS DE SESIÓN"
titleLbl.TextColor3 = Color3.fromRGB(255, 200, 50)
titleLbl.TextScaled = true
titleLbl.Font    = Enum.Font.GothamBold
titleLbl.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
titleLbl.BorderSizePixel = 0
titleLbl.Parent  = panel
Instance.new("UICorner", titleLbl).CornerRadius = UDim.new(0, 20)

local timeLbl = Instance.new("TextLabel")
timeLbl.Name   = "TimeLbl"
timeLbl.Size   = UDim2.new(1, 0, 0, 45)
timeLbl.Position = UDim2.new(0, 0, 0, 65)
timeLbl.Text   = "⏱ Tiempo: 00:00"
timeLbl.TextColor3 = Color3.fromRGB(200, 255, 200)
timeLbl.TextScaled = true
timeLbl.Font   = Enum.Font.GothamBold
timeLbl.BackgroundTransparency = 1
timeLbl.Parent = panel

local killsLbl = Instance.new("TextLabel")
killsLbl.Name  = "KillsLbl"
killsLbl.Size  = UDim2.new(1, 0, 0, 40)
killsLbl.Position = UDim2.new(0, 0, 0, 110)
killsLbl.Text  = "☠ Kills: 0"
killsLbl.TextColor3 = Color3.fromRGB(255, 150, 150)
killsLbl.TextScaled = true
killsLbl.Font  = Enum.Font.GothamBold
killsLbl.BackgroundTransparency = 1
killsLbl.Parent = panel

local starsLbl = Instance.new("TextLabel")
starsLbl.Name  = "StarsLbl"
starsLbl.Size  = UDim2.new(1, 0, 0, 50)
starsLbl.Position = UDim2.new(0, 0, 0, 155)
starsLbl.Text  = "⭐⭐⭐⭐⭐"
starsLbl.TextColor3 = Color3.fromRGB(255, 220, 50)
starsLbl.TextScaled = true
starsLbl.Font  = Enum.Font.GothamBold
starsLbl.BackgroundTransparency = 1
starsLbl.Parent = panel

-- Separator
local sep = Instance.new("Frame")
sep.Size             = UDim2.new(0.9, 0, 0, 2)
sep.Position         = UDim2.new(0.05, 0, 0, 215)
sep.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
sep.BorderSizePixel  = 0
sep.Parent           = panel

local redeemLbl = Instance.new("TextLabel")
redeemLbl.Size   = UDim2.new(1, 0, 0, 35)
redeemLbl.Position = UDim2.new(0, 0, 0, 225)
redeemLbl.Text   = "Canjea tu tiempo de supervivencia:"
redeemLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
redeemLbl.TextScaled = true
redeemLbl.Font   = Enum.Font.Gotham
redeemLbl.BackgroundTransparency = 1
redeemLbl.Parent = panel

-- Botón canjear por monedas
local coinsBtn = Instance.new("TextButton")
coinsBtn.Name  = "CoinsRedeemBtn"
coinsBtn.Size  = UDim2.new(0, 220, 0, 65)
coinsBtn.Position = UDim2.new(0.05, 0, 0, 270)
coinsBtn.Text  = "💰 Canjear por Monedas\n(minutos × 50)"
coinsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
coinsBtn.TextScaled = true
coinsBtn.Font  = Enum.Font.GothamBold
coinsBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
coinsBtn.BorderSizePixel = 0
coinsBtn.Parent = panel
Instance.new("UICorner", coinsBtn).CornerRadius = UDim.new(0, 12)

-- Botón canjear por item
local itemBtn = Instance.new("TextButton")
itemBtn.Name  = "ItemRedeemBtn"
itemBtn.Size  = UDim2.new(0, 245, 0, 65)
itemBtn.Position = UDim2.new(0.5, -5, 0, 270)
itemBtn.Text  = "🎁 Canjear por Ítem\n(5min→Poción, 10min→Upgrade...)"
itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
itemBtn.TextScaled = true
itemBtn.Font  = Enum.Font.GothamBold
itemBtn.BackgroundColor3 = Color3.fromRGB(160, 60, 200)
itemBtn.BorderSizePixel = 0
itemBtn.Parent = panel
Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 12)

local resultMsg = Instance.new("TextLabel")
resultMsg.Name   = "ResultMsg"
resultMsg.Size   = UDim2.new(1, 0, 0, 40)
resultMsg.Position = UDim2.new(0, 0, 0, 345)
resultMsg.Text   = ""
resultMsg.TextColor3 = Color3.fromRGB(255, 220, 100)
resultMsg.TextScaled = true
resultMsg.Font   = Enum.Font.GothamBold
resultMsg.BackgroundTransparency = 1
resultMsg.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Name  = "CloseBtn"
closeBtn.Size  = UDim2.new(0, 150, 0, 45)
closeBtn.Position = UDim2.new(0.5, -75, 1, -60)
closeBtn.Text  = "Cerrar"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.TextScaled = true
closeBtn.Font  = Enum.Font.GothamBold
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

-- ── Eventos ────────────────────────────────────────────────────────────────────
local redeemedThisSession = false

SessionEnd.OnClientEvent:Connect(function(results)
	if not results then return end
	redeemedThisSession = false

	local elapsed = results.elapsed or 0
	local kills   = results.kills or 0
	local stars   = results.stars or 0

	if timeLbl  then timeLbl.Text  = "⏱ Tiempo: " .. formatTime(elapsed) end
	if killsLbl then killsLbl.Text = "☠ Kills: " .. tostring(kills) end

	-- Estrellas
	if starsLbl then
		local starStr = ""
		for i = 1, 5 do
			starStr = starStr .. (i <= stars and "⭐" or "☆")
		end
		starsLbl.Text = starStr
	end

	resultGui.Enabled = true
end)

if coinsBtn then
	coinsBtn.MouseButton1Click:Connect(function()
		if redeemedThisSession then return end
		redeemedThisSession = true
		RedeemTime:FireServer("coins")
		if coinsBtn then coinsBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60) end
		if itemBtn  then itemBtn.BackgroundColor3  = Color3.fromRGB(60, 60, 60) end
	end)
end

if itemBtn then
	itemBtn.MouseButton1Click:Connect(function()
		if redeemedThisSession then return end
		redeemedThisSession = true
		RedeemTime:FireServer("item")
		if coinsBtn then coinsBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60) end
		if itemBtn  then itemBtn.BackgroundColor3  = Color3.fromRGB(60, 60, 60) end
	end)
end

TimeRedeemed.OnClientEvent:Connect(function(reward)
	if not reward then return end
	local msg = "Recompensa: "
	if reward.type == "coins"   then msg = msg .. "💰 " .. (reward.amount or 0) .. " monedas"
	elseif reward.type == "upgrade" then msg = msg .. "⬆ Upgrade gratuito aplicado"
	elseif reward.type == "chest"   then msg = msg .. "📦 Cofre " .. (reward.rarity or "") .. " recibido"
	elseif reward.type == "crystal_key" then msg = msg .. "🔑 Crystal Key obtenida"
	elseif reward.type == "potion" then msg = msg .. "⚡ Poción de velocidad activada" end
	if resultMsg then resultMsg.Text = msg end
end)

if closeBtn then
	closeBtn.MouseButton1Click:Connect(function()
		resultGui.Enabled = false
	end)
end
