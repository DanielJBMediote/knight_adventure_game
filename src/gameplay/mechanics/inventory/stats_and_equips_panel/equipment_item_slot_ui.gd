class_name EquipmentItemSlotUI
extends BaseSlotUI

# signal equipment_updated(new_equipment: EquipmentItem)

@onready var background_item: TextureRect = $BackgroundItem
@onready var item_level: DefaultLabel = $MarginContainer/MarginContainer/Footer/Level

const GROUP_NAME = "equipment_slot_group"
@export var default_texture: Texture2D
@export var slot_type: EquipmentItem.TYPE

#func _ready():
	#PlayerEquipments.equipment_updated.connect(_on_player_equipment_updated)
#
#func _on_player_equipment_updated(_slot_type: EquipmentItem.TYPE, equipment: EquipmentItem) -> void:
	#if _slot_type == slot_type:
		#setup_equipment(equipment)

func _setup_specifics() -> void:
	add_to_group(GROUP_NAME)
	if default_texture:
		background_item.texture = default_texture
	setup_equipment(null)


func setup_equipment(new_equipment: EquipmentItem) -> void:
	super.setup_item(new_equipment)

	if new_equipment:
		item_texture.texture = new_equipment.item_texture
		background_item.visible = false
	else:
		item_texture.texture = null
		background_item.visible = true
		rarity_texture.texture = null
	_update_equipment_level()
	# equipment_updated.emit(new_equipment)


func _update_equipment_level() -> void:
	if not current_item:
		item_level.hide()
		return
	item_level.show()
	item_level.text = "Lv.%d" % current_item.item_level

	var difference = PlayerStats.level - current_item.item_level

	if difference >= 20:
		item_level.add_theme_color_override("font_color", Color.RED)
	elif difference >= 5:
		item_level.add_theme_color_override("font_color", Color.YELLOW)
	elif difference >= 0:
		item_level.add_theme_color_override("font_color", Color.GREEN)
	else:
		item_level.add_theme_color_override("font_color", Color.WHITE)


func _hide_item_visuals() -> void:
	super._hide_item_visuals()
	item_level.hide()
	background_item.show()


func _show_item_visuals() -> void:
	super._show_item_visuals()
	item_level.show()


func _try_move_item(target_slot: BaseSlotUI) -> void:
	if target_slot.is_in_group(InventoryItemSlotUI.GROUP_NAME) and target_slot is InventoryItemSlotUI:
		_try_move_to_inventory_slot(target_slot)
	elif target_slot.is_in_group(EquipmentItemSlotUI.GROUP_NAME):
		# Não existe (todos os slots são diferentes... por enquando, talvez quando tiver 2 slots para aneis)
		global_position = original_position
		InventoryManager.cancel_item_drag()
	else:
		global_position = original_position
		InventoryManager.cancel_item_drag()


func _try_move_to_inventory_slot(inventory_slot: InventoryItemSlotUI) -> void:
	var inventory_item = inventory_slot.get_item()
	var equipped_item = self.get_item() as EquipmentItem
	# Se tiver item no local do drop E for equipamento do mesmo tipo
	if inventory_item and inventory_item is EquipmentItem:
		var inventory_equipment = inventory_item as EquipmentItem
		if inventory_equipment.equipment_type == equipped_item.equipment_type:
			# Faz a troca: equipa o item do inventário e desequipa o atual
			var success = PlayerEquipments.swap_equipment(inventory_equipment)
			if success:
				# Atualiza este slot com o novo equipamento
				setup_equipment(inventory_equipment)
				InventoryManager.item_drag_ended.emit(true)
			else:
				global_position = original_position
				InventoryManager.cancel_item_drag()

		# Tipos diferentes - cancelar
		else:
			global_position = original_position
			InventoryManager.cancel_item_drag()

	else:
		# Slot vazio - apenas desequipa
		var success = PlayerEquipments.unequip(equipped_item, inventory_slot.slot_index)
		if success:
			self.setup_equipment(null)
			InventoryManager.item_drag_ended.emit(true)
		else:
			global_position = original_position
			InventoryManager.cancel_item_drag()
