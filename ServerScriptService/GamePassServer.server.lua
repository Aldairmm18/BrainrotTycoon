-- GamePassServer (Script)
-- ServerScriptService/GamePassServer
-- Handles Game Pass detection and purchase flow.

local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local BrainrotData = require(script.Parent.BrainrotData)

-- ─── Pass IDs (update after publishing the game) ──────────────────────────────
local PASSES = {
	DOUBLE_CASH  = 0,   -- 2× cash multiplier   — 99 R$
	AUTO_COLLECT = 0,   -- auto collect          — 149 R$
	LUCKY_EGG    = 0,   -- +luck in gacha        — 199 R$
	VIP          = 0,   -- VIP zone + title      — 299 R$
	STARTER_PACK = 0,   -- 5 000 cash on join    — 49 R$
}

-- ─── Grant tags for all owned passes ─────────────────────────────────────────
local function grantPassTags(player)
	for passName, passId in pairs(PASSES) do
		if passId > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
			end)
			if ok and owns then
				if not player:FindFirstChild("GP_" .. passName) then
					local tag = Instance.new("BoolValue")
					tag.Name   = "GP_" .. passName
					tag.Value  = true
					tag.Parent = player
				end
			end
		end
	end
end

-- ─── Starter Pack (one-time cash grant) ──────────────────────────────────────
local function applyStarterPack(player)
	if PASSES.STARTER_PACK == 0 then return end
	local data = BrainrotData.Get(player.UserId)
	if not data then return end
	if data.starterPackClaimed then return end

	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, PASSES.STARTER_PACK)
	end)
	if ok and owns then
		BrainrotData.AddCash(player.UserId, 5000)
		data.starterPackClaimed = true
		print(("[GamePassServer] Starter Pack granted to %s"):format(player.Name))
	end
end

-- ─── Player Added ─────────────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		grantPassTags(player)
		applyStarterPack(player)
	end)
end)

-- Handle players already in-game (Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		grantPassTags(player)
		applyStarterPack(player)
	end)
end

-- ─── Client-requested purchase prompt ────────────────────────────────────────
local BuyPass = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("BuyPass")

BuyPass.OnServerEvent:Connect(function(player, passId)
	if typeof(passId) ~= "number" then return end
	-- Validate that passId belongs to a known pass
	local valid = false
	for _, id in pairs(PASSES) do
		if id == passId and passId > 0 then
			valid = true
			break
		end
	end
	if not valid then return end
	MarketplaceService:PromptGamePassPurchase(player, passId)
end)

-- ─── Purchase Completed Callback ─────────────────────────────────────────────
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if not purchased then return end

	for passName, id in pairs(PASSES) do
		if id == passId then
			if not player:FindFirstChild("GP_" .. passName) then
				local tag = Instance.new("BoolValue")
				tag.Name   = "GP_" .. passName
				tag.Value  = true
				tag.Parent = player
			end

			-- Starter Pack purchased mid-session
			if passName == "STARTER_PACK" then
				applyStarterPack(player)
			end

			print(("[GamePassServer] %s purchased pass %s"):format(player.Name, passName))
		end
	end
end)
