-- ReplicatedStorage/Modules/ShopConfig.lua

local ShopConfig = {

	ArmeriaBasica = {
		name       = "Armería Básica",
		zone       = 1,
		position   = Vector3.new(100, 0, 50), -- Editar según mapa real
		description = "Armas simples para empezar.",
		weapons    = {"EspadaHierro", "Lanza", "Arco"},
		stats      = {},
	},

	FarmaciaVelocidad = {
		name       = "Farmacia de Velocidad",
		zone       = 1,
		position   = Vector3.new(120, 0, 50),
		description = "Mejora tu velocidad y resistencia.",
		weapons    = {},
		stats      = {
			{
				id          = "speed_boost_1",
				name        = "Botas Ligeras I",
				description = "+2 velocidad permanente",
				price       = 300,
				effect      = {stat = "speed", amount = 2},
			},
			{
				id          = "hp_boost_1",
				name        = "Poción de Vida I",
				description = "+15 HP máximo permanente",
				price       = 250,
				effect      = {stat = "maxHP", amount = 15},
			},
		},
	},

	ArmeriaMed = {
		name       = "Armería Media",
		zone       = 2,
		position   = Vector3.new(250, 0, 80),
		description = "Armas del Bosque Oscuro.",
		weapons    = {"Martillo", "EspadaCristal", "Katana", "RifleMagico"},
		stats      = {},
	},

	TiendaStats = {
		name       = "Tienda de Stats",
		zone       = 2,
		position   = Vector3.new(280, 0, 80),
		description = "Mejoras de combate avanzadas.",
		weapons    = {},
		stats      = {
			{
				id          = "speed_boost_2",
				name        = "Botas Élite",
				description = "+4 velocidad permanente",
				price       = 800,
				effect      = {stat = "speed", amount = 4},
			},
			{
				id          = "hp_boost_2",
				name        = "Elixir de Vida",
				description = "+30 HP máximo permanente",
				price       = 700,
				effect      = {stat = "maxHP", amount = 30},
			},
			{
				id          = "dmg_boost_1",
				name        = "Fuerza Bruta",
				description = "+10 daño permanente",
				price       = 900,
				effect      = {stat = "damage", amount = 10},
			},
		},
	},

	ArmeriaAvanzada = {
		name       = "Armería Avanzada",
		zone       = 3,
		position   = Vector3.new(450, 0, 100),
		description = "Las armas más poderosas del mundo mortal.",
		weapons    = {"EspadaFuego", "BastonArcano"},
		stats      = {
			{
				id          = "speed_boost_3",
				name        = "Viento del Abismo",
				description = "+6 velocidad permanente",
				price       = 2000,
				effect      = {stat = "speed", amount = 6},
			},
			{
				id          = "hp_boost_3",
				name        = "Cristal Vital",
				description = "+50 HP máximo permanente",
				price       = 1800,
				effect      = {stat = "maxHP", amount = 50},
			},
			{
				id          = "dmg_boost_2",
				name        = "Esencia de Poder",
				description = "+20 daño permanente",
				price       = 2500,
				effect      = {stat = "damage", amount = 20},
			},
		},
	},

	TiendaLegendaria = {
		name       = "Tienda del Void",
		zone       = 4,
		position   = Vector3.new(700, 0, 150),
		description = "Solo para renacidos. Poder absoluto.",
		weapons    = {"LanzaVoid", "EspadaLegendaria"},
		stats      = {
			{
				id          = "void_essence",
				name        = "Esencia Void",
				description = "+35 daño y +5 velocidad permanente",
				price       = 8000,
				effect      = {stat = "both", damage = 35, speed = 5},
			},
		},
	},
}

-- Índice de tiendas por zona para el servidor
ShopConfig.BY_ZONE = {
	[1] = {"ArmeriaBasica", "FarmaciaVelocidad"},
	[2] = {"ArmeriaMed", "TiendaStats"},
	[3] = {"ArmeriaAvanzada"},
	[4] = {"TiendaLegendaria"},
}

return ShopConfig
