class_name EquipmentItemSlotUI
extends BaseSlotUI

signal equipment_updated(new_equipment: EquipmentItem)

@onready var background_item: TextureRect = $BackgroundItem
@onready var item_level: DefaultLabel = $MarginContainer/MarginContainer/Footer/Level

const GROUP_NAME = "equipment_slot_group"
@export var default_texture: Texture2D
@export var slot_type: EquipmentItem.TYPE

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
	background_item.show()


func _show_item_visuals() -> void:
	super._show_item_visuals()
	item_level.show()


func _try_move_item(target_slot: BaseSlotUI) -> void:
	if target_slot.is_in_group(InventoryItemSlotUI.GROUP_NAME):
		var inventory_item = target_slot.current_item
		# Se tiver item no local do drop E for equipamento do mesmo tipo
		if inventory_item and inventory_item is EquipmentItem:
			var inventory_equipment = inventory_item as EquipmentItem
			if inventory_equipment.equipment_type == (current_item as EquipmentItem).equipment_type:
				# Faz a troca: equipa o item do inventário e desequipa o atual
				var success = PlayerEquipments.swap_equipment(inventory_equipment)
				if success:
					# Atualiza este slot com o novo equipamento
					setup_equipment(inventory_equipment)
					InventoryManager.item_drag_ended.emit(true)
				else:
					global_position = original_position
					InventoryManager.cancel_item_drag()

			# Tipos diferentes - apenas desequipa
			else:
				# Tipos diferentes - apenas desequipa
				var success = PlayerEquipments.unequip(current_item as EquipmentItem, target_slot.slot_index)
				if success:
					setup_equipment(null)
					InventoryManager.item_drag_ended.emit(true)
				else:
					global_position = original_position
					InventoryManager.cancel_item_drag()

			# Slot vazio ou não é equipamento - apenas desequipa
		else:
			# Slot vazio ou não é equipamento - apenas desequipa
			var success = PlayerEquipments.unequip(current_item as EquipmentItem, target_slot.slot_index)
			if success:
				setup_equipment(null)
				InventoryManager.item_drag_ended.emit(true)
			else:
				global_position = original_position
				InventoryManager.cancel_item_drag()

	# Troca entre slots de equipamento
	# Não existe, por enquando, talvez quando tiver 2 slots de anel... quem sabe
	elif target_slot.is_in_group(EquipmentItemSlotUI.GROUP_NAME):
		#var equipment_slot = target_slot as EquipmentItemSlotUI
		#var equipment_item = current_item as EquipmentItem
		## Só permite trocar se for do mesmo tipo de equipamento
		#if equipment_item.equipment_type == equipment_slot.slot_type:
			## Se o slot de destino já tem um item, faz a troca
			#if equipment_slot.current_item is EquipmentItem:
				#var target_equipment = equipment_slot.current_item as EquipmentItem
#
				## Desequipa o item do slot de destino primeiro
				#if PlayerEquipments.unequip(target_equipment):
					## Equipa o item que estava sendo arrastado
					#PlayerEquipments.equip(equipment_item)
					#setup_equipment(null)  # Limpa este slot
					#InventoryManager.item_drag_ended.emit(true)
				#else:
					#global_position = original_position
					#InventoryManager.cancel_item_drag()
#
				## Slot de destino vazio - apenas equipa
			#else:
				## Slot de destino vazio - apenas equipa
				#PlayerEquipments.equip(equipment_item)
				#setup_equipment(null)  # Limpa este slot
				#InventoryManager.item_drag_ended.emit(true)
#
			## Tipos diferentes - não permite a troca
		#else:
			# Tipos diferentes - não permite a troca
			global_position = original_position
			InventoryManager.cancel_item_drag()
	else:
		global_position = original_position
		InventoryManager.cancel_item_drag()
