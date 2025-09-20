class_name PotionItem
extends Item

const POTION_WEIGHTS := {
	ItemAttribute.TYPE.HEALTH: 60, # 60% de chance
	ItemAttribute.TYPE.MANA: 15, # 15% de chance
	ItemAttribute.TYPE.ENERGY: 9, # 9% de chance
	ItemAttribute.TYPE.DEFENSE: 5, # 5% de chance
	ItemAttribute.TYPE.DAMAGE: 5, # 5% de chance
	ItemAttribute.TYPE.CRITICAL_RATE: 2.5, # 2,5% de chance
	ItemAttribute.TYPE.CRITICAL_DAMAGE: 2.5, # 2,5% de chance
	ItemAttribute.TYPE.ATTACK_SPEED: 0.5, # 0.5% de chance
	ItemAttribute.TYPE.MOVE_SPEED: 0.5, # 0.5% de chance
}

# nível 1  # nível 10  # nível 20  # nível 30  # nível 40  # nível 50  # nível 60  # nível 70  # nível 80  # nível 90  # nível 100
const BONUS_TABLE = {1: 0, 10: 5, 20: 15, 30: 25, 40: 30, 50: 35, 60: 40, 70: 45, 80: 50, 90: 55, 100: 60}

const MAX_STACK = 99
const LEVEL_INTERVAL = 10
const BASE_POTION_VALUE = 100

@export var potion_type: ItemAttribute.TYPE


func _init() -> void:
	pass


func setup(enemy_stats: EnemyStats) -> void:
	self.potion_type = _generate_random_potion_type()
	self.item_usable = true
	self.stackable = true
	self.max_stack = MAX_STACK
	self.item_category = Item.CATEGORY.CONSUMABLES
	self.item_subcategory = Item.SUBCATEGORY.POTION
	self.item_level = _calculate_potion_level(enemy_stats.level)
	self.item_rarity = _calculate_potion_rarity()
	self.spawn_chance = _calculate_potion_spawn_chance()
	self.item_action = _setup_potion_action()
	self.item_name = _generate_potion_name()
	self.item_descriptions = _generate_potion_description()
	self.item_id = _generate_potion_id()
	self.item_price = _calculate_item_price(BASE_POTION_VALUE)

	_setup_texture()


func _calculate_potion_rarity() -> Item.RARITY:
	var player_level = PlayerStats.level
	var map_level = GameEvents.current_map.get_min_mob_level()
	var difficutly = GameEvents.current_map.get_difficulty()

	var rarity = get_item_rarity_by_difficult_and_player_level(player_level, map_level, difficutly)
	return rarity


func _calculate_potion_spawn_chance() -> float:
	var base_chance = 1.0 # 30% de chance base

	# Multiplicador baseado na raridade
	var rarity_multiplier = {
		Item.RARITY.COMMON: 1.0,
		Item.RARITY.UNCOMMON: 0.7,
		Item.RARITY.RARE: 0.4,
		Item.RARITY.EPIC: 0.2,
		Item.RARITY.LEGENDARY: 0.1,
		Item.RARITY.MYTHICAL: 0.05
	}

	# Multiplicador baseado no nível do item
	var level_multiplier = 1.0 - (item_level / 100.0)

	# Multiplicador baseado na diferença do nível do jogador
	var player_level = PlayerStats.level # Assumindo que você tem acesso ao nível do jogador
	var map_level = GameEvents.current_map.level_mob_min
	var player_level_modifier = Item.get_player_level_modifier(player_level, map_level)

	# Calcula a chance final
	var current_difficulty = GameEvents.current_map.difficulty
	var difficulty_factor = GameEvents.get_drop_modificator_by_difficult(current_difficulty)
	var rarity_factor = rarity_multiplier.get(item_rarity, 1.0)

	var final_chance = base_chance * difficulty_factor * rarity_factor * level_multiplier * player_level_modifier

	# Garante que a chance esteja entre 1% e 100%
	return clamp(final_chance, 0.01, 1.0)


func _generate_potion_id() -> String:
	var potion_resource_name = ItemAttribute.ATTRIBUTE_NAMES.get(potion_type, "UNKNOWN")
	var rarity_name = Item.get_rarity_text(self.item_rarity)
	var level_str = str("L", self.item_level)
	return Item._generate_item_id(["POTION", potion_resource_name, rarity_name, level_str])


func _generate_random_potion_type() -> ItemAttribute.TYPE:
	var total_weight: float = 0.0
	for weight in POTION_WEIGHTS.values():
		total_weight += weight

	var random_value: float = randf_range(0, total_weight)
	var cumulative_weight: float = 0.0

	for type_potion in POTION_WEIGHTS:
		cumulative_weight += POTION_WEIGHTS[type_potion]
		if random_value < cumulative_weight:
			return type_potion

	# Fallback (nunca deve acontecer)
	return ItemAttribute.TYPE.HEALTH


func _generate_potion_name() -> String:
	var potion_key = ItemAttribute.ATTRIBUTE_KEYS[potion_type].to_lower()
	var base_name = LocalizationManager.get_potion_name_text(potion_key)
	var rarity_prefix = Item.get_rarity_prefix_text(item_rarity)
	var rarity_sufix = Item.get_rarity_sufix_text(item_rarity)
	return "%s %s %s" % [rarity_prefix, base_name, rarity_sufix]


func _generate_potion_description() -> Array[String]:
	var potion_type_name = ItemAttribute.ATTRIBUTE_KEYS.get(potion_type, "unknown")
	var base_description = LocalizationManager.get_potion_base_description_text(potion_type_name)
	var params = {"amount": item_action.attribute.value, "duration": item_action.duration}
	base_description = LocalizationManager.format_text_with_params(base_description, params)
	return [base_description]


func calculate_instant_amount() -> float:
	var base_multiply = 1.0 if potion_type == ItemAttribute.TYPE.ENERGY else 5.0

	# Valores base para poção nível 1 comum
	var base_values = {
		ItemAttribute.TYPE.HEALTH: 300.0,
		ItemAttribute.TYPE.MANA: 10.0,
		ItemAttribute.TYPE.ENERGY: 15.0
	}

	# Multiplicadores por nível (cada +10 níveis dobra o valor aproximadamente)
	var level_multiplier = 1.0 + (item_level / float(LEVEL_INTERVAL)) * base_multiply

	# Multiplicadores de raridade (0 a 5)
	var rarity_multipliers = [1.0, 1.5, 1.75, 2.0, 2.5, 3.0]

	var base_amount = base_values[potion_type]
	var rarity_multiplier = rarity_multipliers[clamp(item_rarity, 0, 5)]

	return round(base_amount * level_multiplier * rarity_multiplier)


func calculate_buff_percentage() -> float:
	var base_percentage = 0.0
	# Aumento por nível = 0/5/15/25/30/35/40/45/50/55/60%
	var level_bonus = calculate_buff_level_bonus()

	# Aumenta pela raridade = 0/5/10/15/20/25%
	var rarity_bonus = item_rarity * 5.0

	match potion_type:
		ItemAttribute.TYPE.DEFENSE:
			base_percentage = 15.0
		ItemAttribute.TYPE.DAMAGE:
			base_percentage = 15.0
		ItemAttribute.TYPE.CRITICAL_RATE:
			base_percentage = 15.0
		ItemAttribute.TYPE.CRITICAL_DAMAGE:
			base_percentage = 15.0
		ItemAttribute.TYPE.ATTACK_SPEED:
			base_percentage = 5.0
		ItemAttribute.TYPE.MOVE_SPEED:
			base_percentage = 2.5

	if [ItemAttribute.TYPE.ATTACK_SPEED, ItemAttribute.TYPE.MOVE_SPEED].has(potion_type):
		level_bonus = level_bonus / 2.0

	var total = base_percentage + level_bonus + rarity_bonus

	# Se for unico adiciona +50% do buff
	total += (total * 0.5) if is_unique else 0.0

	return clamp(total, 0.1, 150.0)


func calculate_buff_level_bonus() -> float:
	var level_index: int = item_level
	if BONUS_TABLE.has(level_index):
		return min(100.0, BONUS_TABLE[level_index])
	else:
		return min(100.0, 60.0) # Fallback


func calculate_buff_duration() -> float:
	var duration = 90.0
	var rarity_bonus = item_rarity * 45.0
	var unique_bonus = 120.0 if is_unique else 0.0

	return duration + rarity_bonus + unique_bonus


func _calculate_potion_level(enemy_level: int) -> int:
	var potion_level = max(1, floori(enemy_level / float(LEVEL_INTERVAL)) * LEVEL_INTERVAL)
	return potion_level


func _setup_potion_action() -> ItemAction:
	var attribute = ItemAttribute.new(potion_type, 0)
	var action = ItemAction.new()

	# Define se é instantâneo ou buff
	if potion_type in [ItemAttribute.TYPE.HEALTH, ItemAttribute.TYPE.MANA, ItemAttribute.TYPE.ENERGY]:
		action.action_type = ItemAction.TYPE.INSTANTLY
		attribute.value = calculate_instant_amount()
	else:
		action.action_type = ItemAction.TYPE.BUFF
		attribute.value = calculate_buff_percentage()
		action.duration = calculate_buff_duration()

	action.attribute = attribute
	return action


func _setup_texture() -> void:
	var resource_key = ItemAttribute.ATTRIBUTE_KEYS.get(potion_type)
	var potion_rank = get_potion_rank()
	var base_path = "res://assets/sprites/items/potions/%s_potion_%s.png" % [resource_key, potion_rank]
	var texture = load_texture_with_fallback(base_path, base_path, resource_key)
	self.item_texture = texture


func get_potion_rank() -> String:
	if item_level >= 60:
		return "03"
	elif item_level >= 30:
		return "02"
	else:
		return "01"


static func sort_by_type(a: PotionItem, b: PotionItem, mode := "ASC"):
	if a.potion_type == b.potion_type:
		if mode == "ASC":
			return a.potion_type < b.potion_type
		else:
			return a.potion_type > b.potion_type
	return
