-- EconomyServer (Script)
-- ServerScriptService/EconomyServer
-- Distributes cashPerSec every second using rebirth + gamepass + pet multipliers.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(script.Parent.BrainrotData)
local RarityConfig = require(ReplicatedStorage.Modules.RarityConfig)
local PetServer    = require(script.Parent.PetServer)

local UpdateCash = ReplicatedStorage.RemoteEvents.UpdateCash

local function syncLeaderstats(player, cash)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	local cashVal = ls:FindFirstChild("Cash")
	if cashVal then cashVal.Value = math.floor(cash) end
end

task.spawn(function()
	while true do
		task.wait(1)

		for _, player in ipairs(Players:GetPlayers()) do
			local data = BrainrotData.Get(player.UserId)
			if data then
				local baseCashPerSec = BrainrotData.GetTotalCashPerSec(player.UserId, RarityConfig)

				local multiplier = 1

				-- Rebirth multiplier
				local rebirths = data.rebirths or 0
				multiplier = multiplier * (1 + rebirths * 0.5)

				-- 2× cash Game Pass
				if player:FindFirstChild("GP_DOUBLE_CASH") then
					multiplier = multiplier * 2
				end

				-- Pet multiplier
				multiplier = multiplier * PetServer.GetMultiplier(player.UserId)

				local earned = baseCashPerSec * multiplier
				BrainrotData.AddCash(player.UserId, earned)

				syncLeaderstats(player, data.cash)
				UpdateCash:FireClient(player, math.floor(data.cash))
			end
		end
	end
end)
