class_name EquipmentConsts


const EQUIPMENT_SPAWN_WEIGHTS = {
	EquipmentItem.TYPE.HELMET: 20,
	EquipmentItem.TYPE.ARMOR: 20,
	EquipmentItem.TYPE.BOOTS: 15,
	EquipmentItem.TYPE.GLOVES: 15,
	EquipmentItem.TYPE.RING: 10,
	EquipmentItem.TYPE.AMULET: 10,
	EquipmentItem.TYPE.WEAPON: 10
}

const EQUIPMENT_SET_SPAWN_WEIGHTS = {
	EquipmentItem.GROUPS.COMMON: 90,
	EquipmentItem.GROUPS.UNIQUES: 10,
}

const ATTRIBUTES_PER_RARITY = {
	Item.RARITY.COMMON: 0,
	Item.RARITY.UNCOMMON: 1,
	Item.RARITY.RARE: 2,
	Item.RARITY.EPIC: 3,
	Item.RARITY.LEGENDARY: 4,
	Item.RARITY.MYTHICAL: 5
}

const EQUIPMENT_TYPE_KEYS: Dictionary[EquipmentItem.TYPE, String] = {
	EquipmentItem.TYPE.HELMET: "helmet",
	EquipmentItem.TYPE.ARMOR: "armor",
	EquipmentItem.TYPE.BOOTS: "boots",
	EquipmentItem.TYPE.GLOVES: "gloves",
	EquipmentItem.TYPE.RING: "ring",
	EquipmentItem.TYPE.AMULET: "amulet",
	EquipmentItem.TYPE.WEAPON: "weapon"
}

const EQUIPMENTS_SET_KEYS: Dictionary[EquipmentItem.SETS, String] = {
	EquipmentItem.SETS.TRAVELER: "traveler",
	EquipmentItem.SETS.LEATHER: "leather",
	EquipmentItem.SETS.HUNTER: "hunter",
	EquipmentItem.SETS.BRONZE: "bronze",
	EquipmentItem.SETS.IRON: "iron",
	EquipmentItem.SETS.HEAVY: "heavy",
	EquipmentItem.SETS.GUARDIAN: "guardian",
	EquipmentItem.SETS.NOBLE_PLATINUM: "noble_platinum",
	EquipmentItem.SETS.SHADOW_EBONY: "shadow_ebony",
	EquipmentItem.SETS.SERPENT_EMBRACE: "serpent_embrace",
	EquipmentItem.SETS.SACRED_CRUSADER: "sacred_crusader",
	EquipmentItem.SETS.FROSTBEAR_WRATH: "frostbear_wrath",
	EquipmentItem.SETS.LOST_KING: "lost_king",
	EquipmentItem.SETS.DEMONS_BANE: "demons_bane",
	EquipmentItem.SETS.SOLARIS: "solaris",
	EquipmentItem.SETS.DEATH_REAPER: "death_reaper",
	EquipmentItem.SETS.JUGGERNOUT: "juggernout",
	EquipmentItem.SETS.ELEMENTALS_POWERFULL: "elemental_powerfull",
	EquipmentItem.SETS.SAMURAI: "samurai",
	EquipmentItem.SETS.SILVER_MOON: "silver_moon",
	EquipmentItem.SETS.WINDCUTTER: "windcutter",
}

const COMMONS_SETS = [
	EquipmentItem.SETS.TRAVELER,
	EquipmentItem.SETS.LEATHER,
	EquipmentItem.SETS.HUNTER,
	EquipmentItem.SETS.BRONZE,
	EquipmentItem.SETS.IRON,
	EquipmentItem.SETS.HEAVY,
	EquipmentItem.SETS.GUARDIAN,
	EquipmentItem.SETS.NOBLE_PLATINUM,
	EquipmentItem.SETS.SHADOW_EBONY
]
const UNIQUES_SETS = [
	EquipmentItem.SETS.SERPENT_EMBRACE,
	EquipmentItem.SETS.SACRED_CRUSADER,
	EquipmentItem.SETS.FROSTBEAR_WRATH,
	EquipmentItem.SETS.LOST_KING,
	EquipmentItem.SETS.DEMONS_BANE,
	EquipmentItem.SETS.SOLARIS,
	EquipmentItem.SETS.DEATH_REAPER,
	EquipmentItem.SETS.JUGGERNOUT,
	EquipmentItem.SETS.SAMURAI,
	EquipmentItem.SETS.SILVER_MOON,
	EquipmentItem.SETS.WINDCUTTER,
	EquipmentItem.SETS.ELEMENTALS_POWERFULL
]

const UNIQUE_SETS_SPAWN_CHANCE = {
	EquipmentItem.SETS.SERPENT_EMBRACE: 0.0,
	EquipmentItem.SETS.SACRED_CRUSADER: 0.0,
	EquipmentItem.SETS.FROSTBEAR_WRATH: 0.0,
	EquipmentItem.SETS.LOST_KING: 0.0,
	EquipmentItem.SETS.DEMONS_BANE: 0.0,
	EquipmentItem.SETS.SOLARIS: 0.0,
	EquipmentItem.SETS.DEATH_REAPER: 0.0,
	EquipmentItem.SETS.JUGGERNOUT: 0.0,
	EquipmentItem.SETS.SAMURAI: 0.0,
	EquipmentItem.SETS.SILVER_MOON: 0.0,
	EquipmentItem.SETS.WINDCUTTER: 0.0,
	EquipmentItem.SETS.ELEMENTALS_POWERFULL: 0.0,
}

const UNIQUE_SETS_RARITY = {
	EquipmentItem.SETS.SAMURAI: Item.RARITY.RARE,
	EquipmentItem.SETS.WINDCUTTER: Item.RARITY.RARE,
	EquipmentItem.SETS.SERPENT_EMBRACE: Item.RARITY.RARE,
	EquipmentItem.SETS.SACRED_CRUSADER: Item.RARITY.RARE,
	EquipmentItem.SETS.SILVER_MOON: Item.RARITY.EPIC,
	EquipmentItem.SETS.FROSTBEAR_WRATH: Item.RARITY.EPIC,
	EquipmentItem.SETS.LOST_KING: Item.RARITY.EPIC,
	EquipmentItem.SETS.DEMONS_BANE: Item.RARITY.EPIC,
	EquipmentItem.SETS.SOLARIS: Item.RARITY.LEGENDARY,
	EquipmentItem.SETS.ELEMENTALS_POWERFULL: Item.RARITY.MYTHICAL,
	EquipmentItem.SETS.DEATH_REAPER: Item.RARITY.MYTHICAL,
	EquipmentItem.SETS.JUGGERNOUT: Item.RARITY.MYTHICAL,
}

const SETS_AVAILABLE_PARTS = {
	EquipmentItem.SETS.TRAVELER:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS,
		EquipmentItem.TYPE.GLOVES,
		EquipmentItem.TYPE.WEAPON,
	],
	EquipmentItem.SETS.LEATHER:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS,
		EquipmentItem.TYPE.GLOVES,
		EquipmentItem.TYPE.WEAPON,
	],
	EquipmentItem.SETS.HUNTER:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS,
		EquipmentItem.TYPE.GLOVES,
		EquipmentItem.TYPE.WEAPON,
	],
	EquipmentItem.SETS.BRONZE:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS,
		EquipmentItem.TYPE.GLOVES,
		EquipmentItem.TYPE.WEAPON,
		EquipmentItem.TYPE.RING
	],
	EquipmentItem.SETS.IRON:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS,
		EquipmentItem.TYPE.GLOVES,
		EquipmentItem.TYPE.WEAPON
	],
	EquipmentItem.SETS.HEAVY:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS,
		EquipmentItem.TYPE.GLOVES,
		EquipmentItem.TYPE.WEAPON,
		EquipmentItem.TYPE.RING,
		EquipmentItem.TYPE.AMULET
	],
	EquipmentItem.SETS.GUARDIAN:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS,
		EquipmentItem.TYPE.GLOVES,
		EquipmentItem.TYPE.WEAPON,
		EquipmentItem.TYPE.RING,
		EquipmentItem.TYPE.AMULET
	],
	EquipmentItem.SETS.NOBLE_PLATINUM:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS,
		EquipmentItem.TYPE.GLOVES,
		EquipmentItem.TYPE.WEAPON,
		EquipmentItem.TYPE.RING,
		EquipmentItem.TYPE.AMULET
	],
	EquipmentItem.SETS.SHADOW_EBONY:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS,
		EquipmentItem.TYPE.GLOVES,
		EquipmentItem.TYPE.WEAPON,
		EquipmentItem.TYPE.RING,
		EquipmentItem.TYPE.AMULET
	],
	EquipmentItem.SETS.SERPENT_EMBRACE:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS,
		EquipmentItem.TYPE.GLOVES,
		EquipmentItem.TYPE.WEAPON,
	],
	EquipmentItem.SETS.SACRED_CRUSADER:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS
	],
	EquipmentItem.SETS.FROSTBEAR_WRATH:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS,
		EquipmentItem.TYPE.GLOVES,
		EquipmentItem.TYPE.AMULET
	],
	EquipmentItem.SETS.LOST_KING:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS,
		EquipmentItem.TYPE.GLOVES,
		EquipmentItem.TYPE.WEAPON,
		EquipmentItem.TYPE.RING,
		EquipmentItem.TYPE.AMULET
	],
	EquipmentItem.SETS.DEMONS_BANE:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS,
		EquipmentItem.TYPE.GLOVES,
		EquipmentItem.TYPE.WEAPON,
	],
	EquipmentItem.SETS.SOLARIS:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS,
		EquipmentItem.TYPE.GLOVES,
		EquipmentItem.TYPE.WEAPON,
		EquipmentItem.TYPE.RING
	],
	EquipmentItem.SETS.DEATH_REAPER:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS,
		EquipmentItem.TYPE.GLOVES,
		EquipmentItem.TYPE.WEAPON,
		EquipmentItem.TYPE.RING
	],
	EquipmentItem.SETS.JUGGERNOUT:
	[
		EquipmentItem.TYPE.WEAPON,
	],
	EquipmentItem.SETS.SAMURAI:
	[
		EquipmentItem.TYPE.WEAPON,
	],
	EquipmentItem.SETS.SILVER_MOON:
	[
		EquipmentItem.TYPE.ARMOR,
		EquipmentItem.TYPE.BOOTS,
		EquipmentItem.TYPE.WEAPON,
	],
	EquipmentItem.SETS.WINDCUTTER:
	[
		EquipmentItem.TYPE.HELMET,
		EquipmentItem.TYPE.GLOVES,
		EquipmentItem.TYPE.WEAPON,
	],
	EquipmentItem.SETS.ELEMENTALS_POWERFULL: [
		EquipmentItem.TYPE.RING,
		EquipmentItem.TYPE.AMULET
	]
}

const ALLOWED_ATTRIBUTES_PER_TYPE: Dictionary[EquipmentItem.TYPE, Array] = {
	EquipmentItem.TYPE.WEAPON:
	[
		ItemAttribute.TYPE.DAMAGE,
		ItemAttribute.TYPE.CRITICAL_RATE,
		ItemAttribute.TYPE.CRITICAL_DAMAGE,
		ItemAttribute.TYPE.ATTACK_SPEED
	],
	EquipmentItem.TYPE.ARMOR:
	[
		ItemAttribute.TYPE.DAMAGE,
		ItemAttribute.TYPE.HEALTH,
		ItemAttribute.TYPE.HEALTH_REGEN,
		ItemAttribute.TYPE.DEFENSE,
	],
	EquipmentItem.TYPE.HELMET:
	[
		ItemAttribute.TYPE.DEFENSE,
		ItemAttribute.TYPE.HEALTH,
		ItemAttribute.TYPE.CRITICAL_DAMAGE
	],
	EquipmentItem.TYPE.BOOTS:
	[
		ItemAttribute.TYPE.HEALTH,
		ItemAttribute.TYPE.DEFENSE,
		ItemAttribute.TYPE.MOVE_SPEED
	],
	EquipmentItem.TYPE.GLOVES:
	[
		ItemAttribute.TYPE.DAMAGE,
		ItemAttribute.TYPE.CRITICAL_RATE,
		ItemAttribute.TYPE.ATTACK_SPEED,
	],
	EquipmentItem.TYPE.RING:
	[
		ItemAttribute.TYPE.DAMAGE,
		ItemAttribute.TYPE.ENERGY,
		ItemAttribute.TYPE.ENERGY_REGEN,
		ItemAttribute.TYPE.CRITICAL_RATE,
		ItemAttribute.TYPE.CRITICAL_DAMAGE,
	],
	EquipmentItem.TYPE.AMULET:
	[
		ItemAttribute.TYPE.DAMAGE,
		ItemAttribute.TYPE.MANA,
		ItemAttribute.TYPE.MANA_REGEN,
		ItemAttribute.TYPE.CRITICAL_RATE,
		ItemAttribute.TYPE.CRITICAL_DAMAGE,
		ItemAttribute.TYPE.EXP_BUFF,
	]
}

const EQUIPMENT_BASE_PRICES = {
	EquipmentItem.TYPE.HELMET: 9000,
	EquipmentItem.TYPE.ARMOR: 15000,
	EquipmentItem.TYPE.BOOTS: 8000,
	EquipmentItem.TYPE.GLOVES: 5000,
	EquipmentItem.TYPE.WEAPON: 20000,
	EquipmentItem.TYPE.RING: 18000,
	EquipmentItem.TYPE.AMULET: 17000
}

const EQUIPMENTS_STATS_BASE_VALUES = {
	ItemAttribute.TYPE.DAMAGE: {"base_value": 40.0, "factor": 0.05},
	ItemAttribute.TYPE.DEFENSE: {"base_value": 50.0, "factor": 0.1},
	ItemAttribute.TYPE.HEALTH: {"base_value": 75.0, "factor": 0.5},
	ItemAttribute.TYPE.MANA: {"base_value": 4.0, "factor": 0.05},
	ItemAttribute.TYPE.ENERGY: {"base_value": 2.0, "factor": 0.05},
	ItemAttribute.TYPE.CRITICAL_RATE: {"base_value": 25.0, "factor": 0.15},
	ItemAttribute.TYPE.CRITICAL_DAMAGE: {"base_value": 3.0, "factor": 0.05},
	ItemAttribute.TYPE.ATTACK_SPEED: {"base_value": 3.0, "factor": 0.01},
	ItemAttribute.TYPE.MOVE_SPEED: {"base_value": 3.0, "factor": 0.01},
	ItemAttribute.TYPE.POISON_HIT_RATE: {"base_value": 3.0, "factor": 0.01},
	ItemAttribute.TYPE.BLEED_HIT_RATE: {"base_value": 3.0, "factor": 0.01},
	# ItemAttribute.TYPE.HEALTH_REGEN: {"base_value": 3.0, "factor": 0.01},
	# ItemAttribute.TYPE.MANA_REGEN: {"base_value": 3.0, "factor": 0.01},
	# ItemAttribute.TYPE.ENERGY_REGEN: {"base_value": 3.0, "factor": 0.01},
}
