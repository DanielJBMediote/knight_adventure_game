# autoloads/player_events.gd
extends Node

signal update_equipment(equip: EquipmentItem, is_equipped: bool)

signal interaction_showed(text: String)
signal interaction_hidded(text: String)

signal add_status_effect(effect: StatusEffectData)
signal remove_status_effect(effect: StatusEffectData)
signal clear_status_effects

func _ready() -> void:
	ItemManager.use_potion.connect(_on_use_potion)


func _on_use_potion(potion: PotionItem) -> bool:
	var potion_action = potion.get_item_action()
	if potion_action.action_type.INSTANTLY:
		match potion_action.attribute.type:
			ItemAttribute.TYPE.HEALTH:
				PlayerStats.update_health(potion_action.attribute.value)
			ItemAttribute.TYPE.MANA:
				PlayerStats.update_mana(potion_action.attribute.value)
			ItemAttribute.TYPE.ENERGY:
				PlayerStats.update_energy(potion_action.attribute.value)
			_:
				return false
		PlayerStats.emit_attributes_changed()
		return true
	else:
		match potion_action.attribute.type:
			ItemAttribute.TYPE.DAMAGE:
				pass
			_:
				return false
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
