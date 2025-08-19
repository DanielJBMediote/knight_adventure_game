class_name Item
extends Node

enum ItemCategory { CONSUMABLES, EQUIPMENT, LOOTS, QUEST, OTHERS }
enum ItemSubCategory { POTION, FOOD, WEAPON, ARMOR, ACCESSORY, RESOURCE }
enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHICAL }

@export var item_id: String
@export var item_name: String
@export var item_description: String
@export var item_category: ItemCategory = ItemCategory.OTHERS
@export var item_subcategory: ItemSubCategory = ItemSubCategory.RESOURCE
@export var item_rarity: ItemRarity = ItemRarity.COMMON
@export var spawn_chance: float = 1.0  # 0-1 (0% a 100%)
@export var item_texture: Texture2D
@export var stackable: bool = false
@export var max_stack: int = 1
@export var current_stack: int = 1
@export var is_unique: bool = false
@export var item_value: float = 0.0
@export var item_level: float = 0.0

var item_action: ItemAction
var item_attributes: ItemAttributes

func use() -> void:
	ItemManager.use_item(self)

## Calculate the Rarity of Item. It's based of Difficult
static func calculate_rarity(difficulty: GameEvents.Difficulty) -> ItemRarity:
	var rand_val = randf()
	
	# Chances para cada dificuldade:
	# [COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MITICAL]
	var thresholds = {
		GameEvents.Difficulty.NORMAL: [0.6, 0.3, 0.08, 0.02, 0.0, 0.0],
		GameEvents.Difficulty.PAINFUL: [0.5, 0.35, 0.1, 0.04, 0.01, 0.0],
		GameEvents.Difficulty.FATAL: [0.4, 0.4, 0.15, 0.04, 0.01, 0.0],
		GameEvents.Difficulty.INFERNAL: [0.3, 0.45, 0.2, 0.04, 0.01, 0.0]
	}
	
	var cumulative = 0.0
	for i in range(ItemRarity.values().size()):
		cumulative += thresholds[difficulty][i]
		if rand_val <= cumulative:
			return ItemRarity.values()[i]
	return ItemRarity.COMMON

## Returns de Rarity name of Item 
func get_rarity_name() -> String:
	match item_rarity:
		ItemRarity.UNCOMMON: return LocalizationManager.get_translation("item.rarity.uncommon")
		ItemRarity.RARE: return LocalizationManager.get_translation("item.rarity.rare")
		ItemRarity.EPIC: return LocalizationManager.get_translation("item.rarity.epic")
		ItemRarity.LEGENDARY: return LocalizationManager.get_translation("item.rarity.legendary")
		ItemRarity.MYTHICAL: return LocalizationManager.get_translation("item.rarity.mythical")
		_: return ""

## Returns the Category name of Item 
func get_caategory_name() -> String:
	match item_category:
		ItemCategory.CONSUMABLES: return LocalizationManager.get_translation("item.category.consumables")
		ItemCategory.EQUIPMENT: return LocalizationManager.get_translation("item.category.equipment")
		ItemCategory.LOOTS: return LocalizationManager.get_translation("item.category.loots")
		ItemCategory.QUEST: return LocalizationManager.get_translation("item.category.quest")
		ItemCategory.OTHERS: return LocalizationManager.get_translation("item.category.others")
		_: return ""

## Returns the Rarity prefix name of Item base on Localizations/{local}.json file.
## Default is setted en.json: [ "", "Improved", "Superior", "Epic", "Legendary", "Mythical" ]
func get_rarity_prefix_name() -> String:
	match item_rarity:
		ItemRarity.UNCOMMON: return LocalizationManager.get_translation("item.rarity_prefix.uncommon")
		ItemRarity.RARE: return LocalizationManager.get_translation("item.rarity_prefix.rare")
		ItemRarity.EPIC: return LocalizationManager.get_translation("item.rarity_prefix.epic")
		ItemRarity.LEGENDARY: return LocalizationManager.get_translation("item.rarity_prefix.legendary")
		ItemRarity.MYTHICAL: return LocalizationManager.get_translation("item.rarity_prefix.mythical")
		_: return ""
