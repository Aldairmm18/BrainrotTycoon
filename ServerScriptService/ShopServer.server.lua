-- ServerScriptService/ShopServer.server.lua
-- Compra y venta de armas

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WeaponConfig"))

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local BuyWeapon     = RemoteEvents:WaitForChild("BuyWeapon")
local WeaponBought  = RemoteEvents:WaitForChild("WeaponBought")
local SellWeapon    = RemoteEvents:WaitForChild("SellWeapon")
local UpdateCoins   = RemoteEvents:WaitForChild("UpdateCoins")

local function waitForDSM()
	local t = 0
	while not _G.DataStoreManager and t < 10 do
		task.wait(0.5)
		t += 0.5
	end
	return _G.DataStoreManager
end
local DSM = waitForDSM()

-- ── Comprar arma ──────────────────────────────────────────────────────────────
BuyWeapon.OnServerEvent:Connect(function(player, weaponKey)
	local weaponData = WeaponConfig[weaponKey]
	if not weaponData then
		warn("[ShopServer] Arma inválida: " .. tostring(weaponKey))
		return
	end

	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	-- Ya la tiene
	if data.ownedWeapons and data.ownedWeapons[weaponKey] then
		warn("[ShopServer] " .. player.Name .. " ya tiene " .. weaponKey)
		return
	end

	-- Validar zona
	local zoneReq = weaponData.zoneReq or 1
	if not table.find(data.unlockedZones or {1}, zoneReq) then
		warn("[ShopServer] " .. player.Name .. " no tiene zona " .. zoneReq .. " desbloqueada")
		return
	end

	-- Arma gratis
	if weaponData.isFree then
		if not data.ownedWeapons then data.ownedWeapons = {} end
		data.ownedWeapons[weaponKey] = {level = 1}
		DSM.MarkDirty(player)
		WeaponBought:FireClient(player, weaponKey, data.ownedWeapons)
		return
	end

	-- Cobrar
	local spent = DSM.SpendCoins(player, weaponData.price)
	if not spent then
		warn("[ShopServer] " .. player.Name .. " no tiene suficientes monedas")
		return
	end

	if not data.ownedWeapons then data.ownedWeapons = {} end
	data.ownedWeapons[weaponKey] = {level = 1}
	DSM.MarkDirty(player)

	UpdateCoins:FireClient(player, data.coins)
	WeaponBought:FireClient(player, weaponKey, data.ownedWeapons)
end)

-- ── Vender arma ───────────────────────────────────────────────────────────────
SellWeapon.OnServerEvent:Connect(function(player, weaponKey)
	if weaponKey == "EspadaMadera" then return end  -- No se puede vender el arma base

	local weaponData = WeaponConfig[weaponKey]
	if not weaponData then return end

	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	if not data.ownedWeapons or not data.ownedWeapons[weaponKey] then return end

	-- 50% del precio de compra
	local sellValue = math.floor(weaponData.price * 0.5)
	DSM.AddCoins(player, sellValue)

	-- Si era el equipada, cambiar a madera
	if data.equippedWeapon == weaponKey then
		data.equippedWeapon = "EspadaMadera"
	end

	data.ownedWeapons[weaponKey] = nil
	DSM.MarkDirty(player)

	UpdateCoins:FireClient(player, data.coins)
	-- Reusar WeaponBought para actualizar inventario en cliente
	WeaponBought:FireClient(player, nil, data.ownedWeapons)
end)
