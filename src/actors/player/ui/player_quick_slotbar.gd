class_name PlayerQuickSlotbarUI
extends Control

@onready var quick_slot_scene: PackedScene = preload("res://src/actors/player/ui/quick_slot.tscn")
@onready var slots_control: Control = $MarginContainer/SlotsControl

const SLOT_POSITIONS: Array[Vector2] = [
	Vector2(124, 40),
	Vector2(32, 96),
	Vector2(216, 94),
	Vector2(124, 160),
]

func _ready() -> void:
	for key in 4:
		var quick_slot: QuickSlot = quick_slot_scene.instantiate()
		quick_slot.position = SLOT_POSITIONS[key]
		quick_slot.set_slot_key(key)
		slots_control.add_child(quick_slot)
	
	#InventoryManager.attach_item_to_quick_slot.connect(_on_item_attach_to_quick_slot)

func _on_item_attach_to_quick_slot(slotN: int, item: Item) -> void:
	
	pass
