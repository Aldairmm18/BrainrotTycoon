-- ServerScriptService/TimerServer.server.lua
-- Timer de sesión por jugador, penalizaciones y canje de tiempo

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local TimerUpdate   = RemoteEvents:WaitForChild("TimerUpdate")
local SessionEnd    = RemoteEvents:WaitForChild("SessionEnd")
local RedeemTime    = RemoteEvents:WaitForChild("RedeemTime")
local TimeRedeemed  = RemoteEvents:WaitForChild("TimeRedeemed")
local UpdateCoins   = RemoteEvents:WaitForChild("UpdateCoins")
local GlobalNotif   = RemoteEvents:WaitForChild("GlobalNotif")

local function waitForDSM()
	local t = 0
	while not _G.DataStoreManager and t < 10 do
		task.wait(0.5)
		t += 0.5
	end
	return _G.DataStoreManager
end
local DSM = waitForDSM()

-- Estado de timers por jugador
local timers = {}  -- [userId] = {elapsed=N, kills=0, stars=0, running=true}

-- Recompensas de canje de tiempo
local REDEEM_OPTIONS = {
	coins = function(minutes, rebirthCount)
		local mult = ({1.0, 1.5, 2.0, 2.5, 3.0, 3.0, 3.0, 3.0, 3.0, 3.0, 8.0})[math.min(rebirthCount+1, 11)]
		return math.floor(minutes * 50 * mult)
	end,
	item = {
		{minutesReq = 5,  reward = {type="potion",    effect="speed", duration=600}},
		{minutesReq = 10, reward = {type="upgrade",   description="Upgrade gratuito de arma actual"}},
		{minutesReq = 20, reward = {type="chest",     rarity="legendario"}},
		{minutesReq = 30, reward = {type="crystal_key", description="Abre zona secreta por 24h"}},
	}
}

-- ── Iniciar timer de jugador ──────────────────────────────────────────────────
local function startTimer(player)
	local userId = tostring(player.UserId)
	timers[userId] = {elapsed = 0, running = true, kills = 0}

	task.spawn(function()
		while player.Parent and timers[userId] and timers[userId].running do
			task.wait(1)
			local t = timers[userId]
			if not t then break end

			t.elapsed = t.elapsed + 1

			-- Notificar cliente cada segundo
			TimerUpdate:FireClient(player, t.elapsed)

			-- Hitos de tiempo (procesados en GiftConfig)
			-- Solo notificar si alcanza un hito
		end
	end)
end

-- ── Penalización por muerte ───────────────────────────────────────────────────
local function penalize(player, seconds)
	local userId = tostring(player.UserId)
	local t = timers[userId]
	if not t then return end
	t.elapsed = math.max(0, t.elapsed - seconds)
	TimerUpdate:FireClient(player, t.elapsed)
end

-- ── Fin de sesión ─────────────────────────────────────────────────────────────
local function endSession(player)
	local userId = tostring(player.UserId)
	local t = timers[userId]
	if not t then return end
	t.running = false

	local data = DSM and DSM.Get(userId)
	if not data then return end

	local elapsed = t.elapsed
	local minutes = elapsed / 60

	-- Guardar mejor sesión
	if elapsed > (data.bestSessionTime or 0) then
		data.bestSessionTime = elapsed
	end
	data.totalTimeSurvived = (data.totalTimeSurvived or 0) + elapsed

	-- Calcular estrellas (via StarServer)
	local stars = 0
	if _G.StarServer then
		stars = _G.StarServer.calculateStars(player, t)
	end

	DSM.MarkDirty(player)

	-- Enviar pantalla de resultados
	SessionEnd:FireClient(player, {
		elapsed   = elapsed,
		minutes   = minutes,
		kills     = t.kills or 0,
		stars     = stars,
		rebirthCount = data.rebirthCount or 0,
	})
end

-- ── Canje de tiempo ───────────────────────────────────────────────────────────
RedeemTime.OnServerEvent:Connect(function(player, option)
	local userId = tostring(player.UserId)
	local t      = timers[userId]
	if not t then return end

	local data    = DSM and DSM.Get(userId)
	if not data then return end

	local minutes = math.floor((t.elapsed or 0) / 60)
	local reward  = nil

	if option == "coins" then
		local coins = REDEEM_OPTIONS.coins(minutes, data.rebirthCount or 0)
		DSM.AddCoins(player, coins)
		DSM.MarkDirty(player)
		UpdateCoins:FireClient(player, data.coins)
		reward = {type = "coins", amount = coins}

	elseif option == "item" then
		-- Encontrar el mejor item que puede reclamar
		local bestItem = nil
		for i = #REDEEM_OPTIONS.item, 1, -1 do
			local opt = REDEEM_OPTIONS.item[i]
			if minutes >= opt.minutesReq then
				bestItem = opt.reward
				break
			end
		end
		if bestItem then
			reward = bestItem
			-- Aplicar recompensa
			if bestItem.type == "upgrade" then
				local wk = data.equippedWeapon
				if wk and data.ownedWeapons and data.ownedWeapons[wk] then
					local lvl = data.ownedWeapons[wk].level or 1
					if lvl < 5 then
						data.ownedWeapons[wk].level = lvl + 1
					end
				end
			end
			DSM.MarkDirty(player)
		end
	end

	timers[userId] = nil
	TimeRedeemed:FireClient(player, reward)
end)

-- ── Exponer API ────────────────────────────────────────────────────────────────
_G.TimerServer = {
	penalize   = penalize,
	endSession = endSession,
	getTimer   = function(userId) return timers[tostring(userId)] end,
}

-- ── Lifecycle ─────────────────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	startTimer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = tostring(player.UserId)
	if timers[userId] then
		local data = DSM and DSM.Get(userId)
		if data then
			local elapsed = timers[userId].elapsed or 0
			if elapsed > (data.bestSessionTime or 0) then
				data.bestSessionTime = elapsed
			end
			data.totalTimeSurvived = (data.totalTimeSurvived or 0) + elapsed
			DSM.MarkDirty(player)
		end
		timers[userId] = nil
	end
end)
