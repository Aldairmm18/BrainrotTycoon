-- ServerScriptService/DailyGiftServer.server.lua
-- Regalo diario con sistema de streak

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GiftConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GiftConfig"))

local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local ClaimDailyGift  = RemoteEvents:WaitForChild("ClaimDailyGift")
local DailyGiftResult = RemoteEvents:WaitForChild("DailyGiftResult")
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

local function getToday()
	return os.date("%Y-%m-%d")
end

-- Entregar recompensa al jugador
local function deliverReward(player, data, reward)
	if not reward then return end

	local function deliverSingle(item)
		if item.type == "coins" then
			DSM.AddCoins(player, item.amount or 0)
		elseif item.type == "weapon" then
			if not data.ownedWeapons then data.ownedWeapons = {} end
			data.ownedWeapons[item.key] = data.ownedWeapons[item.key] or {level = 1}
		elseif item.type == "skin" then
			if not table.find(data.ownedSkins or {}, item.key) then
				table.insert(data.ownedSkins, item.key)
			end
		elseif item.type == "skin_temp" then
			-- Skin temporal: guardar con expiración
			if not data.tempSkins then data.tempSkins = {} end
			data.tempSkins[item.key] = os.time() + (item.days or 3) * 86400
		elseif item.type == "rebirth_boost" then
			data._rebirthBoost = (data._rebirthBoost or 0) + (item.amount or 0)
		end
	end

	if reward.type == "multi" then
		for _, item in ipairs(reward.items or {}) do
			deliverSingle(item)
		end
	else
		deliverSingle(reward)
	end
end

ClaimDailyGift.OnServerEvent:Connect(function(player)
	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	local now    = os.time()
	local last   = data.lastGiftClaim or 0
	local today  = getToday()

	-- Verificar que han pasado al menos 20 horas
	local hoursSinceLast = (now - last) / 3600
	if hoursSinceLast < GiftConfig.MIN_HOURS_BETWEEN_CLAIMS then
		local remaining = math.ceil(GiftConfig.MIN_HOURS_BETWEEN_CLAIMS - hoursSinceLast)
		DailyGiftResult:FireClient(player, nil, nil, nil, "cooldown", remaining)
		return
	end

	-- Verificar consecutividad del streak
	local lastDay = data.lastLoginDay or ""
	local streak  = data.streakDays or 0

	if lastDay == today then
		-- Ya reclamó hoy
		DailyGiftResult:FireClient(player, nil, nil, nil, "already_claimed")
		return
	end

	-- Calcular si el streak es consecutivo (ayer)
	local yesterday = os.date("%Y-%m-%d", now - 86400)
	if lastDay == yesterday then
		streak = streak + 1
	else
		-- Streak roto (más de un día sin reclamar)
		streak = 1
	end

	-- Cap de streak en 100 (luego se reinicia)
	if streak > 100 then streak = 1 end

	data.streakDays    = streak
	data.lastGiftClaim = now
	data.lastLoginDay  = today

	-- Obtener regalo
	local reward = GiftConfig[streak]
	if reward then
		deliverReward(player, data, reward)
	end

	DSM.MarkDirty(player)
	UpdateCoins:FireClient(player, data.coins)
	DailyGiftResult:FireClient(player, reward, streak, data.coins, "success")
end)
