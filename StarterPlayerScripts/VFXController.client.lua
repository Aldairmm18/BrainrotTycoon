-- VFXController (LocalScript)
-- StarterPlayerScripts/VFXController
-- Handles screen flash + particle effects when a rare+ brainrot is obtained.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local SoundService      = game:GetService("SoundService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GachaResult = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GachaResult")
local RebornResult = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RebornResult")

-- ─── Sounds ───────────────────────────────────────────────────────────────────
local function playSound(assetId, volume)
	local s = Instance.new("Sound")
	s.SoundId    = "rbxassetid://" .. tostring(assetId)
	s.Volume     = volume or 0.6
	s.RollOffMaxDistance = 0
	s.Parent     = SoundService
	s:Play()
	game:GetService("Debris"):AddItem(s, 8)
end

-- ─── ScreenGui for VFX ────────────────────────────────────────────────────────
local vfxGui = Instance.new("ScreenGui")
vfxGui.Name           = "VFXGui"
vfxGui.ResetOnSpawn   = false
vfxGui.IgnoreGuiInset = true
vfxGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
vfxGui.Parent         = playerGui

-- ─── Flash overlay ────────────────────────────────────────────────────────────
local flashFrame = Instance.new("Frame")
flashFrame.Name                   = "Flash"
flashFrame.Size                   = UDim2.new(1, 0, 1, 0)
flashFrame.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
flashFrame.BackgroundTransparency = 1
flashFrame.BorderSizePixel        = 0
flashFrame.ZIndex                 = 50
flashFrame.Parent                 = vfxGui

-- ─── Big rarity text ─────────────────────────────────────────────────────────
local rarityText = Instance.new("TextLabel")
rarityText.Size                   = UDim2.new(0.8, 0, 0, 80)
rarityText.Position               = UDim2.new(0.1, 0, 0.3, 0)
rarityText.BackgroundTransparency = 1
rarityText.Text                   = ""
rarityText.Font                   = Enum.Font.GothamBold
rarityText.TextSize               = 72
rarityText.TextColor3             = Color3.fromRGB(255, 255, 255)
rarityText.TextStrokeTransparency = 0.1
rarityText.ZIndex                 = 51
rarityText.Visible                = false
rarityText.Parent                 = vfxGui

-- ─── Particle stars (simple label emulation) ──────────────────────────────────
local function spawnStar(color)
	local star = Instance.new("TextLabel")
	star.Size                   = UDim2.new(0, 32, 0, 32)
	star.Position               = UDim2.new(math.random(10, 90) / 100, 0, math.random(10, 90) / 100, 0)
	star.BackgroundTransparency = 1
	star.Text                   = "⭐"
	star.TextColor3             = color
	star.TextScaled             = true
	star.ZIndex                 = 52
	star.Parent                 = vfxGui

	TweenService:Create(star, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(star.Position.X.Scale, 0, star.Position.Y.Scale - 0.25, 0),
		TextTransparency = 1,
		Size = UDim2.new(0, 64, 0, 64),
	}):Play()

	game:GetService("Debris"):AddItem(star, 1.3)
end

-- ─── Rarity VFX config ────────────────────────────────────────────────────────
local RARITY_VFX = {
	Rare      = { flashColor = Color3.fromRGB(50, 255, 120),  flashAlpha = 0.7, stars = 8,  shake = false, soundId = 4590662766 },
	Epic      = { flashColor = Color3.fromRGB(160, 60, 255),  flashAlpha = 0.65, stars = 12, shake = false, soundId = 4849897432 },
	Legendary = { flashColor = Color3.fromRGB(255, 200, 0),   flashAlpha = 0.6, stars = 18, shake = false, soundId = 4849897432 },
	Mythic    = { flashColor = Color3.fromRGB(255, 80, 20),   flashAlpha = 0.58, stars = 24, shake = true,  soundId = 4849897432 },
	Secret    = { flashColor = Color3.fromRGB(255, 50, 200),  flashAlpha = 0.55, stars = 35, shake = true,  soundId = 4849897432 },
}

-- ─── Screen shake ─────────────────────────────────────────────────────────────
local function screenShake()
	for i = 1, 10 do
		local dx = math.random(-8, 8)
		local dy = math.random(-8, 8)
		vfxGui.Parent.CurrentCamera.CFrame = vfxGui.Parent.CurrentCamera.CFrame
			* CFrame.new(dx * 0.005, dy * 0.005, 0)
		task.wait(0.04)
	end
end

-- ─── Flash + Stars ────────────────────────────────────────────────────────────
local function doVFX(rarity, label)
	local cfg = RARITY_VFX[rarity]
	if not cfg then return end

	-- Play sound
	playSound(cfg.soundId, 0.7)

	-- Flash
	flashFrame.BackgroundColor3 = cfg.flashColor
	TweenService:Create(flashFrame, TweenInfo.new(0.1), {BackgroundTransparency = cfg.flashAlpha}):Play()
	task.wait(0.1)
	TweenService:Create(flashFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()

	-- Stars
	for _ = 1, cfg.stars do
		task.spawn(spawnStar, cfg.flashColor)
		task.wait(0.03)
	end

	-- Big rarity label pop-in
	if label then
		rarityText.Text          = label
		rarityText.TextColor3    = cfg.flashColor
		rarityText.TextTransparency = 1
		rarityText.Visible       = true
		rarityText.Size          = UDim2.new(0.8, 0, 0, 20)
		rarityText.Position      = UDim2.new(0.1, 0, 0.35, 0)

		TweenService:Create(rarityText, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextTransparency = 0,
			Size = UDim2.new(0.8, 0, 0, 80),
			Position = UDim2.new(0.1, 0, 0.28, 0),
		}):Play()
		task.wait(1.5)
		TweenService:Create(rarityText, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
		task.wait(0.4)
		rarityText.Visible = false
	end

	-- Screen shake for Mythic / Secret
	if cfg.shake then
		task.spawn(screenShake)
	end
end

-- ─── Listen to GachaResult ────────────────────────────────────────────────────
local TRIGGER_RARITIES = { Rare=true, Epic=true, Legendary=true, Mythic=true, Secret=true }

GachaResult.OnClientEvent:Connect(function(data)
	if TRIGGER_RARITIES[data.rarity] then
		task.spawn(doVFX, data.rarity, ("✨ " .. data.rarity:upper() .. "! ✨"))
	else
		-- Still play a little sound for Common/Uncommon
		playSound(4590662766, 0.4)
	end
end)

-- ─── Rebirth VFX ─────────────────────────────────────────────────────────────
RebornResult.OnClientEvent:Connect(function(resultData)
	playSound(6042053626, 0.8)
	task.spawn(doVFX, "Secret", ("🔄 ¡RENACIDO! x" .. tostring(resultData.rebirths)))
end)
