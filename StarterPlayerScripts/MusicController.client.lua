-- MusicController (LocalScript)
-- StarterPlayerScripts/MusicController
-- Background music with 🎵 toggle button.

local Players      = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─── ScreenGui ────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "MusicUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

-- ─── Music Tracks ────────────────────────────────────────────────────────────
local TRACKS = {
	{ id = 142376088,  name = "Zona Italiana" },      -- Roblox: Regroup (free-to-use)
	{ id = 1843827228, name = "Volcan Romano" },
	{ id = 1842388270, name = "Cosmos Brainrot" },
}

-- ─── Sound Instance ───────────────────────────────────────────────────────────
local bgSound = Instance.new("Sound")
bgSound.SoundId  = "rbxassetid://" .. tostring(TRACKS[1].id)
bgSound.Volume   = 0.3
bgSound.Looped   = true
bgSound.Parent   = SoundService
bgSound:Play()

-- ─── 🎵 Toggle Button ────────────────────────────────────────────────────────
local musicBtn = Instance.new("TextButton")
musicBtn.Name             = "MusicBtn"
musicBtn.Size             = UDim2.new(0, 52, 0, 44)
musicBtn.Position         = UDim2.new(1, -68, 1, -66)
musicBtn.BackgroundColor3 = Color3.fromRGB(20, 18, 40)
musicBtn.BorderSizePixel  = 0
musicBtn.Text             = "🎵"
musicBtn.TextScaled       = true
musicBtn.Font             = Enum.Font.GothamBold
musicBtn.AutoButtonColor  = false
musicBtn.Parent           = screenGui
Instance.new("UICorner", musicBtn).CornerRadius = UDim.new(0, 14)

local musicStroke = Instance.new("UIStroke")
musicStroke.Color     = Color3.fromRGB(80, 60, 160)
musicStroke.Thickness = 1.5
musicStroke.Parent    = musicBtn

local musicEnabled = true

musicBtn.MouseButton1Click:Connect(function()
	musicEnabled = not musicEnabled
	if musicEnabled then
		bgSound:Play()
		musicBtn.Text = "🎵"
		musicStroke.Color = Color3.fromRGB(80, 60, 160)
	else
		bgSound:Stop()
		musicBtn.Text = "🔇"
		musicStroke.Color = Color3.fromRGB(100, 40, 40)
	end
end)

-- Zone-based track switch (poll position every 5 seconds)
task.spawn(function()
	while true do
		task.wait(5)
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local x = hrp.Position.X
				local trackIndex
				if x >= 600 then trackIndex = 3
				elseif x >= 300 then trackIndex = 2
				else trackIndex = 1 end

				local newId = "rbxassetid://" .. tostring(TRACKS[trackIndex].id)
				if bgSound.SoundId ~= newId and musicEnabled then
					TweenService:Create(bgSound, TweenInfo.new(1), {Volume = 0}):Play()
					task.wait(1)
					bgSound.SoundId = newId
					bgSound:Play()
					TweenService:Create(bgSound, TweenInfo.new(1), {Volume = 0.3}):Play()
				end
			end
		end
	end
end)
