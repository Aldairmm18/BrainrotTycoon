-- StarterPlayerScripts/DailyGiftUI.client.lua
-- Cofre animado de regalo diario con streak y calendario

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local ClaimDailyGift  = RemoteEvents:WaitForChild("ClaimDailyGift")
local DailyGiftResult = RemoteEvents:WaitForChild("DailyGiftResult")

local panelOpen = false

-- ── UI ────────────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "DailyGiftGui"
screenGui.ResetOnSpawn   = false
screenGui.Enabled        = false
screenGui.Parent         = playerGui

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 480, 0, 500)
panel.Position         = UDim2.new(0.5, -240, 0.5, -250)
panel.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
panel.BorderSizePixel  = 0
panel.Parent           = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 20)

local header = Instance.new("TextLabel")
header.Size   = UDim2.new(1, 0, 0, 55)
header.Text   = "🎁 REGALO DIARIO"
header.TextColor3 = Color3.fromRGB(255, 200, 50)
header.TextScaled = true
header.Font   = Enum.Font.GothamBold
header.BackgroundColor3 = Color3.fromRGB(40, 30, 10)
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
		screenGui.Enabled = false
		panelOpen = false
	end)
end

-- Cofre / Emoji grande animado
local chestBtn = Instance.new("TextButton")
chestBtn.Name  = "ChestButton"
chestBtn.Size  = UDim2.new(0, 120, 0, 120)
chestBtn.Position = UDim2.new(0.5, -60, 0, 60)
chestBtn.Text  = "🎁"
chestBtn.TextScaled = true
chestBtn.Font  = Enum.Font.GothamBold
chestBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 20)
chestBtn.BorderSizePixel = 0
chestBtn.Parent = panel
Instance.new("UICorner", chestBtn).CornerRadius = UDim.new(0, 20)

local streakLbl = Instance.new("TextLabel")
streakLbl.Name  = "StreakLbl"
streakLbl.Size  = UDim2.new(1, 0, 0, 35)
streakLbl.Position = UDim2.new(0, 0, 0, 185)
streakLbl.Text  = "Streak: 0 días"
streakLbl.TextColor3 = Color3.fromRGB(255, 180, 50)
streakLbl.TextScaled = true
streakLbl.Font  = Enum.Font.GothamBold
streakLbl.BackgroundTransparency = 1
streakLbl.Parent = panel

local statusLbl = Instance.new("TextLabel")
statusLbl.Name  = "StatusLbl"
statusLbl.Size  = UDim2.new(0.9, 0, 0, 40)
statusLbl.Position = UDim2.new(0.05, 0, 0, 225)
statusLbl.Text  = "Haz clic en el cofre para reclamar tu regalo diario."
statusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLbl.TextScaled = true
statusLbl.Font  = Enum.Font.Gotham
statusLbl.TextWrapped = true
statusLbl.BackgroundTransparency = 1
statusLbl.Parent = panel

local rewardLbl = Instance.new("TextLabel")
rewardLbl.Name  = "RewardLbl"
rewardLbl.Size  = UDim2.new(0.9, 0, 0, 50)
rewardLbl.Position = UDim2.new(0.05, 0, 0, 265)
rewardLbl.Text  = ""
rewardLbl.TextColor3 = Color3.fromRGB(100, 255, 150)
rewardLbl.TextScaled = true
rewardLbl.Font  = Enum.Font.GothamBold
rewardLbl.TextWrapped = true
rewardLbl.BackgroundTransparency = 1
rewardLbl.Parent = panel

-- Calendario de próximos días
local calendarLbl = Instance.new("TextLabel")
calendarLbl.Size   = UDim2.new(1, 0, 0, 25)
calendarLbl.Position = UDim2.new(0, 0, 0, 322)
calendarLbl.Text   = "Próximos regalos:"
calendarLbl.TextColor3 = Color3.fromRGB(150, 150, 200)
calendarLbl.TextScaled = true
calendarLbl.Font   = Enum.Font.GothamBold
calendarLbl.BackgroundTransparency = 1
calendarLbl.Parent = panel

local calScroll = Instance.new("ScrollingFrame")
calScroll.Size             = UDim2.new(0.9, 0, 0, 120)
calScroll.Position         = UDim2.new(0.05, 0, 0, 350)
calScroll.BackgroundColor3 = Color3.fromRGB(15, 20, 40)
calScroll.BorderSizePixel  = 0
calScroll.ScrollBarThickness = 4
calScroll.CanvasSize       = UDim2.new(0, 0, 0, 0)
calScroll.Parent           = panel
Instance.new("UICorner", calScroll).CornerRadius = UDim.new(0, 8)

local calLayout = Instance.new("UIGridLayout")
calLayout.CellSize  = UDim2.new(0, 70, 0, 55)
calLayout.CellPaddingX = UDim.new(0, 5)
calLayout.CellPaddingY = UDim.new(0, 5)
calLayout.Parent    = calScroll

local GiftConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GiftConfig"))

-- Construir calendario de los próximos 7 días
local function buildCalendar(currentStreak)
	for _, child in ipairs(calScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local count = 0
	for dayOffset = 1, 7 do
		local day = (currentStreak or 0) + dayOffset
		if day > 100 then break end
		count += 1

		local gift    = GiftConfig[day]
		local giftText = "🎁"
		if gift then
			if gift.type == "coins" then
				giftText = "💰" .. (gift.amount or 0)
			elseif gift.type == "weapon" then
				giftText = "⚔"
			elseif gift.type == "skin" or gift.type == "skin_temp" then
				giftText = "👕"
			elseif gift.type == "multi" then
				giftText = "✨"
			end
		end

		local dayCard = Instance.new("Frame")
		dayCard.BackgroundColor3 = Color3.fromRGB(25, 35, 55)
		dayCard.BorderSizePixel  = 0
		dayCard.Parent           = calScroll
		Instance.new("UICorner", dayCard).CornerRadius = UDim.new(0, 8)

		local dayLbl = Instance.new("TextLabel")
		dayLbl.Size   = UDim2.new(1, 0, 0.5, 0)
		dayLbl.Text   = "Día " .. day
		dayLbl.TextColor3 = Color3.fromRGB(150, 150, 200)
		dayLbl.TextScaled = true
		dayLbl.Font   = Enum.Font.Gotham
		dayLbl.BackgroundTransparency = 1
		dayLbl.Parent = dayCard

		local giftSymbol = Instance.new("TextLabel")
		giftSymbol.Size   = UDim2.new(1, 0, 0.5, 0)
		giftSymbol.Position = UDim2.new(0, 0, 0.5, 0)
		giftSymbol.Text   = giftText
		giftSymbol.TextColor3 = Color3.fromRGB(255, 220, 100)
		giftSymbol.TextScaled = true
		giftSymbol.Font   = Enum.Font.GothamBold
		giftSymbol.BackgroundTransparency = 1
		giftSymbol.Parent = dayCard
	end

	calScroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(count / 6) * 62)
end

-- ── Animación apertura del cofre ──────────────────────────────────────────────
local function animateChest()
	if not chestBtn then return end
	-- Bounce animation
	local tween = TweenService:Create(chestBtn, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 150, 0, 150),
	})
	tween:Play()
	task.wait(0.2)
	TweenService:Create(chestBtn, TweenInfo.new(0.1), {
		Size = UDim2.new(0, 120, 0, 120),
	}):Play()
end

-- ── Abrir cofre ───────────────────────────────────────────────────────────────
if chestBtn then
	chestBtn.MouseButton1Click:Connect(function()
		animateChest()
		ClaimDailyGift:FireServer()
	end)
end

DailyGiftResult.OnClientEvent:Connect(function(reward, streak, coins, status, extra)
	if status == "cooldown" then
		if statusLbl then statusLbl.Text = "⏳ Regresa en " .. tostring(extra or "?") .. " horas." end
		return
	elseif status == "already_claimed" then
		if statusLbl then statusLbl.Text = "✅ Ya reclamaste tu regalo hoy." end
		return
	end

	if streakLbl then streakLbl.Text = "🔥 Streak: " .. tostring(streak or 0) .. " días" end
	buildCalendar(streak)

	-- Mostrar recompensa
	local msg = "Recibiste: "
	if reward then
		if reward.type == "coins"  then msg = msg .. "💰 " .. (reward.amount or 0) .. " monedas"
		elseif reward.type == "weapon" then msg = msg .. "⚔ Arma: " .. (reward.key or "")
		elseif reward.type == "skin"   then msg = msg .. "👕 Skin: " .. (reward.key or "")
		elseif reward.type == "multi"  then msg = msg .. "✨ Múltiples recompensas!"
		end
	end
	if rewardLbl then rewardLbl.Text = msg end
	if statusLbl then statusLbl.Text = "✅ ¡Regalo reclamado!" end
end)

-- ── Botón de apertura ─────────────────────────────────────────────────────────
local openBtn = Instance.new("TextButton")
openBtn.Name  = "GiftOpenButton"
openBtn.Size  = UDim2.new(0, 80, 0, 40)
openBtn.Position = UDim2.new(0, 320, 1, -60)
openBtn.Text  = "🎁 Gift"
openBtn.TextColor3 = Color3.fromRGB(255,255,255)
openBtn.TextScaled = true
openBtn.Font  = Enum.Font.GothamBold
openBtn.BackgroundColor3 = Color3.fromRGB(160, 100, 20)
openBtn.BorderSizePixel = 0
openBtn.ZIndex = 5
openBtn.Parent = playerGui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 10)

openBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	screenGui.Enabled = panelOpen
	if panelOpen then buildCalendar(0) end
end)
