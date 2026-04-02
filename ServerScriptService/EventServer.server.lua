-- EventServer (Script)
-- ServerScriptService/EventServer
-- Limited-time gacha event with server-side countdown and FOMO mechanics.
-- Change CURRENT_EVENT each season — no client code changes needed.

local Players      = game:GetService("Players")
local BrainrotData = require(script.Parent.BrainrotData)

local RE          = game.ReplicatedStorage.RemoteEvents
local UpdateEvent = RE:WaitForChild("UpdateEvent")
local BuyEventEgg = RE:WaitForChild("BuyEventEgg")
local GachaResult = RE:WaitForChild("GachaResult")
local GlobalNotif = RE:WaitForChild("GlobalNotification")

-- ─── Current event definition ─────────────────────────────────────────────────
-- endTime uses os.time() so it is always the server clock, never the client.
local CURRENT_EVENT = {
	name    = "🌋 Evento Volcán Italiano",
	endTime = os.time() + (48 * 3600),   -- 48 h from server start
	eggCost = 1500,
	-- dropChance must sum to 1.0
	brainrots = {
		{ name = "Vulcano Brainrotto",  emoji = "🌋", rarity = "Legendary",
		  cashPerSec = 2000000, dropChance = 0.05 },
		{ name = "Lava Cappuccinone",   emoji = "🔥", rarity = "Epic",
		  cashPerSec = 80000,   dropChance = 0.25 },
		{ name = "Magma Pisellino",     emoji = "💥", rarity = "Rare",
		  cashPerSec = 4000,    dropChance = 0.70 },
	},
}

-- ─── Broadcast timer every 5 s ───────────────────────────────────────────────

task.spawn(function()
	while true do
		task.wait(5)
		local remaining = CURRENT_EVENT.endTime - os.time()
		if remaining <= 0 then break end
		for _, p in ipairs(Players:GetPlayers()) do
			UpdateEvent:FireClient(p, {
				name     = CURRENT_EVENT.name,
				remaining= math.floor(remaining),
				eggCost  = CURRENT_EVENT.eggCost,
			})
		end
	end
	-- Event ended — tell all clients to hide the banner
	for _, p in ipairs(Players:GetPlayers()) do
		UpdateEvent:FireClient(p, nil)
	end
	print("[EventServer] Event ended: " .. CURRENT_EVENT.name)
end)

-- Send event state to late-joiners immediately
Players.PlayerAdded:Connect(function(player)
	local remaining = CURRENT_EVENT.endTime - os.time()
	if remaining > 0 then
		task.wait(2)          -- wait for client to load RemoteEvents
		UpdateEvent:FireClient(player, {
			name      = CURRENT_EVENT.name,
			remaining = math.floor(remaining),
			eggCost   = CURRENT_EVENT.eggCost,
		})
	end
end)

-- ─── Buy event egg handler ────────────────────────────────────────────────────

BuyEventEgg.OnServerEvent:Connect(function(player)
	local data = BrainrotData.Get(player.UserId)
	if not data then return end

	-- Server-side time check
	local remaining = CURRENT_EVENT.endTime - os.time()
	if remaining <= 0 then
		GachaResult:FireClient(player, {
			success = false, message = "El evento ha terminado"
		})
		return
	end

	-- Deduct cost (server-authoritative)
	if not BrainrotData.SpendCash(player.UserId, CURRENT_EVENT.eggCost) then
		GachaResult:FireClient(player, {
			success = false,
			message = "Necesitas $" .. CURRENT_EVENT.eggCost .. " para este huevo"
		})
		return
	end

	-- Weighted roll
	local roll       = math.random()
	local cumulative = 0
	local selected   = CURRENT_EVENT.brainrots[#CURRENT_EVENT.brainrots] -- fallback
	for _, b in ipairs(CURRENT_EVENT.brainrots) do
		cumulative = cumulative + b.dropChance
		if roll <= cumulative then
			selected = b
			break
		end
	end

	-- Add to inventory
	BrainrotData.AddBrainrot(player.UserId, {
		name       = selected.name,
		rarity     = selected.rarity,
		emoji      = selected.emoji,
		cashPerSec = selected.cashPerSec,
	})

	-- Sync leaderstats cash
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local cashVal = ls:FindFirstChild("Cash")
		if cashVal then cashVal.Value = math.floor(data.cash) end
	end

	-- Global broadcast for Legendary drops
	if selected.rarity == "Legendary" then
		for _, p in ipairs(Players:GetPlayers()) do
			GlobalNotif:FireClient(p,
				"🌋 " .. player.Name .. " obtuvo " ..
				selected.emoji .. " " .. selected.name ..
				" del Evento Volcán!")
		end
	end

	GachaResult:FireClient(player, {
		success    = true,
		name       = selected.name,
		emoji      = selected.emoji,
		rarity     = selected.rarity,
		cashPerSec = selected.cashPerSec,
		isEvent    = true,
	})
end)
