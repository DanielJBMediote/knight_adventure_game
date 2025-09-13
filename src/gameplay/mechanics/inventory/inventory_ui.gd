class_name InventoryUI
extends Control

@onready var invenory_item_detail_scene: PackedScene = preload("res://src/gameplay/mechanics/inventory/inventory_item_detail/inventory_item_detail_ui.tscn")
@onready var item_drag_display_scene: PackedScene = preload("res://src/gameplay/mechanics/inventory/inventory_slots/inventory_item_dragging_ui.tscn")

@onready var inventory_slots_panel: InventorySlotsUI = $MarginContainer/VBoxContainer/Panel/MarginContainer/MainConteiner/InventoryContainer/InventorySlotsUI
@onready var stats_and_equips_ui: StatsAndEquipsUI = $MarginContainer/VBoxContainer/Panel/MarginContainer/MainConteiner/InventoryContainer/StatsAndEquipsUI

@onready var close_inventory_button: Button = $MarginContainer/VBoxContainer/CloseInventoryButton

@onready var prev_button: Button = $MarginContainer/VBoxContainer/Panel/MarginContainer/MainConteiner/InventoryHeader/InventoryControls/PrevButton
@onready var next_button: Button = $MarginContainer/VBoxContainer/Panel/MarginContainer/MainConteiner/InventoryHeader/InventoryControls/NextButton

var item_drag_display: InventoryItemDragingUI


func _ready() -> void:
	inventory_slots_panel._update_inventory()
	update_inventory_actions_buttons()

	ItemManager.selected_item_updated.connect(_show_item_detail_modal)
	PlayerEquipments.equipment_updated.connect(_on_equipment_updated)

	InventoryManager.update_inventory_visible.connect(_on_inventory_open_close)
	InventoryManager.item_drag_started.connect(_on_item_drag_started)
	InventoryManager.item_drag_ended.connect(_on_item_drag_ended)

	close_inventory_button.pressed.connect(_on_close_inventory_button_pressed)
	prev_button.pressed.connect(_on_prev_page_pressed)
	next_button.pressed.connect(_on_next_page_pressed)


func _on_item_drag_started(item: Item, _slot_index: int):
	item_drag_display = item_drag_display_scene.instantiate()
	add_child(item_drag_display)
	item_drag_display.global_position = get_global_mouse_position() - item_drag_display.size / 2
	item_drag_display.setup(item)


func _on_item_drag_ended(_success: bool):
	if item_drag_display:
		item_drag_display.queue_free()
		item_drag_display = null


func _on_equipment_updated(slot_type: EquipmentItem.TYPE, equipment: EquipmentItem):
	# Encontra o slot correspondente e atualiza
	for slot in get_tree().get_nodes_in_group("equipment_slots"):
		if slot is EquipmentItemSlotUI and slot.slot_type == slot_type:
			slot.setup_equipment(equipment)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and InventoryManager.drag_item != null:
			var dragging_slot = _find_dragging_slot()
			if dragging_slot:
				dragging_slot.end_drag()


func _find_dragging_slot():
	var groups_to_check = [InventoryItemSlotUI.GROUP_NAME, EquipmentItemSlotUI.GROUP_NAME]

	for group in groups_to_check:
		for slot in get_tree().get_nodes_in_group(group):
			if slot.is_dragging != null and slot.is_dragging:
				return slot
	return null


func _show_item_detail_modal(item: Item) -> void:
	if item:
		var item_info_modal = invenory_item_detail_scene.instantiate() as InventoryItemDetailUI
		GameEvents.get_player_ui().add_child(item_info_modal)
		item_info_modal.setup(item)


func _on_prev_page_pressed():
	InventoryManager.change_page(-1)
	update_inventory_actions_buttons()


func _on_next_page_pressed():
	InventoryManager.change_page(1)
	update_inventory_actions_buttons()


func update_inventory_actions_buttons() -> void:
	prev_button.disabled = true if InventoryManager.current_page == 0 else false
	next_button.disabled = true if InventoryManager.current_page == 2 else false


func _on_close_inventory_button_pressed():
	self.hide()
	InventoryManager.is_open = false
	InventoryManager.update_inventory_visible.emit(false)


func _on_inventory_open_close(is_open: bool) -> void:
	if is_open:
		self.show()
		InventoryManager.inventory_updated.emit()
	else:
		self.hide()
