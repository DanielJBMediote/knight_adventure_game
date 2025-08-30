class_name GemItem
extends Item

enum QUALITY {
	FRAGMENTED,  # Lv 15 (Common)
	COMMON,  # Lv 30 (Uncommon)
	REFINED,  # Lv 45 (Rare)
	FLAWLESS,  # Lv 60 (Epic)
	EXQUISITE,  # Lv 75 (Legendary)
	PRISTINE,  # Lv 90 (Mythical)
}

const GEM_WEIGHTS := {
	ItemAttribute.TYPE.HEALTH: 15,
	ItemAttribute.TYPE.MANA: 10,
	ItemAttribute.TYPE.ENERGY: 2,
	ItemAttribute.TYPE.DEFENSE: 15,
	ItemAttribute.TYPE.DAMAGE: 15,
	ItemAttribute.TYPE.CRITICAL_RATE: 15,
	ItemAttribute.TYPE.CRITICAL_DAMAGE: 15,
	ItemAttribute.TYPE.ATTACK_SPEED: 3,
	ItemAttribute.TYPE.MOVE_SPEED: 3,
	ItemAttribute.TYPE.HEALTH_REGEN: 0.25,
	ItemAttribute.TYPE.MANA_REGEN: 0.25,
	ItemAttribute.TYPE.ENERGY_REGEN: 0.25,
	ItemAttribute.TYPE.EXP_BUFF: 0.25,
}

const GEM_QUALITY_KEY := {
	QUALITY.FRAGMENTED: "fragmented",
	QUALITY.COMMON: "common",
	QUALITY.REFINED: "refined",
	QUALITY.FLAWLESS: "flawless",
	QUALITY.EXQUISITE: "exquisite",
	QUALITY.PRISTINE: "pristine",
}

const UNIQUE_GEMS_KEYS := {
	ItemAttribute.TYPE.HEALTH_REGEN: "health_regen",
	ItemAttribute.TYPE.MANA_REGEN: "mana_regen",
	ItemAttribute.TYPE.ENERGY_REGEN: "energy_regen",
	ItemAttribute.TYPE.EXP_BUFF: "exp_buff",
}

const GEM_COLOR_NAME_KEY := {
	ItemAttribute.TYPE.HEALTH: "pink",
	ItemAttribute.TYPE.MANA: "blue",
	ItemAttribute.TYPE.ENERGY: "green",
	ItemAttribute.TYPE.DEFENSE: "purple",
	ItemAttribute.TYPE.DAMAGE: "orange",
	ItemAttribute.TYPE.CRITICAL_RATE: "yellow",
	ItemAttribute.TYPE.CRITICAL_DAMAGE: "silver",
	ItemAttribute.TYPE.ATTACK_SPEED: "magenta",
	ItemAttribute.TYPE.MOVE_SPEED: "white",
}

# Valores base por tipo de atributo
const BASE_VALUES := {
	ItemAttribute.TYPE.HEALTH: 550.0,
	ItemAttribute.TYPE.MANA: 25.0,
	ItemAttribute.TYPE.ENERGY: 5.0,
	ItemAttribute.TYPE.DEFENSE: 15.0,
	ItemAttribute.TYPE.DAMAGE: 25.0,
	ItemAttribute.TYPE.CRITICAL_RATE: 0.020,
	ItemAttribute.TYPE.CRITICAL_DAMAGE: 0.020,
	ItemAttribute.TYPE.ATTACK_SPEED: 0.010,
	ItemAttribute.TYPE.MOVE_SPEED: 0.010,
	ItemAttribute.TYPE.HEALTH_REGEN: 2.0,
	ItemAttribute.TYPE.MANA_REGEN: 1.0,
	ItemAttribute.TYPE.ENERGY_REGEN: 0.5,
	ItemAttribute.TYPE.EXP_BUFF: 0.5
}

const MAX_STACKS = 999
const LEVEL_INTERVAL = 15
const MIN_LEVEL = 5
const BASE_GEM_PRICE := 300.0

@export var gem_type: ItemAttribute.TYPE
@export var can_upgrade := false
@export var gem_quality: QUALITY

func _init() -> void:
	pass

func get_sort_value() -> int:
	return gem_quality

func setup(enemy_stats: EnemyStats) -> void:
	gem_type = get_random_gem_type()
	
	self.stackable = true
	self.max_stack = MAX_STACKS
	self.item_category = Item.CATEGORY.LOOTS
	self.item_subcategory = Item.SUBCATEGORY.GEM
	self.item_level = calculate_gem_level(enemy_stats.level)
	self.gem_quality = get_gem_quality()
	self.can_upgrade = can_upgrade_gem()
	self.spawn_chance = calculate_spawn_chance(enemy_stats.level)
	self.item_rarity = calculate_gem_rarity()
	self.item_action = null
	self.is_unique = setup_gem_unique()
	self.item_attributes = setup_gem_attributes()
	self.item_name = set_gem_name()
	self.item_description = setup_gem_description()
	self.item_id = generate_gem_id()
	self.item_price = calculate_item_price(BASE_GEM_PRICE)
	
	setup_texture()

func can_upgrade_gem() -> bool:
	return item_level >= MIN_LEVEL and item_level < 100


func calculate_gem_level(enemy_level: int) -> int:
	var gem_level = max(MIN_LEVEL, floori(enemy_level / float(LEVEL_INTERVAL)) * LEVEL_INTERVAL)
	return gem_level


func get_random_gem_type() -> ItemAttribute.TYPE:
	var total_weight: float = 0.0
	for weight in GEM_WEIGHTS.values():
		total_weight += weight

	var random_value = randf() * total_weight
	var cumulative: float = 0.0

	for gem_type in GEM_WEIGHTS:
		cumulative += GEM_WEIGHTS[gem_type]
		if random_value <= cumulative:
			return gem_type

	return ItemAttribute.TYPE.HEALTH


func generate_gem_id() -> String:
	var quality = self.gem_quality
	var quality_str = GEM_QUALITY_KEY[quality]
	var type_str = ItemAttribute.ATTRIBUTE_KEYS[gem_type]
	return generate_item_id(["GEM", quality_str, type_str])


func set_gem_name() -> String:
	var quality = self.gem_quality
	var quality_name = LocalizationManager.get_gem_quality_text(quality)
	var type_str = ItemAttribute.ATTRIBUTE_KEYS[gem_type]
	var gem_type_name = LocalizationManager.get_gem_name_text(type_str).to_lower()
	return "%s %s" % [quality_name, gem_type_name]


func setup_gem_description() -> String:
	var type_str = ItemAttribute.ATTRIBUTE_KEYS.get(gem_type)
	var description = LocalizationManager.get_gem_base_description_text(type_str)

	var quality = self.gem_quality
	var quality_name = LocalizationManager.get_gem_quality_text(quality)

	description = LocalizationManager.format_text_with_params(description, {"quality": quality_name})

	if is_unique:
		if gem_type in UNIQUE_GEMS_KEYS:
			description += "\n\n" + LocalizationManager.get_gem_unique_description_text(type_str)
		else:
			description += ". " + LocalizationManager.get_gem_base_description_text("unique_gem")

	return description


func get_gem_quality() -> QUALITY:
	var level = self.item_level
	if level >= 90:
		return QUALITY.PRISTINE
	elif level >= 75:
		return QUALITY.EXQUISITE
	elif level >= 60:
		return QUALITY.FLAWLESS
	elif level >= 45:
		return QUALITY.REFINED
	elif level >= 30:
		return QUALITY.COMMON
	else:
		return QUALITY.FRAGMENTED


func calculate_gem_rarity() -> Item.RARITY:
	var quality = self.gem_quality
	match quality:
		QUALITY.PRISTINE:
			return Item.RARITY.MYTHICAL
		QUALITY.EXQUISITE:
			return Item.RARITY.LEGENDARY
		QUALITY.FLAWLESS:
			return Item.RARITY.EPIC
		QUALITY.REFINED:
			return Item.RARITY.RARE
		QUALITY.COMMON:
			return Item.RARITY.UNCOMMON
		_:
			return Item.RARITY.COMMON


func calculate_spawn_chance(enemy_level: int) -> float:
	var base_chance = 1.0 if enemy_level >= MIN_LEVEL else 0.0

	# Reduz a chance conforme a qualidade aumenta
	var quality_modifier := 1.0
	match self.gem_quality:
		QUALITY.PRISTINE:
			quality_modifier = 0.01
		QUALITY.EXQUISITE:
			quality_modifier = 0.05
		QUALITY.FLAWLESS:
			quality_modifier = 0.1
		QUALITY.REFINED:
			quality_modifier = 0.3
		QUALITY.COMMON:
			quality_modifier = 0.6
		QUALITY.FRAGMENTED:
			quality_modifier = 1.0

	# Modificador de dificuldade
	var difficulty = GameEvents.current_map.get_difficulty()
	var difficulty_modifier = GameEvents.get_drop_modificator_by_difficult(difficulty)
	
	# Modificador de nível da gema
	var level_modifier = 1.0 - (item_level / 100.0)

	var spawn_chance = base_chance * quality_modifier * difficulty_modifier * level_modifier
	return clamp(spawn_chance, 0.01, 1.0)


func setup_gem_attributes() -> Array[ItemAttribute]:
	var attributes: Array[ItemAttribute] = []
	var attribute = ItemAttribute.new()
	attribute.type = gem_type
	attribute.value = calculate_final_attribute_value()

	if self.gem_quality == QUALITY.PRISTINE and is_unique:
		attribute.value *= 1.5

	attributes.append(attribute)
	return attributes


func calculate_final_attribute_value(_gem_type: ItemAttribute.TYPE = gem_type) -> float:
	var base_value = BASE_VALUES[_gem_type]
	var quality_multiplier = get_quality_multiplier()
	#var level_multiplier = 1.0 + (item_level / 100.0)

	var final_value = base_value * quality_multiplier

	# Se for um tipo de porcentagem, retorna o valor como está
	# A conversão para decimal (÷ 100) será feita na aplicação do atributo
	if _gem_type in ItemAttribute.PERCENTAGE_TYPES:
		return final_value
	else:
		return round(final_value)


func get_quality_multiplier() -> float:
	match self.gem_quality:
		QUALITY.PRISTINE:
			return 6.0
		QUALITY.EXQUISITE:
			return 5.0
		QUALITY.FLAWLESS:
			return 4.0
		QUALITY.REFINED:
			return 3.0
		QUALITY.COMMON:
			return 2.0
		QUALITY.FRAGMENTED:
			return 1.0
		_:
			return 1.0


func setup_gem_unique() -> bool:
	# Gemas dos tipos únicos são sempre únicas
	if gem_type in UNIQUE_GEMS_KEYS:
		return true

	# Gemas Mythical (PRISTINE) têm 50% de chance de serem únicase terem 1 atributo a mais
	if self.gem_quality == QUALITY.PRISTINE:
		return randf() <= 0.5

	return false


func setup_texture() -> void:
	var color = GEM_COLOR_NAME_KEY.get(gem_type, "default")
	var quality_key = GEM_QUALITY_KEY[self.gem_quality]

	var file_path = ""
	if is_unique and gem_type in UNIQUE_GEMS_KEYS:
		var name_key = UNIQUE_GEMS_KEYS[gem_type]
		file_path = "res://assets/sprites/items/gems/gem_%s.png" % [name_key]
	else:
		file_path = "res://assets/sprites/items/gems/gem_%s_%s.png" % [quality_key, color]

	var attribute_key = ItemAttribute.ATTRIBUTE_KEYS[gem_type]
	var texture = load_texture_with_fallback(file_path, "", attribute_key)
	self.item_texture = texture


static func get_gem_attribute_key(gem_type: ItemAttribute.TYPE) -> String:
	return ItemAttribute.ATTRIBUTE_KEYS[gem_type]
