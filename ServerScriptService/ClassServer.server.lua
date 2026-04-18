-- ServerScriptService/ClassServer.server.lua
-- Gestiona la selección de clase y aplica stats al personaje

local Players         = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ClassConfig"))
local DSM         = _G.DataStoreManager

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local SelectClass   = RemoteEvents:WaitForChild("SelectClass")
local ClassSelected = RemoteEvents:WaitForChild("ClassSelected")
local UpdateCoins   = RemoteEvents:WaitForChild("UpdateCoins")

-- Esperar a que DSM esté disponible
local function waitForDSM()
	local t = 0
	while not _G.DataStoreManager and t < 10 do
		task.wait(0.5)
		t += 0.5
	end
	return _G.DataStoreManager
end
DSM = waitForDSM()

-- Aplica los stats de clase al personaje
local function applyClassStats(player, className)
	local config = ClassConfig[className]
	if not config then return end

	local char = player.Character or player.CharacterAdded:Wait()
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid.WalkSpeed  = config.speed
	humanoid.MaxHealth  = config.maxHP
	humanoid.Health     = config.maxHP
end

-- Al unirse un jugador, aplicar clase guardada
Players.PlayerAdded:Connect(function(player)
	local userId = tostring(player.UserId)

	-- Esperar datos
	task.wait(1)
	if not DSM then DSM = waitForDSM() end
	local data = DSM and DSM.Get(userId)
	if not data then return end

	-- Aplicar al spawnar
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		applyClassStats(player, data.selectedClass or "Runner")
	end)

	-- Aplicar si ya tiene personaje
	if player.Character then
		applyClassStats(player, data.selectedClass or "Runner")
	end
end)

-- Manejar selección de clase desde el cliente
SelectClass.OnServerEvent:Connect(function(player, className)
	if not ClassConfig[className] then
		warn("[ClassServer] Clase inválida: " .. tostring(className))
		return
	end

	-- GamePass check para Phantom
	if ClassConfig[className].gamepassRequired then
		local MarketplaceService = game:GetService("MarketplaceService")
		local passId = ClassConfig[className].gamepassId or 0
		local hasPass = false
		local ok, err = pcall(function()
			hasPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		if not (ok and hasPass) then
			warn("[ClassServer] " .. player.Name .. " no tiene GamePass para " .. className)
			return
		end
	end

	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	-- Si ya tiene clase, cobrar por cambiar
	if data.tutorialComplete and data.selectedClass ~= className then
		local cost = ClassConfig.CHANGE_COST
		local spent = DSM.SpendCoins(player, cost)
		if not spent then
			warn("[ClassServer] " .. player.Name .. " no tiene monedas para cambiar de clase")
			return
		end
		UpdateCoins:FireClient(player, data.coins)
	end

	data.selectedClass = className
	DSM.MarkDirty(player)

	-- Aplicar stats inmediatamente
	applyClassStats(player, className)

	-- Notificar al cliente
	ClassSelected:FireClient(player, className, ClassConfig[className])
end)
