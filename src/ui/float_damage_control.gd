class_name FloatDamageControl
extends Control

signal trigged_hit(damage: float)

@onready var float_label_scene: PackedScene = preload("res://src/ui/float_label.tscn")
@onready var tick_timer: Timer = $TickTimer

const CRIT_DAMAGE_SIZE := 64
const STATUS_EFFECT_COLORS := {
	StatusEffectData.EFFECT.BLEED: Color.DARK_RED,
	StatusEffectData.EFFECT.POISON: Color.FOREST_GREEN,
	StatusEffectData.EFFECT.FREEZE: Color.AQUA,
	StatusEffectData.EFFECT.HP_REGEN: Color.GREEN
}

enum DMG_TYPE {NORMAL, BLOCK, BLEEDING, POISONING}
var damage_type = DMG_TYPE.NORMAL
var float_label: FloatLabel

# Dicionário para armazenar status effects ativos
var active_status_effects: Dictionary = {}

func _ready() -> void:
	tick_timer.timeout.connect(_apply_damage_on_finish_tick)
	tick_timer.wait_time = 1.0
	tick_timer.start()

func set_damage(data: DamageData) -> void:
	# Mostra o dano principal
	_show_damage(data.damage, data.is_critical)
	
	# Processa cada status effect
	for effect in data.status_effects:
		if effect.active:
			_start_status_effect(effect)

func _start_status_effect(effect: StatusEffectData) -> void:
	
	# Cria um timer para o efeito se não existir
	if not active_status_effects.has(effect.effect):
		var timer = Timer.new()
		timer.one_shot = true
		timer.timeout.connect(_on_status_effect_ended.bind(effect.effect))
		add_child(timer)
		active_status_effects[effect.effect] = {
			"timer": timer,
			"effect": effect
		}
		timer.start(effect.duration)
	else:
		# Se o efeito já existe, apenas atualiza a duração
		active_status_effects[effect.effect].timer.start(effect.duration)
		active_status_effects[effect.effect].effect = effect

func _on_status_effect_ended(effect_type: StatusEffectData.EFFECT) -> void:
	if active_status_effects.has(effect_type):
		active_status_effects.erase(effect_type)

func _apply_damage_on_finish_tick() -> void:
	# Aplica dano de todos os status effects ativos
	for effect_data in active_status_effects.values():
		var effect: StatusEffectData = effect_data.effect
		_show_status_damage(effect.damage, effect.effect)

func _show_damage(damage: float, is_critical: bool = false) -> void:
	float_label = float_label_scene.instantiate()
	float_label.text = str(roundi(damage))
	
	if is_critical:
		float_label.modulate = Color.ORANGE_RED
		float_label.add_theme_font_size_override("font_size", CRIT_DAMAGE_SIZE)
	
	add_child(float_label)
	trigged_hit.emit(damage)

func _show_status_damage(damage: float, effect_type: StatusEffectData.EFFECT) -> void:
	float_label = float_label_scene.instantiate()
	float_label.text = str(roundi(damage))
	
	# Usa a cor específica para cada tipo de efeito
	if STATUS_EFFECT_COLORS.has(effect_type):
		float_label.modulate = STATUS_EFFECT_COLORS[effect_type]
	
	add_child(float_label)
	trigged_hit.emit(damage)
