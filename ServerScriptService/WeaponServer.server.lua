-- ServerScriptService/WeaponServer.server.lua
-- Equipar armas y restaurarlas al respawnear

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")

local WeaponConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WeaponConfig"))

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local EquipWeapon   = RemoteEvents:WaitForChild("EquipWeapon")

local function waitForDSM()
	local t = 0
	while not _G.DataStoreManager and t < 10 do
		task.wait(0.5)
		t += 0.5
	end
	return _G.DataStoreManager
end
local DSM = waitForDSM()

-- Carpeta de herramientas en ServerStorage
local function getWeaponTool(weaponKey)
	local toolsFolder = ServerStorage:FindFirstChild("Weapons")
	if toolsFolder then
		local tool = toolsFolder:FindFirstChild(weaponKey)
		if tool then return tool:Clone() end
	end

	-- Crear tool básica si no existe modelo
	local tool     = Instance.new("Tool")
	tool.Name      = weaponKey
	tool.RequiresHandle = false

	local handle   = Instance.new("Part")
	handle.Name    = "Handle"
	handle.Size    = Vector3.new(0.3, 2, 0.3)
	handle.BrickColor = BrickColor.new("Bright yellow")
	handle.Parent  = tool

	return tool
end

local function giveWeapon(player, weaponKey)
	if not WeaponConfig[weaponKey] then return end

	local char      = player.Character
	if not char then return end

	-- Eliminar arma anterior del backpack
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") then item:Destroy() end
		end
	end
	-- Eliminar del personaje también
	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Tool") then item:Destroy() end
	end

	local tool = getWeaponTool(weaponKey)
	if backpack then
		tool.Parent = backpack
	end
end

-- ── Equipar arma desde cliente ────────────────────────────────────────────────
EquipWeapon.OnServerEvent:Connect(function(player, weaponKey)
	if not WeaponConfig[weaponKey] then return end

	local userId = tostring(player.UserId)
	local data   = DSM and DSM.Get(userId)
	if not data then return end

	-- Validar posesión
	if not data.ownedWeapons or not data.ownedWeapons[weaponKey] then
		warn("[WeaponServer] " .. player.Name .. " no tiene " .. weaponKey)
		return
	end

	data.equippedWeapon = weaponKey
	DSM.MarkDirty(player)

	giveWeapon(player, weaponKey)
end)

-- ── Restaurar arma al respawnear ──────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		local userId = tostring(player.UserId)
		local data   = DSM and DSM.Get(userId)
		if not data then return end

		local weaponKey = data.equippedWeapon or "EspadaMadera"
		giveWeapon(player, weaponKey)
	end)
end)
