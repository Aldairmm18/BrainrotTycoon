-- RarityConfig (ModuleScript)
-- ReplicatedStorage/Modules/RarityConfig

local RarityConfig = {
	Common = {
		dropChance  = 0.60,
		cashPerSec  = 5,
		color       = Color3.fromRGB(180, 180, 180),
	},
	Uncommon = {
		dropChance  = 0.25,
		cashPerSec  = 100,
		color       = Color3.fromRGB(100, 160, 255),
	},
	Rare = {
		dropChance  = 0.10,
		cashPerSec  = 2500,
		color       = Color3.fromRGB(50, 200, 120),
	},
	Epic = {
		dropChance  = 0.04,
		cashPerSec  = 50000,
		color       = Color3.fromRGB(160, 100, 255),
	},
	Legendary = {
		dropChance  = 0.009,
		cashPerSec  = 1000000,
		color       = Color3.fromRGB(255, 180, 0),
	},
	Mythic = {
		dropChance  = 0.0009,
		cashPerSec  = 25000000,
		color       = Color3.fromRGB(255, 80, 40),
	},
	Secret = {
		dropChance  = 0.0001,
		cashPerSec  = 2000000000,
		color       = Color3.fromRGB(255, 50, 50),
	},
}

-- Ordered list for UI and gacha iteration
RarityConfig.Order = {
	"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"
}

-- Direct purchase prices (without gacha)
RarityConfig.DirectPrice = {
	Common   = 200,
	Uncommon = 2000,
	Rare     = 25000,
	Epic     = 500000,
}

-- Validate sum == 1.0
local total = 0
for _, r in pairs(RarityConfig.Order) do
	total = total + RarityConfig[r].dropChance
end
assert(math.abs(total - 1.0) < 0.0001, "RarityConfig dropChances do not sum to 1.0! Got: " .. tostring(total))

return RarityConfig
