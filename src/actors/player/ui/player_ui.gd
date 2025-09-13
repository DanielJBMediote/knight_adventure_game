class_name PlayerUI
extends CanvasLayer

@onready var inventory_ui: InventoryUI = $InventoryUI
@onready var player_stats_ui: PlayerStatsUI = $PlayerStatsUI
@onready var player_quick_slotbar: PlayerQuickSlotbarUI = $PlayerQuickSlotbar
@onready var interact_label: InteractLabel = $InteractLabel

var is_on_interaction := false
var npc_interaction_ui: NPCInteractionUI

func _ready() -> void:
	add_to_group("player_ui")
	InventoryManager.update_inventory_visible.connect(_on_show_inventory)
	PlayerEvents.interaction_showed.connect(interact_label._on_show)
	PlayerEvents.interaction_hidded.connect(interact_label._on_hide)
	_start_ui()

func _start_ui() -> void:
	inventory_ui.hide()
	player_quick_slotbar.show()
	player_stats_ui.show()

func start_interaction(node: NPCInteractionUI) -> void:
	npc_interaction_ui = node
	
	is_on_interaction = true
	inventory_ui.hide()
	player_quick_slotbar.hide()
	player_stats_ui.hide()
	interact_label.hide()
	add_child(npc_interaction_ui)
	
func end_interaction() -> void:
	is_on_interaction = false
	player_quick_slotbar.show()
	player_stats_ui.show()
	interact_label.show()
	
	if npc_interaction_ui:
		npc_interaction_ui.queue_free()

func _on_show_inventory(is_open: bool)-> void:
	if is_open:
		player_stats_ui.hide()
		player_quick_slotbar.hide()
	else:
		player_stats_ui.show()
		player_quick_slotbar.show()
