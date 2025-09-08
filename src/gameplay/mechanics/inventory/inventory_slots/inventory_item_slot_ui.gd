class_name InventoryItemSlotUI
extends BaseSlotUI

@onready var equip_comparator: TextureRect = $EquipComparator
@onready var locked_panel: Panel = $LockedPanel

const ICON_UP = Rect2(282, 20, 13, 12)
const ICON_DOWN = Rect2(282, 32, 13, 12)


func _setup_specifics() -> void:
	add_to_group("inventory_slots")
	update_lock_status()


func setup_item(new_item: Item) -> void:
	super.setup_item(new_item)
	equip_comparator.hide()

	if new_item != null:
		item_info.text = str(new_item.current_stack) if new_item.stackable else ""
		item_texture.texture = new_item.item_texture
		item_info.visible = new_item.stackable
		if new_item.item_category == Item.CATEGORY.EQUIPMENTS:
			updade_equipment_styles(new_item as EquipmentItem)
		super._set_item_rarity_texture(new_item.item_rarity)
		super._update_border_style(new_item.is_unique)
	else:
		item_info.text = ""
		item_texture.texture = null
		item_info.visible = false
		rarity_texture.texture = null
		super._update_border_style()

	update_lock_status()


func update_lock_status() -> void:
	if slot_index != -1:
		is_locked = !InventoryManager.is_slot_unlocked(slot_index)
		locked_panel.visible = is_locked

		if is_locked:
			self.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			self.mouse_filter = Control.MOUSE_FILTER_PASS


func updade_equipment_styles(new_item: EquipmentItem) -> void:
	var equipped = PlayerEquipments.get_equipped_item_type(new_item.equipment_type)
	if not equipped:
		equip_comparator.hide()
		return

	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = preload("res://assets/ui/buttons.png")

	if equipped.equipment_power > new_item.equipment_power:
		atlas_texture.region = ICON_DOWN
		equip_comparator.modulate = Color.RED
	else:
		atlas_texture.region = ICON_UP
		equip_comparator.modulate = Color.GREEN

	equip_comparator.texture = atlas_texture
	equip_comparator.show()


func _hide_item_visuals() -> void:
	equip_comparator.hide()
	rarity_texture.hide()
	item_texture.hide()
	item_info.hide()
	unique_border.hide()


func _show_item_visuals() -> void:
	if current_item:
		rarity_texture.show()
		item_texture.show()
		item_info.show()
		unique_border.visible = current_item.is_unique
		if (
			current_item.item_category == Item.CATEGORY.EQUIPMENTS
			and (PlayerEquipments.get_equipped_item_type(
				(current_item as EquipmentItem).equipment_type
			))
		):
			equip_comparator.show()


func _try_move_item(target_slot: BaseSlotUI) -> void:
	if target_slot is InventoryItemSlotUI:
		# Move entre slots de inventário
		InventoryManager.swap_items(original_slot_index, target_slot.slot_index)

	elif target_slot is EquipmentItemSlotUI:
		# Tenta equipar o item
		var equipment_slot = target_slot as EquipmentItemSlotUI
		if current_item is EquipmentItem:
			var equipment_item = current_item as EquipmentItem

			# Verifica se o tipo do equipamento corresponde ao slot
			if equipment_item.equipment_type == equipment_slot.slot_type:
				# Se o slot de destino já tem um item, faz a troca
				if equipment_slot.current_item is EquipmentItem:
					var target_equipment = equipment_slot.current_item as EquipmentItem

					# Desequipa o item do slot de destino
					if PlayerEquipments.unequip(target_equipment):
						# Equipa o novo item
						PlayerEquipments.equip(equipment_item)
						InventoryManager.item_drag_ended.emit(true)
					else:
						global_position = original_position
						InventoryManager.cancel_item_drag()
				else:
					# Slot vazio - apenas equipa
					PlayerEquipments.equip(equipment_item)
					InventoryManager.item_drag_ended.emit(true)
			else:
				# Tipo incompatível - cancela
				global_position = original_position
				InventoryManager.cancel_item_drag()

	else:
		global_position = original_position
		InventoryManager.cancel_item_drag()
