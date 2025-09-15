class_name GemConsts

const MAX_STACKS = 32
const LEVEL_INTERVAL = 15
const MIN_LEVEL = 5
const MAX_LEVEL = 75
const BASE_GEM_PRICE := 3000.0
const NUM_RUNES_TO_UPGRADE = 4

const GEM_WEIGHTS := {
	ItemAttribute.TYPE.HEALTH: 15,
	ItemAttribute.TYPE.MANA: 10,
	ItemAttribute.TYPE.ENERGY: 2,
	ItemAttribute.TYPE.DEFENSE: 15,
	ItemAttribute.TYPE.DAMAGE: 15,
	ItemAttribute.TYPE.CRITICAL_RATE: 15,
	ItemAttribute.TYPE.CRITICAL_DAMAGE: 15,
	ItemAttribute.TYPE.ATTACK_SPEED: 3,
	ItemAttribute.TYPE.MOVE_SPEED: 3,
	ItemAttribute.TYPE.HEALTH_REGEN: 0.25,
	ItemAttribute.TYPE.MANA_REGEN: 0.25,
	ItemAttribute.TYPE.ENERGY_REGEN: 0.25,
	ItemAttribute.TYPE.EXP_BOOST: 0.25,
}

const GEM_AVAILABLE_EQUIP_SLOTS = []

const GEM_QUALITY_KEY := {
	GemItem.QUALITY.FRAGMENTED: "fragmented",
	GemItem.QUALITY.COMMON: "common",
	GemItem.QUALITY.REFINED: "refined",
	GemItem.QUALITY.FLAWLESS: "flawless",
	GemItem.QUALITY.EXQUISITE: "exquisite",
	GemItem.QUALITY.PRISTINE: "pristine",
}

const UNIQUE_GEMS_KEYS := {
	ItemAttribute.TYPE.HEALTH_REGEN: "health_regen",
	ItemAttribute.TYPE.MANA_REGEN: "mana_regen",
	ItemAttribute.TYPE.ENERGY_REGEN: "energy_regen",
	ItemAttribute.TYPE.EXP_BOOST: "exp_boost",
}

const GEM_COLOR_NAME_KEY := {
	ItemAttribute.TYPE.HEALTH: "pink",
	ItemAttribute.TYPE.MANA: "blue",
	ItemAttribute.TYPE.ENERGY: "green",
	ItemAttribute.TYPE.DEFENSE: "magenta",
	ItemAttribute.TYPE.DAMAGE: "orange",
	ItemAttribute.TYPE.CRITICAL_RATE: "silver",
	ItemAttribute.TYPE.CRITICAL_DAMAGE: "yellow",
	ItemAttribute.TYPE.ATTACK_SPEED: "white",
	ItemAttribute.TYPE.MOVE_SPEED: "turquoise",
}

# Valores base por tipo de atributo
const BASE_VALUES := {
	ItemAttribute.TYPE.HEALTH: 500.0,
	ItemAttribute.TYPE.MANA: 7.0,
	ItemAttribute.TYPE.ENERGY: 5.0,
	ItemAttribute.TYPE.DEFENSE: 35.0,
	ItemAttribute.TYPE.DAMAGE: 25.0,
	ItemAttribute.TYPE.CRITICAL_RATE: 25.0,
	ItemAttribute.TYPE.CRITICAL_DAMAGE: 0.020,
	ItemAttribute.TYPE.ATTACK_SPEED: 0.010,
	ItemAttribute.TYPE.MOVE_SPEED: 0.010,
	ItemAttribute.TYPE.HEALTH_REGEN: 2.0,
	ItemAttribute.TYPE.MANA_REGEN: 1.0,
	ItemAttribute.TYPE.ENERGY_REGEN: 0.5,
	ItemAttribute.TYPE.EXP_BOOST: 0.5
}
