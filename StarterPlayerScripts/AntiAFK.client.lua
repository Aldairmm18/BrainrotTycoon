-- StarterPlayerScripts/AntiAFK.client.lua
-- Mueve la cámara levemente cada 4 minutos para evitar kick AFK
-- Detecta inactividad y da bonus al volver

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AFK_MOVEMENT_INTERVAL = 240  -- 4 minutos
local INACTIVITY_THRESHOLD  = 300  -- 5 minutos sin input = inactivo

local lastInputTime  = os.clock()
local wasAfk         = false

-- ── Detectar input del jugador ────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input)
	-- Detectar si volvió de AFK
	if wasAfk then
		local idleTime = os.clock() - lastInputTime
		wasAfk = false

		-- Mostrar mensaje de regreso
		local hudGui     = playerGui:FindFirstChild("HudGui")
		local notifFrame = hudGui and hudGui:FindFirstChild("NotifFrame", true)
		local notifLabel = notifFrame and notifFrame:FindFirstChild("NotifLabel")
		if notifLabel and notifFrame then
			notifLabel.Text    = "👋 ¡Bienvenido de vuelta! (AFK por " .. math.floor(idleTime/60) .. " min)"
			notifFrame.Visible = true
			task.delay(3, function()
				if notifFrame then notifFrame.Visible = false end
			end)
		end
	end
	lastInputTime = os.clock()
end)

-- ── Loop de anti-AFK ─────────────────────────────────────────────────────────
task.spawn(function()
	local camera = workspace.CurrentCamera

	while true do
		task.wait(AFK_MOVEMENT_INTERVAL)

		-- Verificar inactividad
		local timeSinceInput = os.clock() - lastInputTime
		if timeSinceInput >= INACTIVITY_THRESHOLD then
			wasAfk = true
		end

		-- Mover cámara levemente para evitar kick AFK
		if camera then
			local originalCFrame = camera.CFrame
			local offset         = CFrame.Angles(0, math.rad(0.1), 0)
			camera.CFrame        = originalCFrame * offset
			task.wait(0.1)
			camera.CFrame        = originalCFrame
		end
	end
end)
