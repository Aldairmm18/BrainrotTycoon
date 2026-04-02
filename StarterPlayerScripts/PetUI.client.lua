-- PetUI (LocalScript)
-- StarterPlayerScripts/PetUI
-- 🐾 Panel to view pet inventory, equip/unequip, and buy Pet Eggs.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PetUpdate    = RemoteEvents:WaitForChild("PetUpdate")
local EquipPet     = RemoteEvents:WaitForChild("EquipPet")
local UnequipPet   = RemoteEvents:WaitForChild("UnequipPet")
local BuyPetEgg    = RemoteEvents:WaitForChild("BuyPetEgg")

-- ─── ScreenGui ────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "PetUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

-- ─── Pet Egg Button (bottom, left of Buy Egg) ─────────────────────────────────
local petEggBtn = Instance.new("TextButton")
petEggBtn.Name             = "PetEggButton"
petEggBtn.Size             = UDim2.new(0, 200, 0, 60)
petEggBtn.Position         = UDim2.new(0.5, -320, 1, -80)
petEggBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 200)
petEggBtn.BorderSizePixel  = 0
petEggBtn.Text             = "🐾 Pet Egg  $2000"
petEggBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
petEggBtn.TextScaled       = true
petEggBtn.Font             = Enum.Font.GothamBold
petEggBtn.AutoButtonColor  = false
petEggBtn.Parent           = screenGui
Instance.new("UICorner", petEggBtn).CornerRadius = UDim.new(0, 16)

petEggBtn.MouseEnter:Connect(function()
	TweenService:Create(petEggBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(150, 90, 240)}):Play()
end)
petEggBtn.MouseLeave:Connect(function()
	TweenService:Create(petEggBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(120, 60, 200)}):Play()
end)

petEggBtn.MouseButton1Click:Connect(function()
	petEggBtn.Text   = "⏳ Abriendo..."
	petEggBtn.Active = false
	BuyPetEgg:FireServer()
	task.wait(1)
	petEggBtn.Text   = "🐾 Pet Egg  $2000"
	petEggBtn.Active = true
end)

-- ─── 🐾 Panel Toggle Button ───────────────────────────────────────────────────
local petsBtn = Instance.new("TextButton")
petsBtn.Name             = "PetsToggleBtn"
petsBtn.Size             = UDim2.new(0, 100, 0, 50)
petsBtn.Position         = UDim2.new(1, -242, 1, -66)
petsBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 140)
petsBtn.BorderSizePixel  = 0
petsBtn.Text             = "🐾 Pets"
petsBtn.TextColor3       = Color3.fromRGB(230, 210, 255)
petsBtn.TextScaled       = true
petsBtn.Font             = Enum.Font.GothamBold
petsBtn.AutoButtonColor  = false
petsBtn.Parent           = screenGui
Instance.new("UICorner", petsBtn).CornerRadius = UDim.new(0, 16)

-- ─── Pet Panel ────────────────────────────────────────────────────────────────
local PANEL_W, PANEL_H = 340, 420

local panel = Instance.new("Frame")
panel.Size                   = UDim2.new(0, PANEL_W, 0, PANEL_H)
panel.Position               = UDim2.new(1, -(PANEL_W + 16), 1, -(PANEL_H + 72))
panel.BackgroundColor3       = Color3.fromRGB(12, 8, 30)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel        = 0
panel.Visible                = false
panel.ZIndex                 = 20
panel.Parent                 = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color     = Color3.fromRGB(130, 60, 220)
panelStroke.Thickness = 2
panelStroke.Parent    = panel

local titleLbl = Instance.new("TextLabel")
titleLbl.Size                  = UDim2.new(1, -16, 0, 44)
titleLbl.Position              = UDim2.new(0, 8, 0, 6)
titleLbl.BackgroundTransparency = 1
titleLbl.Text                  = "🐾  Mis Mascotas"
titleLbl.TextColor3            = Color3.fromRGB(200, 160, 255)
titleLbl.TextScaled            = true
titleLbl.Font                  = Enum.Font.GothamBold
titleLbl.ZIndex                = 21
titleLbl.Parent                = panel

local equippedLbl = Instance.new("TextLabel")
equippedLbl.Name                   = "EquippedLabel"
equippedLbl.Size                   = UDim2.new(1, -16, 0, 28)
equippedLbl.Position               = UDim2.new(0, 8, 0, 52)
equippedLbl.BackgroundTransparency = 1
equippedLbl.Text                   = "Equipada: ninguna"
equippedLbl.TextColor3             = Color3.fromRGB(140, 130, 180)
equippedLbl.TextScaled             = true
equippedLbl.Font                   = Enum.Font.Gotham
equippedLbl.ZIndex                 = 21
equippedLbl.Parent                 = panel

-- Scroll for inventory
local scroll = Instance.new("ScrollingFrame")
scroll.Size                   = UDim2.new(1, -10, 1, -90)
scroll.Position               = UDim2.new(0, 5, 0, 86)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel        = 0
scroll.ScrollBarThickness     = 4
scroll.ScrollBarImageColor3   = Color3.fromRGB(130, 60, 220)
scroll.ZIndex                 = 21
scroll.Parent                 = panel

local grid = Instance.new("UIGridLayout")
grid.CellSize    = UDim2.new(0, 96, 0, 96)
grid.CellPadding = UDim2.new(0, 8, 0, 8)
grid.Parent      = scroll

local gridPad = Instance.new("UIPadding")
gridPad.PaddingAll = UDim.new(0, 6)
gridPad.Parent     = scroll

-- ─── Rarity pet colors ────────────────────────────────────────────────────────
local PET_RARITY_COLORS = {
	Common    = Color3.fromRGB(130, 130, 130),
	Uncommon  = Color3.fromRGB(80, 140, 255),
	Rare      = Color3.fromRGB(40, 190, 110),
	Epic      = Color3.fromRGB(150, 80, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
}

-- ─── Build inventory cards ────────────────────────────────────────────────────
local _equippedIndex = nil

local function buildInventory(inventory, equipped)
	-- Clear existing cards
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
	end

	if #inventory == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size                   = UDim2.new(1, -12, 0, 60)
		empty.Position               = UDim2.new(0, 6, 0, 0)
		empty.BackgroundTransparency = 1
		empty.Text                   = "¡Aún no tienes mascotas!\nCompra un Pet Egg 🐾"
		empty.TextColor3             = Color3.fromRGB(140, 130, 180)
		empty.TextScaled             = true
		empty.Font                   = Enum.Font.Gotham
		empty.ZIndex                 = 22
		empty.Parent                 = scroll
		return
	end

	for i, pet in ipairs(inventory) do
		local isEquipped = equipped and equipped.name == pet.name

		local card = Instance.new("TextButton")
		card.Size             = UDim2.new(0, 96, 0, 96)
		card.BackgroundColor3 = PET_RARITY_COLORS[pet.rarity] or Color3.fromRGB(90, 80, 130)
		card.BackgroundTransparency = isEquipped and 0.1 or 0.45
		card.BorderSizePixel  = 0
		card.Text             = ""
		card.ZIndex           = 22
		card.Parent           = scroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

		if isEquipped then
			local glow = Instance.new("UIStroke")
			glow.Color     = PET_RARITY_COLORS[pet.rarity] or Color3.fromRGB(255, 255, 255)
			glow.Thickness = 2.5
			glow.Parent    = card
		end

		local emojiLbl = Instance.new("TextLabel")
		emojiLbl.Size                   = UDim2.new(1, 0, 0.55, 0)
		emojiLbl.BackgroundTransparency = 1
		emojiLbl.Text                   = pet.emoji
		emojiLbl.TextScaled             = true
		emojiLbl.ZIndex                 = 23
		emojiLbl.Parent                 = card

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size                   = UDim2.new(1, -4, 0.28, 0)
		nameLbl.Position               = UDim2.new(0, 2, 0.55, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text                   = pet.name
		nameLbl.TextScaled             = true
		nameLbl.Font                   = Enum.Font.GothamBold
		nameLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
		nameLbl.ZIndex                 = 23
		nameLbl.Parent                 = card

		local pctLbl = Instance.new("TextLabel")
		pctLbl.Size                   = UDim2.new(1, 0, 0.17, 0)
		pctLbl.Position               = UDim2.new(0, 0, 0.83, 0)
		pctLbl.BackgroundTransparency = 1
		pctLbl.Text                   = ("+" .. math.floor(pet.multiplier * 100) .. "%") 
		pctLbl.TextScaled             = true
		pctLbl.Font                   = Enum.Font.Gotham
		pctLbl.TextColor3             = Color3.fromRGB(180, 255, 180)
		pctLbl.ZIndex                 = 23
		pctLbl.Parent                 = card

		local idx = i
		card.MouseButton1Click:Connect(function()
			if isEquipped then
				UnequipPet:FireServer()
			else
				EquipPet:FireServer(idx)
			end
		end)
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 12)

	equippedLbl.Text = equipped
		and ("Equipada: " .. equipped.emoji .. " " .. equipped.name .. "  +" .. math.floor((equipped.multiplier or 0)*100) .. "%💰")
		or "Equipada: ninguna"
end

PetUpdate.OnClientEvent:Connect(function(inventory, equipped, newPet)
	buildInventory(inventory, equipped)

	-- Show toast for new pet
	if newPet then
		local notifGui = playerGui:FindFirstChild("NotificationsUI")
		-- Simple inline toast
		local lbl = Instance.new("TextLabel")
		lbl.Size                   = UDim2.new(0, 280, 0, 52)
		lbl.Position               = UDim2.new(1, -(280+14), 0, 14)
		lbl.BackgroundColor3       = Color3.fromRGB(12, 10, 28)
		lbl.BackgroundTransparency = 0.1
		lbl.BorderSizePixel        = 0
		lbl.Text                   = "🐾 " .. newPet.emoji .. " " .. newPet.name .. " ¡obtenido!"
		lbl.TextColor3             = Color3.fromRGB(200, 180, 255)
		lbl.TextScaled             = true
		lbl.Font                   = Enum.Font.GothamBold
		lbl.ZIndex                 = 40
		lbl.Parent                 = screenGui
		Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 14)
		game:GetService("Debris"):AddItem(lbl, 3.5)
	end
end)

-- ─── Toggle ───────────────────────────────────────────────────────────────────
local panelOpen = false

petsBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	if panelOpen then
		panel.Visible = true
		panel.Size = UDim2.new(0, PANEL_W, 0, 0)
		TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
		}):Play()
	else
		TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, PANEL_W, 0, 0)
		}):Play()
		task.delay(0.2, function() panel.Visible = false end)
	end
end)
