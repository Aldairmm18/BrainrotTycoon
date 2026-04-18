-- StarterPlayerScripts/HUD.client.lua
-- HUD principal: monedas, HP, XP, timer, notificaciones globales, botón de habilidad

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateCoins   = RemoteEvents:WaitForChild("UpdateCoins")
local TakeDamageRE  = RemoteEvents:WaitForChild("TakeDamage")
local UpdateXP      = RemoteEvents:WaitForChild("UpdateXP")
local TimerUpdate   = RemoteEvents:WaitForChild("TimerUpdate")
local GlobalNotif   = RemoteEvents:WaitForChild("GlobalNotif")
local AbilityUsed   = RemoteEvents:WaitForChild("AbilityUsed")
local UseAbility    = RemoteEvents:WaitForChild("UseAbility")
local LevelUp       = RemoteEvents:WaitForChild("LevelUp")

-- ── Crear HUD ──────────────────────────────────────────────────────────────────
local function createHUD()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name            = "HudGui"
	screenGui.ResetOnSpawn    = false
	screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
	screenGui.Parent          = playerGui

	-- ── Monedas ────────────────────────────────────────────────────────────────
	local coinsFrame = Instance.new("Frame")
	coinsFrame.Name             = "CoinsFrame"
	coinsFrame.Size             = UDim2.new(0, 160, 0, 45)
	coinsFrame.Position         = UDim2.new(0, 10, 0, 10)
	coinsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	coinsFrame.BackgroundTransparency = 0.3
	coinsFrame.BorderSizePixel  = 0
	coinsFrame.Parent           = screenGui
	Instance.new("UICorner", coinsFrame).CornerRadius = UDim.new(0, 10)

	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name            = "CoinsLabel"
	coinsLabel.Size            = UDim2.new(1, 0, 1, 0)
	coinsLabel.Text            = "💰 0"
	coinsLabel.TextColor3      = Color3.fromRGB(255, 220, 50)
	coinsLabel.TextScaled      = true
	coinsLabel.Font            = Enum.Font.GothamBold
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Parent          = coinsFrame

	-- ── HP Bar ──────────────────────────────────────────────────────────────────
	local hpFrame = Instance.new("Frame")
	hpFrame.Name              = "HPFrame"
	hpFrame.Size              = UDim2.new(0, 250, 0, 28)
	hpFrame.Position          = UDim2.new(0, 10, 0, 65)
	hpFrame.BackgroundColor3  = Color3.fromRGB(60, 0, 0)
	hpFrame.BorderSizePixel   = 0
	hpFrame.Parent            = screenGui
	Instance.new("UICorner", hpFrame).CornerRadius = UDim.new(0, 8)

	local hpBar = Instance.new("Frame")
	hpBar.Name              = "HPBar"
	hpBar.Size              = UDim2.new(1, 0, 1, 0)
	hpBar.BackgroundColor3  = Color3.fromRGB(200, 30, 30)
	hpBar.BorderSizePixel   = 0
	hpBar.Parent            = hpFrame
	Instance.new("UICorner", hpBar).CornerRadius = UDim.new(0, 8)

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Name             = "HPLabel"
	hpLabel.Size             = UDim2.new(1, 0, 1, 0)
	hpLabel.Text             = "HP: 100 / 100"
	hpLabel.TextColor3       = Color3.fromRGB(255, 255, 255)
	hpLabel.TextScaled       = true
	hpLabel.Font             = Enum.Font.GothamBold
	hpLabel.BackgroundTransparency = 1
	hpLabel.ZIndex           = 2
	hpLabel.Parent           = hpFrame

	-- ── XP Bar ──────────────────────────────────────────────────────────────────
	local xpFrame = Instance.new("Frame")
	xpFrame.Name              = "XPFrame"
	xpFrame.Size              = UDim2.new(0, 250, 0, 20)
	xpFrame.Position          = UDim2.new(0, 10, 0, 100)
	xpFrame.BackgroundColor3  = Color3.fromRGB(30, 30, 60)
	xpFrame.BorderSizePixel   = 0
	xpFrame.Parent            = screenGui
	Instance.new("UICorner", xpFrame).CornerRadius = UDim.new(0, 6)

	local xpBar = Instance.new("Frame")
	xpBar.Name              = "XPBar"
	xpBar.Size              = UDim2.new(0, 0, 1, 0)
	xpBar.BackgroundColor3  = Color3.fromRGB(80, 120, 255)
	xpBar.BorderSizePixel   = 0
	xpBar.Parent            = xpFrame
	Instance.new("UICorner", xpBar).CornerRadius = UDim.new(0, 6)

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name            = "LevelLabel"
	levelLabel.Size            = UDim2.new(0, 80, 0, 20)
	levelLabel.Position        = UDim2.new(0, 10, 0, 122)
	levelLabel.Text            = "Nivel 1"
	levelLabel.TextColor3      = Color3.fromRGB(200, 200, 255)
	levelLabel.TextScaled      = true
	levelLabel.Font            = Enum.Font.GothamBold
	levelLabel.BackgroundTransparency = 1
	levelLabel.Parent          = screenGui

	-- ── Timer ────────────────────────────────────────────────────────────────────
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name            = "TimerLabel"
	timerLabel.Size            = UDim2.new(0, 150, 0, 50)
	timerLabel.Position        = UDim2.new(0.5, -75, 0, 10)
	timerLabel.Text            = "⏱ 00:00"
	timerLabel.TextColor3      = Color3.fromRGB(255, 255, 255)
	timerLabel.TextScaled      = true
	timerLabel.Font            = Enum.Font.GothamBold
	timerLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	timerLabel.BackgroundTransparency = 0.4
	timerLabel.BorderSizePixel = 0
	timerLabel.Parent          = screenGui
	Instance.new("UICorner", timerLabel).CornerRadius = UDim.new(0, 10)

	-- ── Notificación global ────────────────────────────────────────────────────
	local notifFrame = Instance.new("Frame")
	notifFrame.Name              = "NotifFrame"
	notifFrame.Size              = UDim2.new(0, 400, 0, 50)
	notifFrame.Position          = UDim2.new(0.5, -200, 0, 70)
	notifFrame.BackgroundColor3  = Color3.fromRGB(40, 40, 40)
	notifFrame.BackgroundTransparency = 0.2
	notifFrame.BorderSizePixel   = 0
	notifFrame.Visible           = false
	notifFrame.Parent            = screenGui
	Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 10)

	local notifLabel = Instance.new("TextLabel")
	notifLabel.Name            = "NotifLabel"
	notifLabel.Size            = UDim2.new(1, 0, 1, 0)
	notifLabel.Text            = ""
	notifLabel.TextColor3      = Color3.fromRGB(255, 255, 150)
	notifLabel.TextScaled      = true
	notifLabel.Font            = Enum.Font.GothamBold
	notifLabel.BackgroundTransparency = 1
	notifLabel.Parent          = notifFrame

	-- ── Botón habilidad ────────────────────────────────────────────────────────
	local abilityBtn = Instance.new("TextButton")
	abilityBtn.Name            = "AbilityButton"
	abilityBtn.Size            = UDim2.new(0, 80, 0, 80)
	abilityBtn.Position        = UDim2.new(1, -100, 1, -110)
	abilityBtn.Text            = "E\nHabilidad"
	abilityBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
	abilityBtn.TextScaled      = true
	abilityBtn.Font            = Enum.Font.GothamBold
	abilityBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 160)
	abilityBtn.BorderSizePixel = 0
	abilityBtn.Parent          = screenGui
	Instance.new("UICorner", abilityBtn).CornerRadius = UDim.new(0, 16)

	-- Cooldown overlay
	local cdOverlay = Instance.new("Frame")
	cdOverlay.Name              = "CooldownOverlay"
	cdOverlay.Size              = UDim2.new(1, 0, 0, 0)
	cdOverlay.AnchorPoint       = Vector2.new(0, 1)
	cdOverlay.Position          = UDim2.new(0, 0, 1, 0)
	cdOverlay.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
	cdOverlay.BackgroundTransparency = 0.4
	cdOverlay.BorderSizePixel   = 0
	cdOverlay.Visible           = false
	cdOverlay.Parent            = abilityBtn
	Instance.new("UICorner", cdOverlay).CornerRadius = UDim.new(0, 16)

	return screenGui, {
		coinsLabel  = coinsLabel,
		hpBar       = hpBar,
		hpLabel     = hpLabel,
		xpBar       = xpBar,
		levelLabel  = levelLabel,
		timerLabel  = timerLabel,
		notifFrame  = notifFrame,
		notifLabel  = notifLabel,
		abilityBtn  = abilityBtn,
		cdOverlay   = cdOverlay,
	}
end

-- ── Formateadores ─────────────────────────────────────────────────────────────
local function formatCoins(n)
	if n >= 1e9 then return string.format("%.1fB", n/1e9)
	elseif n >= 1e6 then return string.format("%.1fM", n/1e6)
	elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
	else return tostring(math.floor(n)) end
end

local function formatTime(secs)
	secs = math.max(0, math.floor(secs))
	local m = math.floor(secs / 60)
	local s = secs % 60
	return string.format("%02d:%02d", m, s)
end

-- ── Init ──────────────────────────────────────────────────────────────────────
local gui, elements = createHUD()

-- HP tracking
local humanoid
local function trackHumanoid()
	local char = player.Character or player.CharacterAdded:Wait()
	humanoid   = char:WaitForChild("Humanoid")
	humanoid.HealthChanged:Connect(function(hp)
		if not elements.hpBar then return end
		local maxHP = humanoid.MaxHealth
		local pct   = math.clamp(hp / maxHP, 0, 1)
		elements.hpBar.Size   = UDim2.new(pct, 0, 1, 0)

		-- Color: verde→amarillo→rojo
		local r = math.floor(255 * (1 - pct))
		local g = math.floor(255 * pct)
		elements.hpBar.BackgroundColor3 = Color3.fromRGB(r + 50, g, 30)

		if elements.hpLabel then
			elements.hpLabel.Text = string.format("HP: %d / %d", math.floor(hp), math.floor(maxHP))
		end
	end)
end

player.CharacterAdded:Connect(trackHumanoid)
if player.Character then trackHumanoid() end

-- Monedas
UpdateCoins.OnClientEvent:Connect(function(coins)
	if elements.coinsLabel then
		elements.coinsLabel.Text = "💰 " .. formatCoins(coins or 0)
	end
end)

-- XP
UpdateXP.OnClientEvent:Connect(function(xp, maxXP, level)
	if elements.xpBar then
		local pct = maxXP > 0 and math.clamp(xp / maxXP, 0, 1) or 0
		elements.xpBar.Size = UDim2.new(pct, 0, 1, 0)
	end
	if elements.levelLabel then
		elements.levelLabel.Text = "Nivel " .. tostring(level or 1)
	end
end)

-- Timer
TimerUpdate.OnClientEvent:Connect(function(elapsed)
	if elements.timerLabel then
		elements.timerLabel.Text = "⏱ " .. formatTime(elapsed)
	end
end)

-- Notificación global
GlobalNotif.OnClientEvent:Connect(function(msg)
	if not elements.notifFrame or not elements.notifLabel then return end
	elements.notifLabel.Text = msg or ""
	elements.notifFrame.Visible = true
	task.delay(4, function()
		if elements.notifFrame then
			elements.notifFrame.Visible = false
		end
	end)
end)

-- Level up
LevelUp.OnClientEvent:Connect(function(level, bonusMsg)
	if not elements.notifFrame or not elements.notifLabel then return end
	elements.notifLabel.Text = "🎉 ¡LEVEL UP! → Nivel " .. tostring(level)
	elements.notifFrame.Visible = true
	task.delay(3, function()
		if elements.notifFrame then elements.notifFrame.Visible = false end
	end)
end)

-- Cooldown visual de habilidad
AbilityUsed.OnClientEvent:Connect(function(ability, cooldown)
	if not elements.cdOverlay then return end
	elements.cdOverlay.Visible = true
	elements.cdOverlay.Size    = UDim2.new(1, 0, 1, 0)

	local startTime = os.clock()
	task.spawn(function()
		while true do
			task.wait(0.05)
			local elapsed  = os.clock() - startTime
			local remaining = 1 - (elapsed / cooldown)
			if remaining <= 0 then break end
			if elements.cdOverlay then
				elements.cdOverlay.Size = UDim2.new(1, 0, remaining, 0)
			end
		end
		if elements.cdOverlay then
			elements.cdOverlay.Visible = false
		end
	end)
end)

-- Botón de habilidad
if elements.abilityBtn then
	elements.abilityBtn.MouseButton1Click:Connect(function()
		UseAbility:FireServer()
	end)
	-- Tecla E
	game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.E then
			UseAbility:FireServer()
		end
	end)
end
