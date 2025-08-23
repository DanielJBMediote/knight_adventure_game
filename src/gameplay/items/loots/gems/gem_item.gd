class_name GemItem
extends Item

enum Quality { 
	FRAGMENTED,		# Lv 15 (Common)
	COMMON,			# Lv 30 (Uncommon)
	REFINED,		# Lv 45 (Rare)
	FLAWLESS,		# Lv 60 (Epic)
	EXQUISITE,		# Lv 75 (Legendary)
	PRISTINE,		# Lv 90 (Mythical)
}

const GEM_WEIGHTS := {
	ItemAttribute.Type.HEALTH: 				15,
	ItemAttribute.Type.MANA:				10,
	ItemAttribute.Type.ENERGY:				2,
	ItemAttribute.Type.DEFENSE: 			15,
	ItemAttribute.Type.DAMAGE: 				15,
	ItemAttribute.Type.CRITICAL_RATE:		15,
	ItemAttribute.Type.CRITICAL_DAMAGE:		15,
	ItemAttribute.Type.ATTACK_SPEED: 		3,
	ItemAttribute.Type.MOVE_SPEED:	 		3,
	ItemAttribute.Type.HEALTH_REGEN: 		0.25,
	ItemAttribute.Type.MANA_REGEN: 			0.25,
	ItemAttribute.Type.ENERGY_REGEN: 		0.25,
	ItemAttribute.Type.EXP_BUFF: 			0.25,
}

const GEM_QUALITY_KEY := {
	Quality.FRAGMENTED: 	"fragmented",
	Quality.COMMON: 		"common",
	Quality.REFINED: 		"refined",
	Quality.FLAWLESS: 		"flawless",
	Quality.EXQUISITE: 		"exquisite",
	Quality.PRISTINE: 		"pristine",
}

const UNIQUE_GEMS_KEYS := {
	ItemAttribute.Type.HEALTH_REGEN:	"health_regen",
	ItemAttribute.Type.MANA_REGEN:		"mana_regen",
	ItemAttribute.Type.ENERGY_REGEN:	"energy_regen",
	ItemAttribute.Type.EXP_BUFF:		"exp_buff",
}

const GEM_COLOR_NAME_KEY := {
	ItemAttribute.Type.HEALTH: 			"pink",
	ItemAttribute.Type.MANA:			"blue",
	ItemAttribute.Type.ENERGY:			"green",
	ItemAttribute.Type.DEFENSE: 		"purple",
	ItemAttribute.Type.DAMAGE: 			"orange",
	ItemAttribute.Type.CRITICAL_RATE:	"yellow",
	ItemAttribute.Type.CRITICAL_DAMAGE:	"silver",
	ItemAttribute.Type.ATTACK_SPEED: 	"magenta",
	ItemAttribute.Type.MOVE_SPEED:	 	"white",
}

# Valores base por tipo de atributo
const BASE_VALUES := {
	ItemAttribute.Type.HEALTH: 750.0,
	ItemAttribute.Type.MANA: 25.0,
	ItemAttribute.Type.ENERGY: 5.0,
	ItemAttribute.Type.DEFENSE: 5.0,
	ItemAttribute.Type.DAMAGE: 10.0,
	ItemAttribute.Type.CRITICAL_RATE: 4.0,
	ItemAttribute.Type.CRITICAL_DAMAGE: 5.0,
	ItemAttribute.Type.ATTACK_SPEED: 3.0,
	ItemAttribute.Type.MOVE_SPEED: 2.0,
	ItemAttribute.Type.HEALTH_REGEN: 50.0,
	ItemAttribute.Type.MANA_REGEN: 5.0,
	ItemAttribute.Type.ENERGY_REGEN: 3.0,
	ItemAttribute.Type.EXP_BUFF: 5.0
}

@export var gem_type: ItemAttribute.Type

var can_upgrade := false

const MAX_STACKS = 999
const LEVEL_INTERVAL = 15
const MIN_LEVEL = 15
const BASE_GEM_VALUE := 300.0

func _init() -> void:
	gem_type = get_random_gem_type()
	setup_values()
	setup_texture()

func setup_values() -> void:
	self.stackable = true
	self.max_stack = MAX_STACKS
	self.item_category = ItemCategory.EQUIPMENT
	self.item_subcategory = ItemSubCategory.GEM
	self.item_level = calculate_gem_level()
	self.can_upgrade = can_upgrade_gem()
	self.spawn_chance = calculate_spawn_chance()
	self.item_rarity = calculate_gem_rarity()
	self.item_action = null
	self.item_attributes = []
	self.is_unique = setup_gem_unique()
	self.item_attributes = setup_gem_attributes()
	self.item_name = set_gem_name()
	self.item_description = setup_gem_description()
	self.item_id = generate_gem_id()
	self.item_value = calculate_item_value(BASE_GEM_VALUE)

func can_upgrade_gem() -> bool:
	return item_level >= MIN_LEVEL and item_level < 100

func calculate_gem_level() -> int:
	var map_level = GameEvents.current_map.level_mob_min
	var gem_level = max(MIN_LEVEL, (floori(map_level / float(LEVEL_INTERVAL)) * LEVEL_INTERVAL))
	return gem_level

func get_random_gem_type() -> ItemAttribute.Type:
	var total_weight: float = 0.0
	for weight in GEM_WEIGHTS.values():
		total_weight += weight
	
	var random_value = randf() * total_weight
	var cumulative: float = 0.0

	for gem_type in GEM_WEIGHTS:
		cumulative += GEM_WEIGHTS[gem_type]
		if random_value <= cumulative:
			return gem_type
	
	return ItemAttribute.Type.HEALTH

func generate_gem_id() -> String:
	var quality_str = GEM_QUALITY_KEY[get_gem_quality()]
	var type_str = ItemAttribute.ATTRIBUTE_KEYS[gem_type]
	return "gem_%s_%s_%d" % [quality_str, type_str, item_level]

func set_gem_name() -> String:
	var quality = get_gem_quality()
	var quality_name = LocalizationManager.get_item_name("gem_quality.%s" % GEM_QUALITY_KEY[quality])
	var type_str = ItemAttribute.ATTRIBUTE_KEYS[gem_type]
	var gem_type_name = LocalizationManager.get_item_name("gem_%s" % type_str.to_lower())
	#var attribute_name = ItemAttribute.ATTRIBUTE_NAMES.get(gem_type)
	return "%s %s" % [quality_name, gem_type_name]

func setup_gem_description() -> String:
	var quality = get_gem_quality()
	var type_str = ItemAttribute.ATTRIBUTE_KEYS.get(gem_type)
	
	# Mostrar o primeiro attributo
	var attribute_value = item_attributes[0].value
	# Formata o valor corretamente
	var formatted_value = format_attribute_value(attribute_value, gem_type)
	
	# Usar o sistema de localização para a descrição principal
	var description_key = "items.descriptions.gem_attribute"
	var params = {
		"quality_prefix": LocalizationManager.get_item_name("gem_quality_prefix.%s" % GEM_QUALITY_KEY[quality]),
		"gem_attribute_desc": LocalizationManager.get_item_description("gem_attribute_desc.%s" % ItemAttribute.ATTRIBUTE_KEYS[gem_type]),
	}
	params["gem_attribute_desc"] = LocalizationManager.format_text_with_params(params["gem_attribute_desc"], { "value": formatted_value })
	var description = LocalizationManager.get_translation_format(description_key, params)
	
	# Adiciona informações especiais para gemas únicas usando localização
	if is_unique:
		if gem_type in UNIQUE_GEMS_KEYS:
			var unique_key = "items.descriptions.unique_gem_%s" % ItemAttribute.ATTRIBUTE_KEYS[gem_type]
			description += "\n\n" + LocalizationManager.get_translation(unique_key)
		else:
			var unique_key = "items.descriptions.unique_gem"
			description += " " + LocalizationManager.get_translation(unique_key)
	
	# Informações de nível e raridade usando localização
	var info_text = "\n\n{level_required}: {level_value}\n{rarity}: {rarity_value}"
	var info_params = {
		"level_required": LocalizationManager.get_ui_text("level_required"),
		"level_value": item_level,
		"rarity": LocalizationManager.get_ui_text("rarity"),
		"rarity_value": LocalizationManager.get_item_rarity_name(item_rarity)
	}
	description += LocalizationManager.format_text_with_params(info_text, info_params)
	
	return description

## Formata o valor baseado no tipo de atributo (porcentagem ou valor absoluto)
func format_attribute_value(value: float, gem_type: ItemAttribute.Type) -> String:
	if gem_type in ItemAttribute.PERCENTAGE_TYPES:
		return "%.1f%%" % value
	else:
		return "%.0f" % value

func get_gem_quality() -> Quality:
	var level = self.item_level
	if level >= 90: return Quality.PRISTINE
	elif level >= 75: return Quality.EXQUISITE
	elif level >= 60: return Quality.FLAWLESS
	elif level >= 45: return Quality.REFINED
	elif level >= 30: return Quality.COMMON
	else: return Quality.FRAGMENTED

func calculate_gem_rarity() -> Item.ItemRarity:
	var quality = get_gem_quality()
	match quality:
		Quality.PRISTINE: return ItemRarity.MYTHICAL
		Quality.EXQUISITE: return ItemRarity.LEGENDARY
		Quality.FLAWLESS: return ItemRarity.EPIC
		Quality.REFINED: return ItemRarity.RARE
		Quality.COMMON: return ItemRarity.UNCOMMON
		_: return ItemRarity.COMMON

func calculate_spawn_chance() -> float:
	var base_chance = 1.0
	
	# Reduz a chance conforme a qualidade aumenta
	var quality_modifier := 1.0
	match get_gem_quality():
		Quality.PRISTINE: quality_modifier = 0.01
		Quality.EXQUISITE: quality_modifier = 0.05
		Quality.FLAWLESS: quality_modifier = 0.1
		Quality.REFINED: quality_modifier = 0.3
		Quality.COMMON: quality_modifier = 0.6
		Quality.FRAGMENTED: quality_modifier = 1.0
	
	# Modificador de dificuldade
	var difficulty = GameEvents.current_map.difficulty
	var difficulty_modifier = GameEvents.get_drop_modificator(difficulty)
	
	# Modificador de nível da gema
	var level_modifier = 1.0 - (item_level / 100.0)
	
	return base_chance * quality_modifier * difficulty_modifier * level_modifier

func setup_gem_attributes() -> Array[ItemAttribute]:
	var attributes: Array[ItemAttribute]= []
	var attribute = ItemAttribute.new()
	attribute.type = gem_type
	attribute.value = calculate_final_attribute_value()
	
	if get_gem_quality() == Quality.PRISTINE and is_unique:
		attribute.value *= 1.5
	
	attributes.append(attribute)
	return attributes

func calculate_final_attribute_value(_gem_type: ItemAttribute.Type = gem_type) -> float:
	var base_value = BASE_VALUES[_gem_type]
	var quality_multiplier = get_quality_multiplier()
	var level_multiplier = 1.0 + (item_level / 100.0)
	
	var final_value = base_value * quality_multiplier * level_multiplier
	
	# Se for um tipo de porcentagem, retorna o valor como está
	# A conversão para decimal (÷ 100) será feita na aplicação do atributo
	if _gem_type in ItemAttribute.PERCENTAGE_TYPES:
		return final_value
	else:
		return round(final_value)

func get_quality_multiplier() -> float:
	var quality = get_gem_quality()
	match quality:
		Quality.PRISTINE: return 3.0
		Quality.EXQUISITE: return 2.5
		Quality.FLAWLESS: return 2.0
		Quality.REFINED: return 1.5
		Quality.COMMON: return 1.2
		Quality.FRAGMENTED: return 1.0
		_: return 1.0

func setup_gem_unique() -> bool:
	# Gemas dos tipos únicos são sempre únicas
	if gem_type in UNIQUE_GEMS_KEYS:
		return true
	
	# Gemas Mythical (PRISTINE) têm 50% de chance de serem únicase terem 1 atributo a mais
	if get_gem_quality() == Quality.PRISTINE:
		return randf() <= 0.5
	
	return false

func setup_texture() -> void:
	var color = GEM_COLOR_NAME_KEY.get(gem_type, "default")
	var quality_key = GEM_QUALITY_KEY[get_gem_quality()]
	
	var file_path = ""
	if is_unique and gem_type in UNIQUE_GEMS_KEYS:
		var name_key = UNIQUE_GEMS_KEYS[gem_type]
		file_path = "res://assets/sprites/items/gems/gem_%s.png" % [name_key]
	else:
		file_path = "res://assets/sprites/items/gems/gem_%s_%s.png" % [quality_key, color]
	
	var attribute_key = ItemAttribute.ATTRIBUTE_KEYS[gem_type]
	var texture = load_texture_with_fallback(file_path, "", attribute_key)
	self.item_texture = texture

static func get_gem_attribute_key(gem_type: ItemAttribute.Type) -> String:
	return ItemAttribute.ATTRIBUTE_KEYS[gem_type]
