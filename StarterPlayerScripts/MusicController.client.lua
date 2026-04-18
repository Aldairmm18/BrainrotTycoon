-- StarterPlayerScripts/MusicController.client.lua
-- Música de fondo por zona con transición suave y toggle

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local ZoneUnlocked  = RemoteEvents:WaitForChild("ZoneUnlocked")
local GlobalNotif   = RemoteEvents:WaitForChild("GlobalNotif")

-- IDs de música por zona (reemplazar con IDs reales de Roblox)
local MUSIC_IDS = {
	[0]   = 0,   -- Base (sin música o música suave)
	[1]   = 0,   -- Zona 1: Aventura
	[2]   = 0,   -- Zona 2: Tensión
	[3]   = 0,   -- Zona 3: Intensa
	[4]   = 0,   -- Zona 4: Épica
	blood = 0,   -- Blood Moon: Dramática
}

local musicEnabled  = true
local currentSound  = nil
local currentZone   = 1
local isBloodMoon   = false

-- ── Reproducir música ─────────────────────────────────────────────────────────
local function playMusic(zoneIndex)
	-- Fade out música anterior
	if currentSound then
		local prevSound = currentSound
		local startVol  = prevSound.Volume
		task.spawn(function()
			local steps = 20
			for i = 1, steps do
				task.wait(0.05)
				if prevSound and prevSound.Parent then
					prevSound.Volume = startVol * (1 - i/steps)
				end
			end
			if prevSound and prevSound.Parent then
				prevSound:Stop()
				prevSound:Destroy()
			end
		end)
	end

	if not musicEnabled then return end

	local id = isBloodMoon and MUSIC_IDS.blood or (MUSIC_IDS[zoneIndex] or 0)
	if id == 0 then return end  -- Sin ID configurado

	local sound = Instance.new("Sound")
	sound.SoundId    = "rbxassetid://" .. tostring(id)
	sound.Volume     = 0
	sound.Looped     = true
	sound.Parent     = SoundService

	currentSound = sound
	sound:Play()

	-- Fade in
	task.spawn(function()
		for i = 1, 20 do
			task.wait(0.05)
			if sound and sound.Parent then
				sound.Volume = 0.5 * (i/20)
			end
		end
	end)
end

-- ── Toggle de música ──────────────────────────────────────────────────────────
local function toggleMusic()
	musicEnabled = not musicEnabled
	if musicEnabled then
		playMusic(currentZone)
		return true
	else
		if currentSound then
			currentSound:Stop()
		end
		return false
	end
end

-- ── Blood Moon event ──────────────────────────────────────────────────────────
GlobalNotif.OnClientEvent:Connect(function(msg)
	if msg and msg:find("BLOOD MOON") then
		isBloodMoon = true
		playMusic(currentZone)  -- Cambiar a música de Blood Moon
	end
end)

-- ── Detectar zona del jugador (basado en posición) ────────────────────────────
-- Simplificado: cambiar música cuando ZoneUnlocked se dispara
ZoneUnlocked.OnClientEvent:Connect(function(zoneIndex)
	currentZone = zoneIndex
	playMusic(zoneIndex)
end)

-- ── Botón toggle ──────────────────────────────────────────────────────────────
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name   = "MusicToggleBtn"
toggleBtn.Size   = UDim2.new(0, 40, 0, 40)
toggleBtn.Position = UDim2.new(1, -50, 0, 60)
toggleBtn.Text   = "🎵"
toggleBtn.TextScaled = true
toggleBtn.Font   = Enum.Font.GothamBold
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
toggleBtn.BackgroundTransparency = 0.3
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 5
toggleBtn.Parent = playerGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)

toggleBtn.MouseButton1Click:Connect(function()
	local isOn = toggleMusic()
	if toggleBtn then
		toggleBtn.Text            = isOn and "🎵" or "🔇"
		toggleBtn.BackgroundColor3 = isOn
			and Color3.fromRGB(30, 30, 50)
			or  Color3.fromRGB(80, 20, 20)
	end
end)

-- Iniciar música de la zona base al cargar
task.wait(2)
playMusic(1)
