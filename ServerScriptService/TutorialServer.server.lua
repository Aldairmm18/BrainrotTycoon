-- TutorialServer (Script)
-- ServerScriptService/TutorialServer
-- Tracks whether each player has completed the tutorial.

local Players          = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tutorialStore = DataStoreService:GetDataStore("BrainrotTutorial_v1")
local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local TutorialDone  = RemoteEvents:WaitForChild("TutorialDone")
local TutorialStatus = RemoteEvents:WaitForChild("TutorialStatus")

local _done = {}   -- [userId] = true/false

local function loadTutorial(userId)
	local ok, result = pcall(function()
		return tutorialStore:GetAsync(tostring(userId))
	end)
	_done[userId] = ok and result == true
end

local function saveTutorial(userId)
	local ok, err = pcall(function()
		tutorialStore:SetAsync(tostring(userId), _done[userId] == true)
	end)
	if not ok then
		warn("[TutorialServer] Save failed: " .. tostring(err))
	end
end

TutorialDone.OnServerEvent:Connect(function(player, action)
	local userId = player.UserId
	if action == "check" then
		-- Client is requesting status
		TutorialStatus:FireClient(player, _done[userId] == true)
	else
		-- Client completed tutorial
		_done[userId] = true
		saveTutorial(userId)
	end
end)

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		loadTutorial(player.UserId)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	_done[player.UserId] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadTutorial, player.UserId)
end
