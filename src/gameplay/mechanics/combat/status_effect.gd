class_name StatusEffect
extends Resource

enum TYPE {ACTIVE, PASSIVE, NONE}
enum CATEGORY {BUFF, DEBUFF, NONE}

enum EFFECT {
	POISONING,
	BLEEDING,
	FREEZING,
	CONFUSED,
	STUNNING,
	SLEEPING,
	BURNING,
	PARALYZING,
	HEALTH_REGEN,
	MANA_REGEN,
	DAMAGE_BOOST,
	DAMAGE_REDUCTION,
	CRITICAL_RATE_BOOST,
	CRITICAL_DAMAGE_BOOST,
	DEFENSE_BOOST,
	DEFENSE_REDUCTION,
	EXP_BOOST,
	HEALTH_AMPLIFICATION,
	MANA_AMPLIFICATION,
	ATTACK_SPEED_BOOST,
	ATTACK_SPEED_REDUCTION,
	SPEED_BOOST,
	SPEED_REDUCTION,
	NONE
}

const EFFECT_KEY = {
	EFFECT.POISONING: "poisoning",
	EFFECT.BLEEDING: "bleeding",
	EFFECT.FREEZING: "freezing",
	EFFECT.CONFUSED: "confused",
	EFFECT.STUNNING: "stunning",
	EFFECT.SLEEPING: "sleeping",
	EFFECT.BURNING: "burning",
	EFFECT.PARALYZING: "paralyzing",
	EFFECT.HEALTH_REGEN: "health_regen",
	EFFECT.MANA_REGEN: "mana_regen",
	EFFECT.DAMAGE_BOOST: "damage_boost",
	EFFECT.DAMAGE_REDUCTION: "damage_reduction",
	EFFECT.CRITICAL_RATE_BOOST: "critical_rate_boost",
	EFFECT.CRITICAL_DAMAGE_BOOST: "critical_damage_boost",
	EFFECT.DEFENSE_BOOST: "defense_boost",
	EFFECT.DEFENSE_REDUCTION: "defense_reduction",
	EFFECT.EXP_BOOST: "exp_boost",
	EFFECT.HEALTH_AMPLIFICATION: "health_amplification",
	EFFECT.MANA_AMPLIFICATION: "mana_amplification",
	EFFECT.ATTACK_SPEED_BOOST: "attack_speed_boost",
	EFFECT.ATTACK_SPEED_REDUCTION: "attack_speed_reduction",
	EFFECT.SPEED_BOOST: "speed_boost",
	EFFECT.SPEED_REDUCTION: "speed_reduction",
	EFFECT.NONE: "none"
}

const ATTRIBUTE_TO_EFFECT = {
	ItemAttribute.TYPE.POISON_HIT_RATE: EFFECT.POISONING,
	ItemAttribute.TYPE.BLEED_HIT_RATE: EFFECT.BLEEDING,
	ItemAttribute.TYPE.FREEZE_HIT_RATE: EFFECT.FREEZING,
	ItemAttribute.TYPE.STUN_HIT_RATE: EFFECT.STUNNING,
	ItemAttribute.TYPE.BURN_HIT_RATE: EFFECT.BURNING,
	ItemAttribute.TYPE.HEALTH: EFFECT.HEALTH_AMPLIFICATION,
	ItemAttribute.TYPE.MANA: EFFECT.MANA_AMPLIFICATION,
	ItemAttribute.TYPE.DAMAGE: EFFECT.DAMAGE_BOOST,
	ItemAttribute.TYPE.DEFENSE: EFFECT.DEFENSE_BOOST,
	ItemAttribute.TYPE.EXP_BOOST: EFFECT.EXP_BOOST,
	ItemAttribute.TYPE.CRITICAL_DAMAGE: EFFECT.CRITICAL_DAMAGE_BOOST,
	ItemAttribute.TYPE.CRITICAL_RATE: EFFECT.CRITICAL_RATE_BOOST,
	ItemAttribute.TYPE.ATTACK_SPEED: EFFECT.ATTACK_SPEED_BOOST,
	ItemAttribute.TYPE.MOVE_SPEED: EFFECT.SPEED_BOOST
}

@export var type: TYPE
@export var category: CATEGORY
@export var effect: EFFECT

## The Base Value os effect
@export var base_value: float = 0.0
## Base Rate Chance: Min=0.0 Max=1.0
@export_range(0.0, 1.0) var base_rate_chance: float = 0.0
## Base Duration in seconds.
@export var base_duration: float = 5.0


var is_active: bool = false
var value := 0.0

var rate_chance := 0.0:
		get: return rate_chance
		set(value): rate_chance = clampf(value, 0.0, 1.0)

var duration := 0.0:
		get: return duration
		set(value): duration = maxf(value, base_duration)


func _init(_effect: EFFECT = EFFECT.NONE, _duration: float = base_duration) -> void:
	effect = _effect
	duration = _duration
	
	
func get_effect_value_color() -> Color:
	match effect:
		EFFECT.BLEEDING:
			return Color.DARK_RED
		EFFECT.POISONING:
			return Color.FOREST_GREEN
		EFFECT.FREEZING:
			return Color.AQUA
		EFFECT.HEALTH_REGEN:
			return Color.GREEN
		EFFECT.MANA_REGEN:
			return Color.ALICE_BLUE
		_:
			return Color.WHITE


func get_category_key_text() -> String:
	if category == CATEGORY.BUFF:
		return "buff"
	else:
		return "debuff"


func get_effect_icon_name() -> String:
	match effect:
		EFFECT.POISONING: return "poisoning"
		EFFECT.BLEEDING: return "bleeding"
		EFFECT.FREEZING: return "frozen"
		EFFECT.STUNNING: return "stunned"
		EFFECT.CONFUSED: return "confused"
		EFFECT.BURNING: return "burning"
		EFFECT.HEALTH_REGEN: return "health_regen"
		EFFECT.MANA_REGEN: return "mana_regen"
		EFFECT.DAMAGE_BOOST: return "damage_boost"
		EFFECT.DAMAGE_REDUCTION: return "attack_down"
		EFFECT.CRITICAL_RATE_BOOST: return "critical_boost"
		EFFECT.CRITICAL_DAMAGE_BOOST: return "critical_boost"
		EFFECT.DEFENSE_BOOST: return "defense_boost"
		EFFECT.DEFENSE_REDUCTION: return "defense_down"
		EFFECT.EXP_BOOST: return "exp_boost"
		EFFECT.HEALTH_AMPLIFICATION: return "health_amplification"
		EFFECT.MANA_AMPLIFICATION: return "mana_amplification"
		EFFECT.ATTACK_SPEED_BOOST: return "attack_speed_boost"
		EFFECT.ATTACK_SPEED_REDUCTION: return "attack_down"
		EFFECT.SPEED_BOOST: return "speed_boost"
		_: return ""


func get_effect_description() -> String:
	var base_description := LocalizationManager.get_ui_text("status_effect_base_description")
	
	var effect_name := get_effect_name()
	var effect_key = EFFECT_KEY[effect]
	var effect_color := get_effect_color().to_html()
	
	var params = {
		"effect_name": str("[color=#%s]" % effect_color, effect_key, "[/color]"),
		"value": StringUtils.format_to_percentage(value, 1)
	}

	base_description = LocalizationManager.format_text_with_params(base_description, params)
	var description = str(effect_name, "\n", base_description)

	return description


func get_effect_name() -> String:
	return LocalizationManager.get_attribute_text(EFFECT_KEY[effect])


func get_effect_color() -> Color:
	match effect:
		EFFECT.POISONING: return Color.FOREST_GREEN
		EFFECT.BLEEDING: return Color.DARK_RED
		EFFECT.FREEZING: return Color.AQUA
		EFFECT.STUNNING: return Color.LIGHT_GRAY
		EFFECT.CONFUSED: return Color.VIOLET
		EFFECT.SLEEPING: return Color.INDIGO
		EFFECT.BURNING: return Color.ORANGE_RED
		EFFECT.HEALTH_REGEN: return Color.GREEN
		EFFECT.MANA_REGEN: return Color.ALICE_BLUE
		EFFECT.DAMAGE_BOOST: return Color.GOLD
		EFFECT.DAMAGE_REDUCTION: return Color.SILVER
		EFFECT.CRITICAL_RATE_BOOST: return Color.YELLOW
		EFFECT.CRITICAL_DAMAGE_BOOST: return Color.YELLOW
		EFFECT.DEFENSE_BOOST: return Color.CYAN
		EFFECT.DEFENSE_REDUCTION: return Color.DARK_BLUE
		EFFECT.EXP_BOOST: return Color.PURPLE
		EFFECT.HEALTH_AMPLIFICATION: return Color.LIME_GREEN
		EFFECT.MANA_AMPLIFICATION: return Color.SKY_BLUE
		EFFECT.ATTACK_SPEED_BOOST: return Color.LIGHT_CORAL
		EFFECT.ATTACK_SPEED_REDUCTION: return Color.DARK_RED
		EFFECT.SPEED_BOOST: return Color.LIGHT_GREEN
		EFFECT.SPEED_REDUCTION: return Color.DARK_GREEN
		_: return Color.WHITE
	

static func _filter_by_debuff_effects(_status_effect: StatusEffect) -> bool:
	return (_status_effect.type == TYPE.ACTIVE and _status_effect.category == CATEGORY.DEBUFF and _status_effect.effect != EFFECT.NONE)


static func _filter_by_buff_effects(_status_effect: StatusEffect) -> bool:
	return (_status_effect.type == TYPE.ACTIVE and _status_effect.category == CATEGORY.DEBUFF and _status_effect.effect != EFFECT.NONE)


static func get_effect_by_attribute_type(attribute_type: ItemAttribute.TYPE) -> EFFECT:
	if ATTRIBUTE_TO_EFFECT.has(attribute_type):
		return ATTRIBUTE_TO_EFFECT[attribute_type]
	return EFFECT.NONE