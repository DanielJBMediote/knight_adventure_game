class_name PlayerStatusEffectListUI
extends Control

@onready var base_effect_scene: PackedScene = preload("res://src/actors/player/ui/status_effects/status_effect_ui.tscn")

const MAX_STATUS_EFFECT_SHOWING = 12

@onready var status_list: GridContainer = $StatusList

var effect_scenes: Dictionary[String, PackedScene] = {}

var effect_ui_classes: Dictionary = {
	StatusEffectData.EFFECT.POISON: PoisonStatusEffectUI,
	StatusEffectData.EFFECT.BLEED: BleedStatusEffectUI,
	StatusEffectData.EFFECT.FREEZE: FreezeStatusEffectUI
}

# Armazena referências aos efeitos ativos
var active_effects: Dictionary[StatusEffectData.EFFECT, StatusEffectUI] = {}  
var atctive_effects_remaining: Dictionary[StatusEffectData.EFFECT, StatusEffectUI] = {}

func _ready() -> void:
	for child in status_list.get_children():
		child.queue_free()
		
	#load_effect_scenes()
	PlayerEvents.add_status_effect.connect(_on_add_status_effect)
	PlayerEvents.remove_status_effect.connect(_on_remove_status_effect)
	PlayerEvents.clear_status_effects.connect(_on_clear_status_effects)

#func load_effect_scenes() -> void:
	#var dir = DirAccess.open("res://src/actors/player/ui/status_effects/")
	#if dir:
		#dir.list_dir_begin()
		#var file_name = dir.get_next()
		#while file_name != "":
			#if file_name.ends_with(".tscn"):
				#var effect_name = file_name.replace("_status_effect_ui.tscn", "")
				#effect_scenes[effect_name] = load(dir.get_current_dir().path_join(file_name))
			#file_name = dir.get_next()

#func instantiated_effect(effect_name: String) -> Node:
	#var effect_instance
	#if effect_scenes.has(effect_name):
		#effect_instance = effect_scenes[effect_name].instantiate()
		#return effect_instance
	#else:
		#return null

func _on_add_status_effect(effect_data: StatusEffectData) -> void:
	# Verifica se o efeito já está ativo
	if active_effects.has(effect_data.effect):
		update_active_status_effect(effect_data)
		return
	
	# Cria a UI apropriada para o tipo de efeito
	var effect_ui = create_effect_ui(effect_data.effect)
	if effect_ui:
		active_effects[effect_data.effect] = effect_ui
		add_status_on_list(effect_ui, effect_data)
		effect_ui.setup_effect(effect_data)
		_start_effect_timer(effect_ui, effect_data)

func add_status_on_list(effect_ui: StatusEffectUI, effect_data: StatusEffectData) -> void:
	update_list_columns()
	
	if active_effects.size() <= MAX_STATUS_EFFECT_SHOWING:
		status_list.add_child(effect_ui)
		return
	
	#atctive_effects_remaining[effect_data.effect] = effect_ui

func update_list_columns() -> void:
	var status_size = active_effects.size()
	if status_size > 4 and status_size < 8:
		status_list.columns = 2
	elif  status_size > 8 and status_size < MAX_STATUS_EFFECT_SHOWING:
		status_list.columns = 3
	else:
		status_list.columns = 1

func create_effect_ui(effect_type: StatusEffectData.EFFECT) -> StatusEffectUI:
	if effect_ui_classes.has(effect_type):
		# Instancia a cena base
		var base_instance = base_effect_scene.instantiate() as StatusEffectUI
		
		# Configura o script da classe específica
		var specific_class = effect_ui_classes[effect_type]
		base_instance.set_script(specific_class)
		#base_instance.effect_ended.connect(_on_effect_endded)
		
		return base_instance
	return null

func update_active_status_effect(effect_data: StatusEffectData) -> void:
	if active_effects.has(effect_data.effect):
		var effect_ui: StatusEffectUI = active_effects[effect_data.effect]
		effect_ui.extend_effect_duration(effect_data.duration)

func _on_remove_status_effect(effect_data: StatusEffectData) -> void:
	if active_effects.has(effect_data.effect):
		var effect_ui = active_effects[effect_data.effect]
		effect_ui.queue_free()
		active_effects.erase(effect_data.effect)

func _on_clear_status_effects() -> void:
	for effect_ui in active_effects.values():
		effect_ui.queue_free()
	active_effects.clear()

func _start_effect_timer(effect_ui: StatusEffectUI, effect_data: StatusEffectData) -> void:
	effect_ui.start_timer(effect_data)

func format_time(seconds: int) -> String:
	var minutes = int(seconds / 60)
	var secs = int(seconds % 60)
	return "%02d:%02d" % [minutes, secs]
