class_name ItemAttribute
extends RefCounted

enum Type {
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
}

# Mapeamento de tipos que devem ser convertidos para porcentagem
const PERCENTAGE_TYPES := [
	Type.DEFENSE,
	Type.CRITICAL_RATE,
	Type.CRITICAL_DAMAGE,
	Type.ATTACK_SPEED,
	Type.MOVE_SPEED,
	Type.EXP_BUFF
]

const ATTRIBUTE_NAMES = {
	Type.HEALTH: "Health",
	Type.MANA: "Mana",
	Type.ENERGY: "Energy",
	Type.DEFENSE: "Defense",
	Type.DAMAGE: "Damage",
	Type.CRITICAL_RATE: "Critical Rate",
	Type.CRITICAL_DAMAGE: "Critical Damage",
	Type.ATTACK_SPEED: "Attack Speed", 
	Type.MOVE_SPEED: "Move Speed",
	Type.HEALTH_REGEN: "Health Regen",
	Type.MANA_REGEN: "Mana Regen",
	Type.ENERGY_REGEN: "Energy Regen",
	Type.EXP_BUFF: "Exp Buff"
}

const ATTRIBUTE_KEYS := {
	Type.HEALTH: "health",
	Type.MANA: "mana",
	Type.ENERGY: "energy",
	Type.DEFENSE: "defense",
	Type.DAMAGE: "damage",
	Type.CRITICAL_RATE: "critical_rate",
	Type.CRITICAL_DAMAGE: "critical_damage",
	Type.ATTACK_SPEED: "attack_speed",
	Type.MOVE_SPEED: "move_speed",
	Type.HEALTH_REGEN: "health_regen",
	Type.MANA_REGEN: "mana_regen",
	Type.ENERGY_REGEN: "energy_regen",
	Type.EXP_BUFF: "exp_buff"
}

var type: Type
var value: float = 0.0

static func get_attribute_type_name(_attribute_type: Type) -> String:
	return LocalizationManager.get_ui_attribute_name(ATTRIBUTE_KEYS[_attribute_type])
