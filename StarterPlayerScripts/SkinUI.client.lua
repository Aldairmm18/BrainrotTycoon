-- StarterPlayerScripts/SkinUI.client.lua
-- Catálogo de skins con preview y método de desbloqueo

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SkinConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SkinConfig"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local BuySkin      = RemoteEvents:WaitForChild("BuySkin")
local SkinBought   = RemoteEvents:WaitForChild("SkinBought")
local EquipSkin    = RemoteEvents:WaitForChild("EquipSkin")

local ownedSkins   = {"default"}
local equippedSkin = "default"
local panelOpen    = false

-- ── UI ────────────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "SkinGui"
screenGui.ResetOnSpawn   = false
screenGui.Enabled        = false
screenGui.Parent         = playerGui

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 580, 0, 520)
panel.Position         = UDim2.new(0.5, -290, 0.5, -260)
panel.BackgroundColor3 = Color3.fromRGB(10, 12, 25)
panel.BorderSizePixel  = 0
panel.Parent           = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)

local header = Instance.new("TextLabel")
header.Size   = UDim2.new(1, 0, 0, 55)
header.Text   = "👕 CATÁLOGO DE SKINS"
header.TextColor3 = Color3.fromRGB(200, 150, 255)
header.TextScaled = true
header.Font   = Enum.Font.GothamBold
header.BackgroundColor3 = Color3.fromRGB(30, 20, 60)
header.BorderSizePixel = 0
header.Parent = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 18)

local closeBtn = Instance.new("TextButton")
closeBtn.Size   = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 7)
closeBtn.Text   = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font   = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
if closeBtn then
	closeBtn.MouseButton1Click:Connect(function()
		screenGui.Enabled = false; panelOpen = false
	end)
end

local scroll = Instance.new("ScrollingFrame")
scroll.Size              = UDim2.new(1, -20, 1, -65)
scroll.Position          = UDim2.new(0, 10, 0, 60)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel   = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize        = UDim2.new(0, 0, 0, 0)
scroll.Parent            = panel

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize    = UDim2.new(0, 155, 0, 175)
gridLayout.CellPaddingX = UDim.new(0, 10)
gridLayout.CellPaddingY = UDim.new(0, 10)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.Parent      = scroll

local UNLOCK_COLORS = {
	free        = Color3.fromRGB(50, 150, 50),
	coins       = Color3.fromRGB(160, 120, 20),
	streak      = Color3.fromRGB(180, 80, 20),
	time        = Color3.fromRGB(20, 100, 160),
	event       = Color3.fromRGB(150, 20, 20),
	robux       = Color3.fromRGB(100, 50, 200),
	rebirth     = Color3.fromRGB(200, 50, 50),
	achievement = Color3.fromRGB(60, 160, 160),
}

local function buildSkinCatalog()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local count = 0
	for _, skin in ipairs(SkinConfig) do
		count += 1
		local isOwned    = table.find(ownedSkins, skin.id) ~= nil
		local isEquipped = equippedSkin == skin.id

		local card = Instance.new("Frame")
		card.Name              = skin.id
		card.BackgroundColor3  = isEquipped
			and Color3.fromRGB(30, 80, 30)
			or (isOwned and Color3.fromRGB(25, 40, 60) or Color3.fromRGB(20, 20, 35))
		card.BorderSizePixel   = 0
		card.Parent            = scroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

		-- Preview color
		local preview = Instance.new("Frame")
		preview.Size              = UDim2.new(0.6, 0, 0, 60)
		preview.Position          = UDim2.new(0.2, 0, 0, 5)
		preview.BackgroundColor3  = skin.preview and skin.preview.bodyColor or Color3.fromRGB(150, 150, 150)
		preview.BorderSizePixel   = 0
		preview.Parent            = card
		Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 10)

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size   = UDim2.new(1, 0, 0, 25)
		nameLbl.Position = UDim2.new(0, 0, 0, 70)
		nameLbl.Text   = skin.name or skin.id
		nameLbl.TextColor3 = Color3.fromRGB(255,255,255)
		nameLbl.TextScaled = true
		nameLbl.Font   = Enum.Font.GothamBold
		nameLbl.BackgroundTransparency = 1
		nameLbl.Parent = card

		-- Tipo de desbloqueo
		local unlockText = skin.unlock
		if skin.unlock == "coins"   then unlockText = "💰 " .. (skin.price or 0)
		elseif skin.unlock == "streak" then unlockText = "🔥 Día " .. (skin.streakReq or "?")
		elseif skin.unlock == "time"   then unlockText = "⏱ " .. (skin.minutesReq or "?") .. " min"
		elseif skin.unlock == "robux"  then unlockText = "R$ " .. (skin.robuxPrice or "?")
		elseif skin.unlock == "rebirth" then unlockText = "♻ Rebirth " .. (skin.rebirthReq or "?")
		elseif skin.unlock == "free"   then unlockText = "GRATIS"
		elseif skin.unlock == "event"  then unlockText = "🌕 Evento" end

		local unlockLbl = Instance.new("TextLabel")
		unlockLbl.Size   = UDim2.new(1, 0, 0, 20)
		unlockLbl.Position = UDim2.new(0, 0, 0, 95)
		unlockLbl.Text   = unlockText
		unlockLbl.TextColor3 = UNLOCK_COLORS[skin.unlock] or Color3.fromRGB(180,180,180)
		unlockLbl.TextScaled = true
		unlockLbl.Font   = Enum.Font.Gotham
		unlockLbl.BackgroundTransparency = 1
		unlockLbl.Parent = card

		-- Descripción de alternativa Robux
		if skin.unlock == "robux" and skin.altDescription then
			local altLbl = Instance.new("TextLabel")
			altLbl.Size   = UDim2.new(1, -6, 0, 28)
			altLbl.Position = UDim2.new(0, 3, 0, 116)
			altLbl.Text   = skin.altDescription
			altLbl.TextColor3 = Color3.fromRGB(150, 200, 150)
			altLbl.TextScaled = true
			altLbl.Font   = Enum.Font.Gotham
			altLbl.TextWrapped = true
			altLbl.BackgroundTransparency = 1
			altLbl.Parent = card
		end

		-- Botón acción
		local btnY = skin.unlock == "robux" and 148 or 120
		local actionBtn = Instance.new("TextButton")
		actionBtn.Size  = UDim2.new(0.85, 0, 0, 30)
		actionBtn.Position = UDim2.new(0.075, 0, 0, btnY)
		actionBtn.BorderSizePixel = 0
		actionBtn.Parent = card
		Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 8)

		if isEquipped then
			actionBtn.Text = "✓ Equipada"
			actionBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
			actionBtn.TextColor3 = Color3.fromRGB(150, 255, 150)
		elseif isOwned then
			actionBtn.Text = "Equipar"
			actionBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 160)
			actionBtn.TextColor3 = Color3.fromRGB(255,255,255)
			if actionBtn then
				local capturedId = skin.id
				actionBtn.MouseButton1Click:Connect(function()
					EquipSkin:FireServer(capturedId)
					equippedSkin = capturedId
					buildSkinCatalog()
				end)
			end
		else
			actionBtn.Text = "Obtener"
			actionBtn.BackgroundColor3 = UNLOCK_COLORS[skin.unlock] or Color3.fromRGB(100,100,100)
			actionBtn.TextColor3 = Color3.fromRGB(255,255,255)
			if actionBtn and skin.unlock == "coins" then
				local capturedId = skin.id
				actionBtn.MouseButton1Click:Connect(function()
					BuySkin:FireServer(capturedId)
				end)
			end
		end
	end

	local rows = math.ceil(count / 3)
	scroll.CanvasSize = UDim2.new(0, 0, 0, rows * 190)
end

SkinBought.OnClientEvent:Connect(function(newId, allOwned)
	if allOwned then ownedSkins = allOwned end
	if panelOpen then buildSkinCatalog() end
end)

-- ── Botón de apertura ─────────────────────────────────────────────────────────
local openBtn = Instance.new("TextButton")
openBtn.Name  = "SkinOpenBtn"
openBtn.Size  = UDim2.new(0, 70, 0, 40)
openBtn.Position = UDim2.new(1, -80, 1, -60)
openBtn.Text  = "👕 Skins"
openBtn.TextColor3 = Color3.fromRGB(255,255,255)
openBtn.TextScaled = true
openBtn.Font  = Enum.Font.GothamBold
openBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 140)
openBtn.BorderSizePixel = 0
openBtn.ZIndex = 5
openBtn.Parent = playerGui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 10)

openBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	screenGui.Enabled = panelOpen
	if panelOpen then buildSkinCatalog() end
end)
