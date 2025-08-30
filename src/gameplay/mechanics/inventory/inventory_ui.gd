class_name InventoryUI
extends Control

@onready var stats_and_equips_panel: StatsAndEquipsPanelUI = $MarginContainer/VBoxContainer/Panel/MarginContainer/MainConteiner/InventoryContainer/StatsAndEquipsPanel
@onready var inventory_slots_panel: InventorySlotsPanel = $MarginContainer/VBoxContainer/Panel/MarginContainer/MainConteiner/InventoryContainer/InventorySlotsPanel

@onready var close_inventory_button: Button = $MarginContainer/VBoxContainer/CloseInventoryButton

@onready var prev_button: Button = $MarginContainer/VBoxContainer/Panel/MarginContainer/MainConteiner/InventoryHeader/InventoryControls/PrevButton
@onready var next_button: Button = $MarginContainer/VBoxContainer/Panel/MarginContainer/MainConteiner/InventoryHeader/InventoryControls/NextButton

func _init() -> void:
	pass

func _ready() -> void:
	inventory_slots_panel._update_inventory()
	update_inventory_actions_buttons()
	
	InventoryManager.update_inventory_visible.connect(_on_inventory_open_close)
	close_inventory_button.pressed.connect(_on_close_inventory_button_pressed)
	prev_button.pressed.connect(_on_prev_page_pressed)
	next_button.pressed.connect(_on_next_page_pressed)


func _on_prev_page_pressed():
	InventoryManager.change_page(-1)
	update_inventory_actions_buttons()

func _on_next_page_pressed():
	InventoryManager.change_page(1)
	update_inventory_actions_buttons()

func update_inventory_actions_buttons() -> void:
	prev_button.disabled = true if InventoryManager.current_page == 0 else false
	next_button.disabled = true if InventoryManager.current_page == 2 else false

func _on_close_inventory_button_pressed():
	self.hide()
	InventoryManager.is_open = false
	InventoryManager.update_inventory_visible.emit(false)

func _on_inventory_open_close(is_open: bool) -> void:
	if is_open:
		self.show()
		InventoryManager.inventory_updated.emit()
	else:
		self.hide()
		
