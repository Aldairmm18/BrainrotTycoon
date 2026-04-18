-- ServerScriptService/GameModeServer.server.lua
-- Gestiona transiciones entre modos de juego

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local RemoteEvents     = ReplicatedStorage:WaitForChild("RemoteEvents")
local SelectGameMode   = RemoteEvents:WaitForChild("SelectGameMode")
local GameModeStarted  = RemoteEvents:WaitForChild("GameModeStarted")
local GlobalNotif      = RemoteEvents:WaitForChild("GlobalNotif")

local function waitForDSM()
	local t = 0
	while not _G.DataStoreManager and t < 10 do
		task.wait(0.5)
		t += 0.5
	end
	return _G.DataStoreManager
end
local DSM = waitForDSM()

local VALID_MODES = {"Survival", "Creative", "PvP", "BloodMoon", "Coop"}

-- Posición del área PvP (arena separada)
local PVP_ARENA_CENTER = Vector3.new(1000, 10, 1000)
local BASE_SPAWN       = Vector3.new(0, 5, 0)

-- Verificar si es Blood Moon (viernes=6, sábado=7 en os.date con %w)
local function isBloodMoonDay()
	local wday = tonumber(os.date("%w")) -- 0=Dom, 1=Lun, ..., 5=Vie, 6=Sab
	return wday == 5 or wday == 6
end

-- Jugadores en PvP
local pvpPlayers = {}

SelectGameMode.OnServerEvent:Connect(function(player, mode)
	if not table.find(VALID_MODES, mode) then
		warn("[GameModeServer] Modo inválido: " .. tostring(mode))
		return
	end

	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	-- BloodMoon solo en viernes/sábado (o con GamePass en el futuro)
	if mode == "BloodMoon" and not isBloodMoonDay() then
		GameModeStarted:FireClient(player, nil, "BloodMoon solo está disponible los viernes y sábados.")
		return
	end

	-- Salir del modo PvP anterior si aplica
	if data.currentGameMode == "PvP" then
		pvpPlayers[userId] = nil
		local char = player.Character
		if char and char.PrimaryPart then
			char:SetPrimaryPartCFrame(CFrame.new(BASE_SPAWN))
		end
	end

	data.currentGameMode = mode
	DSM.MarkDirty(player)

	-- Acciones por modo
	if mode == "PvP" then
		pvpPlayers[userId] = true
		local char = player.Character
		if char and char.PrimaryPart then
			local offset = Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
			char:SetPrimaryPartCFrame(CFrame.new(PVP_ARENA_CENTER + offset))
		end
		-- Igualar stats (simplificado)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.MaxHealth = 100
			humanoid.Health    = 100
			humanoid.WalkSpeed = 16
		end

	elseif mode == "BloodMoon" then
		GlobalNotif:FireAllClients("🌕 ¡BLOOD MOON ha comenzado! Los enemigos son 3x más peligrosos!")

	elseif mode == "Creative" then
		-- EnemySpawner chequeará este modo y no spawneará
		GameModeStarted:FireClient(player, mode, "Modo Creativo activado. Sin XP ni monedas.")
		return
	end

	GameModeStarted:FireClient(player, mode)
end)

-- Exponer estado de modos
_G.GameModeServer = {
	isBloodMoonDay = isBloodMoonDay,
	pvpPlayers     = pvpPlayers,
}
