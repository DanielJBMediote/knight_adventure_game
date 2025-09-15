class_name StatusEffectData
extends Resource

enum EFFECT {
	POISONING,
	BLEEDING,
	FREEZING,
	CONFUSED,
	STUNING,
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
}

enum CATEGORY {BUFF, DEBUFF}
enum TYPE {ACTIVE, PASSIVE}

@export var category: CATEGORY
@export var type: TYPE
@export var effect: EFFECT

## The Base Value os effect
@export var base_value: float = 0.0
## Base Rate Chance: Min=0.0 Max=1.0
@export_range(0.0, 1.0) var base_rate_chance: float = 0.0
## Base Duration in seconds.
@export var base_duration: float = 10.0


var is_active: bool = false
var value := 0.0
var rate_chance := 0.0
var duration := 0.0


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


static func _filter_by_active_effects(_status_effect: StatusEffectData) -> bool:
	return _status_effect.is_active == true and _status_effect.type == TYPE.ACTIVE


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
		EFFECT.STUNING: return "stunned"
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
		EFFECT.SPEED_BOOST: return "swiftness"
		_: return ""
