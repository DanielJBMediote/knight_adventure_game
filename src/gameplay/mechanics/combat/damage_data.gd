# damage_data.gd
class_name DamageData

var damage: float = 0.0
var is_critical: bool = false
var is_knockback_hit: bool = false
var status_effects: Array[StatusEffectData] = []

func _init():
	pass


func get_active_status_effects() -> Array[StatusEffectData]:
	return status_effects.filter(StatusEffectData._filter_by_active_effects)
