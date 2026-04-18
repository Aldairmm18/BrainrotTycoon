-- ReplicatedStorage/Modules/GiftConfig.lua

-- Tipos de regalo posibles:
-- {type="coins", amount=N}
-- {type="weapon", key="WeaponKey"}
-- {type="skin", key="SkinKey"}
-- {type="skin_temp", key="SkinKey", days=N}
-- {type="potion", effect="speed", duration=600}  -- segundos
-- {type="rebirth_boost", amount=N}   -- XP boost temporal
-- {type="title", name="Titulo"}
-- {type="aura", name="Aura"}
-- {type="multi", items={...}}        -- múltiples items

local GiftConfig = {}

-- Días intermedios: escalado gradual de monedas
local function interpolateCoins(day)
	-- Fórmula: base 100 + (day-1) * 25, cap en puntos clave
	return math.floor(100 + (day - 1) * 25)
end

-- Días especiales
local specialDays = {
	[1]  = {type = "coins",    amount = 200},
	[2]  = {type = "coins",    amount = 500},
	[3]  = {type = "weapon",   key = "Lanza"},
	[4]  = {type = "multi",    items = {
		{type = "coins", amount = 1000},
		{type = "potion", effect = "speed", duration = 600},
	}},
	[5]  = {type = "skin_temp", key = "skinStreak7", days = 3},
	[6]  = {type = "coins",    amount = 2000},
	[7]  = {type = "multi",    items = {
		{type = "skin",   key = "skinOroBronce"},
		{type = "coins",  amount = 3000},
	}},
	[14] = {type = "weapon",   key = "EspadaCristal"},
	[21] = {type = "coins",    amount = 5000},
	[30] = {type = "multi",    items = {
		{type = "skin",   key = "skinDiamante"},
		{type = "coins",  amount = 10000},
	}},
	[60] = {type = "multi",    items = {
		{type = "title",  name = "Dedicado"},
		{type = "aura",   name = "AuraDorada"},
		{type = "coins",  amount = 25000},
	}},
	[100] = {type = "multi",   items = {
		{type = "skin",          key = "skinVoidKnight"},
		{type = "rebirth_boost", amount = 2},
	}},
}

-- Construir tabla completa días 1-100
for day = 1, 100 do
	if specialDays[day] then
		GiftConfig[day] = specialDays[day]
	else
		GiftConfig[day] = {type = "coins", amount = interpolateCoins(day)}
	end
end

-- Recompensas de hitos de tiempo de sesión
GiftConfig.TIME_MILESTONES = {
	{minutes = 1,  reward = {type = "coins", amount = 100}},
	{minutes = 3,  reward = {type = "coins", amount = 300}},
	{minutes = 5,  reward = {type = "weapon_chest", rarity = "raro"}},
	{minutes = 10, reward = {type = "multi", items = {
		{type = "coins", amount = 1000},
		{type = "title", name = "10min Survivor"},
	}}},
	{minutes = 15, reward = {type = "skin_temp", key = "skinSurvivor", days = 3}},
	{minutes = 20, reward = {type = "multi", items = {
		{type = "coins", amount = 3000},
		{type = "zone_access", zone = "exclusive", duration = 3600},
	}}},
	{minutes = 30, reward = {type = "skin", key = "skinSurvivor"}},
	{minutes = 45, reward = {type = "multi", items = {
		{type = "coins", amount = 5000},
		{type = "weapon_temp", key = "EspadaLegendaria", duration = 3600},
	}}},
	{minutes = 60, reward = {type = "multi", items = {
		{type = "title", name = "1h Legend"},
		{type = "coins", amount = 10000},
		{type = "skin",  key = "skinBloodMoon"},
	}}},
}

-- Horas mínimas entre reclamaciones del regalo diario
GiftConfig.MIN_HOURS_BETWEEN_CLAIMS = 20

return GiftConfig
