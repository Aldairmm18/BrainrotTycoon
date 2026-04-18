-- StarterPlayerScripts/ShopUI.client.lua
-- Panel de tienda: armas filtradas por zona, compra/venta

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local WeaponConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WeaponConfig"))

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local BuyWeapon     = RemoteEvents:WaitForChild("BuyWeapon")
local WeaponBought  = RemoteEvents:WaitForChild("WeaponBought")
local SellWeapon    = RemoteEvents:WaitForChild("SellWeapon")
local UpdateCoins   = RemoteEvents:WaitForChild("UpdateCoins")

local playerCoins     = 0
local unlockedZones   = {1}
local ownedWeaponKeys = {}
local shopOpen        = false

-- ── Crear UI ──────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ShopGui"
screenGui.ResetOnSpawn   = false
screenGui.Enabled        = false
screenGui.Parent         = playerGui

local panel = Instance.new("Frame")
panel.Size              = UDim2.new(0, 600, 0, 500)
panel.Position          = UDim2.new(0.5, -300, 0.5, -250)
panel.BackgroundColor3  = Color3.fromRGB(15, 15, 30)
panel.BorderSizePixel   = 0
panel.Parent            = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)

local header = Instance.new("TextLabel")
header.Size   = UDim2.new(1, 0, 0, 50)
header.Text   = "🗡️ TIENDA DE ARMAS"
header.TextColor3 = Color3.fromRGB(255, 200, 50)
header.TextScaled = true
header.Font   = Enum.Font.GothamBold
header.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
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
closeBtn.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
	shopOpen = false
end)

-- ScrollingFrame para items
local scroll = Instance.new("ScrollingFrame")
scroll.Size              = UDim2.new(1, -20, 1, -60)
scroll.Position          = UDim2.new(0, 10, 0, 55)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel   = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize        = UDim2.new(0, 0, 0, 0)
scroll.Parent            = panel

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize    = UDim2.new(0, 170, 0, 130)
gridLayout.CellPaddingX = UDim.new(0, 10)
gridLayout.CellPaddingY = UDim.new(0, 10)
gridLayout.Parent      = scroll

-- ── Construir items del shop ───────────────────────────────────────────────────
local function buildShop()
	-- Limpiar
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local count = 0
	for _, key in ipairs(WeaponConfig.ORDER) do
		local wData = WeaponConfig[key]
		if not wData then continue end

		-- Filtrar por zona desbloqueada
		local zoneOk = table.find(unlockedZones, wData.zoneReq or 1) ~= nil
		if not zoneOk then continue end

		count = count + 1
		local owned = table.find(ownedWeaponKeys, key) ~= nil

		local card = Instance.new("Frame")
		card.BackgroundColor3 = owned
			and Color3.fromRGB(30, 80, 30)
			or  Color3.fromRGB(30, 40, 70)
		card.BorderSizePixel  = 0
		card.Parent           = scroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size   = UDim2.new(1, 0, 0, 35)
		nameLabel.Text   = wData.name or key
		nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
		nameLabel.TextScaled = true
		nameLabel.Font   = Enum.Font.GothamBold
		nameLabel.BackgroundTransparency = 1
		nameLabel.Parent = card

		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size   = UDim2.new(1, 0, 0, 25)
		priceLabel.Position = UDim2.new(0, 0, 0, 35)
		priceLabel.Text   = wData.isFree and "GRATIS" or ("💰 " .. tostring(wData.price))
		priceLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
		priceLabel.TextScaled = true
		priceLabel.Font   = Enum.Font.Gotham
		priceLabel.BackgroundTransparency = 1
		priceLabel.Parent = card

		local dmgLabel = Instance.new("TextLabel")
		dmgLabel.Size   = UDim2.new(1, 0, 0, 20)
		dmgLabel.Position = UDim2.new(0, 0, 0, 60)
		dmgLabel.Text   = "⚔ " .. wData.damage .. " dmg | " .. (wData.type or "Melee")
		dmgLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
		dmgLabel.TextScaled = true
		dmgLabel.Font   = Enum.Font.Gotham
		dmgLabel.BackgroundTransparency = 1
		dmgLabel.Parent = card

		-- Botones comprar / vender
		if owned then
			local sellBtn = Instance.new("TextButton")
			sellBtn.Name  = "SellBtn_" .. key
			sellBtn.Size  = UDim2.new(0.8, 0, 0, 30)
			sellBtn.Position = UDim2.new(0.1, 0, 1, -35)
			sellBtn.Text  = "Vender (50%)"
			sellBtn.TextColor3 = Color3.fromRGB(255,255,255)
			sellBtn.TextScaled = true
			sellBtn.Font  = Enum.Font.Gotham
			sellBtn.BackgroundColor3 = Color3.fromRGB(160, 60, 30)
			sellBtn.BorderSizePixel = 0
			sellBtn.Parent = card
			Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0, 8)

			if sellBtn then
				sellBtn.MouseButton1Click:Connect(function()
					SellWeapon:FireServer(key)
				end)
			end
		else
			local affordText = (wData.isFree or playerCoins >= (wData.price or 0)) and "Comprar" or "Sin monedas"
			local buyBtn = Instance.new("TextButton")
			buyBtn.Name  = "BuyBtn_" .. key
			buyBtn.Size  = UDim2.new(0.8, 0, 0, 30)
			buyBtn.Position = UDim2.new(0.1, 0, 1, -35)
			buyBtn.Text  = affordText
			buyBtn.TextColor3 = Color3.fromRGB(255,255,255)
			buyBtn.TextScaled = true
			buyBtn.Font  = Enum.Font.Gotham
			buyBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 80)
			buyBtn.BorderSizePixel = 0
			buyBtn.Parent = card
			Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)

			if buyBtn then
				buyBtn.MouseButton1Click:Connect(function()
					BuyWeapon:FireServer(key)
				end)
			end
		end
	end

	-- Actualizar canvas
	local rows = math.ceil(count / 3)
	scroll.CanvasSize = UDim2.new(0, 0, 0, rows * 145)
end

-- Actualizar lista al comprar/vender
WeaponBought.OnClientEvent:Connect(function(newWeaponKey, allOwned)
	ownedWeaponKeys = {}
	if allOwned then
		for k, _ in pairs(allOwned) do
			table.insert(ownedWeaponKeys, k)
		end
	end
	if screenGui.Enabled then buildShop() end

	if newWeaponKey then
		-- Mostrar confirmación breve
		local notifGui = playerGui:FindFirstChild("HudGui")
		local notifFrame = notifGui and notifGui:FindFirstChild("NotifFrame", true)
		local notifLabel = notifFrame and notifFrame:FindFirstChild("NotifLabel")
		if notifLabel and notifFrame then
			notifLabel.Text     = "✅ Comprado: " .. tostring(newWeaponKey)
			notifFrame.Visible  = true
			task.delay(2, function()
				if notifFrame then notifFrame.Visible = false end
			end)
		end
	end
end)

UpdateCoins.OnClientEvent:Connect(function(coins)
	playerCoins = coins or 0
end)

-- ── Botón de apertura ─────────────────────────────────────────────────────────
local openBtn = Instance.new("TextButton")
openBtn.Name  = "ShopOpenButton"
openBtn.Size  = UDim2.new(0, 90, 0, 40)
openBtn.Position = UDim2.new(0, 10, 1, -60)
openBtn.Text  = "🛒 Tienda"
openBtn.TextColor3 = Color3.fromRGB(255,255,255)
openBtn.TextScaled = true
openBtn.Font  = Enum.Font.GothamBold
openBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 200)
openBtn.BorderSizePixel = 0
openBtn.ZIndex = 5
openBtn.Parent = playerGui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 10)

openBtn.MouseButton1Click:Connect(function()
	shopOpen = not shopOpen
	screenGui.Enabled = shopOpen
	if shopOpen then buildShop() end
end)
