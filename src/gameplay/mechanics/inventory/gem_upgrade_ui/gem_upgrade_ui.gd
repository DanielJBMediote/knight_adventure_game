class_name GemUpgradeUI
extends Control

@onready var req_content_ui_scene: PackedScene = preload("res://src/gameplay/mechanics/inventory/gem_upgrade_ui/requirement_content_ui.tscn")

@onready var title: Label = $Panel/MarginContainer/Content/Title
@onready var subtitle: Label = $Panel/MarginContainer/Content/Subtitle
@onready var requirement_label: Label = $Panel/MarginContainer/Content/RequirementContainer/RequirementLabel
@onready var requirement_items: GridContainer = $Panel/MarginContainer/Content/RequirementContainer/RequirementItems

@onready var close: Button = $Panel/MarginContainer/Close
@onready var upgrade_button: Button = $Panel/MarginContainer/Content/UpgradeButton

@onready var prev_gem_preview: GemUpgradePreviewUI = $Panel/MarginContainer/Content/GemTextures/PrevGemPreview
@onready var next_gem_preview: GemUpgradePreviewUI = $Panel/MarginContainer/Content/GemTextures/NextGemPreview
# @onready var rarity_texture_prev: TextureRect = $Panel/RarityTexturePrev
# @onready var rarity_texture_next: TextureRect = $Panel/RarityTextureNext

@onready var quantity_label: Label = $Panel/MarginContainer/Content/QuantityContainer/QuantityLabel
@onready var quantity_value: DefaultLabel = $Panel/MarginContainer/Content/QuantityContainer/Quantity
@onready var remove_button: Button = $Panel/MarginContainer/Content/QuantityContainer/RemoveButton
@onready var add_button: Button = $Panel/MarginContainer/Content/QuantityContainer/AddButton

@onready var item_price: ItemPriceUI = $Panel/MarginContainer/Content/ItemPrice

var current_gem: GemItem
var runes_in_inventory: Array[Item] = []
var gems_in_inventory: Array[Item] = []
var amount_gem_to_upgrade: int = 1


func _ready() -> void:
	title.text = LocalizationManager.get_ui_text("gem_upgrade_ui.title")
	requirement_label.text = LocalizationManager.get_ui_text("gem_upgrade_ui.requirements_label")
	close.pressed.connect(_on_close_button_pressed)
	upgrade_button.text = LocalizationManager.get_ui_text("confirm")
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	upgrade_button.mouse_exited.connect(func(): upgrade_button.release_focus())
	add_button.pressed.connect(_on_update_quantity_gem.bind(1))
	remove_button.pressed.connect(_on_update_quantity_gem.bind(-1))


func setup(gem: GemItem) -> void:
	if gem and gem.can_upgrade_gem():
		current_gem = gem
		var next_gem = gem.get_preview_next_gem()

		# rarity_texture_prev.texture = ItemManager.get_bg_gradient_by_rarity(gem.item_rarity)
		# rarity_texture_next.texture = ItemManager.get_bg_gradient_by_rarity(next_gem.item_rarity)

		prev_gem_preview.setup(gem)
		next_gem_preview.setup(next_gem)

		var subtitle_text = LocalizationManager.get_ui_text("gem_upgrade_ui.subtitle")
		subtitle_text = LocalizationManager.format_text_with_params(
			subtitle_text, {"gem": gem.item_name, "next_gem": next_gem.item_name}
		)

		subtitle.text = subtitle_text

		_update_requirements()


func _update_requirements() -> void:
	for child in requirement_items.get_children():
		child.queue_free()

		# Find all gems of the same type EXCEPT the one we're upgrading
	quantity_value.text = str(amount_gem_to_upgrade)

	var rune = current_gem.get_required_preview_rune_for_upgrade()
	if rune:
		var rune_requirement_ui: RequirementContentUI = req_content_ui_scene.instantiate()
		runes_in_inventory = InventoryManager.find_many_items_by_id(rune.item_id)
		var amount_runes_in_inventory = 0
		for rune_item in runes_in_inventory:
			amount_runes_in_inventory += rune_item.current_stack
		requirement_items.add_child(rune_requirement_ui)
		rune_requirement_ui.quantity_needed = current_gem.get_number_of_runes_to_upgrade() * amount_gem_to_upgrade
		rune_requirement_ui.quantity = amount_runes_in_inventory
		rune_requirement_ui.setup(rune)

		# Find all gems of the same type EXCEPT the one we're upgrading
	gems_in_inventory = InventoryManager.find_many_items_by_id(current_gem.item_id)
	var amount_gems_in_inventory = 0
	for gem_item in gems_in_inventory:
		amount_gems_in_inventory += gem_item.current_stack
	var gem_requirement_ui: RequirementContentUI = req_content_ui_scene.instantiate()
	requirement_items.add_child(gem_requirement_ui)
	gem_requirement_ui.quantity_needed = 1 * amount_gem_to_upgrade
	gem_requirement_ui.quantity = max(amount_gems_in_inventory - 1, 0)
	gem_requirement_ui.setup(current_gem)

	var coins = CurrencyManager.convert_value_to_coins(current_gem.price_to_upgrade * amount_gem_to_upgrade)
	item_price.update_golds(coins.golds)
	item_price.update_silvers(coins.silvers, coins.golds > 0)
	item_price.update_bronzes(coins.bronzes, coins.silvers > 0)


# func _on_upgrade_button_pressed(runes_in_inventory: Array[RuneItem], gems_in_inventory: Array[GemItem]) -> void:
func _on_upgrade_button_pressed() -> void:
	if current_gem:
		if current_gem.upgrade_gem(runes_in_inventory, gems_in_inventory, amount_gem_to_upgrade):
			queue_free()


func _on_update_quantity_gem(value: int) -> void:
	amount_gem_to_upgrade = max(1, amount_gem_to_upgrade + value)
	_update_requirements()


func _on_close_button_pressed() -> void:
	queue_free()
