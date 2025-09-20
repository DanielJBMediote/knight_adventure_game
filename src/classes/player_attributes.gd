class_name PlayerAttributes

var level: int
var health_points: float
var max_health_points: float
var health_regen_per_seconds: float
var mana_points: float
var max_mana_points: float
var mana_regen_per_seconds: float
var energy_points: float
var max_energy_points: float
var energy_regen_per_seconds: float
var attack_speed: float
var move_speed: float
var min_damage: float
var max_damage: float
var critical_points: float
var max_critical_points: float
var critical_rate: float
var critical_damage: float
var defense_points: float
var defense_rate: float
var max_defense_points: float
var current_exp: float
var total_exp: float
var exp_to_next_level: float
var exp_boost: float
var knockback_resistance: float
var knockback_force: float
var knockback_chance: float
var hit_rate_status_effects: Array[StatusEffect]


func get_hit_rate_value_by_effect(effect: StatusEffect.EFFECT) -> float:
	var index = hit_rate_status_effects.find_custom(func(ase): return ase.effect == effect)
	if index != -1:
		return hit_rate_status_effects[index].rate_chance
	return 0.0
