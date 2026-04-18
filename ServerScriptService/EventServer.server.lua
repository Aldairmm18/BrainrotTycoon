-- ServerScriptService/EventServer.server.lua
-- Blood Moon event: viernes/sábado, enemigos x3, luna roja

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local GlobalNotif   = RemoteEvents:WaitForChild("GlobalNotif")

local BLOOD_MOON_DURATION = 7200 -- 2 horas en segundos
local CHECK_INTERVAL      = 60   -- verificar cada minuto

local bloodMoonActive = false
local bloodMoonStart  = 0

-- Estado original del lighting
local originalAmbient     = Lighting.Ambient
local originalOutdoor     = Lighting.OutdoorAmbient
local originalSkyColor    = Color3.fromRGB(0, 0, 0)

local function isBloodMoonDay()
	local wday = tonumber(os.date("%w")) -- 0=Dom...5=Vie, 6=Sab
	return wday == 5 or wday == 6
end

local function activateBloodMoon()
	if bloodMoonActive then return end
	bloodMoonActive = true
	bloodMoonStart  = os.time()

	-- Modificar iluminación
	Lighting.Ambient        = Color3.fromRGB(120, 0, 0)
	Lighting.OutdoorAmbient = Color3.fromRGB(100, 0, 0)
	Lighting.TimeOfDay      = "00:00:00"

	-- Notificar a todos
	GlobalNotif:FireAllClients("🌕 ¡BLOOD MOON ha comenzado! Enemigos 3x más poderosos. Dura 2 horas.")

	-- Exponer estado
	if _G.GameModeServer then
		_G.GameModeServer.bloodMoonActive = true
	end
end

local function deactivateBloodMoon()
	if not bloodMoonActive then return end
	bloodMoonActive = false

	-- Restaurar iluminación
	Lighting.Ambient        = originalAmbient
	Lighting.OutdoorAmbient = originalOutdoor
	Lighting.TimeOfDay      = "14:00:00"

	GlobalNotif:FireAllClients("🌑 Blood Moon ha terminado. Los enemigos vuelven a la normalidad.")

	if _G.GameModeServer then
		_G.GameModeServer.bloodMoonActive = false
	end
end

-- Loop de verificación de Blood Moon
task.spawn(function()
	while true do
		task.wait(CHECK_INTERVAL)

		if isBloodMoonDay() and not bloodMoonActive then
			activateBloodMoon()
		elseif bloodMoonActive then
			local elapsed = os.time() - bloodMoonStart
			if elapsed >= BLOOD_MOON_DURATION or not isBloodMoonDay() then
				deactivateBloodMoon()
			end
		end
	end
end)

-- Exponer estado para otros scripts
_G.EventServer = {
	isBloodMoonActive = function() return bloodMoonActive end,
}

-- Aplicar multiplicador de Blood Moon a stats de enemigos
-- (EnemySpawner consultará esto al hacer spawn)
-- bloodMoonMultiplier = 3.0 en hp y damage cuando bloodMoonActive

-- Verificar inmediatamente al iniciar
task.wait(2)
if isBloodMoonDay() then
	activateBloodMoon()
end
