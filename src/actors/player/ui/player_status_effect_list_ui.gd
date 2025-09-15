class_name PlayerStatusEffectListUI
extends Control

const MAX_STATUS_EFFECT_SHOWING = 12

@onready var status_list: HBoxContainer = $StatusList

func _ready() -> void:
	for child in status_list.get_children():
		child.queue_free()
		
	PlayerEvents.status_effect_added.connect(_on_status_effect_added)
	# PlayerEvents.status_effect_removed.connect(_on_status_effect_removed)
	#PlayerEvents.clear_status_effects.connect(_on_clear_status_effects)

func _on_status_effect_added(effect_data: StatusEffectData, effect_ui: StatusEffectUI) -> void:
	_add_status_on_list(effect_ui, effect_data)
	_start_effect_timer(effect_ui, effect_data)

func _add_status_on_list(effect_ui: StatusEffectUI, effect_data: StatusEffectData) -> void:
	if PlayerEvents.active_effects.size() <= MAX_STATUS_EFFECT_SHOWING:
		status_list.add_child(effect_ui)
		effect_ui.setup_effect(effect_data)


func _update_active_status_effect(effect_data: StatusEffectData) -> void:
	if PlayerEvents.active_effects.has(effect_data.effect):
		var effect_ui: StatusEffectUI = PlayerEvents.active_effects[effect_data.effect]
		effect_ui.extend_effect_duration(effect_data.duration)

# func _on_status_effect_removed(_effect_data: StatusEffectData, effect_ui: StatusEffectUI) -> void:
# 	for child in status_list.get_children():
# 		if effect_ui == child:
# 			effect_ui.queue_free()
# 			break

func _on_clear_status_effects() -> void:
	for effect_ui in PlayerEvents.active_effects.values():
		effect_ui.queue_free()
	PlayerEvents.active_effects.clear()

func _start_effect_timer(effect_ui: StatusEffectUI, effect_data: StatusEffectData) -> void:
	effect_ui.start_timer(effect_data)

func format_time(seconds: int) -> String:
	var minutes = int(float(seconds) / 60)
	var secs = int(seconds % 60)
	return "%02d:%02d" % [minutes, secs]
