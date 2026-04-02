-- ActivityBonusServer (Script)
-- ServerScriptService/ActivityBonusServer
-- Rewards anti-AFK bonus: income×30 seconds of passive earnings.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(script.Parent.BrainrotData)
local RarityConfig = require(ReplicatedStorage.Modules.RarityConfig)

local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local ActivityBonus   = RemoteEvents:WaitForChild("ActivityBonus")
local UpdateCash      = RemoteEvents:WaitForChild("UpdateCash")

-- Rate-limit: one bonus per player every 2.5 minutes
local _lastBonus = {}

ActivityBonus.OnServerEvent:Connect(function(player)
	local userId = player.UserId
	local now    = os.time()
	local last   = _lastBonus[userId] or 0

	if now - last < 150 then return end   -- 2.5 min cooldown
	_lastBonus[userId] = now

	local data = BrainrotData.Get(userId)
	if not data then return end

	local cashPerSec = BrainrotData.GetTotalCashPerSec(userId, RarityConfig)
	local rebirths   = data.rebirths or 0
	local mult       = 1 + (rebirths * 0.5)
	if player:FindFirstChild("GP_DOUBLE_CASH") then mult = mult * 2 end

	local bonus = cashPerSec * mult * 30   -- 30 seconds of income
	if bonus < 1 then bonus = 100 end      -- minimum 100 cash bonus

	BrainrotData.AddCash(userId, bonus)

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local cv = ls:FindFirstChild("Cash")
		if cv then cv.Value = math.floor(data.cash) end
	end

	UpdateCash:FireClient(player, math.floor(data.cash))
	print(("[ActivityBonus] %s claimed bonus: +%d cash"):format(player.Name, math.floor(bonus)))
end)

Players.PlayerRemoving:Connect(function(player)
	_lastBonus[player.UserId] = nil
end)
