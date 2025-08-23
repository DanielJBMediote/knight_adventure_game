class_name InventorySlotsPanel
extends Panel

@export var item_slot: PackedScene = preload("res://src/gameplay/mechanics/inventory/inventory_slots_panel/item_slot.tscn")

@onready var inventory_slots_grid: GridContainer = $MarginContainer/VBoxContainer/InventorySlotsGrid
@onready var organize_button_asc: Button = $MarginContainer/VBoxContainer/HBoxContainer/OrganizeButtonASC
@onready var organize_button_desc: Button = $MarginContainer/VBoxContainer/HBoxContainer/OrganizeButtonDESC
@onready var page_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/PageLabel

const MAX_SLOTS := 18 
static var slots: Array[InventoryItemSlot] = []

func _ready() -> void:
	for i in MAX_SLOTS:
		var slot: InventoryItemSlot = item_slot.instantiate()
		inventory_slots_grid.add_child(slot)
		slots.append(slot)

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
	var current_items = InventoryManager.get_current_page_items()
	for i in range(slots.size()):
		if i < current_items.size():
			slots[i].set_item(current_items[i])
		else:
			# Limpa o slot se não houver item nesta posição
			slots[i].set_item(null)

func _update_page_label():
	page_label.text = "%d/%d" % [InventoryManager.current_page + 1, InventoryManager.MAX_SLOTS / InventoryManager.SLOTS_PER_PAGE]
