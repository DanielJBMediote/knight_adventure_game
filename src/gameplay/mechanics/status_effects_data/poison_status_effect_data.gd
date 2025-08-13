class_name PoisonEffectData
extends StatusEffectData

var move_speed_reduction := 0.25 # 25% de redução de Move Speed
var _damage: float
var damage: float:
	get: return _damage
	set(value):
		_damage = value if value >= 1.0 else 0.0
		active = _damage > 0.0  # Atualiza automaticamente o estado active

func _init(dmg: float, dur: float, mv_reduc: float = 0.25) -> void:
	self.damage = dmg
	self.duration = dur
	self.move_speed_reduction = mv_reduc
	self.effect = StatusEffectData.EFFECT.POISON
	self.type = StatusEffectData.TYPE.DEBUFF
