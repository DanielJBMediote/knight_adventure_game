class_name EquipmentItem
extends Item

enum TYPE { HELMET, ARMOR, BOOTS, GLOVES, RING, AMULET, WEAPON }
enum GROUPS { COMMON, UNIQUES }

enum SETS {
	TRAVELER,
	LEATHER,
	HUNTER,
	BRONZE,
	IRON,
	HEAVY,
	GUARDIAN,
	NOBLE_PLATINUM,
	SHADOW_EBONY,
	SERPENT_EMBRACE,
	SACRED_CRUSADER,
	FROSTBEAR_WRATH,
	LOST_KING,
	DEMONS_BANE,
	SOLARIS,
	DEATH_REAPER,
	JUGGERNOUT,
	ELEMENTALS_POWERFULL,
	SAMURAI,
	SILVER_MOON,
	WINDCUTTER,
}


class SetLevelConfig:
	var set_group: GROUPS
	var equipment_set: SETS
	var level_range: Array[int]

	func _init(_set_group: GROUPS, _equipment_set: SETS, _level_range: Array[int]) -> void:
		set_group = _set_group
		equipment_set = _equipment_set
		level_range = _level_range


var level_configs: Array[SetLevelConfig] = [
	SetLevelConfig.new(GROUPS.COMMON, SETS.TRAVELER, [1, 10]),
	SetLevelConfig.new(GROUPS.COMMON, SETS.LEATHER, [11, 20]),
	SetLevelConfig.new(GROUPS.COMMON, SETS.HUNTER, [21, 30]),
	SetLevelConfig.new(GROUPS.COMMON, SETS.BRONZE, [31, 40]),
	SetLevelConfig.new(GROUPS.COMMON, SETS.IRON, [41, 50]),
	SetLevelConfig.new(GROUPS.COMMON, SETS.HEAVY, [51, 60]),
	SetLevelConfig.new(GROUPS.COMMON, SETS.GUARDIAN, [61, 70]),
	SetLevelConfig.new(GROUPS.COMMON, SETS.NOBLE_PLATINUM, [71, 80]),
	SetLevelConfig.new(GROUPS.COMMON, SETS.SHADOW_EBONY, [81, 115]),
	SetLevelConfig.new(GROUPS.UNIQUES, SETS.SAMURAI, [1, 19]),
	SetLevelConfig.new(GROUPS.UNIQUES, SETS.WINDCUTTER, [20, 29]),
	SetLevelConfig.new(GROUPS.UNIQUES, SETS.SERPENT_EMBRACE, [30, 39]),
	SetLevelConfig.new(GROUPS.UNIQUES, SETS.SILVER_MOON, [40, 49]),
	SetLevelConfig.new(GROUPS.UNIQUES, SETS.SACRED_CRUSADER, [50, 59]),
	SetLevelConfig.new(GROUPS.UNIQUES, SETS.FROSTBEAR_WRATH, [60, 69]),
	SetLevelConfig.new(GROUPS.UNIQUES, SETS.LOST_KING, [70, 79]),
	SetLevelConfig.new(GROUPS.UNIQUES, SETS.DEMONS_BANE, [80, 89]),
	SetLevelConfig.new(GROUPS.UNIQUES, SETS.SOLARIS, [90, 95]),
	SetLevelConfig.new(GROUPS.UNIQUES, SETS.DEATH_REAPER, [95, 99]),
	SetLevelConfig.new(GROUPS.UNIQUES, SETS.JUGGERNOUT, [100, 110]),
	SetLevelConfig.new(GROUPS.UNIQUES, SETS.ELEMENTALS_POWERFULL, [111, 115])
]

const EQUIPMENT_SPAWN_WEIGHTS = {
	TYPE.HELMET: 20, TYPE.ARMOR: 20, TYPE.BOOTS: 15, TYPE.GLOVES: 15, TYPE.RING: 10, TYPE.AMULET: 10, TYPE.WEAPON: 10
}

const EQUIPMENT_SET_SPAWN_WEIGHTS = {
	GROUPS.COMMON: 90,
	GROUPS.UNIQUES: 10,
}

const ATTRIBUTES_PER_RARITY = {
	RARITY.COMMON: 0, RARITY.UNCOMMON: 1, RARITY.RARE: 2, RARITY.EPIC: 3, RARITY.LEGENDARY: 4, RARITY.MYTHICAL: 5
}

const UNIQUE_EQUIPMENTS_SET_BONUS_TRIGGER = {}

@export var equipment_type: TYPE
@export var equipment_group: GROUPS
@export var equipment_set: SETS
@export var set_bonus_attributes: Array[ItemAttribute] = []

@export var damage: ItemAttribute
@export var defense: ItemAttribute


func _init() -> void:
	pass


func clone() -> EquipmentItem:
	var copy: EquipmentItem = super.clone()

	copy.equipment_type = self.equipment_type
	copy.equipment_group = self.equipment_group
	copy.equipment_set = self.equipment_set
	copy.damage = self.damage
	copy.defense = self.defense

	if self.set_bonus_attributes:
		copy.set_bonus_attributes = self.set_bonus_attributes

	return copy


func get_sort_value() -> int:
	return equipment_type


func setup(enemy_stats: EnemyStats) -> void:
	self.max_stack = 1
	self.item_level = enemy_stats.level
	self.spawn_chance = calculate_spawn_chance()
	self.item_category = Item.CATEGORY.EQUIPMENTS

	self.equipment_group = determine_equipment_group()
	self.is_unique = (equipment_group == GROUPS.UNIQUES)
	self.equipment_set = determine_equipment_set(enemy_stats.level)
	#self.item_rarity = Item.RARITY.MYTHICAL
	self.item_rarity = calculate_item_rarity(enemy_stats)
	self.equipment_type = determine_equipment_type()
	self.item_subcategory = determine_equipment_subcategory()

	# GERA PRIMEIRO OS ATRIBUTOS BASE (dano/defesa)
	setup_base_values()

	# DEPOIS GERA OS ATRIBUTOS ADICIONAIS
	self.item_attributes.append_array(generate_attributes())
	self.set_bonus_attributes = generate_set_bonus_attributes()

	self.item_name = generate_name()
	self.item_description = generate_description()
	self.item_id = generate_equipment_id()
	self.item_price = calculate_item_price(calculate_equipment_base_price())
	setup_texture()


func calculate_spawn_chance() -> float:
	var base_chance = 1.0  # 30% base chance

	# Aplica peso do tipo de equipamento
	var type_weight = EQUIPMENT_SPAWN_WEIGHTS[equipment_type] / 100.0

	# Modificador de raridade (itens mais raros são mais raros)
	var rarity_modifier = 1.0 - (item_rarity * 0.1)

	# Modificador de dificultade
	var difficulty = GameEvents.current_map.difficulty
	var difficulty_modifier = GameEvents.get_drop_modificator_by_difficult(difficulty)

	# Modificador de nível (itens de nível mais alto são mais raros)
	var level_modifier = 1.0 - (item_level * 0.005)
	var spawn_chance = base_chance * type_weight * rarity_modifier * level_modifier * difficulty_modifier
	return clamp(spawn_chance, 0.001, 1.0)


func determine_equipment_type() -> TYPE:
	var available_sets = EquipmentConsts.SETS_AVAILABLE_PARTS
	# Para TODOS os conjuntos que têm partes específicas definidas
	if available_sets.has(equipment_set):
		var available_parts = available_sets[equipment_set] as Array[TYPE]

		if available_parts.size() == 1:
			return available_parts[0]

		# Escolhe aleatoriamente entre as partes disponíveis
		var random_index = randi() % available_parts.size()
		return available_parts[random_index]

	# Fallback: usa o sistema original de pesos (para conjuntos não definidos)
	var total_weight = 0
	for weight in EQUIPMENT_SPAWN_WEIGHTS.values():
		total_weight += weight

	var random_value = randi() % total_weight
	var cumulative_weight = 0

	for type in EQUIPMENT_SPAWN_WEIGHTS:
		cumulative_weight += EQUIPMENT_SPAWN_WEIGHTS[type]
		if random_value < cumulative_weight:
			return type

	return TYPE.HELMET  # Fallback


func determine_equipment_subcategory() -> Item.SUBCATEGORY:
	var armors = [TYPE.HELMET, TYPE.ARMOR, TYPE.BOOTS, TYPE.GLOVES]
	if armors.has(self.equipment_type):
		return Item.SUBCATEGORY.ARMOR
	elif self.equipment_type == TYPE.WEAPON:
		return Item.SUBCATEGORY.WEAPON
	else:
		return Item.SUBCATEGORY.ACCESSORY


## Determina se vai ser do grupo Communs ou Únicos
func determine_equipment_group() -> GROUPS:
	var total_weight = 0

	for weight in EQUIPMENT_SET_SPAWN_WEIGHTS.values():
		total_weight += weight

	var random_value = randi() % total_weight
	var cumulative_weight = 0

	for _set_type in EQUIPMENT_SET_SPAWN_WEIGHTS:
		cumulative_weight += EQUIPMENT_SET_SPAWN_WEIGHTS[_set_type]
		if random_value < cumulative_weight:
			return _set_type

	return GROUPS.COMMON


func determine_equipment_set(enemy_level: int) -> SETS:
	# Filtra as configurações pelo equipment_group atual
	var configs_for_group = level_configs.filter(filter_equipments_sets_config)

	# Para conjuntos únicos, queremos o conjunto com o nível mínimo mais alto que seja <= enemy_level
	# Para conjuntos comuns, queremos o intervalo que contenha o enemy_level
	for config in configs_for_group:
		if is_level_in_level_range(enemy_level, config.level_range):
			return config.equipment_set
	# Fallback
	if equipment_group == GROUPS.UNIQUES:
		return SETS.SAMURAI
	return SETS.TRAVELER


func filter_equipments_sets_config(_config: SetLevelConfig) -> bool:
	#print("Grupo:", equipment_group, " Conj.: ", EQUIPMENTS_SET_KEYS[equipment_set] )
	return _config.set_group == equipment_group


# Geralmente vai ter apenas 1 ou 2 intervalos de níveis
func is_level_in_level_range(level: int, level_range: Array[int]) -> bool:
	if level_range.size() > 1:
		return level >= level_range[0] and level <= level_range[1]
	else:
		return level >= level_range[0]
	return false


func calculate_item_rarity(enemy_stats: EnemyStats) -> Item.RARITY:
	if self.equipment_group == GROUPS.UNIQUES:
		return EquipmentConsts.UNIQUE_SETS_RARITY[equipment_set]
	else:
		var player_level = PlayerStats.level
		var map_level = GameEvents.current_map.get_min_mob_level()
		var difficulty = GameEvents.current_map.difficulty
		return Item.get_item_rarity_by_difficult_and_player_level(player_level, map_level, difficulty)


func generate_attributes() -> Array[ItemAttribute]:
	var attributes: Array[ItemAttribute] = []
	var num_attributes = ATTRIBUTES_PER_RARITY[item_rarity]

	if num_attributes <= 0:
		return attributes

	# Define atributos permitidos para cada tipo de equipamento
	var allowed_attributes = get_allowed_attributes_for_type()

	# Se não há atributos permitidos, retorna vazio
	if allowed_attributes.is_empty():
		return attributes

	# Garante que não gere mais atributos do que os permitidos
	#num_attributes = min(num_attributes, allowed_attributes.size())
	var rarity_multiplier = 1.0 + (item_rarity * 0.005)

	for i in range(num_attributes):
		# Escolhe um atributo aleatório da lista de permitidos
		var random_index = randi() % allowed_attributes.size()
		var random_type = allowed_attributes[random_index]

		# Remove o atributo escolhido para não repetir
		#allowed_attributes.remove_at(random_index)

		var attribute = ItemAttribute.new()
		attribute.type = random_type
		attribute.base_value = calculate_attribute_value(random_type)
		var min_value = attribute.get_min_value_range()
		var max_value = attribute.get_max_value_range()
		attribute.min_value = min_value
		attribute.max_value = max_value
		attribute.value = clamp(randf_range(min_value, max_value) * rarity_multiplier, min_value, max_value)

		attributes.append(attribute)

	return attributes


func get_allowed_attributes_for_type() -> Array:
	return EquipmentConsts.ALLOWED_ATTRIBUTES_PER_TYPE.get(self.equipment_type, [])


func calculate_attribute_value(attribute_type: ItemAttribute.TYPE) -> float:
	var base_value = EquipmentConsts.EQUIPMENTS_STATS_BASE_VALUES[attribute_type]["base_value"]
	var level_multiplier = 1.0 + (min(item_level, 100) * 0.01)
	var rarity_multiplier = 1.0 + (item_rarity * 0.3)
	var factor = EquipmentConsts.EQUIPMENTS_STATS_BASE_VALUES[attribute_type]["factor"]

	base_value += (item_level * factor)

	# Converte para porcentagem se necessário
	if attribute_type in ItemAttribute.PERCENTAGE_TYPES:
		base_value *= 0.01
	var final_value = base_value * level_multiplier * rarity_multiplier
	return final_value


func generate_set_bonus_attributes() -> Array[ItemAttribute]:
	var bonuses: Array[ItemAttribute] = []

	# Bônus de conjunto apenas para itens do conjunto de unicos
	if equipment_group != GROUPS.UNIQUES:
		return bonuses

	# Adiciona bônus baseado no conjunto
	match equipment_set:
		SETS.SERPENT_EMBRACE:
			var sepent_embrace_attributes = generate_sepernt_embrace_attributes(item_level)
			bonuses.append_array(sepent_embrace_attributes)

		SETS.FROSTBEAR_WRATH:
			var health_bonus = ItemAttribute.new()
			health_bonus.type = ItemAttribute.TYPE.HEALTH
			health_bonus.value = 3.0 + (item_level * 0.1)
			bonuses.append(health_bonus)

		SETS.SOLARIS:
			var damage_bonus = ItemAttribute.new()
			damage_bonus.type = ItemAttribute.TYPE.DEFENSE
			damage_bonus.value = 10.0 + (item_level * 0.5)
			bonuses.append(damage_bonus)

	return bonuses


func generate_name() -> String:
	var base_name = ""
	var set_name_key = EquipmentConsts.EQUIPMENTS_SET_KEYS[equipment_set]
	var equip_type_key = EquipmentConsts.EQUIPMENT_TYPE_KEYS[equipment_type]

	match equipment_group:
		GROUPS.COMMON:
			base_name = LocalizationManager.get_equipment_common_item(equipment_set, equipment_type)
		GROUPS.UNIQUES:
			base_name = LocalizationManager.get_equipment_unique_item(equipment_set, equipment_type)
		_:
			pass

	var rarity_prefix = Item.get_rarity_prefix_text(item_rarity)
	if not rarity_prefix.is_empty():
		return "%s %s" % [rarity_prefix, base_name]

	return base_name


func generate_description() -> String:
	var description = ""

	var set_name_key = EquipmentConsts.EQUIPMENTS_SET_KEYS[equipment_set]
	var equip_type_key = EquipmentConsts.EQUIPMENT_TYPE_KEYS[equipment_type]

	description += LocalizationManager.get_equipment_text("base_set_description")

	var params = {}
	if self.equipment_group == GROUPS.UNIQUES:
		var base_desc = "uniques.%s.description" % set_name_key
		var base_name = "uniques.%s.set_name" % set_name_key
		params = {"set_name": LocalizationManager.get_equipment_text(base_name)}
		description += '\n"' + LocalizationManager.get_equipment_text(base_desc)
	else:
		var base_desc = "commons.%s.description" % set_name_key
		var base_name = "commons.%s.set_name" % set_name_key
		params = {"set_name": LocalizationManager.get_equipment_text(base_name)}
		description += '\n"' + LocalizationManager.get_equipment_text(base_desc)

	description = LocalizationManager.format_text_with_params(description, params)

	return description


func setup_base_values() -> void:
	if self.item_subcategory == Item.SUBCATEGORY.WEAPON:
		generate_damage_stats()
	else:
		generate_defense_stats()


func generate_damage_stats() -> void:
	var base_damage = calculate_base_damage()

	self.damage = ItemAttribute.new()
	self.damage.type = ItemAttribute.TYPE.DAMAGE
	self.damage.base_value = base_damage

	var min_value = self.damage.get_min_value_range()
	var max_value = self.damage.get_max_value_range()
	self.damage.value = randf_range(min_value, max_value)


func generate_defense_stats() -> void:
	var base_defense = calculate_base_defense()

	self.defense = ItemAttribute.new()
	self.defense.type = ItemAttribute.TYPE.DEFENSE
	self.defense.base_value = base_defense
	self.defense.value = randf_range(self.defense.min_value, self.defense.max_value)


func calculate_base_damage() -> float:
	var att_type = ItemAttribute.TYPE.DAMAGE
	var data = EquipmentConsts.EQUIPMENTS_STATS_BASE_VALUES[att_type]
	var base_value = data["base_value"]
	var factor = data["factor"]
	var level_multiplier = 1.0 + (min(item_level, 100) * 0.01)
	var rarity_multiplier = 1.0 + (item_rarity * 0.3)
	base_value += (item_level * factor * level_multiplier * rarity_multiplier)

	# Bônus para itens únicos
	if is_unique:
		base_value *= 1.5

	return base_value


func calculate_base_defense() -> float:
	var att_type = ItemAttribute.TYPE.DEFENSE
	var data = EquipmentConsts.EQUIPMENTS_STATS_BASE_VALUES[att_type]
	var base_value = data["base_value"]
	var factor = data["factor"]
	var level_multiplier = 1.0 + (min(item_level, 100) * 0.01)
	var rarity_multiplier = 1.0 + (item_rarity * 0.3)
	base_value += (item_level * factor * level_multiplier * rarity_multiplier)

	# Diferentes tipos de armadura têm defesa diferente
	match equipment_type:
		TYPE.ARMOR:
			base_value *= 1.5  # Peito tem mais defesa
		TYPE.HELMET:
			base_value *= 1.2
		TYPE.BOOTS:
			base_value *= 0.8
		TYPE.GLOVES:
			base_value *= 0.7
		TYPE.RING, TYPE.AMULET:
			base_value *= 0.5  # Acessórios têm menos defesa

	# Bônus para itens únicos
	if is_unique:
		base_value *= 1.3

	return base_value


func calculate_equipment_base_price() -> int:
	var min_price = EquipmentConsts.EQUIPMENT_BASE_PRICES[equipment_type] * 0.75
	var max_price = EquipmentConsts.EQUIPMENT_BASE_PRICES[equipment_type] * 1.25
	var base_value = randi_range(floori(min_price), ceili(max_price))
	return base_value

func generate_equipment_id() -> String:
	var equip_set_str = EquipmentConsts.EQUIPMENTS_SET_KEYS[equipment_set]
	var equip_type_str = EquipmentConsts.EQUIPMENT_TYPE_KEYS[equipment_type]
	var id_parts: Array[String] = [
		"EQUIPMENT", equip_set_str, equip_type_str, str("L", item_level), RARITY_KEYS[item_rarity]
	]
	return Item.generate_item_id(id_parts)


func get_all_attributes() -> Array[ItemAttribute]:
	var all_attributes = item_attributes.duplicate()
	#all_attributes.append_array(self.set_bonus_attributes)
	return all_attributes


func setup_texture() -> void:
	var equip_type_key = EquipmentConsts.EQUIPMENT_TYPE_KEYS[equipment_type]
	var equip_name_key = EquipmentConsts.EQUIPMENTS_SET_KEYS[equipment_set]

	var file_path = "res://assets/sprites/items/equipments/%s/%s.png" % [equip_type_key, equip_name_key]
	var texture = load_texture_with_fallback(file_path, "", str(" ", equip_type_key, "/", equip_name_key))
	self.item_texture = texture


static func generate_sepernt_embrace_attributes(_item_level: int) -> Array[ItemAttribute]:
	var poison_bonus = ItemAttribute.new()
	poison_bonus.type = ItemAttribute.TYPE.POISON_HIT_RATE
	poison_bonus.value = 5.0 + (_item_level * 0.2)

	var damage_bonus = ItemAttribute.new()
	damage_bonus.type = ItemAttribute.TYPE.DAMAGE
	damage_bonus.value = 10.0 + (_item_level * 0.2)

	return [poison_bonus, damage_bonus]
