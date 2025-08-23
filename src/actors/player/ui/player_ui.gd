extends CanvasLayer

@onready var player_stats_ui: PlayerStatsUI = $PlayerStatsUI
@onready var player_inventory: InventoryUI = $PlayerInventory
@onready var player_quick_slotbar: PlayerQuickSlotbarUI = $PlayerQuickSlotbar

func _ready() -> void:
	player_inventory.hide()
	InventoryManager.update_inventory_visible.connect(_on_show_inventory)
	
func _on_show_inventory(is_open: bool)-> void:
	if is_open:
		player_stats_ui.hide()
		player_quick_slotbar.hide()
	else:
		player_stats_ui.show()
		player_quick_slotbar.show()
