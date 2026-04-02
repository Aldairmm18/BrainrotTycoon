-- BrainrotList (ModuleScript)
-- ReplicatedStorage/Modules/BrainrotList
-- 30 Brainrots: 17 with real 3D models (stored in ServerStorage.BrainrotTemplates)
-- and 13 text-only fallbacks that spawn as coloured Parts.
-- modelName = exact name used in ServerStorage.BrainrotTemplates
-- cashPerSec is the per-second income; RarityConfig may override visual colour.

local BrainrotList = {

	-- ═══ COMMON (4) ══════════════════════════════════════════════════════════
	{ name = "CakeTrap",          rarity = "Common",    emoji = "🎂",
	  modelName = "CakeTrap",        cashPerSec = 5   },
	{ name = "BubbleGum Machine", rarity = "Common",    emoji = "🫧",
	  modelName = "BubbleGumMach",   cashPerSec = 5   },
	{ name = "Tralalero Tralala", rarity = "Common",    emoji = "🐟",
	  modelName = nil,               cashPerSec = 5   },
	{ name = "Gatto Volante",     rarity = "Common",    emoji = "🐱",
	  modelName = nil,               cashPerSec = 5   },

	-- ═══ UNCOMMON (7) ════════════════════════════════════════════════════════
	{ name = "Tung Tung Tung Sahur",  rarity = "Uncommon", emoji = "🥁",
	  modelName = "Tung Tung Tung S",  cashPerSec = 100 },
	{ name = "Burbaloni Loliloli",    rarity = "Uncommon", emoji = "🫧",
	  modelName = "Burbaloni Lolilo", cashPerSec = 100 },
	{ name = "Trulimero Trulicina",   rarity = "Uncommon", emoji = "🎵",
	  modelName = "Trulimero Trulici",cashPerSec = 100 },
	{ name = "Rainbow Machine",       rarity = "Uncommon", emoji = "🌈",
	  modelName = "RainbowMachine",   cashPerSec = 100 },
	{ name = "Coccodrillo Pistola",   rarity = "Uncommon", emoji = "🐊",
	  modelName = nil,                cashPerSec = 100 },
	{ name = "Tigre Razzo",           rarity = "Uncommon", emoji = "🐯",
	  modelName = nil,                cashPerSec = 100 },
	{ name = "Squalo Moto",           rarity = "Uncommon", emoji = "🦈",
	  modelName = nil,                cashPerSec = 100 },

	-- ═══ RARE (9) ════════════════════════════════════════════════════════════
	{ name = "Ballerina Cappuccina",  rarity = "Rare",  emoji = "💃",
	  modelName = "Ballerina Cappuc", cashPerSec = 2500 },
	{ name = "Boneca Ambalabú",       rarity = "Rare",  emoji = "🪆",
	  modelName = "Boneca Ambalab",   cashPerSec = 2500 },
	{ name = "Avocadini Guffo",       rarity = "Rare",  emoji = "🥑",
	  modelName = "Avocadini Guffo",  cashPerSec = 2500 },
	{ name = "Cacto Hipopotarri",     rarity = "Rare",  emoji = "🌵",
	  modelName = "Cacto Hipopotar",  cashPerSec = 2500 },
	{ name = "Rhino Toasterino",      rarity = "Rare",  emoji = "🦏",
	  modelName = "Rhino Toasterino", cashPerSec = 2500 },
	{ name = "Zibra Zubra Zibra",    rarity = "Rare",  emoji = "🦓",
	  modelName = "Zibra Zubra Zibra",cashPerSec = 2500 },
	{ name = "Pizzaiolo Ninja",       rarity = "Rare",  emoji = "🍕",
	  modelName = nil,                cashPerSec = 2500 },
	{ name = "Spaghetti Mostro",      rarity = "Rare",  emoji = "🍝",
	  modelName = nil,                cashPerSec = 2500 },
	{ name = "Gelato Guerriero",      rarity = "Rare",  emoji = "🍦",
	  modelName = nil,                cashPerSec = 2500 },

	-- ═══ EPIC (6) ════════════════════════════════════════════════════════════
	{ name = "Cappuccino Assassino",  rarity = "Epic",  emoji = "☕",
	  modelName = "Cappuccino Assa",  cashPerSec = 50000 },
	{ name = "Chimpanzini Banana",    rarity = "Epic",  emoji = "🐒",
	  modelName = "Chimpanzini Ban",  cashPerSec = 50000 },
	{ name = "Pandaccini Banana",     rarity = "Epic",  emoji = "🐼",
	  modelName = "Pandaccini Banar", cashPerSec = 50000 },
	{ name = "Chef Crabracadabra",    rarity = "Epic",  emoji = "🦀",
	  modelName = "Chef Crabracadat", cashPerSec = 50000 },
	{ name = "Bombardiro Crocodilo",  rarity = "Epic",  emoji = "🐊",
	  modelName = nil,                cashPerSec = 50000 },
	{ name = "Drago Napoletano",      rarity = "Epic",  emoji = "🐉",
	  modelName = nil,                cashPerSec = 50000 },

	-- ═══ LEGENDARY (2) ═══════════════════════════════════════════════════════
	{ name = "Mythic Lucky Block",    rarity = "Legendary", emoji = "🍀",
	  modelName = "Mythic Lucky Blo", cashPerSec = 1000000 },
	{ name = "Bombombini Gusini",     rarity = "Legendary", emoji = "💣",
	  modelName = nil,                cashPerSec = 1000000 },

	-- ═══ MYTHIC (1) ══════════════════════════════════════════════════════════
	{ name = "Lirilì Larilà",         rarity = "Mythic", emoji = "🌋",
	  modelName = nil,                cashPerSec = 10000000 },

	-- ═══ SECRET (1) ══════════════════════════════════════════════════════════
	{ name = "La Vaca Saturno Cosmica", rarity = "Secret", emoji = "🪐",
	  modelName = nil,                  cashPerSec = 100000000 },
}

-- ─── Helper: get all brainrots of a given rarity ──────────────────────────────
function BrainrotList.GetByRarity(rarity)
	local result = {}
	for _, b in ipairs(BrainrotList) do
		if b.rarity == rarity then
			table.insert(result, b)
		end
	end
	return result
end

-- ─── Helper: find by name ─────────────────────────────────────────────────────
function BrainrotList.FindByName(name)
	for _, b in ipairs(BrainrotList) do
		if b.name == name then return b end
	end
	return nil
end

return BrainrotList
