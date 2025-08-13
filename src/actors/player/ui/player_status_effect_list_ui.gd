class_name PlayerStatusEffectListUI
extends Control

@onready var status_list: VBoxContainer = $StatusList

# Cenas pré-carregadas para cada tipo de status
#@onready var bleed_ui_scene = preload("res://src/player/ui/status_effects/bleed_status_effect_ui.tscn")
#@onready var freeze_ui_scene = preload("res://src/player/ui/status_effects/freeze_status_effect_ui.tscn")

var effect_scenes = {}
var active_effects: Dictionary = {}  # Armazena referências aos efeitos ativos

func _ready() -> void:
	load_effect_scenes()
	# Conecta aos sinais do PlayerEvents
	PlayerEvents.add_status_effect.connect(_on_add_status_effect)
	PlayerEvents.remove_status_effect.connect(_on_remove_status_effect)
	PlayerEvents.clear_status_effects.connect(_on_clear_status_effects)

func load_effect_scenes() -> void:
	var dir = DirAccess.open("res://src/actors/player/ui/status_effects/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var effect_name = file_name.replace("_status_effect_ui.tscn", "")
				effect_scenes[effect_name] = load(dir.get_current_dir().path_join(file_name))
			file_name = dir.get_next()

func instantiated_effect(effect_name: String) -> Node:
	var effect_instance
	if effect_scenes.has(effect_name):
		effect_instance = effect_scenes[effect_name].instantiate()
		return effect_instance
	else:
		return null

func _on_add_status_effect(effect_data: StatusEffectData) -> void:
	# Verifica se o efeito já está ativo
	if active_effects.has(effect_data.effect):
		return
	
	# Cria a UI apropriada para o tipo de efeito
	var effect_ui: StatusEffectUI
	
	match effect_data.effect:
		StatusEffectData.EFFECT.POISON:
			effect_ui = instantiated_effect("poison")
		StatusEffectData.EFFECT.BLEED:
			effect_ui = instantiated_effect("bleed")
		StatusEffectData.EFFECT.FREEZE:
			effect_ui = instantiated_effect("freeze")
		_:
			return
	
	# Configura a UI
	status_list.add_child(effect_ui)
	active_effects[effect_data.effect] = effect_ui
	
	# Inicia a animação/atualização do tempo
	_start_effect_timer(effect_ui, effect_data.duration)

func _on_remove_status_effect(effect_data: StatusEffectData) -> void:
	if active_effects.has(effect_data.effect):
		var effect_ui = active_effects[effect_data.effect]
		effect_ui.queue_free()
		active_effects.erase(effect_data.effect)

func _on_clear_status_effects() -> void:
	for effect_ui in active_effects.values():
		effect_ui.queue_free()
	active_effects.clear()

func _start_effect_timer(effect_ui: StatusEffectUI, duration: float) -> void:
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(_on_effect_timeout.bind(effect_ui, timer))
	add_child(timer)
	timer.start()
	
	# Atualiza a barra de progresso
	var tween = create_tween()
	effect_ui.progress_bar.max_value = duration
	tween.tween_property(effect_ui.progress_bar, "value", 0, duration)
	
	# Atualiza o label de tempo
	effect_ui.timer_label.text = format_time(duration)
	var time_tween = create_tween().set_loops()
	time_tween.tween_interval(1.0)
	time_tween.tween_callback(_update_time_label.bind(effect_ui))

func _update_time_label(effect_ui: StatusEffectUI) -> void:
	var remaining_time = effect_ui.progress_bar.value / effect_ui.progress_bar.max_value * effect_ui.progress_bar.max_value
	effect_ui.timer_label.text = format_time(remaining_time)

func _on_effect_timeout(effect_ui: StatusEffectUI, timer: Timer) -> void:
	effect_ui.queue_free()
	timer.queue_free()
	active_effects.erase(effect_ui.effect)

func format_time(seconds: int) -> String:
	var minutes = int(seconds / 60)
	var secs = int(seconds % 60)
	return "%02d:%02d" % [minutes, secs]
