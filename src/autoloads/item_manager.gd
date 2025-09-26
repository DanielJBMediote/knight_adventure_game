extends Node

signal selected_item_updated(item: Item)

const BG_GRADIENT_ITEM_COMMON = preload("res://src/ui/themes/items_themes/bg_gradient_item_common.tres")
const BG_GRADIENT_ITEM_UNCOMMON = preload("res://src/ui/themes/items_themes/bg_gradient_item_uncommon.tres")
const BG_GRADIENT_ITEM_RARE = preload("res://src/ui/themes/items_themes/bg_gradient_item_rare.tres")
const BG_GRADIENT_ITEM_EPIC = preload("res://src/ui/themes/items_themes/bg_gradient_item_epic.tres")
const BG_GRADIENT_ITEM_LEGENDARY = preload("res://src/ui/themes/items_themes/bg_gradient_item_legendary.tres")
const BG_GRADIENT_ITEM_MITICAL = preload("res://src/ui/themes/items_themes/bg_gradient_item_mitical.tres")

var current_selected_item: Item

func update_selected_item(item: Item) -> void:
	if item:
		current_selected_item = item
		selected_item_updated.emit(item)
	else:
		current_selected_item = null

func compare_player_level(item_level: int) -> bool:
	return PlayerStats.level >= item_level or PlayerStats.level == 100

func get_background_theme_by_rarity(rarity: Item.RARITY) -> GradientTexture2D:
	match rarity:
		Item.RARITY.COMMON:
			return BG_GRADIENT_ITEM_COMMON
		Item.RARITY.UNCOMMON:
			return BG_GRADIENT_ITEM_UNCOMMON
		Item.RARITY.RARE:
			return BG_GRADIENT_ITEM_RARE
		Item.RARITY.EPIC:
			return BG_GRADIENT_ITEM_EPIC
		Item.RARITY.LEGENDARY:
			return BG_GRADIENT_ITEM_LEGENDARY
		Item.RARITY.MYTHICAL:
			return BG_GRADIENT_ITEM_MITICAL
		_:
			return BG_GRADIENT_ITEM_COMMON
