extends Node

signal use_potion(potion: PotionItem)
signal use_food(food: Item)

signal use_equipment(equipment: EquipmentItem)

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

static func compare_player_level(item_level: int) -> bool:
	return PlayerStats.level >= item_level or PlayerStats.level == 100
