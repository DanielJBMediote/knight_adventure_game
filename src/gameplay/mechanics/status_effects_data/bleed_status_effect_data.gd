# bleed_effect_data.gd
class_name BleedEffectData
extends StatusEffectData

var incremental_damage_per_tick := 0.1 # Aumenta em 10% a cada tick
var _damage: float = 0.0  # Variável privada para armazenar o valor

# Propriedade com validação
var damage: float:
	get: return _damage
	set(value):
		_damage = value if value >= 1.0 else 0.0
		active = _damage > 0.0  # Atualiza automaticamente o estado active

func _init(dmg: float, dur: float, inc_dmg_tick: float = 0.1) -> void:
	self.damage = dmg
	self.duration = dur
	self.incremental_damage_per_tick = inc_dmg_tick
	self.effect = StatusEffectData.EFFECT.BLEED
	self.type = StatusEffectData.TYPE.DEBUFF
