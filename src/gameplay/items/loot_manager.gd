class_name LootManager

# Dicionário para mapear categorias para itens
static var ITEMS_BY_CATEGORY = {
	Item.ItemCategory.CONSUMABLES: [
		preload("res://src/gameplay/items/consumables/potions/potion_item.tscn"),
		#preload("res://src/gameplay/items/consumables/food_item.gd")
	],
	#Item.ItemCategory.EQUIPMENT: [
		#preload("res://src/gameplay/items/equipment/weapon_item.gd"),
		#preload("res://src/gameplay/items/equipment/armor_item.gd")
	#],
	Item.ItemCategory.LOOTS: [
		preload("res://src/gameplay/items/loots/gems/gem_item.tscn"),
		#preload("res://src/gameplay/items/loots/gold_item.gd"),
		#preload("res://src/gameplay/items/loots/resource_item.gd")
	],
	#Item.ItemCategory.QUEST: [
		#preload("res://src/gameplay/items/quest/quest_item.gd")
	#]
}

# Configuração de drop rates por categoria
static var CATEGORY_DROP_RATES = {
	Item.ItemCategory.LOOTS: 0.4,
	Item.ItemCategory.EQUIPMENT: 0.3,
	Item.ItemCategory.CONSUMABLES: 0.2,
	Item.ItemCategory.QUEST: 0.1
}

static func get_items_from_categories(categories: Array[Item.ItemCategory]) -> Array[PackedScene]:
	var items: Array[PackedScene] = []
	
	for category in categories:
		if ITEMS_BY_CATEGORY.has(category):
			items.append_array(ITEMS_BY_CATEGORY[category])
	
	return items

static func get_random_item_from_category(category: Item.ItemCategory) -> PackedScene:
	var items = ITEMS_BY_CATEGORY.get(category, [])
	if items.is_empty():
		return null
	return items[randi() % items.size()]

static func get_weighted_random_category() -> Item.ItemCategory:
	var total_weight = 0.0
	for weight in CATEGORY_DROP_RATES.values():
		total_weight += weight
	
	var random_value = randf() * total_weight
	var cumulative = 0.0
	
	for category in CATEGORY_DROP_RATES:
		cumulative += CATEGORY_DROP_RATES[category]
		if random_value <= cumulative:
			return category
	
	return Item.ItemCategory.LOOTS

static func generate_loot_for_enemy(enemy_level: int, available_categories: Array[Item.ItemCategory]) -> Array[Item]:
	var loot_items: Array[Item] = []
	
	# Escolhe uma categoria baseada nos pesos
	var selected_category = get_weighted_random_category()
	
	# Verifica se a categoria está disponível para este inimigo
	if selected_category in available_categories:
		var item_scene = get_random_item_from_category(selected_category)
		if item_scene:
			var item_instance = item_scene.instantiate() as Item
			if item_instance:
				# Configura o item baseado no nível do inimigo
				configure_item_based_on_level(item_instance, enemy_level)
				loot_items.append(item_instance)
	
	return loot_items

static func configure_item_based_on_level(item: Item, enemy_level: int):
	item.item_level = enemy_level
	item.item_rarity = item.calculate_item_rarity_by_game_difficult(GameEvents.current_map.difficulty)
	item.item_value = item.calculate_item_value()
	item.spawn_chance = item.calculate_item_spawn_chance()
