-- ServerScriptService/TutorialServer.server.lua
-- Tutorial inicial y arma aleatoria de inicio

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WeaponConfig"))

local RemoteEvents       = ReplicatedStorage:WaitForChild("RemoteEvents")
local TutorialCompleteRE = RemoteEvents:WaitForChild("TutorialComplete")
local ClassSelected      = RemoteEvents:WaitForChild("ClassSelected")
local GlobalNotif        = RemoteEvents:WaitForChild("GlobalNotif")

local function waitForDSM()
	local t = 0
	while not _G.DataStoreManager and t < 10 do
		task.wait(0.5)
		t += 0.5
	end
	return _G.DataStoreManager
end
local DSM = waitForDSM()

-- Selección aleatoria de arma de inicio
local function pickStartWeapon()
	local total  = 0
	local chances = WeaponConfig.START_CHANCES
	for _, entry in ipairs(chances) do
		total = total + entry.weight
	end
	local roll = math.random(1, total)
	local cumulative = 0
	for _, entry in ipairs(chances) do
		cumulative = cumulative + entry.weight
		if roll <= cumulative then
			return entry.key
		end
	end
	return "EspadaMadera"
end

-- Al entrar un jugador nuevo: mostrar tutorial
Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	if not data.tutorialComplete then
		-- El cliente mostrará el tutorial al recibir el ClassSelected vacío
		-- El servidor espera el evento TutorialComplete antes de dar el arma
	end
end)

-- Al completar el tutorial: dar arma inicial y aplicar clase
TutorialCompleteRE.OnServerEvent:Connect(function(player, selectedClass)
	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	if data.tutorialComplete then return end

	data.tutorialComplete = true

	-- Dar arma de inicio aleatoria
	local startWeapon = pickStartWeapon()
	if not data.ownedWeapons then data.ownedWeapons = {} end
	data.ownedWeapons[startWeapon]  = {level = 1}
	data.ownedWeapons["EspadaMadera"] = data.ownedWeapons["EspadaMadera"] or {level = 1}
	data.equippedWeapon = startWeapon

	-- Aplicar clase seleccionada
	if selectedClass then
		data.selectedClass = selectedClass
	end

	DSM.MarkDirty(player)

	-- Aplicar stats de clase
	if _G.ClassServer then
		-- ClassServer maneja esto automáticamente en CharacterAdded
		-- Forzar reload del personaje para aplicar stats
	end

	-- Notificar al cliente
	ClassSelected:FireClient(player, data.selectedClass, nil)

	-- Dar el arma físicamente
	if _G.WeaponServer then
		-- WeaponServer dará el arma al respawnear
	else
		-- Fallback manual
		task.wait(1)
		if player.Character then
			local backpack = player:FindFirstChildOfClass("Backpack")
			if backpack then
				local tool = Instance.new("Tool")
				tool.Name           = startWeapon
				tool.RequiresHandle = false
				local handle        = Instance.new("Part")
				handle.Name         = "Handle"
				handle.Size         = Vector3.new(0.3, 2, 0.3)
				handle.Parent       = tool
				tool.Parent         = backpack
			end
		end
	end

	GlobalNotif:FireClient(player, "🗡️ Obtuviste: " .. (WeaponConfig[startWeapon] and WeaponConfig[startWeapon].name or startWeapon))
end)
