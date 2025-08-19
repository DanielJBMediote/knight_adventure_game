extends Node

signal use_potion(potion: PotionItem)

const ItemCategory = Item.ItemCategory
const ItemRarity = Item.ItemRarity
const ItemSubCategory = Item.ItemSubCategory

func use_item(item: Item) -> void:
	if item.item_category == ItemCategory.CONSUMABLES:
		if item.item_subcategory == ItemSubCategory.POTION:
			use_potion.emit(item)
