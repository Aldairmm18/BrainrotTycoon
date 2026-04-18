-- ServerScriptService/StarServer.server.lua
-- Sistema de 5 estrellas al finalizar sesión

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Contadores de habilidades usadas por sesión
local abilityCount = {}  -- [userId] = N

-- Criterios de estrellas
local STAR_CRITERIA = {
	{id="time5",      desc="Sobrevivir más de 5 minutos",    check = function(t) return t.elapsed >= 300 end},
	{id="kills20",    desc="Matar 20+ enemigos",            check = function(t) return (t.kills or 0) >= 20 end},
	{id="noDeath",    desc="Sin morir en la sesión",        check = function(t) return (t.deaths or 0) == 0 end},
	{id="missionDone",desc="Completar una misión",          check = function(t) return (t.missionComplete or false) end},
	{id="ability5",   desc="Usar habilidad 5 veces",        check = function(t) return (t.abilitiesUsed or 0) >= 5 end},
}

local RANK_THRESHOLDS = {
	{name="Bronze",   stars=0},
	{name="Silver",   stars=25},
	{name="Gold",     stars=75},
	{name="Platinum", stars=150},
	{name="Diamond",  stars=300},
	{name="Legend",   stars=500},
}

local function getStarRank(totalStars)
	local rank = "Bronze"
	for _, r in ipairs(RANK_THRESHOLDS) do
		if totalStars >= r.stars then
			rank = r.name
		end
	end
	return rank
end

local function onAbilityUsed(player)
	local userId = tostring(player.UserId)
	abilityCount[userId] = (abilityCount[userId] or 0) + 1
end

local function calculateStars(player, timerState)
	local userId = tostring(player.UserId)

	local sessionData = {
		elapsed        = timerState.elapsed or 0,
		kills          = timerState.kills or 0,
		deaths         = timerState.deaths or 0,
		missionComplete = timerState.missionComplete or false,
		abilitiesUsed  = abilityCount[userId] or 0,
	}

	local starCount = 0
	local results   = {}

	for _, criterion in ipairs(STAR_CRITERIA) do
		local passed = criterion.check(sessionData)
		table.insert(results, {id=criterion.id, desc=criterion.desc, passed=passed})
		if passed then starCount += 1 end
	end

	-- Acumular estrellas en DataStore
	local DSM = _G.DataStoreManager
	local data = DSM and DSM.Get(userId)
	if data then
		data.totalStars = (data.totalStars or 0) + starCount
		data.starRank   = getStarRank(data.totalStars)
		DSM.MarkDirty(player)
	end

	-- Reset contadores de sesión
	abilityCount[userId] = 0

	return starCount, results, data and data.totalStars or 0, data and data.starRank or "Bronze"
end

_G.StarServer = {
	onAbilityUsed   = onAbilityUsed,
	calculateStars  = calculateStars,
}

Players.PlayerRemoving:Connect(function(player)
	abilityCount[tostring(player.UserId)] = nil
end)
