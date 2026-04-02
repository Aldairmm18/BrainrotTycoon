-- RebornServer (Script)
-- ServerScriptService/RebornServer
-- Handles Rebirth requests. Awards titles and fires global notification.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(script.Parent.BrainrotData)

local RemoteEvents        = ReplicatedStorage.RemoteEvents
local RebirthEvent        = RemoteEvents.Rebirth
local RebornResult        = RemoteEvents.RebornResult
local GlobalNotification  = RemoteEvents:WaitForChild("GlobalNotification")

local MIN_BRAINROTS = 10

-- ─── Title Table ──────────────────────────────────────────────────────────────
local function getTitle(rebirths)
	if rebirths == 0 then   return "Novato Brainrot"
	elseif rebirths <= 2  then return "Coleccionista"
	elseif rebirths <= 5  then return "Maestro Brainrot"
	elseif rebirths <= 10 then return "Leyenda Brainrot"
	elseif rebirths <= 20 then return "Místico Brainrot"
	else                       return "👑 DIOS BRAINROT"
	end
end

-- ─── Title Billboard above character ─────────────────────────────────────────
local function updateTitleBillboard(player, title)
	local char = player.Character
	if not char then return end

	local old = char:FindFirstChild("TitleBillboard")
	if old then old:Destroy() end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name         = "TitleBillboard"
	billboard.Size         = UDim2.new(0, 200, 0, 36)
	billboard.StudsOffset  = Vector3.new(0, 2.8, 0)
	billboard.AlwaysOnTop  = false
	billboard.ResetOnSpawn = false
	billboard.Parent       = hrp

	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = title
	lbl.TextScaled             = true
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextColor3             = Color3.fromRGB(255, 220, 60)
	lbl.TextStrokeTransparency = 0.3
	lbl.ZIndex                 = 5
	lbl.Parent                 = billboard
end

-- ─── Clear workspace parts for player ────────────────────────────────────────
local function clearPlayerParts(userId)
	local folder = workspace:FindFirstChild("Brainrots")
	if not folder then return end
	for _, part in ipairs(folder:GetChildren()) do
		if part:GetAttribute("OwnerId") == userId then
			part:Destroy()
		end
	end
end

-- ─── Rebirth Handler ─────────────────────────────────────────────────────────
RebirthEvent.OnServerEvent:Connect(function(player)
	local userId = player.UserId
	local data   = BrainrotData.Get(userId)
	if not data then return end

	if #data.brainrots < MIN_BRAINROTS then
		warn(("[RebornServer] %s needs %d brainrots, has %d"):format(
			player.Name, MIN_BRAINROTS, #data.brainrots))
		return
	end

	-- 1. Clear world parts
	clearPlayerParts(userId)

	-- 2. Reset data
	BrainrotData.Rebirth(userId)
	local newData = BrainrotData.Get(userId)

	-- 3. Multiplier + title
	local rebirths       = newData.rebirths
	local cashMultiplier = 1 + (rebirths * 0.5)
	local title          = getTitle(rebirths)

	-- 4. Update leaderstats
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local cashVal  = ls:FindFirstChild("Cash")
		if cashVal then cashVal.Value = 0 end
		local rebVal   = ls:FindFirstChild("Rebirths")
		if rebVal then rebVal.Value = rebirths end
	end

	-- 5. Update title billboard (on next CharacterAdded or immediately)
	if player.Character then
		updateTitleBillboard(player, title)
	end
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		updateTitleBillboard(player, title)
	end)

	-- 6. Fire result to client (for explosion animation)
	RebornResult:FireClient(player, {
		rebirths       = rebirths,
		cashMultiplier = cashMultiplier,
		title          = title,
	})

	-- 7. Global notification
	GlobalNotification:FireAllClients({
		msg   = ("🔄 %s hizo Renacimiento #%d!"):format(player.Name, rebirths),
		color = "gold",
	})

	print(("[RebornServer] %s rebirthed #%d → %.1fx multiplier"):format(
		player.Name, rebirths, cashMultiplier))
end)

-- Restore titles on character spawn
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		local data = BrainrotData.Get(player.UserId)
		if data and data.rebirths and data.rebirths > 0 then
			task.wait(0.5)
			updateTitleBillboard(player, getTitle(data.rebirths))
		end
	end)
end)
