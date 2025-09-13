class_name ESGSGemPanel
extends Panel

signal available_gem_ui_oppened(equipment: EquipmentItem)

@onready var esgs_gem_socket_ui_scene = preload("res://src/actors/npcs/blacksmith/ui/esgs_gem_socket_ui.tscn")

@onready var title: Label = $MarginContainer/Container/Title
@onready var sockets_list: VBoxContainer = $MarginContainer/Container/SocketsList
@onready var esgs_equipment_slot_ui: ESGSEquipmentItemSlotUI = $MarginContainer/Container/ESGSEquipmentSlotUI

var current_equipment: EquipmentItem = null
var current_socket_managing = -1

func _ready() -> void:
	_update_sockets_display()
	title.text = LocalizationManager.get_ui_text("gem_socket_system_ui.desc")
	esgs_equipment_slot_ui.equipment_updated.connect(_on_selected_equipment_updated)
	PlayerEquipments.equipment_updated.connect(_on_equip_item_updated)

func _on_equip_item_updated(_slot_type: EquipmentItem.TYPE, equipment: EquipmentItem) -> void:
	if equipment == current_equipment:
		esgs_equipment_slot_ui.setup_equipment(null)

func _on_selected_equipment_updated(equipment: EquipmentItem) -> void:
	current_equipment = equipment
	_update_sockets_display()


func _update_sockets_display() -> void:
	# Limpar sockets existentes
	for child in sockets_list.get_children():
		child.queue_free()

	if not current_equipment:
		return

	var available_sockets = current_equipment.available_sockets
	var attached_gems = current_equipment.attached_gems

	for socket_index in range(available_sockets):
		var esgs_gem_socket_ui: ESGSGemSocketUI = esgs_gem_socket_ui_scene.instantiate()
		var gem = attached_gems.get(socket_index, null)
		sockets_list.add_child(esgs_gem_socket_ui)
		esgs_gem_socket_ui.update_gem(gem)

		esgs_gem_socket_ui.socket_button.pressed.connect(_on_socket_button_pressed.bind(socket_index))


func _on_socket_button_pressed(socket_index: int) -> void:
	if not current_equipment:
		return
	current_socket_managing = socket_index
	var gem = current_equipment.attached_gems.get(socket_index)
	if gem:
		if EquipmentSocketManager.remove_gem_from_socket(current_equipment, socket_index):
			_update_sockets_display()
	else:
		available_gem_ui_oppened.emit(current_equipment)

func attach_gem_on_equipment(new_gem: GemItem) -> void:
	EquipmentSocketManager.add_gem_to_socket(current_equipment, new_gem, current_socket_managing)
	_update_sockets_display()
