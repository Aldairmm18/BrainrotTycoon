-- ServerScriptService/DataStoreManager.server.lua
-- Módulo central de datos del jugador para SurvivalRush

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")

local STORE_NAME  = "SurvivalRushV1"
local AUTOSAVE_INTERVAL = 60

local mainStore = DataStoreService:GetDataStore(STORE_NAME)

-- ── Defaults ─────────────────────────────────────────────────────────────────
local DEFAULTS = {
	coins              = 0,
	level              = 1,
	xp                 = 0,
	rebirthCount       = 0,
	totalKills         = 0,
	totalDeaths        = 0,
	totalTimeSurvived  = 0,
	bestSessionTime    = 0,
	selectedClass      = "Runner",
	ownedWeapons       = {EspadaMadera = {level = 1}},
	equippedWeapon     = "EspadaMadera",
	totalStars         = 0,
	starRank           = "Bronze",
	lastGiftClaim      = 0,
	streakDays         = 0,
	lastLoginDay       = "",
	missionsToday      = {},
	lastMissionReset   = "",
	ownedSkins         = {"default"},
	equippedSkin       = "default",
	unlockedZones      = {1},
	tutorialComplete   = false,
	currentGameMode    = "Survival",
	baseSpeed          = 16,
	baseHP             = 100,
	baseDamage         = 10,
	-- Logros para skins alternativas
	achievements       = {},
}

-- ── Estado en memoria ────────────────────────────────────────────────────────
local DataStoreManager = {}
local _cache   = {}  -- [userId] = data
local _dirty   = {}  -- [userId] = true si tiene cambios sin guardar

-- ── Utilidades ────────────────────────────────────────────────────────────────
local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

local function mergeDefaults(data)
	for key, defaultValue in pairs(DEFAULTS) do
		if data[key] == nil then
			if type(defaultValue) == "table" then
				data[key] = deepCopy(defaultValue)
			else
				data[key] = defaultValue
			end
		end
	end
	return data
end

-- ── Load ─────────────────────────────────────────────────────────────────────
function DataStoreManager.Get(userId)
	if _cache[userId] then
		return _cache[userId]
	end

	local data
	local success, err = pcall(function()
		data = mainStore:GetAsync("player_" .. userId)
	end)

	if not success then
		warn("[DataStoreManager] Error al cargar datos de " .. userId .. ": " .. tostring(err))
		data = nil
	end

	if type(data) ~= "table" then
		data = deepCopy(DEFAULTS)
	else
		data = mergeDefaults(data)
	end

	_cache[userId]  = data
	_dirty[userId]  = false
	return data
end

-- ── Save ─────────────────────────────────────────────────────────────────────
function DataStoreManager.Save(player)
	if typeof(player) == "Instance" then
		player = player.UserId
	end
	local userId = tostring(player)
	local data   = _cache[userId]
	if not data then return end

	local success, err = pcall(function()
		mainStore:SetAsync("player_" .. userId, data)
	end)

	if success then
		_dirty[userId] = false
	else
		warn("[DataStoreManager] Error al guardar datos de " .. userId .. ": " .. tostring(err))
	end
end

-- ── Coins ─────────────────────────────────────────────────────────────────────
function DataStoreManager.AddCoins(player, amount)
	local userId = tostring(typeof(player) == "Instance" and player.UserId or player)
	local data   = _cache[userId]
	if not data then return false end
	data.coins  = data.coins + amount
	_dirty[userId] = true
	return true
end

function DataStoreManager.SpendCoins(player, amount)
	local userId = tostring(typeof(player) == "Instance" and player.UserId or player)
	local data   = _cache[userId]
	if not data then return false end
	if data.coins < amount then return false end
	data.coins  = data.coins - amount
	_dirty[userId] = true
	return true
end

-- ── Mark dirty ────────────────────────────────────────────────────────────────
function DataStoreManager.MarkDirty(player)
	local userId = tostring(typeof(player) == "Instance" and player.UserId or player)
	_dirty[userId] = true
end

-- ── Player lifecycle ─────────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	DataStoreManager.Get(tostring(player.UserId))
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = tostring(player.UserId)
	DataStoreManager.Save(userId)
	_cache[userId] = nil
	_dirty[userId] = nil
end)

-- ── Auto-save loop ────────────────────────────────────────────────────────────
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for userId, isDirty in pairs(_dirty) do
			if isDirty then
				DataStoreManager.Save(userId)
			end
		end
	end
end)

-- ── Shutdown save ─────────────────────────────────────────────────────────────
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataStoreManager.Save(player)
	end
end)

-- Exponer como módulo a requerir desde otros scripts
local moduleRef = {}
for k, v in pairs(DataStoreManager) do
	moduleRef[k] = v
end
_G.DataStoreManager = DataStoreManager

return DataStoreManager
