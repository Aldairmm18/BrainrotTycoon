-- FusionUI (LocalScript)
-- StarterPlayerScripts/FusionUI
-- Implements a collapsible panel where players can sacrifice 3 Brainrots
-- of lower rarity to obtain 1 of the next tier.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player       = Players.LocalPlayer
local playerGui    = player:WaitForChild("PlayerGui")

local RE          = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local FuseRequest = RE:WaitForChild("FuseRequest")
local FuseResult  = RE:WaitForChild("FuseResult")

-- ─── ScreenGui ────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name           = "FusionUI"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = playerGui

-- ─── Bottom-left toggle button ────────────────────────────────────────────────
local fuseToggle = Instance.new("TextButton")
fuseToggle.Name             = "ToggleBtn"
fuseToggle.Size             = UDim2.new(0, 110, 0, 44)
-- Positioned near the bottom-left corner with some padding
fuseToggle.Position         = UDim2.new(0, 16, 1, -120)
fuseToggle.BackgroundColor3 = Color3.fromRGB(80, 20, 140)
fuseToggle.BorderSizePixel  = 0
fuseToggle.Text             = "⚗️ Fusión"
fuseToggle.TextColor3       = Color3.fromRGB(240, 240, 240)
fuseToggle.TextScaled       = true
fuseToggle.Font             = Enum.Font.GothamBold
fuseToggle.AutoButtonColor  = false
fuseToggle.Parent           = gui
Instance.new("UICorner", fuseToggle).CornerRadius = UDim.new(0, 10)

local fuseStroke = Instance.new("UIStroke")
fuseStroke.Color           = Color3.fromRGB(160, 100, 255)
fuseStroke.Thickness       = 1.5
fuseStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
fuseStroke.Parent          = fuseToggle

fuseToggle.MouseEnter:Connect(function()
	TweenService:Create(fuseToggle, TweenInfo.new(0.1),
		{ BackgroundColor3 = Color3.fromRGB(100, 30, 170) }):Play()
end)
fuseToggle.MouseLeave:Connect(function()
	TweenService:Create(fuseToggle, TweenInfo.new(0.1),
		{ BackgroundColor3 = Color3.fromRGB(80, 20, 140) }):Play()
end)

-- ─── Main panel ───────────────────────────────────────────────────────────────
local panel = Instance.new("Frame")
panel.Name                   = "FusionPanel"
panel.Size                   = UDim2.new(0, 280, 0, 0) -- tweened Open
panel.Position               = UDim2.new(0.5, -140, 0.5, -190)
panel.BackgroundColor3       = Color3.fromRGB(18, 6, 32)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel        = 0
panel.Visible                = false
panel.ClipsDescendants       = true
panel.ZIndex                 = 20
panel.Parent                 = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color     = Color3.fromRGB(160, 100, 255)
panelStroke.Thickness = 2
panelStroke.Parent    = panel

-- Headers
local title = Instance.new("TextLabel")
title.Name                   = "Title"
title.Size                   = UDim2.new(1, -16, 0, 36)
title.Position               = UDim2.new(0, 8, 0, 8)
title.BackgroundTransparency = 1
title.Text                   = "⚗️ Fusión de Brainrots"
title.TextColor3             = Color3.fromRGB(220, 170, 255)
title.TextScaled             = true
title.Font                   = Enum.Font.GothamBold
title.ZIndex                 = 21
title.Parent                 = panel

local desc = Instance.new("TextLabel")
desc.Name                    = "Description"
desc.Size                    = UDim2.new(1, -24, 0, 32)
desc.Position                = UDim2.new(0, 12, 0, 44)
desc.BackgroundTransparency  = 1
desc.Text                    = "Combina 3 iguales para obtener uno de la siguiente rareza."
desc.TextColor3              = Color3.fromRGB(180, 180, 180)
desc.TextScaled              = true
desc.TextWrapped             = true
desc.Font                    = Enum.Font.Gotham
desc.ZIndex                  = 21
desc.Parent                  = panel

-- ─── Rarity buttons ───────────────────────────────────────────────────────────
local rarities = {
	{ name="Common",   next="Uncommon",  color=Color3.fromRGB(180,180,180) },
	{ name="Uncommon", next="Rare",      color=Color3.fromRGB(100,160,255) },
	{ name="Rare",     next="Epic",      color=Color3.fromRGB(50,200,120)  },
	{ name="Epic",     next="Legendary", color=Color3.fromRGB(160,100,255) },
	{ name="Legendary",next="Mythic",    color=Color3.fromRGB(255,180,0)   },
	{ name="Mythic",   next="Secret",    color=Color3.fromRGB(255,80,40)   },
}

for i, r in ipairs(rarities) do
	local b = Instance.new("TextButton")
	b.Name             = "Fuse" .. r.name
	b.Size             = UDim2.new(1, -24, 0, 34)
	b.Position         = UDim2.new(0, 12, 0, 82 + (i - 1) * 40)
	b.BackgroundColor3 = Color3.fromRGB(30, 12, 50)
	b.BorderSizePixel  = 0
	b.Text             = ("3× %s  →  %s"):format(r.name, r.next)
	b.TextColor3       = r.color
	b.TextScaled       = true
	b.Font             = Enum.Font.GothamBold
	b.AutoButtonColor  = false
	b.ZIndex           = 22
	b.Parent           = panel
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	
	local str = Instance.new("UIStroke")
	str.Color = Color3.fromRGB(45, 18, 75)
	str.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	str.Parent = b

	-- Hover
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.1),
			{ BackgroundColor3 = Color3.fromRGB(45, 18, 75) }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.1),
			{ BackgroundColor3 = Color3.fromRGB(30, 12, 50) }):Play()
	end)

	b.MouseButton1Click:Connect(function()
		-- Shrink + hide panel
		TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Sine),
			{ Size = UDim2.new(0, 280, 0, 0) }):Play()
		task.delay(0.3, function() panel.Visible = false end)
		
		FuseRequest:FireServer(r.name)
	end)
end

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Name             = "CloseBtn"
closeBtn.Size             = UDim2.new(1, -24, 0, 34)
closeBtn.Position         = UDim2.new(0, 12, 0, 330)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 15, 20)
closeBtn.BorderSizePixel  = 0
closeBtn.Text             = "Cerrar"
closeBtn.TextColor3       = Color3.fromRGB(255, 120, 120)
closeBtn.TextScaled       = true
closeBtn.Font             = Enum.Font.Gotham
closeBtn.ZIndex           = 22
closeBtn.Parent           = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

closeBtn.MouseButton1Click:Connect(function()
	TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Sine),
		{ Size = UDim2.new(0, 280, 0, 0) }):Play()
	task.delay(0.3, function() panel.Visible = false end)
end)

-- Toggle click
fuseToggle.MouseButton1Click:Connect(function()
	if panel.Visible then
		TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Sine),
			{ Size = UDim2.new(0, 280, 0, 0) }):Play()
		task.delay(0.3, function() panel.Visible = false end)
	else
		panel.Size = UDim2.new(0, 280, 0, 0)
		panel.Visible = true
		TweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = UDim2.new(0, 280, 0, 376) }):Play()
	end
end)

-- ─── Result handling ──────────────────────────────────────────────────────────

FuseResult.OnClientEvent:Connect(function(success, message, resultBrot)
	-- Show toast (using custom animated toast here to not disrupt others)
	local toast = Instance.new("TextLabel")
	toast.Size                   = UDim2.new(0, 300, 0, 50)
	toast.Position               = UDim2.new(0.5, -150, 0.4, 0)
	toast.BackgroundColor3       = success and Color3.fromRGB(30, 80, 40) or Color3.fromRGB(80, 30, 30)
	toast.BackgroundTransparency = 1 -- animate in
	toast.BorderSizePixel        = 0
	toast.Text                   = (success and "✅ " or "❌ ") .. message
	toast.TextColor3             = Color3.fromRGB(255, 255, 255)
	toast.TextStrokeTransparency = 0.5
	toast.TextTransparency       = 1 -- animate in
	toast.TextScaled             = true
	toast.Font                   = Enum.Font.GothamBold
	toast.ZIndex                 = 60
	toast.Parent                 = gui
	Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 10)

	local sT = Instance.new("UIStroke")
	sT.Color = success and Color3.fromRGB(60, 200, 80) or Color3.fromRGB(200, 60, 60)
	sT.Thickness = 2
	sT.Transparency = 1
	sT.Parent = toast

	-- Pop in
	toast.Position = UDim2.new(0.5, -150, 0.45, 0)
	TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -150, 0.4, 0),
		BackgroundTransparency = 0.1,
		TextTransparency       = 0
	}):Play()
	TweenService:Create(sT, TweenInfo.new(0.4), { Transparency = 0 }):Play()

	-- Celebration flash if successful
	if success then
		local flash = Instance.new("Frame")
		flash.Size = UDim2.new(1, 0, 1, 0)
		flash.BackgroundColor3 = Color3.fromRGB(160, 100, 255)
		flash.BackgroundTransparency = 0.2
		flash.BorderSizePixel = 0
		flash.ZIndex = 50
		flash.Parent = gui

		TweenService:Create(flash, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }):Play()
		task.delay(0.6, function() flash:Destroy() end)
	end

	-- Fade out toast
	task.delay(3, function()
		TweenService:Create(toast, TweenInfo.new(0.4), {
			BackgroundTransparency = 1,
			TextTransparency       = 1
		}):Play()
		TweenService:Create(sT, TweenInfo.new(0.4), { Transparency = 1 }):Play()
		task.delay(0.4, function() toast:Destroy() end)
	end)
end)
