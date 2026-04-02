-- CodesServer (Script)
-- ServerScriptService/CodesServer
-- Handles promo code redemption. Each code can only be used once per player.
-- FIX 8: Updated codes list.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local BrainrotData = require(script.Parent.BrainrotData)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RedeemCode   = RemoteEvents:WaitForChild("RedeemCode")
local CodeResult   = RemoteEvents:WaitForChild("CodeResult")
local UpdateCash   = RemoteEvents:WaitForChild("UpdateCash")

-- ─── Code Database ────────────────────────────────────────────────────────────
local CODES = {
	["BRAINROT2025"] = { cash = 1000, used = {} },
	["TRALALA"]      = { cash = 500,  used = {} },
	["TUNGKUNG"]     = { cash = 500,  used = {} },
	["LAUNCH"]       = { cash = 2000, used = {} },
	["ITALIANO"]     = { cash = 1500, used = {} },
	["VACA"]         = { cash = 750,  used = {} },
	["CAPPUCCINO"]   = { cash = 750,  used = {} },
	["WELCOME"]      = { cash = 3000, used = {} },
}

-- ─── Handler ──────────────────────────────────────────────────────────────────
RedeemCode.OnServerEvent:Connect(function(player, code)
	if typeof(code) ~= "string" then return end
	code = string.upper(string.gsub(code, "%s+", ""))

	local codeData = CODES[code]
	if not codeData then
		CodeResult:FireClient(player, false, "❌ Código inválido")
		return
	end

	if codeData.used[player.UserId] then
		CodeResult:FireClient(player, false, "⚠️ Ya usaste este código")
		return
	end

	codeData.used[player.UserId] = true
	BrainrotData.AddCash(player.UserId, codeData.cash)

	local data = BrainrotData.Get(player.UserId)
	if data then
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local cashVal = ls:FindFirstChild("Cash")
			if cashVal then cashVal.Value = math.floor(data.cash) end
		end
		UpdateCash:FireClient(player, math.floor(data.cash))
	end

	CodeResult:FireClient(player, true, "✅ +" .. codeData.cash .. " coins!")
	print(("[CodesServer] %s redeemed code %s for %d cash"):format(player.Name, code, codeData.cash))
end)
