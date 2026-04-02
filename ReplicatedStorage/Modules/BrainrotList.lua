-- BrainrotList (ModuleScript)
-- ReplicatedStorage/Modules/BrainrotList

local BrainrotList = {
	{ name = "Tralalero Tralala",    rarity = "Common",    emoji = "🐟" },
	{ name = "Tung Tung Sahur",      rarity = "Uncommon",  emoji = "🥁" },
	{ name = "Cappuccino Assassino", rarity = "Rare",      emoji = "☕" },
	{ name = "Bombardiro Crocodilo", rarity = "Epic",      emoji = "🐊" },
	{ name = "Ballerina Cappuccina", rarity = "Epic",      emoji = "💃" },
	{ name = "Frigo Camelo",         rarity = "Legendary", emoji = "🐪" },
	{ name = "Bombombini Gusini",    rarity = "Legendary", emoji = "💣" },
	{ name = "Lirilì Larilà",        rarity = "Mythic",    emoji = "🌋" },
	{ name = "Glorbo Fruttodrillo",  rarity = "Mythic",    emoji = "🦎" },
	{ name = "La Vaca Saturno",      rarity = "Secret",    emoji = "🪐" },
}

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
		if b.name == name then
			return b
		end
	end
	return nil
end

return BrainrotList
