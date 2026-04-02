-- RemoveSABKit (Script)
-- ServerScriptService/RemoveSABKit
-- Removes any third-party/SAB kit scripts that modify WalkSpeed/JumpPower.

local function scanAndDisable(parent)
	for _, child in ipairs(parent:GetDescendants()) do
		if child:IsA("Script") or child:IsA("LocalScript") then
			-- List of known BrainrotTycoon core scripts to keep safe
			local safeScripts = {
				"ActivityBonusServer", "AuraServer", "CodesServer",
				"DataStoreManager", "EconomyServer", "EventServer",
				"FusionServer", "GachaServer", "GamePassServer",
				"GuardianServer", "LeaderboardGlobal", "MissionsServer",
				"PetServer", "RebornServer", "StealServer", "TutorialServer",
				"RemoveSABKit", "BrainrotData"
			}
			
			local isSafe = false
			for _, safeName in ipairs(safeScripts) do
				if child.Name == safeName then
					isSafe = true
					break
				end
			end

			-- Check if it belongs to SAB or is a speed script
			if not isSafe then
				local n = string.lower(child.Name)
				-- We look for SAB or anything speed related in Workspace/ServerScriptService
				if string.find(n, "speed") or string.find(n, "sab") or string.find(n, "walk") or string.find(n, "jump") then
					child.Disabled = true
					child:Destroy()
					print("[SAB Fix] Destroyed interfering speed/SAB script:", child.GetFullName and child:GetFullName() or child.Name)
				end
			end
		end
	end
end

-- Scan Workspace and ServerScriptService immediately on startup
scanAndDisable(workspace)
scanAndDisable(game:GetService("ServerScriptService"))

-- Just to be 100% safe, enforce WalkSpeed=16 and JumpPower=50 on all characters
game:GetService("Players").PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			-- Reset to default Roblox values continuously if changed by any leftover rogue script
			hum.WalkSpeed = 16
			hum.JumpPower = 50
			
			hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				if hum.WalkSpeed ~= 16 then
					hum.WalkSpeed = 16
				end
			end)
			hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
				if hum.JumpPower ~= 50 then
					hum.JumpPower = 50
				end
			end)
		end
	end)
end)
