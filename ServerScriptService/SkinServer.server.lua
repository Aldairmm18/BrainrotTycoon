-- ServerScriptService/SkinServer.server.lua
-- Compra y equipamiento de skins

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SkinConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SkinConfig"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local BuySkin      = RemoteEvents:WaitForChild("BuySkin")
local SkinBought   = RemoteEvents:WaitForChild("SkinBought")
local EquipSkin    = RemoteEvents:WaitForChild("EquipSkin")
local UpdateCoins  = RemoteEvents:WaitForChild("UpdateCoins")

local function waitForDSM()
	local t = 0
	while not _G.DataStoreManager and t < 10 do
		task.wait(0.5)
		t += 0.5
	end
	return _G.DataStoreManager
end
local DSM = waitForDSM()

-- Aplicar apariencia de skin al personaje
local function applySkin(player, skinId)
	local skin = SkinConfig.getById(skinId)
	if not skin or not skin.preview then return end

	local char = player.Character
	if not char then return end

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			if skin.preview.bodyColor then
				part.Color    = skin.preview.bodyColor
			end
			if skin.preview.material then
				part.Material = skin.preview.material
			end
		end
	end
end

-- ── Comprar skin ──────────────────────────────────────────────────────────────
BuySkin.OnServerEvent:Connect(function(player, skinId)
	local skin = SkinConfig.getById(skinId)
	if not skin then
		warn("[SkinServer] Skin inválido: " .. tostring(skinId))
		return
	end

	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	-- Ya la tiene
	if table.find(data.ownedSkins or {}, skinId) then return end

	-- Método de desbloqueo
	local unlock = skin.unlock
	if unlock == "free" then
		-- Siempre disponible
	elseif unlock == "coins" then
		local spent = DSM.SpendCoins(player, skin.price or 0)
		if not spent then
			warn("[SkinServer] " .. player.Name .. " no tiene suficientes monedas")
			return
		end
		UpdateCoins:FireClient(player, data.coins)
	elseif unlock == "streak" then
		if (data.streakDays or 0) < (skin.streakReq or 999) then return end
	elseif unlock == "time" then
		local minutes = (data.bestSessionTime or 0) / 60
		if minutes < (skin.minutesReq or 999) then return end
	elseif unlock == "rebirth" then
		if (data.rebirthCount or 0) < (skin.rebirthReq or 999) then return end
	elseif unlock == "robux" then
		-- Verificar GamePass o logro alternativo
		local hasAlt = data.achievements and data.achievements[skin.altAchievement or ""]
		if not hasAlt then
			warn("[SkinServer] " .. player.Name .. " no tiene el logro para " .. skinId)
			return
		end
	end

	if not data.ownedSkins then data.ownedSkins = {} end
	table.insert(data.ownedSkins, skinId)
	DSM.MarkDirty(player)

	SkinBought:FireClient(player, skinId, data.ownedSkins)
end)

-- ── Equipar skin ──────────────────────────────────────────────────────────────
EquipSkin.OnServerEvent:Connect(function(player, skinId)
	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	if not table.find(data.ownedSkins or {}, skinId) then
		warn("[SkinServer] " .. player.Name .. " no tiene skin " .. skinId)
		return
	end

	data.equippedSkin = skinId
	DSM.MarkDirty(player)

	applySkin(player, skinId)
end)

-- Aplicar skin al respawnear
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		local userId = tostring(player.UserId)
		local data   = DSM and DSM.Get(userId)
		if data then
			applySkin(player, data.equippedSkin or "default")
		end
	end)
end)
