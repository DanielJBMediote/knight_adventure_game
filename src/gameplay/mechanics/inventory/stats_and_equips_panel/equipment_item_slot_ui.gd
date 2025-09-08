class_name EquipmentItemSlotUI
extends BaseSlotUI

@onready var background_item: TextureRect = $BackgroundItem

@export var default_texture: Texture2D
@export var slot_type: EquipmentItem.TYPE


func _setup_specifics() -> void:
	add_to_group("equipment_slots")
	if default_texture:
		background_item.texture = default_texture
	setup_equipment(null)


func setup_equipment(new_equipment: EquipmentItem) -> void:
	super.setup_item(new_equipment)

	if new_equipment:
		item_texture.texture = new_equipment.item_texture
		background_item.visible = false
		item_info.visible = true
		update_equipment_level(new_equipment.item_level)
		super._set_item_rarity_texture(new_equipment.item_rarity)
		super._update_border_style(new_equipment.is_unique)
	else:
		item_texture.texture = null
		background_item.visible = true
		item_info.text = ""
		item_info.visible = false
		rarity_texture.texture = null
		super._update_border_style()


func update_equipment_level(level: int) -> void:
	item_info.text = str(level)
	var player_level = PlayerStats.level
	var difference = player_level - level

	if difference >= 20:
		item_info.add_theme_color_override("font_color", Color.RED)
	elif difference >= 5:
		item_info.add_theme_color_override("font_color", Color.YELLOW)
	elif difference == 0:
		item_info.add_theme_color_override("font_color", Color.GREEN)
	else:
		item_info.add_theme_color_override("font_color", Color.WHITE)


func _hide_item_visuals() -> void:
	rarity_texture.hide()
	item_texture.hide()
	item_info.hide()
	unique_border.hide()
	background_item.show()


func _show_item_visuals() -> void:
	if current_item:
		rarity_texture.show()
		item_texture.show()
		item_info.show()
		unique_border.visible = current_item.is_unique


func _try_move_item(target_slot: BaseSlotUI) -> void:
	if target_slot is InventoryItemSlotUI:
		var target_item = target_slot.current_item
		# Se tiver item no local do drop E for equipamento do mesmo tipo
		if target_item and target_item is EquipmentItem:
			var target_equipment = target_item as EquipmentItem
			if target_equipment.equipment_type == (current_item as EquipmentItem).equipment_type:
				# Faz a troca: equipa o item do inventário e desequipa o atual
				var success = PlayerEquipments.swap_equipment(target_equipment)
				if success:
					# Atualiza este slot com o novo equipamento
					setup_equipment(target_equipment)
					InventoryManager.item_drag_ended.emit(true)
				else:
					global_position = original_position
					InventoryManager.cancel_item_drag()
			else:
				# Tipos diferentes - apenas desequipa
				var success = PlayerEquipments.unequip(current_item as EquipmentItem)
				if success:
					setup_equipment(null)
					InventoryManager.item_drag_ended.emit(true)
				else:
					global_position = original_position
					InventoryManager.cancel_item_drag()
		else:
			# Slot vazio ou não é equipamento - apenas desequipa
			var success = PlayerEquipments.unequip(current_item as EquipmentItem)
			if success:
				setup_equipment(null)
				InventoryManager.item_drag_ended.emit(true)
			else:
				global_position = original_position
				InventoryManager.cancel_item_drag()
		InventoryManager.inventory_updated.emit()

	elif target_slot is EquipmentItemSlotUI:
		# Troca entre slots de equipamento - VERIFICA SE É DO MESMO TIPO
		var equipment_slot = target_slot as EquipmentItemSlotUI
		var equipment_item = current_item as EquipmentItem

		# Só permite trocar se for do mesmo tipo de equipamento
		if equipment_item.equipment_type == equipment_slot.slot_type:
			# Se o slot de destino já tem um item, faz a troca
			if equipment_slot.current_item is EquipmentItem:
				var target_equipment = equipment_slot.current_item as EquipmentItem

				# Desequipa o item do slot de destino primeiro
				if PlayerEquipments.unequip(target_equipment):
					# Equipa o item que estava sendo arrastado
					PlayerEquipments.equip(equipment_item)
					setup_equipment(null)  # Limpa este slot
					InventoryManager.item_drag_ended.emit(true)
				else:
					global_position = original_position
					InventoryManager.cancel_item_drag()
			else:
				# Slot de destino vazio - apenas equipa
				PlayerEquipments.equip(equipment_item)
				setup_equipment(null)  # Limpa este slot
				InventoryManager.item_drag_ended.emit(true)
		else:
			# Tipos diferentes - não permite a troca
			global_position = original_position
			InventoryManager.cancel_item_drag()

	else:
		global_position = original_position
		InventoryManager.cancel_item_drag()
