-- EconomyServer (Script)
-- ServerScriptService/EconomyServer
-- Distributes cashPerSec every second to all players.

local Players           = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData  = require(script.Parent.BrainrotData)
local RarityConfig  = require(ReplicatedStorage.Modules.RarityConfig)

local UpdateCash = ReplicatedStorage.RemoteEvents.UpdateCash

-- Placeholder GamePass ID for 2x multiplier
local GAMEPASS_2X_ID = 123456

local function hasGamepass(player, passId)
	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	if success then return result end
	return false
end

local function syncLeaderstats(player, cash)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	local cashVal = ls:FindFirstChild("Cash")
	if cashVal then cashVal.Value = math.floor(cash) end
end

-- ─── Main Economy Loop ──────────────────────────────────────────────────────

task.spawn(function()
	while true do
		task.wait(1)

		for _, player in ipairs(Players:GetPlayers()) do
			local data = BrainrotData.Get(player.UserId)
			if data then
				local earned = BrainrotData.GetTotalCashPerSec(player.UserId, RarityConfig)

				-- Apply 2x gamepass multiplier
				if hasGamepass(player, GAMEPASS_2X_ID) then
					earned = earned * 2
				end

				BrainrotData.AddCash(player.UserId, earned)

				-- Sync IntValue in leaderstats
				syncLeaderstats(player, data.cash)

				-- Notify client
				UpdateCash:FireClient(player, math.floor(data.cash))
			end
		end
	end
end)
