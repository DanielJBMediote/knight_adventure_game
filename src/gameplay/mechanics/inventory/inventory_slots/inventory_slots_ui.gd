class_name InventorySlotsUI
extends Panel

# @export var inventory_item_slot_ui_scene: PackedScene = preload("res://src/gameplay/mechanics/inventory/inventory_slots/inventory_item_slot_ui.tscn")

@onready var inventory_slots_grid: GridContainer = $MarginContainer/VBoxContainer/InventorySlotsGrid
@onready var organize_button_asc: Button = $MarginContainer/VBoxContainer/HBoxContainer/OrganizeButtonASC
@onready var organize_button_desc: Button = $MarginContainer/VBoxContainer/HBoxContainer/OrganizeButtonDESC
@onready var page_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/PageLabel

const MAX_SLOTS := InventoryManager.SLOTS_PER_PAGE
static var slots: Array[InventoryItemSlotUI] = []

func _ready() -> void:
	for child in inventory_slots_grid.get_children():
		if child is InventoryItemSlotUI:
			slots.append(child)
	
	# for i in MAX_SLOTS:
	# 	var slot: InventoryItemSlotUI = inventory_item_slot_ui_scene.instantiate()
	# 	inventory_slots_grid.add_child(slot)
	# 	slot.name = str("InventoryItemSlotUI", i)
	# 	slots.append(slot)
	
	InventoryManager.inventory_updated.connect(_update_inventory)
	InventoryManager.page_changed.connect(_update_page_label)
	
	organize_button_asc.pressed.connect(_on_organize_asc)
	organize_button_desc.pressed.connect(_on_organize_desc)

# Novas funções para conectar os botões
func _on_organize_asc() -> void:
	InventoryManager.sort_inventory("ASC")

func _on_organize_desc() -> void:
	InventoryManager.sort_inventory("DESC")

# Toda vez que algum item for atualizado no InventoryManger, 
# o iventário será atualizado.
func _update_inventory():
	var current_page = InventoryManager.current_page
	var current_items = InventoryManager.get_current_page_items()
	for i in range(slots.size()):
		slots[i].slot_index = i + (current_page * MAX_SLOTS)
		if i < current_items.size():
			slots[i].setup_item(current_items[i])
		else:
			# Limpa o slot se não houver item nesta posição
			slots[i].setup_item(null)

func _update_page_label():
	var current_page = InventoryManager.current_page + 1
	var slots_per_page = InventoryManager.SLOTS_PER_PAGE
	var total_pages = int(InventoryManager.MAX_SLOTS / float(slots_per_page))
	page_label.text = "%d of %d" % [current_page, total_pages]
