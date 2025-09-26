class_name PlayerUI
extends CanvasLayer

@onready var inventory_item_detail_scene: PackedScene = preload("res://src/gameplay/mechanics/inventory/inventory_item_detail/inventory_item_detail_ui.tscn")
@onready var inventory_ui_scene: PackedScene = preload("res://src/gameplay/mechanics/inventory/inventory_ui.tscn")

@onready var player_quick_slot_bar: PlayerQuickSlotBar = $PlayerQuickSlotBar
@onready var player_stats_ui: PlayerStatsUI = $PlayerStatsUI
@onready var interact_label: InteractLabel = $InteractLabel
@onready var game_saving_loading: GameSavingLoading = $GameSavingLoading

var is_on_interaction := false
var npc_interaction_ui: NPCInteractionUI
var inventory_ui: InventoryUI

func _ready() -> void:
	add_to_group("player_ui")
	ItemManager.selected_item_updated.connect(_show_item_detail_modal)
	PlayerEvents.interaction_showed.connect(interact_label._on_show)
	PlayerEvents.interaction_hided.connect(interact_label._on_hide)
	InventoryManager.inventory_opened.connect(_on_inventory_opened)
	GameManager.game_saved.connect(_on_game_saved)
	_start_ui()

func _start_ui() -> void:
	player_quick_slot_bar.show()
	player_stats_ui.show()

func start_interaction(node: NPCInteractionUI) -> void:
	npc_interaction_ui = node
	is_on_interaction = true
	player_quick_slot_bar.hide()
	player_stats_ui.hide()
	interact_label.hide()
	add_child(npc_interaction_ui)
	
func end_interaction() -> void:
	is_on_interaction = false
	player_quick_slot_bar.show()
	player_stats_ui.show()
	interact_label.show()
	
	if npc_interaction_ui:
		npc_interaction_ui.queue_free()

func _on_inventory_opened(is_open: bool) -> void:
	if is_on_interaction:
		return

	if is_open:
		player_stats_ui.hide()
		player_quick_slot_bar.hide()
		inventory_ui = inventory_ui_scene.instantiate()
		add_child(inventory_ui)
	else:
		player_stats_ui.show()
		player_quick_slot_bar.show()
		if inventory_ui:
			inventory_ui.queue_free()

func _show_item_detail_modal(item: Item) -> void:
	if item:
		var item_info_modal = inventory_item_detail_scene.instantiate() as InventoryItemDetailUI
		add_child(item_info_modal)

func _on_game_saved(saved: bool) -> void:
	if saved:
		game_saving_loading.show_animation(LocalizationManager.get_ui_text("saving"))
