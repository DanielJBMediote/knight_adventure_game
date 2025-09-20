class_name FloatDamageControl
extends Control

signal hitted(damage: float)

@onready var custom_font = preload("res://assets/fonts/deltarune.ttf")
@onready var float_label_scene: PackedScene = preload("res://src/ui/float_label.tscn")
@onready var tick_timer: Timer = $TickTimer

# Dicionário para armazenar status effects ativos
var active_status_effects: Dictionary = {}

func _ready() -> void:
	tick_timer.timeout.connect(_apply_damage_on_finish_tick)
	tick_timer.wait_time = 1.0
	tick_timer.start()

func update_damage(damage_data: DamageData) -> void:
	# Mostra o dano principal
	_show_damage(damage_data.damage, damage_data.is_critical)
	
	# Processa cada status effect
	for status_effect in damage_data.get_debuff_status_effects():
		if status_effect.is_active:
			_start_status_effect(status_effect)

func _start_status_effect(status_effect: StatusEffect) -> void:
	var effect = status_effect.effect
	var duration = status_effect.duration
	
	# Cria um timer para o efeito se não existir
	if not active_status_effects.has(effect):
		var timer = Timer.new()
		timer.one_shot = true
		timer.timeout.connect(_on_status_effect_ended.bind(effect))
		add_child(timer)
		active_status_effects[effect] = {
			"timer": timer,
			"effect": status_effect
		}
		timer.start(duration)
	else:
		# Se o efeito já existe, apenas atualiza a duração
		active_status_effects[effect].timer.start(duration)
		active_status_effects[effect].effect = status_effect

func _on_status_effect_ended(effect: StatusEffect.EFFECT) -> void:
	if active_status_effects.has(effect):
		active_status_effects.erase(effect)

func _apply_damage_on_finish_tick() -> void:
	# Aplica dano de todos os status effects ativos
	for effect_data in active_status_effects.values():
		var status_effect: StatusEffect = effect_data.effect
		_show_status_damage(status_effect.value, status_effect)

func _show_damage(damage: float, is_critical: bool = false) -> void:
	var float_label: FloatLabel = float_label_scene.instantiate()
	float_label.text = str(roundi(damage))
	
	var font_config = FontVariation.new()
	font_config.base_font = custom_font
	float_label.add_theme_font_override("font", font_config)
	
	if is_critical:
		float_label.add_theme_color_override("font_color", Color.ORANGE_RED)
		float_label.add_theme_font_size_override("font_size", 48)
	
	add_child(float_label)
	hitted.emit(damage)

func _show_status_damage(damage: float, status_effect: StatusEffect) -> void:
	var float_label: FloatLabel = float_label_scene.instantiate()
	float_label.text = str(roundi(damage))

	var font_config = FontVariation.new()
	font_config.base_font = custom_font
	float_label.add_theme_font_override("font", font_config)
	# Usa a cor específica para cada tipo de efeito
	float_label.add_theme_color_override("font_color", status_effect.get_effect_value_color())
	
	add_child(float_label)
	hitted.emit(damage)
