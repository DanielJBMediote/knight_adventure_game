class_name ESGSAvailableGemPanel
extends Control

@onready var item_scene = preload("res://src/actors/npcs/blacksmith/ui/esgs_avalable_gem_panel/esgs_available_gem_item.tscn")

signal gem_selected(gem: GemItem)

@onready var overlay: ColorRect = $Overlay
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var gem_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/GemList
@onready var close_button: Button = $Panel/MarginContainer/CloseButton

func _ready() -> void:
	close_button.pressed.connect(hide)
	title_label.text = LocalizationManager.get_ui_esgs_text("available_gems")

func update_available_gems(equipment: EquipmentItem) -> void:
	for child in gem_list.get_children():
		child.queue_free()
	
	var equip_type = equipment.equipment_type
	var all_gems = InventoryManager.get_items_by_subcategory(Item.SUBCATEGORY.GEM)
	var filtered_gems = all_gems.filter(func(gem): return _filter_by_corret_socket_type(equip_type, gem))
	
	for gem in filtered_gems:
		var new_gem_item: ESGSAvailableGemItem = item_scene.instantiate()
		new_gem_item.gem = gem
		gem_list.add_child(new_gem_item)
		new_gem_item.select_pressed.connect(_on_select_gem.bind(equipment, gem))

func _filter_by_corret_socket_type(equip_type: EquipmentItem.TYPE, gem: GemItem) -> bool:
	return equip_type in gem.available_equipments_type

func _on_select_gem(equipment: EquipmentItem, selected_gem: GemItem) -> void:
	if equipment.item_level < selected_gem.item_level:
		var alert = LocalizationManager.get_ui_alerts_text("equipment_lower_level")
		GameManager.show_instant_message(alert, InstantMessage.TYPE.WARNING)
	else:
		gem_selected.emit(selected_gem)
		hide()
