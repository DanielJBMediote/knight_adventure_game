class_name LootManager

# Dicionário para mapear categorias para itens
static var ITEMS_BY_CATEGORY = {
	Item.CATEGORY.CONSUMABLES: [
		preload("res://src/gameplay/items/consumables/potions/potion_item.tres"),
		#preload("res://src/gameplay/items/consumables/food_item.gd")
	],
	Item.CATEGORY.EQUIPMENTS: [
		preload("res://src/gameplay/items/equipments/equipment_item.tres"),
		#preload("res://src/gameplay/items/equipment/armor_item.gd")
	],
	Item.CATEGORY.LOOTS: [
		preload("res://src/gameplay/items/loots/gems/gem_item.tres"),
		#preload("res://src/gameplay/items/loots/gold_item.gd"),
		#preload("res://src/gameplay/items/loots/resource_item.gd")
	],
	#Item.CATEGORY.QUEST: [
		#preload("res://src/gameplay/items/quest/quest_item.gd")
	#]
}

# Configuração de drop rates por categoria
static var CATEGORY_DROP_RATES = {
	Item.CATEGORY.LOOTS: 0.4,
	Item.CATEGORY.EQUIPMENTS: 0.3,
	Item.CATEGORY.CONSUMABLES: 0.2,
	Item.CATEGORY.QUEST: 0.1
}

static func get_items_resources_from_categories(categories: Array[Item.CATEGORY]) -> Array[Item]:
	var items: Array[Item] = []
	
	for category in categories:
		if ITEMS_BY_CATEGORY.has(category):
			items.append_array(ITEMS_BY_CATEGORY[category])
	
	return items

static func get_random_item_resource_from_category(category: Item.CATEGORY) -> Item:
	var item_paths = ITEMS_BY_CATEGORY.get(category, [])
	if item_paths.is_empty():
		return null
	
	var resource = item_paths[randi() % item_paths.size()]
	if resource and resource is Item:
		var item_instance: Item = resource.duplicate(true)
		return item_instance
	
	push_error("Failed to load item from path: " + resource.name)
	return null
	

static func get_weighted_random_category() -> Item.CATEGORY:
	var total_weight = 0.0
	for weight in CATEGORY_DROP_RATES.values():
		total_weight += weight
	
	var random_value = randf() * total_weight
	var cumulative = 0.0
	
	for category in CATEGORY_DROP_RATES:
		cumulative += CATEGORY_DROP_RATES[category]
		if random_value <= cumulative:
			return category
	
	return Item.CATEGORY.LOOTS

static func generate_loot_for_enemy(enemy_stats: EnemyStats, available_categories: Array[Item.CATEGORY]) -> Array[Item]:
	var loot_items: Array[Item] = []
	
	# Escolhe uma categoria baseada nos pesos
	var selected_category = get_weighted_random_category()
	
	# Verifica se a categoria está disponível para este inimigo
	if selected_category in available_categories:
		var item_instance: Item = get_random_item_resource_from_category(selected_category)
		
		if item_instance:
			item_instance.setup(enemy_stats)
			loot_items.append(item_instance)
	
	return loot_items
