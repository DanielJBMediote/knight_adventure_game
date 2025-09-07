class_name EquipmentGemSocketSlots
extends VBoxContainer

@onready var equip_gem_socket_slot_ui_scene: PackedScene = preload("res://src/gameplay/mechanics/inventory/inventory_item_detail/equipment_sockets_slots/equip_gem_socket_slot_ui.tscn")

@export var gems: Array[GemItem] = []

func setup():
	for gem in gems:
		var gem_slot: EquipGemSocketSlotUI = equip_gem_socket_slot_ui_scene.instantiate()
		gem_slot.gem = gem
		add_child(gem_slot)
