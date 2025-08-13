# freeze_effect_status_data.gd
class_name FreezeStatusEffect
extends StatusEffectData

var move_speed_redution := 0.5
var attack_speed_redution := 0.5

func _init() -> void:
	self.effect = StatusEffectData.EFFECT.FREEZE
	self.type = StatusEffectData.TYPE.DEBUFF
	
