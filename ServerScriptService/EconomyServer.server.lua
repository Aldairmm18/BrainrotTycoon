-- EconomyServer (Script)
-- ServerScriptService/EconomyServer
-- Distributes cashPerSec every second using rebirth + gamepass + pet multipliers.
-- FIX 7: task.wait(1), IntValue cap 2^31-1, efficient loop.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(script.Parent.BrainrotData)
local RarityConfig = require(ReplicatedStorage.Modules.RarityConfig)

local UpdateCash = ReplicatedStorage.RemoteEvents.UpdateCash

local INT_VALUE_MAX = 2147483647  -- 2^31 - 1 (IntValue limit)

local function syncLeaderstats(player, cash)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	local cashVal = ls:FindFirstChild("Cash")
	if cashVal then
		cashVal.Value = math.min(math.floor(cash), INT_VALUE_MAX)
	end
end

task.spawn(function()
	while true do
		task.wait(1)

		local activePlayers = Players:GetPlayers()
		for _, player in ipairs(activePlayers) do
			local data = BrainrotData.Get(player.UserId)
			if data then
				local baseCashPerSec = BrainrotData.GetTotalCashPerSec(player.UserId, RarityConfig)

				local multiplier = 1 + (data.rebirths or 0) * 0.5

				-- 2× cash Game Pass
				if player:FindFirstChild("GP_DOUBLE_CASH") then
					multiplier = multiplier * 2
				end

				-- Pet multiplier (PetServer handles pet-specific bonuses separately)

				local earned = baseCashPerSec * multiplier
				if earned > 0 then
					BrainrotData.AddCash(player.UserId, earned)
				end

				-- Cap and sync
				if data.cash > INT_VALUE_MAX then
					data.cash = INT_VALUE_MAX
				end

				syncLeaderstats(player, data.cash)
				UpdateCash:FireClient(player, math.min(math.floor(data.cash), INT_VALUE_MAX))
			end
		end
	end
end)
