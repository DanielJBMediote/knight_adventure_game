# damage_data.gd
class_name DamageData

var damage: float = 0.0
var is_critical: bool = false
var is_knockback_hit: bool = false
var status_effects: Array[StatusEffect] = []

func _init():
	pass


func get_debuff_status_effects() -> Array[StatusEffect]:
	return status_effects.filter(StatusEffect._filter_by_debuff_effects)
