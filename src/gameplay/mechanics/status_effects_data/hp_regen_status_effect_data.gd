# hp_regen_effect_status_data.gd
class_name HealthRegenStatusEffect
extends StatusEffectData

var percent_health_per_tick: float = 0.1
var mutiply_factor: float = 1.0

func _init(dur: float) -> void:
	self.duration = dur
	self.effect = StatusEffectData.EFFECT.HP_REGEN
	self.type = StatusEffectData.TYPE.BUFF
