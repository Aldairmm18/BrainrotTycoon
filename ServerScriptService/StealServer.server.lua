-- StealServer (Script)
-- ServerScriptService/StealServer
-- Server-authoritative player-vs-player Brainrot steal system.

local Players = game:GetService("Players")

local BrainrotData = require(script.Parent.BrainrotData)

local RE                 = game.ReplicatedStorage.RemoteEvents
local StealAttempt       = RE:WaitForChild("StealAttempt")
local StealResult        = RE:WaitForChild("StealResult")
local GlobalNotification = RE:WaitForChild("GlobalNotification")

-- ─── Config ───────────────────────────────────────────────────────────────────
local STEAL_COOLDOWN      = 30          -- seconds between steal attempts
local MAX_STEALS_PER_HOUR = 5           -- hourly cap per player
local STEAL_SUCCESS_BASE  = 0.40        -- 40 % base success chance
local GUARDIAN_REDUCTION  = 0.10        -- each guardian reduces success by 10 %
local REBIRTH_BONUS       = 0.05        -- +5 % per thief rebirth
local REBIRTH_PENALTY     = 0.05        -- -5 % per victim rebirth

-- ─── Rate-limit state (in-memory, resets on server restart) ───────────────────
local cooldowns  = {}   -- [userId] = tick()  last steal attempt
local stealCount = {}   -- [userId] = { count: number, resetTime: number }

-- ─── Rate-limit check ─────────────────────────────────────────────────────────
local function canSteal(player)
	local uid = player.UserId
	local now = tick()

	-- Cooldown
	if cooldowns[uid] and (now - cooldowns[uid]) < STEAL_COOLDOWN then
		local remaining = math.ceil(STEAL_COOLDOWN - (now - cooldowns[uid]))
		return false, "Espera " .. remaining .. "s para volver a robar"
	end

	-- Hourly cap
	if stealCount[uid] then
		if now > stealCount[uid].resetTime then
			stealCount[uid] = { count = 0, resetTime = now + 3600 }
		elseif stealCount[uid].count >= MAX_STEALS_PER_HOUR then
			return false, "Límite de robos por hora alcanzado (" .. MAX_STEALS_PER_HOUR .. "/h)"
		end
	else
		stealCount[uid] = { count = 0, resetTime = now + 3600 }
	end

	return true, "ok"
end

-- ─── Rarity order (higher = more valuable) ────────────────────────────────────
local RARITY_ORDER = {
	Common   = 1,
	Uncommon = 2,
	Rare     = 3,
	Epic     = 4,
	Legendary= 5,
	Mythic   = 6,
	Secret   = 7,
}

-- ─── Main Handler ─────────────────────────────────────────────────────────────

StealAttempt.OnServerEvent:Connect(function(thief, targetName)
	-- 1. Validate thief rate-limit
	local canDo, msg = canSteal(thief)
	if not canDo then
		StealResult:FireClient(thief, false, msg, nil)
		return
	end

	-- 2. Validate target
	if type(targetName) ~= "string" then
		StealResult:FireClient(thief, false, "Petición inválida", nil)
		return
	end

	local victim = Players:FindFirstChild(targetName)
	if not victim or victim == thief then
		StealResult:FireClient(thief, false, "Jugador no encontrado", nil)
		return
	end

	local victimData = BrainrotData.Get(victim.UserId)
	local thiefData  = BrainrotData.Get(thief.UserId)

	if not victimData or not thiefData then
		StealResult:FireClient(thief, false, "Error al leer datos", nil)
		return
	end

	-- 3. Victim must have at least 1 Brainrot
	if #victimData.brainrots == 0 then
		StealResult:FireClient(thief, false, targetName .. " no tiene Brainrots que robar", nil)
		return
	end

	-- 4. Calculate success chance
	local thiefRebirths  = thiefData.rebirths  or 0
	local victimRebirths = victimData.rebirths or 0
	local victimGuardians = victimData.guardians or 0

	local successChance = STEAL_SUCCESS_BASE
	successChance = successChance + (thiefRebirths  * REBIRTH_BONUS)
	successChance = successChance - (victimRebirths * REBIRTH_PENALTY)
	successChance = successChance - (victimGuardians * GUARDIAN_REDUCTION)
	successChance = math.clamp(successChance, 0.05, 0.80)

	-- 5. Apply cooldown + count BEFORE roll (prevents spam on error)
	cooldowns[thief.UserId] = tick()
	stealCount[thief.UserId].count = stealCount[thief.UserId].count + 1

	-- 6. Roll
	if math.random() <= successChance then
		-- ── SUCCESS ──────────────────────────────────────────────────────────
		-- Sort victim's brainrots by rarity descending
		table.sort(victimData.brainrots, function(a, b)
			return (RARITY_ORDER[a.rarity] or 0) > (RARITY_ORDER[b.rarity] or 0)
		end)

		-- Steal from the top 50 % (always at least 1)
		local topHalf = math.max(1, math.ceil(#victimData.brainrots * 0.5))
		local idx     = math.random(1, topHalf)
		local stolen  = table.remove(victimData.brainrots, idx)

		-- Give stolen Brainrot to thief
		table.insert(thiefData.brainrots, stolen)

		-- Notify thief
		StealResult:FireClient(thief, true,
			"¡Robaste " .. (stolen.emoji or "") .. " " .. stolen.name ..
			" de " .. targetName .. "!",
			stolen)

		-- Notify victim (success = false so UI shows red)
		StealResult:FireClient(victim, false,
			"¡" .. thief.Name .. " te robó " ..
			(stolen.emoji or "") .. " " .. stolen.name .. "!",
			stolen)

		-- Global broadcast for Rare or better
		if (RARITY_ORDER[stolen.rarity] or 0) >= RARITY_ORDER["Rare"] then
			local broadcast = "🚨 " .. thief.Name .. " robó " ..
				(stolen.emoji or "") .. " " .. stolen.name ..
				" (" .. stolen.rarity .. ") de " .. targetName .. "!"
			for _, p in ipairs(Players:GetPlayers()) do
				GlobalNotification:FireClient(p, broadcast)
			end
		end

	else
		-- ── FAIL ─────────────────────────────────────────────────────────────
		StealResult:FireClient(thief, false,
			"¡Fallaste el robo a " .. targetName .. "! (" ..
			math.floor(successChance * 100) .. "% chance)", nil)

		-- Tip-off the victim
		StealResult:FireClient(victim, nil,
			"¡" .. thief.Name .. " intentó robarte pero falló!", nil)
	end
end)
