-- RebornServer (Script)
-- ServerScriptService/RebornServer
-- Handles Rebirth requests from clients.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(script.Parent.BrainrotData)

local RemoteEvents  = ReplicatedStorage.RemoteEvents
local RebirthEvent  = RemoteEvents.Rebirth
local RebornResult  = RemoteEvents.RebornResult

local MIN_BRAINROTS_FOR_REBIRTH = 10

-- Remove all workspace Brainrot Parts owned by this player
local function clearPlayerParts(userId)
	local brainrotFolder = workspace:FindFirstChild("Brainrots")
	if not brainrotFolder then return end
	for _, part in ipairs(brainrotFolder:GetChildren()) do
		if part:GetAttribute("OwnerId") == userId then
			part:Destroy()
		end
	end
end

RebirthEvent.OnServerEvent:Connect(function(player)
	local userId = player.UserId
	local data   = BrainrotData.Get(userId)
	if not data then return end

	-- Condition: must have at least 10 Brainrots
	if #data.brainrots < MIN_BRAINROTS_FOR_REBIRTH then
		warn(("[RebornServer] %s tried to rebirth with only %d brainrots"):format(player.Name, #data.brainrots))
		return
	end

	-- 1. Remove all Brainrot Parts from Workspace
	clearPlayerParts(userId)

	-- 2 & 3. Reset cash and brainrot list (handled inside BrainrotData.Rebirth)
	BrainrotData.Rebirth(userId)

	-- 4. Increment rebirths is also handled by BrainrotData.Rebirth
	local newData = BrainrotData.Get(userId)

	-- 5. Calculate new permanent multiplier
	local rebirths          = newData.rebirths
	local cashMultiplier    = 1 + (rebirths * 0.5)

	-- 6. Update leaderstats
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local cashVal = ls:FindFirstChild("Cash")
		if cashVal then cashVal.Value = 0 end

		local rebirthsVal = ls:FindFirstChild("Rebirths")
		if rebirthsVal then rebirthsVal.Value = rebirths end
	end

	-- 7. Notify client
	RebornResult:FireClient(player, {
		rebirths       = rebirths,
		cashMultiplier = cashMultiplier,
	})

	print(("[RebornServer] %s rebirthed! Now has %d rebirths (%.1fx multiplier)"):format(
		player.Name, rebirths, cashMultiplier))
end)
