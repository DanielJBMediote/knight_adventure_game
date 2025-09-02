class_name GemUpgradeUI
extends Control

@onready var req_content_ui_scene: PackedScene = preload("res://src/gameplay/mechanics/inventory/gem_upgrade_ui/requeriment_content_ui.tscn")

@onready var title: Label = $Panel/MarginContainer/Content/Title
@onready var subtitle: Label = $Panel/MarginContainer/Content/Subtitle
@onready var requeriment_label: Label = $Panel/MarginContainer/Content/RequerimentContainer/RequerimentLabel
@onready var requeriment_items: GridContainer = $Panel/MarginContainer/Content/RequerimentContainer/RequerimentItems


@onready var close: Button = $Panel/MarginContainer/Close
@onready var upgrade_button: Button = $Panel/MarginContainer/Content/UpgradeButton

@onready var prev_gem_preview: GemUpgradePreviewUI = $Panel/MarginContainer/Content/GemTextures/PrevGemPreview
@onready var next_gem_prview: GemUpgradePreviewUI = $Panel/MarginContainer/Content/GemTextures/NextGemPreview
# @onready var rarity_texture_prev: TextureRect = $Panel/RarityTexturePrev
# @onready var rarity_texture_next: TextureRect = $Panel/RarityTextureNext

@onready var item_price: ItemPriceUI = $Panel/MarginContainer/Content/ItemPrice

var current_gem: GemItem
var runes_in_inventory: Array[Item] = []
var gems_in_inventory: Array[Item] = []

func _ready() -> void:
	title.text = LocalizationManager.get_ui_text("gem_upgrade_ui_title")
	requeriment_label.text = LocalizationManager.get_ui_text("gem_upgrade_ui_requeriments_label")
	close.pressed.connect(_on_close_button_pressed)
	upgrade_button.text = LocalizationManager.get_ui_text("confirm")
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	upgrade_button.mouse_exited.connect(func(): upgrade_button.release_focus())

func setup(gem: GemItem) -> void:
	if gem and gem.can_upgrade_gem():
		current_gem = gem
		var next_gem = gem.get_preview_next_gem()
		
		# rarity_texture_prev.texture = ItemManager.get_bg_gradient_by_rarity(gem.item_rarity)
		# rarity_texture_next.texture = ItemManager.get_bg_gradient_by_rarity(next_gem.item_rarity)
		
		prev_gem_preview.setup(gem)
		next_gem_prview.setup(next_gem)

		var subtitle_text = LocalizationManager.get_ui_text("gem_upgrade_ui_subtitle")
		subtitle_text = LocalizationManager.format_text_with_params(subtitle_text, {
			"gem": gem.item_name,
			"next_gem": next_gem.item_name
		})
		
		subtitle.text = subtitle_text

		var rune = gem.get_required_preview_rune_for_upgrade()
		if rune:
			var rune_requeriment_ui: RequerimentContentUI = req_content_ui_scene.instantiate()
			runes_in_inventory = InventoryManager.find_many_items_by_id(rune.item_id)
			var amount_runes_in_inventory = 0
			for rune_item in runes_in_inventory:
				amount_runes_in_inventory += rune_item.current_stack
			
			requeriment_items.add_child(rune_requeriment_ui)
			rune_requeriment_ui.quantity_needed = gem.get_number_of_runes_to_upgrade()
			rune_requeriment_ui.quanity = amount_runes_in_inventory
			rune_requeriment_ui.setup(rune)
		
		# Find all gems of the same type EXCEPT the one we're upgrading
		gems_in_inventory = InventoryManager.find_many_items_by_id(gem.item_id)
		var amount_gems_in_inventory = 0
		for gem_item in gems_in_inventory:
			amount_gems_in_inventory += gem_item.current_stack
		
		var gem_requeriment_ui: RequerimentContentUI = req_content_ui_scene.instantiate()
		requeriment_items.add_child(gem_requeriment_ui)
		gem_requeriment_ui.quantity_needed = 1
		gem_requeriment_ui.quanity = max(amount_gems_in_inventory - 1, 0)
		gem_requeriment_ui.setup(gem)

		var coins = CurrencyManager.convert_value_to_coins(gem.price_to_upgrade)
		item_price.update_golds(coins.golds)
		item_price.update_silvers(coins.silvers, coins.golds > 0)
		item_price.update_bronzes(coins.bronzes, coins.silvers > 0)

		# Store the inventory items for the upgrade button
		# upgrade_button.pressed.connect(_on_upgrade_button_pressed.bind(runes_in_inventory, all_gems))

# func _on_upgrade_button_pressed(runes_in_inventory: Array[RuneItem], gems_in_inventory: Array[GemItem]) -> void:
func _on_upgrade_button_pressed() -> void:
	if current_gem:
		if current_gem.upgrade_gem(runes_in_inventory, gems_in_inventory):
			queue_free()

func _on_close_button_pressed() -> void:
	queue_free()
