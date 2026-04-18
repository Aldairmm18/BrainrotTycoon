-- ServerScriptService/UpgradeServer.server.lua
-- Mejoras de armas (hasta nivel 5)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponConfig  = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WeaponConfig"))

local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpgradeWeapon   = RemoteEvents:WaitForChild("UpgradeWeapon")
local WeaponUpgraded  = RemoteEvents:WaitForChild("WeaponUpgraded")
local UpdateCoins     = RemoteEvents:WaitForChild("UpdateCoins")

local function waitForDSM()
	local t = 0
	while not _G.DataStoreManager and t < 10 do
		task.wait(0.5)
		t += 0.5
	end
	return _G.DataStoreManager
end
local DSM = waitForDSM()

UpgradeWeapon.OnServerEvent:Connect(function(player, weaponKey)
	local weaponConfig = WeaponConfig[weaponKey]
	if not weaponConfig then
		warn("[UpgradeServer] Arma inválida: " .. tostring(weaponKey))
		return
	end

	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	-- Verificar que el jugador tiene el arma
	local owned = data.ownedWeapons and data.ownedWeapons[weaponKey]
	if not owned then
		warn("[UpgradeServer] " .. player.Name .. " no tiene " .. weaponKey)
		return
	end

	local currentLevel = owned.level or 1
	local targetLevel  = currentLevel + 1

	-- Máximo nivel 5
	if currentLevel >= WeaponConfig.MAX_LEVEL then
		warn("[UpgradeServer] " .. weaponKey .. " ya está al máximo nivel")
		return
	end

	-- Calcular costo
	local cost = WeaponConfig.getUpgradeCost(weaponKey, targetLevel)
	local spent = DSM.SpendCoins(player, cost)
	if not spent then
		warn("[UpgradeServer] " .. player.Name .. " no tiene suficientes monedas")
		return
	end

	-- Subir nivel
	data.ownedWeapons[weaponKey].level = targetLevel
	DSM.MarkDirty(player)

	local newDamage = WeaponConfig.getUpgradedDamage(weaponKey, targetLevel)
	local newMult   = WeaponConfig.getMultiplier(targetLevel)

	UpdateCoins:FireClient(player, data.coins)
	WeaponUpgraded:FireClient(player, weaponKey, targetLevel, newDamage, newMult, data.ownedWeapons)
end)
