-- ReplicatedStorage/Modules/ZoneConfig.lua

local ZoneConfig = {
	[1] = {
		name           = "Campo Abierto",
		levelReq       = 1,
		requiresRebirth = 0,
		description    = "El punto de entrada. Enemigos básicos.",
		ambientColor   = Color3.fromRGB(135, 206, 235), -- cielo azul
		fogEnd         = 1000,
	},
	[2] = {
		name           = "Bosque Oscuro",
		levelReq       = 10,
		requiresRebirth = 0,
		description    = "La oscuridad esconde peligros.",
		ambientColor   = Color3.fromRGB(30, 60, 30),
		fogEnd         = 400,
	},
	[3] = {
		name           = "Ruinas Volcánicas",
		levelReq       = 30,
		requiresRebirth = 0,
		description    = "El suelo arde. Los enemigos son brutales.",
		ambientColor   = Color3.fromRGB(180, 60, 20),
		fogEnd         = 300,
	},
	[4] = {
		name           = "El Void",
		levelReq       = 60,
		requiresRebirth = 1,
		description    = "Solo los renacidos pueden entrar. El fin del camino.",
		ambientColor   = Color3.fromRGB(20, 0, 40),
		fogEnd         = 200,
	},
}

-- Zona Base (zona segura de spawn)
ZoneConfig.BASE = {
	name        = "Home Base",
	description = "Zona segura. Aquí empieza todo.",
	levelReq    = 0,
}

-- Número total de zonas normales
ZoneConfig.TOTAL_ZONES = 4

-- Devuelve si un jugador puede entrar a una zona
function ZoneConfig.canEnterZone(zoneIndex, playerLevel, playerRebirth)
	local zone = ZoneConfig[zoneIndex]
	if not zone then return false end
	local levelOk   = playerLevel >= zone.levelReq
	local rebirthOk = playerRebirth >= (zone.requiresRebirth or 0)
	return levelOk and rebirthOk
end

return ZoneConfig
