class_name RuneConsts

const MIN_LEVEL = 15
const LEVEL_INTERVAL = 15
const MAX_LEVEL = 75
const BASE_PRICE = 6000
const MAX_STACKS = 32

const RUNE_TO_ATTRIBUTE_MAPPING = {
	RuneItem.TYPE.VITALITY: [ItemAttribute.TYPE.HEALTH],
	RuneItem.TYPE.ESSENCE: [ItemAttribute.TYPE.MANA],
	RuneItem.TYPE.VIGOR: [ItemAttribute.TYPE.ENERGY],
	RuneItem.TYPE.PROTECTION: [ItemAttribute.TYPE.DEFENSE],
	RuneItem.TYPE.STRENGTH: [ItemAttribute.TYPE.DAMAGE],
	RuneItem.TYPE.PRECISION: [ItemAttribute.TYPE.CRITICAL_RATE],
	RuneItem.TYPE.FURY: [ItemAttribute.TYPE.CRITICAL_DAMAGE],
	RuneItem.TYPE.SWIFTNESS: [ItemAttribute.TYPE.ATTACK_SPEED],
	RuneItem.TYPE.AGILITY: [ItemAttribute.TYPE.MOVE_SPEED],
	RuneItem.TYPE.SPECIAL: [ItemAttribute.TYPE.HEALTH_REGEN, ItemAttribute.TYPE.MANA_REGEN, ItemAttribute.TYPE.ENERGY_REGEN]
}

const RUNE_TYPE_KEYS = {
	RuneItem.TYPE.VITALITY: "vitality",
	RuneItem.TYPE.ESSENCE: "essence",
	RuneItem.TYPE.VIGOR: "vigor",
	RuneItem.TYPE.PROTECTION: "protection",
	RuneItem.TYPE.STRENGTH: "strength",
	RuneItem.TYPE.PRECISION: "precision",
	RuneItem.TYPE.FURY: "fury",
	RuneItem.TYPE.AGILITY: "agility",
	RuneItem.TYPE.SWIFTNESS: "swiftness",
	RuneItem.TYPE.SPECIAL: "special",
}

const RUNE_WEIGHT = {
	RuneItem.TYPE.VITALITY: 15,
	RuneItem.TYPE.ESSENCE: 10,
	RuneItem.TYPE.VIGOR: 2,
	RuneItem.TYPE.PROTECTION: 15,
	RuneItem.TYPE.STRENGTH: 15,
	RuneItem.TYPE.PRECISION: 15,
	RuneItem.TYPE.FURY: 15,
	RuneItem.TYPE.AGILITY: 3,
	RuneItem.TYPE.SWIFTNESS: 3,
	RuneItem.TYPE.SPECIAL: 0.25,
}
