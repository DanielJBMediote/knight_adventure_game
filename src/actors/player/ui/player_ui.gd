extends CanvasLayer

@onready var player_stats_ui: PlayerStatsUI = $PlayerStatsUI
@onready var player_inventory: InventoryUI = $PlayerInventory


func _ready() -> void:
	player_inventory.hide()
	InventoryManager.close_open_inventory.connect(_on_show_inventory)
	
func _on_show_inventory(is_open: bool)-> void:
	if is_open:
		player_stats_ui.hide()
	else:
		player_stats_ui.show()
