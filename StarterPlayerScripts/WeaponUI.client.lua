-- StarterPlayerScripts/WeaponUI.client.lua
-- Panel de armas poseídas: nivel, upgrade, equipar

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local WeaponConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WeaponConfig"))

local RemoteEvents   = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpgradeWeapon  = RemoteEvents:WaitForChild("UpgradeWeapon")
local WeaponUpgraded = RemoteEvents:WaitForChild("WeaponUpgraded")
local EquipWeapon    = RemoteEvents:WaitForChild("EquipWeapon")
local WeaponBought   = RemoteEvents:WaitForChild("WeaponBought")

local ownedWeapons   = {}
local equippedWeapon = "EspadaMadera"
local panelOpen      = false

-- ── Crear UI ──────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "WeaponGui"
screenGui.ResetOnSpawn   = false
screenGui.Enabled        = false
screenGui.Parent         = playerGui

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 550, 0, 480)
panel.Position         = UDim2.new(0.5, -275, 0.5, -240)
panel.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
panel.BorderSizePixel  = 0
panel.Parent           = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)

local header = Instance.new("TextLabel")
header.Size   = UDim2.new(1, 0, 0, 50)
header.Text   = "⚔️ MIS ARMAS"
header.TextColor3 = Color3.fromRGB(200, 180, 255)
header.TextScaled = true
header.Font   = Enum.Font.GothamBold
header.BackgroundColor3 = Color3.fromRGB(40, 30, 70)
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
	panelOpen = false
end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size              = UDim2.new(1, -20, 1, -60)
scroll.Position          = UDim2.new(0, 10, 0, 55)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel   = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize        = UDim2.new(0, 0, 0, 0)
scroll.Parent            = panel

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder   = Enum.SortOrder.LayoutOrder
listLayout.Padding     = UDim.new(0, 8)
listLayout.Parent      = scroll

-- ── Construir lista de armas ──────────────────────────────────────────────────
local function buildWeaponList()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local count = 0
	for weaponKey, weaponData in pairs(ownedWeapons) do
		local wConfig = WeaponConfig[weaponKey]
		if not wConfig then continue end
		count += 1

		local level   = weaponData.level or 1
		local isEquip = equippedWeapon == weaponKey

		local row = Instance.new("Frame")
		row.Name              = weaponKey
		row.Size              = UDim2.new(1, 0, 0, 80)
		row.BackgroundColor3  = isEquip
			and Color3.fromRGB(30, 80, 30)
			or  Color3.fromRGB(25, 35, 60)
		row.BorderSizePixel   = 0
		row.Parent            = scroll
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

		-- Nombre
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size             = UDim2.new(0.4, 0, 0.5, 0)
		nameLabel.Position         = UDim2.new(0, 10, 0, 5)
		nameLabel.Text             = wConfig.name or weaponKey
		nameLabel.TextColor3       = Color3.fromRGB(255,255,255)
		nameLabel.TextScaled       = true
		nameLabel.Font             = Enum.Font.GothamBold
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextXAlignment   = Enum.TextXAlignment.Left
		nameLabel.Parent           = row

		-- Nivel y daño
		local statsLabel = Instance.new("TextLabel")
		statsLabel.Size           = UDim2.new(0.4, 0, 0.5, 0)
		statsLabel.Position       = UDim2.new(0, 10, 0.5, 0)
		local curDmg = WeaponConfig.getUpgradedDamage(weaponKey, level)
		local mult   = WeaponConfig.getMultiplier(level)
		statsLabel.Text           = string.format("Nivel %d | ⚔ %d dmg (x%.1f)", level, curDmg, mult)
		statsLabel.TextColor3     = Color3.fromRGB(180, 220, 255)
		statsLabel.TextScaled     = true
		statsLabel.Font           = Enum.Font.Gotham
		statsLabel.BackgroundTransparency = 1
		statsLabel.TextXAlignment = Enum.TextXAlignment.Left
		statsLabel.Parent         = row

		-- Botón equipar
		local equipBtn = Instance.new("TextButton")
		equipBtn.Name  = "EquipBtn_" .. weaponKey
		equipBtn.Size  = UDim2.new(0, 80, 0, 32)
		equipBtn.Position = UDim2.new(1, -190, 0.5, -16)
		equipBtn.Text  = isEquip and "✓ Equipada" or "Equipar"
		equipBtn.TextColor3 = Color3.fromRGB(255,255,255)
		equipBtn.TextScaled = true
		equipBtn.Font  = Enum.Font.Gotham
		equipBtn.BackgroundColor3 = isEquip
			and Color3.fromRGB(30, 130, 30)
			or  Color3.fromRGB(50, 80, 160)
		equipBtn.BorderSizePixel = 0
		equipBtn.Parent = row
		Instance.new("UICorner", equipBtn).CornerRadius = UDim.new(0, 8)

		if equipBtn then
			local capturedKey = weaponKey
			equipBtn.MouseButton1Click:Connect(function()
				EquipWeapon:FireServer(capturedKey)
				equippedWeapon = capturedKey
				buildWeaponList()
			end)
		end

		-- Botón upgrade
		local upgradeBtn = Instance.new("TextButton")
		upgradeBtn.Name = "UpgradeBtn_" .. weaponKey
		if level >= WeaponConfig.MAX_LEVEL then
			upgradeBtn.Text = "MAX"
			upgradeBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 20)
		else
			local cost = WeaponConfig.getUpgradeCost(weaponKey, level + 1)
			upgradeBtn.Text = "⬆ " .. tostring(cost) .. "💰"
			upgradeBtn.BackgroundColor3 = Color3.fromRGB(160, 100, 20)
		end
		upgradeBtn.Size  = UDim2.new(0, 100, 0, 32)
		upgradeBtn.Position = UDim2.new(1, -100, 0.5, -16)
		upgradeBtn.TextColor3 = Color3.fromRGB(255,255,255)
		upgradeBtn.TextScaled = true
		upgradeBtn.Font  = Enum.Font.Gotham
		upgradeBtn.BorderSizePixel = 0
		upgradeBtn.Parent = row
		Instance.new("UICorner", upgradeBtn).CornerRadius = UDim.new(0, 8)

		if upgradeBtn and level < WeaponConfig.MAX_LEVEL then
			local capturedKey = weaponKey
			upgradeBtn.MouseButton1Click:Connect(function()
				UpgradeWeapon:FireServer(capturedKey)
			end)
		end
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, count * 90)
end

-- Eventos del servidor
WeaponBought.OnClientEvent:Connect(function(newKey, allOwned)
	if allOwned then ownedWeapons = allOwned end
	if panelOpen then buildWeaponList() end
end)

WeaponUpgraded.OnClientEvent:Connect(function(weaponKey, newLevel, newDamage, newMult, allOwned)
	if allOwned then ownedWeapons = allOwned end
	if panelOpen then buildWeaponList() end
end)

-- ── Botón de apertura ─────────────────────────────────────────────────────────
local openBtn = Instance.new("TextButton")
openBtn.Name  = "WeaponOpenButton"
openBtn.Size  = UDim2.new(0, 90, 0, 40)
openBtn.Position = UDim2.new(0, 110, 1, -60)
openBtn.Text  = "⚔ Armas"
openBtn.TextColor3 = Color3.fromRGB(255,255,255)
openBtn.TextScaled = true
openBtn.Font  = Enum.Font.GothamBold
openBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 160)
openBtn.BorderSizePixel = 0
openBtn.ZIndex = 5
openBtn.Parent = playerGui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 10)

openBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	screenGui.Enabled = panelOpen
	if panelOpen then buildWeaponList() end
end)
