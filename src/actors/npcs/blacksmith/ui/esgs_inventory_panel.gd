class_name ESGSInventoryPanel
extends Panel


@onready var currency_info_ui: CurrencyInfoUI = $MarginContainer/MainContainer/Header/CurrencyInfoUI
@onready var inventory_slots: GridContainer = $MarginContainer/MainContainer/InventorySlots
@onready var page_label: Label = $MarginContainer/MainContainer/InventoryControls/PageLabel
@onready var prev_button: Button = $MarginContainer/MainContainer/InventoryControls/PrevButton
@onready var next_button: Button = $MarginContainer/MainContainer/InventoryControls/NextButton
@onready var inventory_controls: HBoxContainer = $MarginContainer/MainContainer/InventoryControls

const MAX_SLOTS := InventoryManager.SLOTS_PER_PAGE
var slots: Array[InventoryItemSlotUI] = []

var showing_inventory := true


func _ready() -> void:
	for child in inventory_slots.get_children():
		if child is InventoryItemSlotUI:
			slots.append(child)
	
	InventoryManager.inventory_updated.connect(_update_inventory)
	
	prev_button.pressed.connect(_on_prev_page_pressed)
	next_button.pressed.connect(_on_next_page_pressed)


func _update_inventory():
	var current_items = InventoryManager.get_current_page_items()
	var current_page = InventoryManager.current_page
	for i in range(slots.size()):
		slots[i].show()
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


func _on_prev_page_pressed():
	InventoryManager.change_page(-1)
	_update_page_label()
	update_inventory_actions_buttons()


func _on_next_page_pressed():
	InventoryManager.change_page(1)
	_update_page_label()
	update_inventory_actions_buttons()


func update_inventory_actions_buttons() -> void:
	prev_button.disabled = true if InventoryManager.current_page == 0 else false
	next_button.disabled = true if InventoryManager.current_page == 2 else false
