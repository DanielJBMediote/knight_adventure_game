class_name RuneItem
extends Item

# HEALTH  # MANA  # ENERGY  # DEFENSE  # DAMAGE  # CRITICAL_RATE  # CRITICAL_DAMAGE  # ATTACK_SPEED  # MOVE_SPEED  # HEALTH_REGEN, MANA_REGEN, ENERGY_REGEN
enum TYPE {VITALITY, ESSENCE, VIGOR, PROTECTION, STRENGTH, PRECISION, FURY, AGILITY, SWIFTNESS, SPECIAL}

@export var rune_type: TYPE

func _init() -> void:
	pass


func get_sort_value() -> int:
	return rune_type


func setup(enemy_stats: EnemyStats) -> void:
	self.rune_type = get_random_type()
	self.stackable = true
	self.max_stack = RuneConsts.MAX_STACKS
	self.item_category = Item.CATEGORY.LOOTS
	self.item_subcategory = Item.SUBCATEGORY.RESOURCE
	self.item_level = calculate_rune_level(enemy_stats.level)
	self.item_rarity = get_rune_rarity()
	self.spawn_chance = calculate_spawn_chance(enemy_stats.level)
	self.item_name = generate_rune_name()
	self.item_descriptions = generate_rune_descriptions()
	self.item_id = generate_rune_id()
	self.item_price = _calculate_item_price(RuneConsts.BASE_PRICE)
	self.item_texture = generate_rune_texture()


func generate_rune_id() -> String:
	var rune_type_key = RuneConsts.RUNE_TYPE_KEYS.get(self.rune_type, "UNKNOWN")
	var rune_name = "%s_%d" % [rune_type_key, self.item_level]
	var rune_id = Item._generate_item_id([rune_name])
	return rune_id


func generate_rune_name() -> String:
	var rune_key = RuneConsts.RUNE_TYPE_KEYS.get(self.rune_type, "UNKNOWN")
	var base_name = LocalizationManager.get_rune_name_text(rune_key)
	var rarity_prefix = Item.get_rarity_prefix_text(self.item_rarity)
	var rune_name = "%s %s" % [rarity_prefix, base_name] if rarity_prefix != "" else base_name
	return rune_name


func generate_rune_descriptions() -> Array[String]:
	var rune_key = RuneConsts.RUNE_TYPE_KEYS.get(self.rune_type, "UNKNOWN")
	var next_gem_quality = GemItem.get_next_gem_quality_by_required_rune(self.item_rarity)
	var next_gem_quality_key = GemConsts.GEM_QUALITY_KEY[next_gem_quality]
	var prev_gem_quality_key = GemConsts.GEM_QUALITY_KEY[next_gem_quality - 1]
	var prev_gem_name = LocalizationManager.get_gem_quality_text(prev_gem_quality_key).capitalize()
	var next_gem_name = LocalizationManager.get_gem_quality_text(next_gem_quality_key).capitalize()
	var base_description = LocalizationManager.get_rune_description_text(rune_key)
	var params = {"next_gem_quality": next_gem_name, "gem_quality": prev_gem_name}
	base_description = LocalizationManager.format_text_with_params(base_description, params)
	return [base_description]

func get_random_type() -> TYPE:
	var total_weight: float = 0.0
	for weight in RuneConsts.RUNE_WEIGHT.values():
		total_weight += weight

	var random_value = randf() * total_weight
	var cumulative: float = 0.0

	for _rune_type in RuneConsts.RUNE_WEIGHT:
		cumulative += RuneConsts.RUNE_WEIGHT[_rune_type]
		if random_value <= cumulative:
			return _rune_type

	return TYPE.VITALITY


## Runes levels are in intervals of LEVEL_INTERVAL (e.g., 15, 30, 45, 60, 75 and 90)
## The rune level is determined based on the enemy level, clamped between MIN_LEVEL and MAX_LEVEL
func calculate_rune_level(enemy_level: int) -> int:
	var rune_level = clamp(floori(enemy_level / float(RuneConsts.LEVEL_INTERVAL)) * RuneConsts.LEVEL_INTERVAL, RuneConsts.MIN_LEVEL, RuneConsts.MAX_LEVEL)
	return rune_level


func get_rune_rarity() -> Item.RARITY:
	var level = self.item_level
	if level >= 75:
		return Item.RARITY.MYTHICAL
	elif level >= 60:
		return Item.RARITY.LEGENDARY
	elif level >= 45:
		return Item.RARITY.EPIC
	elif level >= 30:
		return Item.RARITY.RARE
	elif level >= 15:
		return Item.RARITY.UNCOMMON
	else:
		return Item.RARITY.COMMON

func get_level_by_rarity() -> int:
	match self.item_rarity:
		Item.RARITY.UNCOMMON:
			return 15
		Item.RARITY.RARE:
			return 30
		Item.RARITY.EPIC:
			return 45
		Item.RARITY.LEGENDARY:
			return 60
		Item.RARITY.MYTHICAL:
			return 75
		_:
			return RuneConsts.MIN_LEVEL


func calculate_spawn_chance(enemy_level: int) -> float:
	var base_chance = 1.0 if enemy_level >= RuneConsts.MIN_LEVEL else 0.0
	if base_chance == 0.0:
		return 0.0

	var difficulty = GameEvents.current_map.get_difficulty()
	var difficulty_multiplier = GameEvents.get_drop_modificator_by_difficult(difficulty)
	var level_factor = (enemy_level - RuneConsts.MIN_LEVEL) / float(RuneConsts.LEVEL_INTERVAL)
	var calculated_spawn_chance = base_chance + (level_factor * difficulty_multiplier)

	return clamp(calculated_spawn_chance, 0.01, 1.0)


func generate_rune_texture() -> Texture2D:
	var attribute_key = RuneConsts.RUNE_TYPE_KEYS.get(self.rune_type, "UNKNOWN")
	var file_path = "res://assets/sprites/items/runes/%s.png" % attribute_key
	return load_texture_with_fallback(file_path, "", attribute_key)
