-- ServerScriptService/ZoneServer.server.lua
-- Gestiona el desbloqueo de zonas al subir de nivel

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local ZoneConfig  = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ZoneConfig"))

local RemoteEvents   = ReplicatedStorage:WaitForChild("RemoteEvents")
local ZoneUnlocked   = RemoteEvents:WaitForChild("ZoneUnlocked")

local function waitForDSM()
	local t = 0
	while not _G.DataStoreManager and t < 10 do
		task.wait(0.5)
		t += 0.5
	end
	return _G.DataStoreManager
end
local DSM = waitForDSM()

-- Referencia a puertas físicas en el mapa
-- Las puertas deben nombrarse "ZoneDoor_2", "ZoneDoor_3", etc.
local function setZoneDoor(zoneIndex, open)
	local doorName = "ZoneDoor_" .. tostring(zoneIndex)
	local door = Workspace:FindFirstChild(doorName, true)
	if door then
		if open then
			door.CanCollide    = false
			door.Transparency  = 0.85
		else
			door.CanCollide    = true
			door.Transparency  = 0
		end
	end
end

-- Sincronizar puertas con zonas desbloqueadas del jugador
local function syncDoors(unlockedZones)
	for i = 2, ZoneConfig.TOTAL_ZONES do
		local isUnlocked = table.find(unlockedZones, i) ~= nil
		setZoneDoor(i, isUnlocked)
	end
end

-- Verificar si el jugador desbloquea nuevas zonas
function checkZoneUnlocks(player, data)
	local unlocked = data.unlockedZones or {1}
	local newUnlocks = {}

	for i = 1, ZoneConfig.TOTAL_ZONES do
		if not table.find(unlocked, i) then
			local zone = ZoneConfig[i]
			if zone then
				local levelOk   = data.level >= zone.levelReq
				local rebirthOk = data.rebirthCount >= (zone.requiresRebirth or 0)
				if levelOk and rebirthOk then
					table.insert(unlocked, i)
					table.insert(newUnlocks, i)
				end
			end
		end
	end

	if #newUnlocks > 0 then
		data.unlockedZones = unlocked
		DSM.MarkDirty(player)

		-- Abrir puertas
		for _, zoneIndex in ipairs(newUnlocks) do
			setZoneDoor(zoneIndex, true)
			ZoneUnlocked:FireClient(player, zoneIndex, ZoneConfig[zoneIndex])
		end
	end

	return newUnlocks
end

-- Exponer para que LevelingServer lo llame
_G.ZoneServer = {
	checkZoneUnlocks = checkZoneUnlocks,
}

-- Al entrar un jugador: sincronizar sus puertas
Players.PlayerAdded:Connect(function(player)
	task.wait(2) -- Esperar a que carguen datos
	local data = DSM and DSM.Get(tostring(player.UserId))
	if not data then return end

	-- Actualizar según personaje
	player.CharacterAdded:Connect(function()
		task.wait(1)
		syncDoors(data.unlockedZones or {1})
	end)
end)
