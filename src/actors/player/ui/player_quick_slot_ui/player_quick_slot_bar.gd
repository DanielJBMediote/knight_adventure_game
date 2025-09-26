class_name PlayerQuickSlotBar
extends Control

@onready var quick_slot_1: QuickSlot = $MarginContainer/HBoxContainer/QuickSlot1
@onready var quick_slot_2: QuickSlot = $MarginContainer/HBoxContainer/QuickSlot2
@onready var quick_slot_3: QuickSlot = $MarginContainer/HBoxContainer/QuickSlot3


func _ready() -> void:
	InventoryManager.quick_slot_updated.connect(_on_quick_slot_updated)

func _on_quick_slot_updated(slot_index: int, item: Item) -> void:
	match slot_index:
		1:
			quick_slot_1.item = item
			quick_slot_1._setup()
		2:
			quick_slot_2.item = item
			quick_slot_2._setup()
		3:
			quick_slot_3.item = item
			quick_slot_3._setup()
