class_name StatusEffectData

enum EFFECT {POISON, BLEED, FREEZE, STUN, HP_REGEN, MP_REGEN}
var effect: EFFECT

enum TYPE {BUFF, DEBUFF}
var type: TYPE

var active: bool = false
var duration: float = 0.0

func _init() -> void:
	pass

func get_effect_name() -> String:
	match effect:
		EFFECT.POISON:
			return "Poisoning"
		EFFECT.BLEED:
			return "Bleeding"
		EFFECT.FREEZE:
			return "Freezening"
		EFFECT.STUN:
			return "Stunned"
		EFFECT.HP_REGEN:
			return "Health Regen"
		EFFECT.MP_REGEN:
			return "Mana Regen"
		
	return "Unknown Effect"
