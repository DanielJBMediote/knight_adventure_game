# autoloads/player_events.gd
extends Node

signal update_equipment(equip: EquipmentItem, is_equipped: bool)

signal interaction_showed(text: String)
signal interaction_hidded(text: String)

signal status_effect_added(effect: StatusEffect, effect_ui: StatusEffectUI)
signal status_effect_removed(effect: StatusEffect, effect_ui: StatusEffectUI)

static var active_effects_ui: Dictionary[StatusEffect.EFFECT, StatusEffectUI] = {}


func _ready() -> void:
	ItemManager.use_potion.connect(_on_use_potion)


func _input(event: InputEvent) -> void:
	if GameEvents.is_paused:
		return

	if event.is_action_pressed("inventory"):
		if InventoryManager.is_open:
			InventoryManager.close_inventory()
		else:
			InventoryManager.open_inventory()


func _on_use_potion(potion: PotionItem) -> bool:
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
	
	InventoryManager.remove_item(potion)
	PlayerStats.emit_attributes_changed()
	return true


func equip_item(equipment_item: EquipmentItem) -> bool:
	# Verifica se pode equipar
	if ItemManager.compare_player_level(equipment_item.item_level):
		update_equipment.emit(equipment_item)
		return true
	else:
		var part_1 = LocalizationManager.get_ui_text("insufficient_level")
		var part_2 = LocalizationManager.get_ui_text("level_required")
		var message = str(part_1, "! ", part_2, ": ", equipment_item.item_level, ".")
		GameEvents.show_instant_message(message, InstantMessage.TYPE.DANGER)
		return false


func show_interaction(text: String) -> void:
	interaction_showed.emit(text)


func hide_interaction() -> void:
	interaction_hidded.emit()


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
