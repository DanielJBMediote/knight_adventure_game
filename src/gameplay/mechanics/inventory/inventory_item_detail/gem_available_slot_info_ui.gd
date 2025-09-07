class_name GemAvailableSlotInfoUI
extends VBoxContainer

@onready var main_label: Label = $MainLabel

@export var equip_slots: Array[EquipmentItem.TYPE]

func _ready():
	main_label.text = LocalizationManager.get_ui_text("gem_equip_slots") + ":"

func display_names() -> void:
	for slot in equip_slots:
		var slot_label = AttributeLabel.new()
		slot_label.custom_text = "- " + LocalizationManager.get_equipment_type_name(slot)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		add_child(slot_label)
