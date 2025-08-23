extends Node

signal use_potion(potion: PotionItem)
signal use_food(food: Item)

signal use_equipment(equipment: Item)

const ItemCategory = Item.ItemCategory
const ItemRarity = Item.ItemRarity
const ItemSubCategory = Item.ItemSubCategory

var current_selected_item: Item

func consume_item(item: Item) -> void:
	match item.item_subcategory:
		ItemSubCategory.POTION:
			use_potion.emit(item)
		ItemSubCategory.FOOD:
			use_food.emit(item)
		_:
			return

func equip_item(item: Item) -> void:
	use_equipment.emit(item)
