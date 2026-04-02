-- GuardianServer (Script)
-- ServerScriptService/GuardianServer
-- Players can buy up to 3 guardians that each cut steal success chance by 10%.

local BrainrotData = require(script.Parent.BrainrotData)

local RE         = game.ReplicatedStorage.RemoteEvents
local BuyGuardian = RE:WaitForChild("BuyGuardian")
local CodeResult  = RE:WaitForChild("CodeResult")   -- reuse for simple feedback toast

local GUARDIAN_COST = 5000  -- cash per guardian
local MAX_GUARDIANS = 3

BuyGuardian.OnServerEvent:Connect(function(player)
	local data = BrainrotData.Get(player.UserId)
	if not data then return end

	local guardians = data.guardians or 0

	-- Cap check
	if guardians >= MAX_GUARDIANS then
		CodeResult:FireClient(player, false,
			"Ya tienes el máximo de guardianes (" .. MAX_GUARDIANS .. "/" .. MAX_GUARDIANS .. ")")
		return
	end

	-- Funds check (SpendCash is authoritative)
	if not BrainrotData.SpendCash(player.UserId, GUARDIAN_COST) then
		CodeResult:FireClient(player, false,
			"No tienes suficiente cash ($" .. GUARDIAN_COST .. " requeridos)")
		return
	end

	data.guardians = guardians + 1

	-- Sync leaderstats cash
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local cashVal = ls:FindFirstChild("Cash")
		if cashVal then cashVal.Value = math.floor(data.cash) end
	end

	CodeResult:FireClient(player, true,
		"🛡️ ¡Guardián comprado! (" .. data.guardians .. "/" .. MAX_GUARDIANS ..
		") — cada guardián reduce un 10% la chance de robo")
end)
