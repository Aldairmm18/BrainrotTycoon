-- FusionServer (Script)
-- ServerScriptService/FusionServer
-- Players sacrifice 3 Brainrots of one rarity to receive 1 of the next rarity.
-- All logic is server-authoritative; client only fires the request and shows result.

local Players      = game:GetService("Players")
local BrainrotData = require(script.Parent.BrainrotData)

local RE          = game.ReplicatedStorage.RemoteEvents
local FuseRequest = RE:WaitForChild("FuseRequest")
local FuseResult  = RE:WaitForChild("FuseResult")
local GlobalNotif = RE:WaitForChild("GlobalNotification")

local RarityConfig = require(game.ReplicatedStorage.Modules.RarityConfig)
local BrainrotList = require(game.ReplicatedStorage.Modules.BrainrotList)

-- ─── Rarity progression ───────────────────────────────────────────────────────
local RARITY_ORDER = {
	"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"
}

local RARITY_INDEX = {}
local NEXT_RARITY  = {}
for i, r in ipairs(RARITY_ORDER) do
	RARITY_INDEX[r]    = i
	NEXT_RARITY[r]     = RARITY_ORDER[i + 1]  -- nil for "Secret"
end

local FUSION_COST = 3   -- Brainrots consumed per fusion

-- ─── Handler ──────────────────────────────────────────────────────────────────

FuseRequest.OnServerEvent:Connect(function(player, rarity)
	-- Basic validation
	if type(rarity) ~= "string" or not RARITY_INDEX[rarity] then
		FuseResult:FireClient(player, false, "Rareza inválida", nil)
		return
	end

	local nextRarity = NEXT_RARITY[rarity]
	if not nextRarity then
		FuseResult:FireClient(player, false,
			"Los Brainrots Secret son el máximo — no se pueden fusionar", nil)
		return
	end

	local data = BrainrotData.Get(player.UserId)
	if not data then return end

	-- Find indices of matching brainrots
	local matchingIndices = {}
	for i, b in ipairs(data.brainrots) do
		if b.rarity == rarity then
			table.insert(matchingIndices, i)
			if #matchingIndices == FUSION_COST then break end
		end
	end

	if #matchingIndices < FUSION_COST then
		FuseResult:FireClient(player, false,
			"Necesitas " .. FUSION_COST .. " Brainrots " .. rarity ..
			" (tienes " .. #matchingIndices .. ")", nil)
		return
	end

	-- Remove from back to front to keep indices valid
	table.sort(matchingIndices, function(a, b) return a > b end)
	for _, idx in ipairs(matchingIndices) do
		table.remove(data.brainrots, idx)
	end

	-- Pick a random Brainrot of the next rarity from BrainrotList
	local candidates = {}
	for _, b in ipairs(BrainrotList) do
		if b.rarity == nextRarity then
			table.insert(candidates, b)
		end
	end

	local result
	if #candidates > 0 then
		result = candidates[math.random(1, #candidates)]
	else
		-- Fallback: synthesise a generic entry for this rarity
		local cfg = RarityConfig[nextRarity]
		result = {
			name       = nextRarity .. " Brainrot",
			rarity     = nextRarity,
			emoji      = "⭐",
			cashPerSec = cfg and cfg.cashPerSec or 1000,
		}
	end

	-- Add fused result
	table.insert(data.brainrots, {
		name       = result.name,
		rarity     = result.rarity,
		emoji      = result.emoji,
		cashPerSec = result.cashPerSec or 0,
		modelName  = result.modelName,
	})

	-- Global broadcast for Legendary+
	if (RARITY_INDEX[nextRarity] or 0) >= RARITY_INDEX["Legendary"] then
		local msg = "⚗️ " .. player.Name ..
			" fusionó 3 " .. rarity ..
			" y obtuvo " .. (result.emoji or "⭐") ..
			" " .. result.name ..
			" (" .. nextRarity .. ")!"
		for _, p in ipairs(Players:GetPlayers()) do
			GlobalNotif:FireClient(p, msg)
		end
	end

	FuseResult:FireClient(player, true,
		"¡Fusión! 3× " .. rarity .. " → " .. (result.emoji or "") ..
		" " .. result.name,
		result)

	print(("[FusionServer] %s fused 3× %s → %s"):format(
		player.Name, rarity, result.name))
end)
