class_name StatusEffectData

enum EFFECT {POISON, BLEED, FREEZE, STUN, HP_REGEN, MP_REGEN}
var effect: EFFECT

enum TYPE {BUFF, DEBUFF}
var type: TYPE

var active: bool = false
var duration: float = 0.0

func _init() -> void:
	pass
