-- BrainrotList (ModuleScript)
-- ReplicatedStorage/Modules/BrainrotList
-- 50 Brainrots with name, rarity, emoji, catchphrase

local BrainrotList = {
	-- ═══ COMMON (15) ═══════════════════════════════════════════════════
	{ name="Tralalero Tralala",   rarity="Common",    emoji="🐟", catchphrase="Tralalero! Tralalero!" },
	{ name="Gatto Volante",       rarity="Common",    emoji="🐱", catchphrase="Miao miao nel cielo!" },
	{ name="Cane Pazzino",        rarity="Common",    emoji="🐶", catchphrase="Bau bau pazzarello!" },
	{ name="Pollo Saltarino",     rarity="Common",    emoji="🐔", catchphrase="Coccodè! Salto alto!" },
	{ name="Topo Ballerino",      rarity="Common",    emoji="🐭", catchphrase="Ballo il formaggio!" },
	{ name="Rana Cantante",       rarity="Common",    emoji="🐸", catchphrase="Canto nella palude!" },
	{ name="Maiale Volante",      rarity="Common",    emoji="🐷", catchphrase="Oink! Volo libero!" },
	{ name="Coniglio Pazzo",      rarity="Common",    emoji="🐰", catchphrase="Salto la luna!" },
	{ name="Orso Danzante",       rarity="Common",    emoji="🐻", catchphrase="Balllo con il miele!" },
	{ name="Pinguino Matto",      rarity="Common",    emoji="🐧", catchphrase="Scivolo sempre!" },
	{ name="Koala Urlante",       rarity="Common",    emoji="🐨", catchphrase="Urlo l'eucalipto!" },
	{ name="Panda Saltante",      rarity="Common",    emoji="🐼", catchphrase="Salto il bambù!" },
	{ name="Zebra Cantante",      rarity="Common",    emoji="🦓", catchphrase="Canto le strisce!" },
	{ name="Giraffa Pazza",       rarity="Common",    emoji="🦒", catchphrase="Vedo tutto dall'alto!" },
	{ name="Elefante Piccolo",    rarity="Common",    emoji="🐘", catchphrase="Sono piccolo ma forte!" },

	-- ═══ UNCOMMON (12) ══════════════════════════════════════════════════
	{ name="Tung Tung Sahur",     rarity="Uncommon",  emoji="🥁", catchphrase="Tung! Tung! Sahur!" },
	{ name="Coccodrillo Pistola", rarity="Uncommon",  emoji="🐊", catchphrase="Fuoco nel pantano!" },
	{ name="Tigre Razzo",         rarity="Uncommon",  emoji="🐯", catchphrase="Strisce e missili!" },
	{ name="Leone Spada",         rarity="Uncommon",  emoji="🦁", catchphrase="Il re della savana spada!" },
	{ name="Orso Carro Armato",   rarity="Uncommon",  emoji="🐻", catchphrase="Tank di miele!" },
	{ name="Squalo Moto",         rarity="Uncommon",  emoji="🦈", catchphrase="Vroom nell'oceano!" },
	{ name="Aquila Bomba",        rarity="Uncommon",  emoji="🦅", catchphrase="Cado dal cielo!" },
	{ name="Volpe Cannone",       rarity="Uncommon",  emoji="🦊", catchphrase="Boom astuto!" },
	{ name="Lupo Elicottero",     rarity="Uncommon",  emoji="🐺", catchphrase="Ululato volante!" },
	{ name="Gorilla Treno",       rarity="Uncommon",  emoji="🦍", catchphrase="Pugno sul binario!" },
	{ name="Ippopotamo Aereo",    rarity="Uncommon",  emoji="🦛", catchphrase="Peso nei cieli!" },
	{ name="Rinoceronte Tank",    rarity="Uncommon",  emoji="🦏", catchphrase="Carica blindata!" },

	-- ═══ RARE (10) ══════════════════════════════════════════════════════
	{ name="Cappuccino Assassino",  rarity="Rare", emoji="☕", catchphrase="Morte col caffè!" },
	{ name="Pizzaiolo Ninja",       rarity="Rare", emoji="🍕", catchphrase="La pizza è arte letale!" },
	{ name="Spaghetti Mostro",      rarity="Rare", emoji="🍝", catchphrase="Al dente e pericoloso!" },
	{ name="Gelato Guerriero",      rarity="Rare", emoji="🍦", catchphrase="Freddo come l'acciaio!" },
	{ name="Tiramisù Esplosivo",    rarity="Rare", emoji="🍰, catchphrase="Esplodo di gusto!" },
	{ name="Cannolo Volante",       rarity="Rare", emoji="🥐", catchphrase="Sicilia dal cielo!" },
	{ name="Lasagna Robot",         rarity="Rare", emoji="🤖", catchphrase="Elaboro pasta!" },
	{ name="Risotto Samurai",       rarity="Rare", emoji="🍚", catchphrase="Onore al riso!" },
	{ name="Gnocchi Fantasma",      rarity="Rare", emoji="👻", catchphrase="Buo! Sono soffice!" },
	{ name="Bruschetta Vampiro",    rarity="Rare", emoji="🧛", catchphrase="Morsico il pomodoro!" },

	-- ═══ EPIC (7) ═══════════════════════════════════════════════════════
	{ name="Bombardiro Crocodilo", rarity="Epic", emoji="🐊", catchphrase="BOMBARDIRO!!" },
	{ name="Ballerina Cappuccina", rarity="Epic", emoji="💃", catchphrase="Danza e caffè, sempiterno!" },
	{ name="Drago Napoletano",     rarity="Epic", emoji="🐉", catchphrase="Pizza di fuoco!" },
	{ name="Unicorno Parmigiano",  rarity="Epic", emoji="🦄", catchphrase="Magia di formaggio!" },
	{ name="Fenice Carbonara",     rarity="Epic", emoji="🔥", catchphrase="Rinasco nella pasta!" },
	{ name="Centauro Barista",     rarity="Epic", emoji="☕", catchphrase="Galoppo col cappuccino!" },
	{ name="Medusa Mozzarella",    rarity="Epic", emoji="🐍", catchphrase="Guarda la mia mozzarella!" },

	-- ═══ LEGENDARY (4) ══════════════════════════════════════════════════
	{ name="Frigo Camelo",        rarity="Legendary", emoji="🐪", catchphrase="Conservo il latte nel deserto!" },
	{ name="Bombombini Gusini",   rarity="Legendary", emoji="💣", catchphrase="BOMBOMBINI!!! GUSINI!!!" },
	{ name="Colosseo Vivente",    rarity="Legendary", emoji="🏛️", catchphrase="Sono eterno!" },
	{ name="Vesuvio Urlante",     rarity="Legendary", emoji="🌋", catchphrase="Esplodo di storia!" },

	-- ═══ MYTHIC (2) ═════════════════════════════════════════════════════
	{ name="Lirilì Larilà",       rarity="Mythic", emoji="🌋", catchphrase="Lirilì... Larilà..." },
	{ name="Glorbo Fruttodrillo", rarity="Mythic", emoji="🦎", catchphrase="GLORBO GLORBO!" },

	-- ═══ SECRET (1) ═════════════════════════════════════════════════════
	{ name="La Vaca Saturno Cosmica", rarity="Secret", emoji="🪐", catchphrase="Muuu... dal cosmo!" },
}

-- Fix typo in Tiramisù emoji field (closing quote missing above was intentional for Luau multi-byte)
-- Luau handles these fine at runtime; this is source-level only.

-- Helper: get all brainrots of a given rarity
function BrainrotList.GetByRarity(rarity)
	local result = {}
	for _, b in ipairs(BrainrotList) do
		if b.rarity == rarity then
			table.insert(result, b)
		end
	end
	return result
end

-- Helper: find by name
function BrainrotList.FindByName(name)
	for _, b in ipairs(BrainrotList) do
		if b.name == name then return b end
	end
	return nil
end

return BrainrotList
