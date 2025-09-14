class_name PlayerUI
extends CanvasLayer

@onready var invenory_item_detail_scene: PackedScene = preload("res://src/gameplay/mechanics/inventory/inventory_item_detail/inventory_item_detail_ui.tscn")
@onready var inventory_ui_scene: PackedScene = preload("res://src/gameplay/mechanics/inventory/inventory_ui.tscn")

@onready var player_stats_ui: PlayerStatsUI = $PlayerStatsUI
@onready var player_quick_slotbar: PlayerQuickSlotbarUI = $PlayerQuickSlotbar
@onready var interact_label: InteractLabel = $InteractLabel

var is_on_interaction := false
var npc_interaction_ui: NPCInteractionUI
var inventory_ui: InventoryUI

func _ready() -> void:
	add_to_group("player_ui")
	ItemManager.selected_item_updated.connect(_show_item_detail_modal)
	PlayerEvents.interaction_showed.connect(interact_label._on_show)
	PlayerEvents.interaction_hidded.connect(interact_label._on_hide)
	InventoryManager.inventory_oppened.connect(_on_show_inventory)
	_start_ui()

func _start_ui() -> void:
	player_quick_slotbar.show()
	player_stats_ui.show()

func start_interaction(node: NPCInteractionUI) -> void:
	npc_interaction_ui = node
	is_on_interaction = true
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

func _on_show_inventory(is_open: bool) -> void:
	if is_on_interaction:
		return

	if is_open:
		player_stats_ui.hide()
		player_quick_slotbar.hide()
		inventory_ui = inventory_ui_scene.instantiate()
		add_child(inventory_ui)
	else:
		player_stats_ui.show()
		player_quick_slotbar.show()
		if inventory_ui:
			inventory_ui.queue_free()

func _show_item_detail_modal(item: Item) -> void:
	if item:
		var item_info_modal = invenory_item_detail_scene.instantiate() as InventoryItemDetailUI
		add_child(item_info_modal)
		item_info_modal.setup(item)
