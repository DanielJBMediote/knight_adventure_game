# autoloads/player_events.gd
extends Node

signal update_equipment(equip: EquipmentItem, is_equipped: bool)

signal interaction_showed(text: String)
signal interaction_hided(text: String)

static var active_effects_ui: Dictionary[StatusEffect.EFFECT, StatusEffectUI] = {}
signal status_effect_added(effect: StatusEffect, effect_ui: StatusEffectUI)
signal status_effect_removed(effect: StatusEffect, effect_ui: StatusEffectUI)

static var potion_cooldown_timers: Dictionary[String, SceneTreeTimer] = {}
signal potion_cooldown_started(potion_id: String, cooldown_time: float)
signal potion_cooldown_finished(potion_id: String)
# signal potion_cooldown_updated(potion_id: String, time_remaining: float)


func _ready() -> void:
	pass


func _input(event: InputEvent) -> void:
	if GameManager.is_paused:
		return

	if event.is_action_pressed("inventory"):
		if InventoryManager.is_open:
			InventoryManager.close_inventory()
		else:
			InventoryManager.open_inventory()


func use_potion(potion: PotionItem) -> bool:
	if potion == null or potion.item_action == null:
		return false

	if is_potion_in_cooldown(potion.item_id):
		GameManager.show_instant_message("Potion in Cooldown, can't use it.")
		return false

	var potion_action = potion.get_item_action()

	if potion_action.action_type == ItemAction.TYPE.INSTANTLY:
		var amount = potion_action.attribute.value
		match potion_action.attribute.type:
			ItemAttribute.TYPE.HEALTH:
				PlayerStats.update_health(amount)
			ItemAttribute.TYPE.MANA:
				PlayerStats.update_mana(amount)
			ItemAttribute.TYPE.ENERGY:
				PlayerStats.update_energy(amount)
			_:
				return false
	else:
		PlayerStats.update_active_potions_status_effects(potion_action)
	
	InventoryManager.remove_item(potion, 1)
	PlayerStats.emit_attributes_changed()
	
	_setup_potion_cooldown(potion)
	
	return true

func _setup_potion_cooldown(potion: PotionItem) -> void:
	var timer = get_tree().create_timer(potion.cooldown)
	timer.timeout.connect(_on_potion_cooldown_finished.bind(potion.item_id))
	potion_cooldown_timers[potion.item_id] = timer
	potion_cooldown_started.emit(potion.item_id, potion.cooldown)
	
func _on_potion_cooldown_finished(potion_id: String) -> void:
	if potion_cooldown_timers.has(potion_id):
		potion_cooldown_timers.erase(potion_id)
		potion_cooldown_finished.emit(potion_id)

func get_potion_cooldown_remaining(potion_id: String) -> float:
	if potion_cooldown_timers.has(potion_id):
		var timer = potion_cooldown_timers[potion_id]
		return timer.time_left
	return 0.0

func is_potion_in_cooldown(potion_id: String) -> bool:
	if potion_cooldown_timers.has(potion_id):
		var timer = potion_cooldown_timers[potion_id]
		return not timer.time_left == 0.0
	return false

func equip_item(equipment_item: EquipmentItem) -> bool:
	# Verifica se pode equipar
	if ItemManager.compare_player_level(equipment_item.item_level):
		update_equipment.emit(equipment_item)
		return true
	else:
		var part_1 = LocalizationManager.get_ui_text("insufficient_level")
		var part_2 = LocalizationManager.get_ui_text("level_required")
		var message = str(part_1, "! ", part_2, ": ", equipment_item.item_level, ".")
		GameManager.show_instant_message(message, InstantMessage.TYPE.DANGER)
		return false


func show_interaction(text: String) -> void:
	interaction_showed.emit(text)


func hide_interaction() -> void:
	interaction_hided.emit()


func add_new_status_effect(status_effect: StatusEffect) -> void:
	if active_effects_ui.has(status_effect.effect):
		var effect_ui = active_effects_ui[status_effect.effect]
		effect_ui.updated_effect_duration(status_effect.duration)
	else:
		var effect_ui = _create_effect_ui(status_effect)
		active_effects_ui[status_effect.effect] = effect_ui
		status_effect_added.emit(status_effect, effect_ui)


func remove_status_effect(effect_data: StatusEffect) -> void:
	var effect = effect_data.effect
	if active_effects_ui.has(effect):
		var effect_ui = active_effects_ui[effect]
		if effect_ui:
			effect_ui.queue_free()
			# Remove from UI
			active_effects_ui.erase(effect)
			effect_data.is_active = false
			status_effect_removed.emit(effect_data, effect_ui)


func _create_effect_ui(effect_data: StatusEffect) -> StatusEffectUI:
	var base_effect_scene: PackedScene = preload("res://src/gameplay/mechanics/combat/ui/status_effect_ui.tscn")
	var base_instance = base_effect_scene.instantiate() as StatusEffectUI

	var type_str = effect_data.get_category_key_text()
	var effect_str = effect_data.get_effect_icon_name()
	var base_path = "res://assets/ui/status_effect_icons/%ss/%s.png" % [type_str, effect_str]
	var icon_texture = FileUtils.load_texture_with_fallback(base_path)
	base_instance.set_icon(icon_texture)

	return base_instance
