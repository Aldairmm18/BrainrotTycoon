-- ReplicatedStorage/Modules/MissionConfig.lua

local MissionConfig = {}

-- Tipos de misión:
-- "kill"    : matar N enemigos
-- "survive" : sobrevivir N segundos
-- "zone"    : llegar/desbloquear zona N
-- "ability" : usar habilidades N veces
-- "kills_zone": matar N enemigos en zona específica

MissionConfig.POOL = {
	-- ══ FÁCILES ══
	{
		id          = "kill_20",
		difficulty  = "easy",
		title       = "Cazador Novato",
		description = "Mata 20 enemigos en una sesión",
		type        = "kill",
		target      = 20,
		reward      = {type = "coins", amount = 300},
	},
	{
		id          = "survive_2min",
		difficulty  = "easy",
		title       = "Superviviente",
		description = "Sobrevive 2 minutos sin morir",
		type        = "survive",
		target      = 120, -- segundos
		reward      = {type = "coins", amount = 300},
	},
	{
		id          = "visit_zone2",
		difficulty  = "easy",
		title       = "Explorador",
		description = "Visita el Bosque Oscuro (Zona 2)",
		type        = "zone",
		target      = 2,
		reward      = {type = "coins", amount = 200},
	},

	-- ══ MEDIAS ══
	{
		id          = "kill_50",
		difficulty  = "medium",
		title       = "Matanza",
		description = "Mata 50 enemigos en total hoy",
		type        = "kill",
		target      = 50,
		reward      = {type = "coins", amount = 600},
	},
	{
		id          = "survive_5min",
		difficulty  = "medium",
		title       = "Resistencia",
		description = "Sobrevive 5 minutos y obtén una estrella",
		type        = "survive_star",
		target      = 300,
		reward      = {type = "multi", items = {
			{type = "coins", amount = 600},
			{type = "star",  amount = 1},
		}},
	},
	{
		id          = "reach_zone3",
		difficulty  = "medium",
		title       = "Atleta del Infierno",
		description = "Llega a las Ruinas Volcánicas (Zona 3)",
		type        = "zone",
		target      = 3,
		reward      = {type = "coins", amount = 500},
	},

	-- ══ DIFÍCILES ══
	{
		id          = "kill_100",
		difficulty  = "hard",
		title       = "Genocida",
		description = "Mata 100 enemigos en total hoy",
		type        = "kill",
		target      = 100,
		reward      = {type = "coins", amount = 1200},
	},
	{
		id          = "survive_10min",
		difficulty  = "hard",
		title       = "Leyenda Viviente",
		description = "Sobrevive 10 minutos y abre el cofre del guerrero",
		type        = "survive_chest",
		target      = 600,
		reward      = {type = "multi", items = {
			{type = "coins",        amount = 1200},
			{type = "weapon_chest", rarity = "legendario"},
		}},
	},
	{
		id          = "reach_zone4",
		difficulty  = "hard",
		title       = "Conquistador del Void",
		description = "Llega al Void (Zona 4) con Rebirth desbloqueado",
		type        = "zone",
		target      = 4,
		reward      = {type = "coins", amount = 1000},
	},
}

-- Una de cada dificultad por día
MissionConfig.DAILY_COUNT = {easy = 1, medium = 1, hard = 1}

-- Resetear misiones a medianoche (comparar fecha YYYY-MM-DD)
MissionConfig.RESET_TIME = "midnight"

return MissionConfig
