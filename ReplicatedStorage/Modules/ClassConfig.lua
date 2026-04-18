-- ReplicatedStorage/Modules/ClassConfig.lua

local ClassConfig = {
	Runner = {
		speed    = 32,
		damage   = 15,
		maxHP    = 80,
		ability  = "sprint",
		cooldown = 15,
		description = "El más veloz. Corre alejarte del peligro.",
		gamepassRequired = false,
	},
	Tank = {
		speed    = 14,
		damage   = 22,
		maxHP    = 200,
		ability  = "shield",
		cooldown = 20,
		description = "Aguanta todo. Escudo indestructible.",
		gamepassRequired = false,
	},
	Warrior = {
		speed    = 20,
		damage   = 40,
		maxHP    = 120,
		ability  = "berserker",
		cooldown = 18,
		description = "Furia total. Dobla el daño por 4 segundos.",
		gamepassRequired = false,
	},
	Mage = {
		speed    = 20,
		damage   = 35,
		maxHP    = 100,
		ability  = "aoe_freeze",
		cooldown = 22,
		description = "Congela todos los enemigos en radio.",
		gamepassRequired = false,
	},
	Rogue = {
		speed    = 26,
		damage   = 32,
		maxHP    = 90,
		ability  = "invisible",
		cooldown = 16,
		description = "Invisibilidad por 4 segundos.",
		gamepassRequired = false,
	},
	Phantom = {
		speed    = 28,
		damage   = 35,
		maxHP    = 130,
		ability  = "teleport",
		cooldown = 12,
		description = "Teletransportación instantánea (20 studs). [GAMEPASS]",
		gamepassRequired = true,
		gamepassId = 0, -- Reemplazar con ID real del GamePass
	},
}

-- Costo de cambiar de clase (si ya tenía una)
ClassConfig.CHANGE_COST = 500

-- Orden de presentación en la UI
ClassConfig.ORDER = {"Runner", "Tank", "Warrior", "Mage", "Rogue", "Phantom"}

return ClassConfig
