-- ServerScriptService/RebirthServer.server.lua
-- Sistema de Rebirth al llegar al nivel 60

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local RequestRebirth  = RemoteEvents:WaitForChild("RequestRebirth")
local RebirthResult   = RemoteEvents:WaitForChild("RebirthResult")
local UpdateCoins     = RemoteEvents:WaitForChild("UpdateCoins")
local GlobalNotif     = RemoteEvents:WaitForChild("GlobalNotif")

local function waitForDSM()
	local t = 0
	while not _G.DataStoreManager and t < 10 do
		task.wait(0.5)
		t += 0.5
	end
	return _G.DataStoreManager
end
local DSM = waitForDSM()

-- Bonuses permanentes por rebirth
local REBIRTH_BONUSES = {
	[1]  = {xpMult=1.5, coinBonus=0.2, hpBonus=0,    speedBonus=0,    dmgBonus=0,    colorName="Azul",    aura=false},
	[2]  = {xpMult=2.0, coinBonus=0.2, hpBonus=0.3,  speedBonus=0,    dmgBonus=0,    colorName="Verde",   aura=false},
	[3]  = {xpMult=2.5, coinBonus=0,   hpBonus=0,    speedBonus=0.25, dmgBonus=0,    colorName="Morado",  aura=false},
	[4]  = {xpMult=3.0, coinBonus=0,   hpBonus=0,    speedBonus=0,    dmgBonus=0,    colorName="Dorado",  aura=false, skin="skinRebirth4"},
	[5]  = {xpMult=4.0, coinBonus=0,   hpBonus=0,    speedBonus=0,    dmgBonus=0.5,  colorName="Rojo",    aura="fuego"},
	[10] = {xpMult=8.0, coinBonus=0,   hpBonus=0,    speedBonus=0,    dmgBonus=0,    colorName="Arcoíris",aura="arcoiris", skin="skinLegendario", title="Leyenda"},
}

-- Se conserva: armas, monedas, skins, amigos
-- Se reinicia: nivel, xp, zonas desbloqueadas
RequestRebirth.OnServerEvent:Connect(function(player)
	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	-- Verificar nivel 60
	if (data.level or 1) < 60 then
		RebirthResult:FireClient(player, false, "Necesitas nivel 60 para renacer.")
		return
	end

	-- Aplicar rebirth
	local newRebirth = (data.rebirthCount or 0) + 1

	-- Stats a conservar
	local conservedCoins  = data.coins
	local conservedWeapons = data.ownedWeapons
	local conservedSkins  = data.ownedSkins
	local conservedStars  = data.totalStars
	local conservedKills  = data.totalKills

	-- Reiniciar stats de progresión
	data.level          = 1
	data.xp             = 0
	data.unlockedZones  = {1}
	data.baseHP         = 100
	data.baseSpeed      = 16
	data.baseDamage     = 10

	-- Restaurar conservados
	data.coins          = conservedCoins
	data.ownedWeapons   = conservedWeapons
	data.ownedSkins     = conservedSkins
	data.totalStars     = conservedStars
	data.totalKills     = conservedKills
	data.rebirthCount   = newRebirth

	-- Aplicar bonus permanente del rebirth
	local bonus = REBIRTH_BONUSES[newRebirth] or REBIRTH_BONUSES[math.min(newRebirth, 10)]
	if bonus then
		if bonus.hpBonus    > 0 then data.baseHP      = data.baseHP    * (1 + bonus.hpBonus) end
		if bonus.speedBonus > 0 then data.baseSpeed   = data.baseSpeed * (1 + bonus.speedBonus) end
		if bonus.dmgBonus   > 0 then data.baseDamage  = data.baseDamage * (1 + bonus.dmgBonus) end
		-- Skin de rebirth
		if bonus.skin and not table.find(data.ownedSkins, bonus.skin) then
			table.insert(data.ownedSkins, bonus.skin)
		end
	end

	DSM.MarkDirty(player)

	-- Respawnear personaje
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.Health = 0 end
	end

	-- Notificar al mundo
	GlobalNotif:FireAllClients("🌟 " .. player.Name .. " ha alcanzado Rebirth #" .. newRebirth .. "!")

	RebirthResult:FireClient(player, true, newRebirth, bonus)
end)
