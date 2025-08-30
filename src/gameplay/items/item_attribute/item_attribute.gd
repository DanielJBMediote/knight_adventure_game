class_name ItemAttribute
extends Resource

enum TYPE {
	HEALTH,
	MANA,
	ENERGY,
	DEFENSE,
	DAMAGE,
	CRITICAL_RATE,
	CRITICAL_DAMAGE,
	ATTACK_SPEED,
	MOVE_SPEED,
	HEALTH_REGEN,
	MANA_REGEN,
	ENERGY_REGEN,
	EXP_BUFF,
	POISON_HIT_RATE,
	BLEED_HIT_RATE,
	FREEZE_HIT_RATE
}

# Mapeamento de tipos que devem ser convertidos para porcentagem
const PERCENTAGE_TYPES := [
	#TYPE.DEFENSE,
	TYPE.CRITICAL_RATE,
	TYPE.CRITICAL_DAMAGE,
	TYPE.ATTACK_SPEED,
	TYPE.MOVE_SPEED,
	TYPE.EXP_BUFF,
	TYPE.POISON_HIT_RATE,
	TYPE.BLEED_HIT_RATE,
	TYPE.FREEZE_HIT_RATE
]

const ATTRIBUTE_NAMES = {
	TYPE.HEALTH: "Health",
	TYPE.MANA: "Mana",
	TYPE.ENERGY: "Energy",
	TYPE.DEFENSE: "Defense",
	TYPE.DAMAGE: "Damage",
	TYPE.CRITICAL_RATE: "Critical Rate",
	TYPE.CRITICAL_DAMAGE: "Critical Damage",
	TYPE.ATTACK_SPEED: "Attack Speed",
	TYPE.MOVE_SPEED: "Move Speed",
	TYPE.HEALTH_REGEN: "Health Regen",
	TYPE.MANA_REGEN: "Mana Regen",
	TYPE.ENERGY_REGEN: "Energy Regen",
	TYPE.EXP_BUFF: "Exp Buff",
	TYPE.POISON_HIT_RATE: "Poison Rate",
	TYPE.BLEED_HIT_RATE: "Bleed Rate",
	TYPE.FREEZE_HIT_RATE: "Freeze Rate",
}

const ATTRIBUTE_KEYS := {
	TYPE.HEALTH: "health",
	TYPE.MANA: "mana",
	TYPE.ENERGY: "energy",
	TYPE.DEFENSE: "defense",
	TYPE.DAMAGE: "damage",
	TYPE.CRITICAL_RATE: "critical_rate",
	TYPE.CRITICAL_DAMAGE: "critical_damage",
	TYPE.ATTACK_SPEED: "attack_speed",
	TYPE.MOVE_SPEED: "move_speed",
	TYPE.HEALTH_REGEN: "health_regen",
	TYPE.MANA_REGEN: "mana_regen",
	TYPE.ENERGY_REGEN: "energy_regen",
	TYPE.EXP_BUFF: "exp_buff",
	TYPE.POISON_HIT_RATE: "poison_hit_rate",
	TYPE.BLEED_HIT_RATE: "bleed_hit_rate",
	TYPE.FREEZE_HIT_RATE: "Freeze_hit_rate",
}

const COLOR_MINIMAL = Color.WHITE  # ⚪ Abaixo do normal
const COLOR_NORMAL = Color.WEB_GREEN  # 🟢 Normal (95%-105%)
const COLOR_GOOD = Color.GOLDENROD  # 🟡 Bom (105%-115%)
#const COLOR_EXCELLENT = Color.DEEP_SKY_BLUE  # 🔵 Excelente (115%-125%)
const COLOR_PERFECT = Color.FUCHSIA  # 🟣 Perfeito (125%+)

@export var type: TYPE
@export var base_value: float = 0.0
@export var value: float = 0.0
@export var min_value: float:
	get:
		return base_value * 0.75
	set(value):
		min_value = value
@export var max_value: float:
	get:
		return base_value * 1.25
	set(value):
		max_value = value


func get_max_value_range() -> float:
	return max_value


func get_min_value_range() -> float:
	return min_value


static func get_attribute_type_name(_attribute_type: TYPE) -> String:
	return LocalizationManager.get_ui_text(ATTRIBUTE_KEYS[_attribute_type])


static func filter_by_type(attribute: ItemAttribute, filter_type: TYPE) -> bool:
	return attribute.type == filter_type

	
static func get_attribute_value_color(_attribute: ItemAttribute) -> Color:
	if _attribute.value == _attribute.min_value:
		return COLOR_MINIMAL

	var percentage = _attribute.value / _attribute.base_value

	if percentage < 0.95:
		return COLOR_MINIMAL  # ⚪ Abaixo de 95%
	elif percentage < 1.15:
		return COLOR_NORMAL  # 🟢 95% - 115%
	elif percentage < 1.25:
		return COLOR_GOOD  # 🟡 115% - 125%
	#elif percentage < 1.25:
		#return COLOR_EXCELLENT  # 🔵 115% - 125%
	else:
		return COLOR_PERFECT  # 🟣 125%+ (Perfeito)
