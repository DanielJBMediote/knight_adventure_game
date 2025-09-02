extends Node

signal use_potion(potion: PotionItem)
signal use_food(food: Item)

signal use_equipment(equipment: EquipmentItem)
signal selected_item_updated(item: Item)

const BG_GRADIENT_ITEM_COMMOM = preload("res://src/ui/themes/items_themes/bg_gradient_item_common.tres")
const BG_GRADIENT_ITEM_UNCOMMON = preload("res://src/ui/themes/items_themes/bg_gradient_item_uncommon.tres")
const BG_GRADIENT_ITEM_RARE = preload("res://src/ui/themes/items_themes/bg_gradient_item_rare.tres")
const BG_GRADIENT_ITEM_EPIC = preload("res://src/ui/themes/items_themes/bg_gradient_item_epic.tres")
const BG_GRADIENT_ITEM_LEGENDARY = preload("res://src/ui/themes/items_themes/bg_gradient_item_legendary.tres")
const BG_GRADIENT_ITEM_MITICAL = preload("res://src/ui/themes/items_themes/bg_gradient_item_mitical.tres")

const ItemCategory = Item.CATEGORY
const ItemRarity = Item.RARITY
const ItemSubCategory = Item.SUBCATEGORY

var current_selected_item: Item

func consume_item(item: Item) -> void:
	match item.item_subcategory:
		ItemSubCategory.POTION:
			use_potion.emit(item)
		ItemSubCategory.FOOD:
			use_food.emit(item)
		_:
			return

func equip_item(equipment: EquipmentItem) -> void:
	use_equipment.emit(equipment)

func update_selected_item(item: Item) -> void:
	if item:
		current_selected_item = item
		selected_item_updated.emit(item)
	else:
		current_selected_item = null

func compare_player_level(item_level: int) -> bool:
	return PlayerStats.level >= item_level or PlayerStats.level == 100

func get_bg_gradient_by_rarity(rarity: Item.RARITY) -> GradientTexture2D:
	match rarity:
		ItemRarity.COMMON:
			return BG_GRADIENT_ITEM_COMMOM
		ItemRarity.UNCOMMON:
			return BG_GRADIENT_ITEM_UNCOMMON
		ItemRarity.RARE:
			return BG_GRADIENT_ITEM_RARE
		ItemRarity.EPIC:
			return BG_GRADIENT_ITEM_EPIC
		ItemRarity.LEGENDARY:
			return BG_GRADIENT_ITEM_LEGENDARY
		ItemRarity.MYTHICAL:
			return BG_GRADIENT_ITEM_MITICAL
		_:
			return BG_GRADIENT_ITEM_COMMOM
