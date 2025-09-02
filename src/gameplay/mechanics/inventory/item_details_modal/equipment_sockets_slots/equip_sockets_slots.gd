class_name EquipmentSocketSlots
extends VBoxContainer

@onready var equip_socket_scene: PackedScene = preload("res://src/gameplay/mechanics/inventory/item_details_modal/equipment_sockets_slots/equip_gem_socket_slot.tscn")

@export var gems: Array[GemItem] = []

func setup():
	for gem in gems:
		var gem_slot: EquipGemSocketSlot = equip_socket_scene.instantiate()
		gem_slot.gem = gem
		add_child(gem_slot)
