class_name InventoryUI
extends Control

@export var item_slot: PackedScene = preload("res://src/gameplay/mechanics/inventory/item_slot.tscn")
@onready var inventory_slots_grid: GridContainer = $MarginContainer/VBoxContainer/Panel/MarginContainer/MainConteiner/InventoryContainer/InventorySlotsPanel/MarginContainer/VBoxContainer/InventorySlotsGrid
@onready var animated_sprite_2d: AnimatedSprite2D = $MarginContainer/VBoxContainer/Panel/MarginContainer/MainConteiner/InventoryContainer/StatsAndEquipsPanel/MarginContainer/AnimatedSprite2D
@onready var page_label: Label = $MarginContainer/VBoxContainer/Panel/MarginContainer/MainConteiner/InventoryContainer/InventorySlotsPanel/MarginContainer/VBoxContainer/HBoxContainer/PageLabel

@onready var close_inventory_button: Button = $MarginContainer/VBoxContainer/CloseInventoryButton
@onready var prev_button: Button = $MarginContainer/VBoxContainer/Panel/MarginContainer/MainConteiner/InventoryHeader/InventoryControls/PrevButton
@onready var next_button: Button = $MarginContainer/VBoxContainer/Panel/MarginContainer/MainConteiner/InventoryHeader/InventoryControls/NextButton

static var slots: Array[InventoryItemSlot] = []

func _ready() -> void:
	animated_sprite_2d.play("default")
	update_inventory_actions_buttons()
	# Preencher com 18 slots
	for i in 18:
		var slot: InventoryItemSlot = item_slot.instantiate()
		inventory_slots_grid.add_child(slot)
		slots.append(slot)
	
	InventoryManager.inventory_updated.connect(update_inventory)
	
	InventoryManager.close_open_inventory.connect(_on_inventory_open_close)
	close_inventory_button.pressed.connect(_on_close_inventory_button_pressed)
	prev_button.pressed.connect(_on_prev_page_pressed)
	next_button.pressed.connect(_on_next_page_pressed)

# Toda vez que algum item for atualizado no InventoryManger, 
# o iventário será atualizado.
func update_inventory():
	var current_items = InventoryManager.get_current_page_items()
	for i in range(slots.size()):
		if i < current_items.size():
			slots[i].set_item(current_items[i])
		else:
			# Limpa o slot se não houver item nesta posição
			slots[i].set_item(null)

func _on_prev_page_pressed():
	InventoryManager.change_page(-1)
	update_page_label()
	update_inventory_actions_buttons()

func _on_next_page_pressed():
	InventoryManager.change_page(1)
	update_page_label()
	update_inventory_actions_buttons()

func update_inventory_actions_buttons() -> void:
	prev_button.disabled = true if InventoryManager.current_page == 0 else false
	next_button.disabled = true if InventoryManager.current_page == 2 else false

func update_page_label():
	page_label.text = "%d/%d" % [InventoryManager.current_page + 1, InventoryManager.MAX_SLOTS / InventoryManager.SLOTS_PER_PAGE]

func _on_close_inventory_button_pressed():
	self.hide()
	InventoryManager.is_open = false
	InventoryManager.close_open_inventory.emit(false)

func _on_inventory_open_close(is_open: bool) -> void:
	if is_open:
		self.show()
		update_inventory()
	else:
		self.hide()
