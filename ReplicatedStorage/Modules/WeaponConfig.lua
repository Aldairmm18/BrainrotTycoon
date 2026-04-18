-- ReplicatedStorage/Modules/WeaponConfig.lua

-- Multiplicadores de daño por nivel de upgrade
local UPGRADE_MULTIPLIERS = {1.0, 1.3, 1.7, 2.2, 3.0}

-- Costos de upgrade (precio_arma * factor)
local UPGRADE_COST_FACTORS = {0, 0.5, 1.0, 2.0, 4.0}

local WeaponConfig = {
	EspadaMadera = {
		name       = "Espada de Madera",
		type       = "Melee",
		damage     = 10,
		attackSpeed = "Rapido",
		range      = "Corto",
		price      = 0,
		zoneReq    = 1,
		isFree     = true,
		description = "El arma de inicio. Débil pero rápida.",
	},
	EspadaHierro = {
		name       = "Espada de Hierro",
		type       = "Melee",
		damage     = 22,
		attackSpeed = "Rapido",
		range      = "Corto",
		price      = 200,
		zoneReq    = 1,
		description = "Sólida y confiable.",
	},
	Lanza = {
		name       = "Lanza",
		type       = "Melee",
		damage     = 18,
		attackSpeed = "Medio",
		range      = "Medio",
		price      = 350,
		zoneReq    = 1,
		description = "Mayor alcance que las espadas.",
	},
	Arco = {
		name       = "Arco",
		type       = "Ranged",
		damage     = 15,
		attackSpeed = "Medio",
		range      = "Largo",
		price      = 400,
		zoneReq    = 1,
		description = "Ataque a distancia. Ideal para kiting.",
	},
	Martillo = {
		name       = "Martillo",
		type       = "Melee",
		damage     = 40,
		attackSpeed = "Lento",
		range      = "Corto",
		price      = 600,
		zoneReq    = 2,
		description = "Lento pero brutal.",
	},
	EspadaCristal = {
		name       = "Espada de Cristal",
		type       = "Melee",
		damage     = 55,
		attackSpeed = "Rapido",
		range      = "Corto",
		price      = 1200,
		zoneReq    = 2,
		description = "Cristalina y mortal.",
	},
	Katana = {
		name       = "Katana",
		type       = "Melee",
		damage     = 45,
		attackSpeed = "MuyRapido",
		range      = "Corto",
		price      = 1500,
		zoneReq    = 2,
		description = "Velocidad de ataque extrema.",
	},
	RifleMagico = {
		name       = "Rifle Mágico",
		type       = "Magic",
		damage     = 50,
		attackSpeed = "Medio",
		range      = "MuyLargo",
		price      = 2000,
		zoneReq    = 2,
		description = "Proyectiles mágicos de larga distancia.",
	},
	EspadaFuego = {
		name       = "Espada de Fuego",
		type       = "Melee",
		damage     = 80,
		attackSpeed = "Rapido",
		range      = "Corto",
		price      = 4000,
		zoneReq    = 3,
		description = "Arde con fuego infernal.",
	},
	BastonArcano = {
		name       = "Bastón Arcano",
		type       = "Magic",
		damage     = 120,
		attackSpeed = "Lento",
		range      = "Largo",
		price      = 8000,
		zoneReq    = 3,
		description = "Poder arcano concentrado.",
	},
	LanzaVoid = {
		name       = "Lanza del Void",
		type       = "Melee",
		damage     = 150,
		attackSpeed = "Rapido",
		range      = "Medio",
		price      = 10000,
		zoneReq    = 4,
		description = "Forjada en las profundidades del Void.",
	},
	EspadaLegendaria = {
		name       = "Espada Legendaria",
		type       = "Melee",
		damage     = 200,
		attackSpeed = "MuyRapido",
		range      = "Corto",
		price      = 25000,
		zoneReq    = 4,
		description = "La cima del poder. Solo para los mejores.",
	},
}

-- Calcular daño y costo de upgrade para un arma en cierto nivel
function WeaponConfig.getUpgradedDamage(weaponKey, upgradeLevel)
	local weapon = WeaponConfig[weaponKey]
	if not weapon then return 0 end
	local mult = UPGRADE_MULTIPLIERS[upgradeLevel] or 1.0
	return math.floor(weapon.damage * mult)
end

function WeaponConfig.getUpgradeCost(weaponKey, targetLevel)
	local weapon = WeaponConfig[weaponKey]
	if not weapon then return math.huge end
	local factor = UPGRADE_COST_FACTORS[targetLevel] or 0
	return math.floor(weapon.price * factor)
end

function WeaponConfig.getMultiplier(upgradeLevel)
	return UPGRADE_MULTIPLIERS[upgradeLevel] or 1.0
end

-- Orden de presentación en la tienda
WeaponConfig.ORDER = {
	"EspadaMadera", "EspadaHierro", "Lanza", "Arco",
	"Martillo", "EspadaCristal", "Katana", "RifleMagico",
	"EspadaFuego", "BastonArcano", "LanzaVoid", "EspadaLegendaria"
}

-- Max upgrade level
WeaponConfig.MAX_LEVEL = 5

-- Probabilidades de arma de inicio aleatoria
WeaponConfig.START_CHANCES = {
	{key = "EspadaMadera",  weight = 70},
	{key = "Lanza",         weight = 20},
	{key = "Arco",          weight = 8},
	{key = "EspadaHierro",  weight = 2},
}

return WeaponConfig
