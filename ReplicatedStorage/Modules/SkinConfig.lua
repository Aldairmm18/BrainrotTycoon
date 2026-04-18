-- ReplicatedStorage/Modules/SkinConfig.lua

-- Métodos de desbloqueo:
-- "free"    : todos lo tienen desde el inicio
-- "coins"   : comprar con monedas
-- "streak"  : alcanzar streak de regalo diario
-- "time"    : sobrevivir X minutos acumulados
-- "event"   : evento especial (Blood Moon, etc.)
-- "robux"   : comprar con Robux (GamePass)
-- "rebirth" : alcanzar rebirth N
-- "achievement": logro específico

local SkinConfig = {
	-- ══ DEFAULT ══
	{
		id          = "default",
		name        = "Clásico",
		description = "El skin base. Simple y funcional.",
		unlock      = "free",
		preview     = {
			bodyColor   = Color3.fromRGB(163, 162, 165),
			material    = Enum.Material.SmoothPlastic,
		},
	},

	-- ══ COINS ══
	{
		id          = "skinOroBronce",
		name        = "Guerrero Bronce",
		description = "Reluciente armadura de bronce.",
		unlock      = "coins",
		price       = 2000,
		preview     = {
			bodyColor   = Color3.fromRGB(180, 120, 50),
			material    = Enum.Material.Metal,
		},
	},
	{
		id          = "skinDiamante",
		name        = "Campeón Diamante",
		description = "Puro cristal de diamante.",
		unlock      = "coins",
		price       = 5000,
		preview     = {
			bodyColor   = Color3.fromRGB(185, 242, 255),
			material    = Enum.Material.Glass,
		},
	},
	{
		id          = "skinOscuro",
		name        = "Sombra Oscura",
		description = "Emerge de las sombras.",
		unlock      = "coins",
		price       = 3500,
		preview     = {
			bodyColor   = Color3.fromRGB(20, 20, 30),
			material    = Enum.Material.SmoothPlastic,
		},
	},

	-- ══ STREAK / LOGROS ══
	{
		id          = "skinStreak7",
		name        = "Fiel Guerrero",
		description = "Premio por 7 días de streak seguidos.",
		unlock      = "streak",
		streakReq   = 7,
		preview     = {
			bodyColor   = Color3.fromRGB(255, 200, 50),
			material    = Enum.Material.Neon,
		},
	},

	-- ══ TIEMPO ══
	{
		id          = "skinSurvivor",
		name        = "Superviviente",
		description = "Sobrevive 30 minutos en una sesión.",
		unlock      = "time",
		minutesReq  = 30,
		preview     = {
			bodyColor   = Color3.fromRGB(50, 200, 100),
			material    = Enum.Material.SmoothPlastic,
		},
	},

	-- ══ EVENTO ══
	{
		id          = "skinBloodMoon",
		name        = "Maldito de la Luna Roja",
		description = "Solo disponible durante el evento Blood Moon.",
		unlock      = "event",
		eventId     = "blood_moon",
		preview     = {
			bodyColor   = Color3.fromRGB(180, 0, 30),
			material    = Enum.Material.Neon,
		},
	},

	-- ══ ROBUX / LOGRO ALTERNATIVO ══
	{
		id              = "skinVoidKnight",
		name            = "Caballero del Void",
		description     = "Forjado en el Void. Aterra a los enemigos.",
		unlock          = "robux",
		robuxPrice      = 399,
		-- Alternativa por logro: sobrevivir 30 min en 5 sesiones distintas
		altUnlock       = "achievement",
		altAchievement  = "survive_30min_5times",
		altDescription  = "O sobrevive 30 min en 5 sesiones separadas.",
		preview         = {
			bodyColor   = Color3.fromRGB(50, 0, 100),
			material    = Enum.Material.Neon,
		},
	},

	-- ══ REBIRTH ══
	{
		id          = "skinRebirth4",
		name        = "Eterno Renacido",
		description = "Premio por alcanzar Rebirth 4.",
		unlock      = "rebirth",
		rebirthReq  = 4,
		preview     = {
			bodyColor   = Color3.fromRGB(255, 165, 0),
			material    = Enum.Material.Foil,
		},
	},
	{
		id          = "skinLegendario",
		name        = "Leyenda Arcoíris",
		description = "Premio máximo: Rebirth 10.",
		unlock      = "rebirth",
		rebirthReq  = 10,
		preview     = {
			bodyColor   = Color3.fromRGB(255, 100, 200),
			material    = Enum.Material.Neon,
		},
	},
	{
		id          = "skinFuego",
		name        = "Alma de Fuego",
		description = "Para quienes dominan las Ruinas Volcánicas.",
		unlock      = "achievement",
		altAchievement  = "kill_zone3_500",
		altDescription  = "Mata 500 enemigos en Zona 3.",
		preview     = {
			bodyColor   = Color3.fromRGB(255, 80, 0),
			material    = Enum.Material.Neon,
		},
	},
}

-- Crear índice por id para acceso rápido
local _byId = {}
for _, skin in ipairs(SkinConfig) do
	_byId[skin.id] = skin
end

function SkinConfig.getById(id)
	return _byId[id]
end

return SkinConfig
