# autoloads/player_events.gd
extends Node

signal update_equipment(equip: EquipmentItem, is_equipped: bool)

signal energy_warning

signal add_status_effect(effect: StatusEffectData)
signal remove_status_effect(effect: StatusEffectData)
signal clear_status_effects


func _ready() -> void:
	ItemManager.use_potion.connect(_on_use_potion)
	ItemManager.use_equipment.connect(_on_use_equipment)


func _on_use_potion(potion: PotionItem) -> bool:
	print("Potion use: ", potion.item_name)
	print("Effects: ", potion.item_description)

	return true


func _on_use_equipment(item: EquipmentItem) -> void:
	# Verifica se pode equipar
	if ItemManager.compare_player_level(item.item_level):
		var is_equipped = PlayerEquipments.is_equipped(item)
		update_equipment.emit(item, is_equipped)
	else:
		var node = get_tree().get_nodes_in_group("player_ui")[0]
		var part_1 = LocalizationManager.get_ui_text("insufficient_level")
		var part_2 = LocalizationManager.get_ui_text("level_required")
		var text = str(part_1, "! ", part_2, ": ", item.item_level, ".")
		InstantMessage.show_instant_message(node, text, InstantMessage.TYPE.DANGER)
