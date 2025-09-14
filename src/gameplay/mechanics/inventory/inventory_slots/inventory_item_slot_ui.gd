class_name InventoryItemSlotUI
extends BaseSlotUI

@onready var equip_comparator: TextureRect = $EquipComparator
@onready var locked_panel: Panel = $LockedPanel
@onready var level_label: DefaultLabel = $MarginContainer/DetailContainer/Footer/LevelLabel

const GROUP_NAME = "inventory_slot_group"
const ICON_UP = Rect2(282, 20, 13, 12)
const ICON_DOWN = Rect2(282, 32, 13, 12)

func _setup_specifics() -> void:
	add_to_group(GROUP_NAME)
	_update_lock_status()


func setup_item(new_item: Item) -> void:
	super.setup_item(new_item)
	equip_comparator.hide()

	if new_item != null:
		item_texture.texture = new_item.item_texture
		level_label.hide()
		if new_item.item_category == Item.CATEGORY.EQUIPMENTS:
			_updade_equipment_styles(new_item as EquipmentItem)
			_update_equipment_level()
	else:
		item_texture.texture = null
		level_label.hide()


func _update_lock_status() -> void:
	if slot_index != -1:
		is_locked = !InventoryManager.is_slot_unlocked(slot_index)
		locked_panel.visible = is_locked

		if is_locked:
			self.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			self.mouse_filter = Control.MOUSE_FILTER_PASS


func _updade_equipment_styles(new_item: EquipmentItem) -> void:
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

func _update_equipment_level() -> void:
	level_label.show()
	level_label.text = "Lv.%d" % current_item.item_level
	
	if PlayerStats.level < current_item.item_level:
		level_label.add_theme_color_override("font_color", Color.RED)
	else:
		level_label.add_theme_color_override("font_color", Color.WHITE)

func _hide_item_visuals() -> void:
	super._hide_item_visuals()
	equip_comparator.hide()
	level_label.hide()


func _show_item_visuals() -> void:
	super._show_item_visuals()
	if current_item.item_category == Item.CATEGORY.EQUIPMENTS:
		level_label.show()
		var equipment_item = current_item as EquipmentItem
		if PlayerEquipments.get_equipped_item_type(equipment_item.equipment_type):
			equip_comparator.show()


func _try_move_item(target_slot: BaseSlotUI) -> void:
	if target_slot.is_in_group(InventoryItemSlotUI.GROUP_NAME):
		InventoryManager.swap_items(original_slot_index, target_slot.slot_index)
	elif target_slot.is_in_group(EquipmentItemSlotUI.GROUP_NAME):
		_try_move_to_equippment_slot(target_slot)
	elif target_slot.is_in_group(ESGSEquipmentItemSlotUI.GROUP_NAME):
		_try_move_to_esgs_equipment_slot(target_slot)
	else:
		global_position = original_position
		InventoryManager.cancel_item_drag()


func _try_move_to_esgs_equipment_slot(esgs_equipment_slot: ESGSEquipmentItemSlotUI) -> void:
	var inventory_item = current_item
	# Verificar se o item do inventário é um Equipamento
	if inventory_item is EquipmentItem:
		if inventory_item.item_rarity > Item.RARITY.COMMON:
			var target_item = esgs_equipment_slot.current_item
			var to_socket_slot = inventory_item.clone()
			# Verificar se no TargetSlot já tem um Equipamento
			if target_item != null:
				# Adicionaro equipamento de volta ao inventário
				InventoryManager.remove_item(inventory_item)
				InventoryManager.add_item(target_item, to_socket_slot.slot_index_ref)
			else:
				InventoryManager.remove_item(inventory_item)
			esgs_equipment_slot.setup_equipment(to_socket_slot)
			InventoryManager.item_drag_ended.emit(true)
		else:
			var warning = LocalizationManager.get_ui_esgs_text("sockets_unavailable")
			GameEvents.show_instant_message(warning, InstantMessage.TYPE.WARNING)
			global_position = original_position
			InventoryManager.cancel_item_drag()
	else:
		var alert_message = LocalizationManager.get_ui_esgs_text("incompatible_type")
		var item_a_str = Item.get_category_text(inventory_item.item_category)
		var params = {"a": item_a_str}
		alert_message = LocalizationManager.format_text_with_params(alert_message, params)
		GameEvents.show_instant_message(alert_message, InstantMessage.TYPE.WARNING)

		global_position = original_position
		InventoryManager.cancel_item_drag()


func _try_move_to_equippment_slot(equipment_slot: EquipmentItemSlotUI) -> void:
	# Se o item movido é um Equipamento
	if self.get_item() is EquipmentItem:
		var inventory_item = self.get_item() as EquipmentItem
		# Verifica se o tipo do equipamento corresponde ao slot
		if inventory_item.equipment_type == equipment_slot.slot_type:
			# Se o slot de destino já tem um item, faz a troca
			if equipment_slot.get_item() and equipment_slot.get_item() is EquipmentItem:
				var success = PlayerEquipments.swap_equipment(inventory_item)
				if success:
					InventoryManager.item_drag_ended.emit(true)
					equipment_slot.setup_equipment(inventory_item)
				else:
					global_position = original_position
					InventoryManager.cancel_item_drag()
			else:
				# Slot de equipamento está vazio - equipar
				if PlayerEquipments.equip(inventory_item):
					InventoryManager.item_drag_ended.emit(true)
					equipment_slot.setup_equipment(inventory_item)
				else:
					global_position = original_position
					InventoryManager.cancel_item_drag()
		# Se for equipamento, porém nao corresponder com o tipo de slot, cancelar
		else:
			global_position = original_position
			InventoryManager.cancel_item_drag()
	# Se não for equipamento, cancelar
	else:
		global_position = original_position
		InventoryManager.cancel_item_drag()
