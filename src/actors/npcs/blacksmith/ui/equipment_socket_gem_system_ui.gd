## Equipment Socket Gem System UI
class_name EquipmentSocketGemSystemUI
extends Control

signal system_closed

@onready var item_drag_display_scene: PackedScene = load("res://src/gameplay/mechanics/inventory/inventory_slots/inventory_item_dragging_ui.tscn")
@onready var esgs_gem_panel: ESGSGemPanel = $MarginContainer/HBoxContainer/ESGSGemPanel
@onready var esgs_inventory_panel: ESGSInventoryPanel = $MarginContainer/HBoxContainer/ESGSInventoryPanel
@onready var esgs_available_gem_panel: ESGSAvailableGemPanel = $MarginContainer/ESGSAvailableGemPanel

var item_drag_display: InventoryItemDragingUI


func _ready() -> void:
	esgs_available_gem_panel.hide()
	esgs_inventory_panel._update_inventory()
	InventoryManager.item_drag_started.connect(_on_item_drag_started)
	InventoryManager.item_drag_ended.connect(_on_item_drag_ended)
	esgs_gem_panel.available_gem_ui_oppened.connect(_show_avalable_gem_panel)
	esgs_available_gem_panel.gem_selected.connect(esgs_gem_panel.attach_gem_on_equipment)

func _on_item_drag_started(item: Item, _slot_index: int):
	item_drag_display = item_drag_display_scene.instantiate()
	add_child(item_drag_display)
	item_drag_display.global_position = get_global_mouse_position() - item_drag_display.size / 2
	item_drag_display.setup(item)


func _on_item_drag_ended(_success: bool):
	if item_drag_display:
		item_drag_display.queue_free()
		item_drag_display = null


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and InventoryManager.drag_item != null:
			var dragging_slot = _find_dragging_slot()
			if dragging_slot:
				dragging_slot.end_drag()

func _find_dragging_slot():
	var groups_to_check = [InventoryItemSlotUI.GROUP_NAME, ESGSEquipmentItemSlotUI.GROUP_NAME]

	for group in groups_to_check:
		for slot in get_tree().get_nodes_in_group(group):
			if slot.is_dragging != null and slot.is_dragging:
				return slot
	return null


func _show_avalable_gem_panel(equipment: EquipmentItem) -> void:
	esgs_available_gem_panel.show()
	esgs_available_gem_panel.update_available_gems(equipment)

# Lógica para fechar a UI adequadamente
func close_ui() -> void:
	if esgs_gem_panel.current_equipment:
		var equipment = esgs_gem_panel.current_equipment
		InventoryManager.add_item(equipment, equipment.slot_index_ref)
	hide()
	system_closed.emit()  # Emitir o sinal se necessário
