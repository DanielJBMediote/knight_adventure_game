class_name ESGSEquipmentItemSlotUI
extends BaseSlotUI

signal equipment_updated(new_equipment: EquipmentItem)

const GROUP_NAME = "esgs_slot_group"
@onready var item_level: DefaultLabel = $MarginContainer/MarginContainer/Footer/Level

func _setup_specifics() -> void:
	add_to_group(GROUP_NAME)
	setup_equipment(null)


func setup_equipment(new_equipment: EquipmentItem) -> void:
	super.setup_item(new_equipment)

	if new_equipment:
		item_texture.texture = new_equipment.item_texture
	else:
		item_texture.texture = null
		rarity_texture.texture = null
	_update_equipment_level()
	equipment_updated.emit(new_equipment)


func _update_equipment_level() -> void:
	if not current_item:
		item_level.hide()
		return
	item_level.show()
	var level = current_item.item_level
	item_level.text = "Lv.%d" % level
	var player_level = PlayerStats.level
	var difference = player_level - level

	if difference >= 20:
		item_level.add_theme_color_override("font_color", Color.RED)
	elif difference >= 5:
		item_level.add_theme_color_override("font_color", Color.YELLOW)
	elif difference == 0:
		item_level.add_theme_color_override("font_color", Color.GREEN)
	else:
		item_level.add_theme_color_override("font_color", Color.WHITE)


func _hide_item_visuals() -> void:
	super._hide_item_visuals()
	item_level.hide()


func _show_item_visuals() -> void:
	super._show_item_visuals()
	item_level.show()


func _try_move_item(target_slot: BaseSlotUI) -> void:
	if target_slot.is_in_group(InventoryItemSlotUI.GROUP_NAME):
		var inventory_item = target_slot.current_item
		if inventory_item and inventory_item is EquipmentItem:
			if inventory_item.item_rarity > Item.RARITY.COMMON:
				var to_socket = inventory_item.clone()
				InventoryManager.remove_item(inventory_item)
				InventoryManager.add_item(current_item, target_slot.slot_index)
				setup_equipment(to_socket)
				InventoryManager.item_drag_ended.emit(true)
			else:
				global_position = original_position
				InventoryManager.cancel_item_drag()
		
		# Se não tem item no target_slot do inventário, apenas remover
		else:
			InventoryManager.add_item(current_item, target_slot.slot_index)
			setup_equipment(null)
			InventoryManager.item_drag_ended.emit(true)
	else:
		global_position = original_position
		InventoryManager.cancel_item_drag()
