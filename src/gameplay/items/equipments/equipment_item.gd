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


static var level_configs: Array[SetLevelConfig] = [
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

@export var equipment_type: TYPE
@export var equipment_group: GROUPS
@export var equipment_set: SETS
@export var available_sockets: int = 0
@export var gems_in_sockets: Array[GemItem] = []
@export var damage: ItemAttribute
@export var defense: ItemAttribute
@export var equipment_power: float = 0.0


func _init() -> void:
	pass


func clone() -> EquipmentItem:
	var copy: EquipmentItem = super.clone()

	copy.equipment_type = self.equipment_type
	copy.equipment_group = self.equipment_group
	copy.equipment_set = self.equipment_set
	copy.damage = self.damage
	copy.defense = self.defense

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
	self.item_rarity = calculate_item_rarity(enemy_stats)
	self.available_sockets = clampi(item_rarity, 0, 4)  # Itens mais raros podem ter mais slots de gemas
	self.equipment_type = determine_equipment_type()
	self.item_subcategory = determine_equipment_subcategory()

	# GERA PRIMEIRO OS ATRIBUTOS BASE (dano/defesa)
	setup_base_values()

	# DEPOIS GERA OS ATRIBUTOS ADICIONAIS
	self.item_attributes.append_array(generate_attributes())
	self.item_name = generate_name()
	self.item_descriptions = generate_equipment_descriptions()
	self.item_id = generate_equipment_id()
	self.item_price = calculate_item_price(calculate_equipment_base_price())
	self.equipment_power = calculate_equipment_power()
	setup_texture()


func calculate_spawn_chance() -> float:
	var base_chance = 1.0  # 30% base chance

	# Aplica peso do tipo de equipamento
	var type_weight = EquipmentConsts.EQUIPMENT_SPAWN_WEIGHTS[equipment_type] / 100.0

	# Modificador de raridade (itens mais raros são mais raros)
	var rarity_modifier = 1.0 - (item_rarity * 0.1)

	# Modificador de dificultade
	var difficulty = GameEvents.current_map.difficulty
	var difficulty_modifier = GameEvents.get_drop_modificator_by_difficult(difficulty)

	# Modificador de nível (itens de nível mais alto são mais raros)
	var level_modifier = 1.0 - (item_level * 0.005)
	var calculated_spawn_chance = (
		base_chance * type_weight * rarity_modifier * level_modifier * difficulty_modifier
	)
	return clamp(calculated_spawn_chance, 0.001, 1.0)


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
	for weight in EquipmentConsts.EQUIPMENT_SPAWN_WEIGHTS.values():
		total_weight += weight

	var random_value = randi() % total_weight
	var cumulative_weight = 0

	for type in EquipmentConsts.EQUIPMENT_SPAWN_WEIGHTS:
		cumulative_weight += EquipmentConsts.EQUIPMENT_SPAWN_WEIGHTS[type]
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

	for weight in EquipmentConsts.EQUIPMENT_SET_SPAWN_WEIGHTS.values():
		total_weight += weight

	var random_value = randi() % total_weight
	var cumulative_weight = 0

	for _set_type in EquipmentConsts.EQUIPMENT_SET_SPAWN_WEIGHTS:
		cumulative_weight += EquipmentConsts.EQUIPMENT_SET_SPAWN_WEIGHTS[_set_type]
		if random_value < cumulative_weight:
			return _set_type

	return GROUPS.COMMON


func determine_equipment_set(enemy_level: int) -> SETS:
	var configs_for_group = level_configs.filter(filter_equipments_sets_config)

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


func calculate_item_rarity(_enemy_stats: EnemyStats) -> Item.RARITY:
	if self.equipment_group == GROUPS.UNIQUES:
		return EquipmentConsts.UNIQUE_SETS_RARITY[equipment_set]
	else:
		var player_level = PlayerStats.level
		var map_level = GameEvents.current_map.get_min_mob_level()
		var difficulty = GameEvents.current_map.difficulty
		return Item.get_item_rarity_by_difficult_and_player_level(
			player_level, map_level, difficulty
		)


func generate_attributes() -> Array[ItemAttribute]:
	var attributes: Array[ItemAttribute] = []
	var num_attributes = EquipmentConsts.ATTRIBUTES_PER_RARITY[item_rarity]

	if num_attributes <= 0:
		return attributes

	# Define atributos permitidos para cada tipo de equipamento
	var allowed_attributes = get_allowed_attributes_for_type()

	# Se não há atributos permitidos, retorna vazio
	if allowed_attributes.is_empty():
		return attributes

	# Garante que não gere mais atributos do que os permitidos
	#num_attributes = min(num_attributes, allowed_attributes.size())

	var rarity_multiplier = 1.0 + (item_rarity * 0.015)
	var unique_factor = 1.25 if is_unique else 1.0
	var combined_factor = rarity_multiplier * unique_factor

	for i in range(num_attributes):
		# Escolhe um atributo aleatório da lista de permitidos
		var random_index = randi() % allowed_attributes.size()
		var random_type = allowed_attributes[random_index]

		# Remove o atributo escolhido para não repetir
		#allowed_attributes.remove_at(random_index)

		var base_value = calculate_attribute_value(random_type)
		var attribute = ItemAttribute.new(random_type, base_value)

		var min_value = attribute.get_min_value_range()
		var max_value = attribute.get_max_value_range()

		attribute.min_value = min_value
		attribute.max_value = max_value

		# attribute.value = clamp(randf_range(min_value, max_value) * rarity_multiplier, min_value, max_value)
		attribute.value = calculate_balanced_value(min_value, max_value, combined_factor)
		attributes.append(attribute)

	return attributes


func calculate_balanced_value(min_val: float, max_val: float, multiplier: float) -> float:
	var range_size = max_val - min_val

	# Usa distribuição exponencial para favorecer valores mais altos com multiplicadores
	# Quanto maior o multiplier, mais a distribuição se inclina para valores altos
	var exponent = 1.0 + (multiplier - 1.0) * 2.0  # Ajusta a curva

	# Gera um valor entre 0 e 1 com distribuição exponencial
	var normalized_value = pow(randf(), 2.5 / exponent)

	# Inverte para que valores mais altos sejam mais prováveis
	normalized_value = 1.0 - normalized_value

	# Aplica ao range
	var value = min_val + (normalized_value * range_size)

	return clamp(value, min_val, max_val)


func get_allowed_attributes_for_type() -> Array:
	var allowed_attributes: Array = EquipmentConsts.ALLOWED_ATTRIBUTES_PER_TYPE.get(
		self.equipment_type, []
	)
	var excluded_attributes: Array = [
		ItemAttribute.TYPE.HEALTH_REGEN,
		ItemAttribute.TYPE.MANA_REGEN,
		ItemAttribute.TYPE.ENERGY_REGEN,
		ItemAttribute.TYPE.EXP_BUFF
	]

	var attributes = []
	for attrib in allowed_attributes:
		if attrib not in excluded_attributes:
			attributes.append(attrib)

	return attributes


func calculate_attribute_value(attribute_type: ItemAttribute.TYPE) -> float:
	var base_value = EquipmentConsts.EQUIPMENTS_STATS_BASE_VALUES[attribute_type]["base_value"]
	var factor = EquipmentConsts.EQUIPMENTS_STATS_BASE_VALUES[attribute_type]["factor"]
	var level_multiplier = 1.0 + (min(item_level, 100.0) * factor)
	# var rarity_multiplier = 1.0 + (item_rarity * 0.1)

	# Converte para porcentagem se necessário
	if attribute_type in ItemAttribute.PERCENTAGE_TYPES:
		base_value *= 0.01
	#var final_value = base_value * rarity_multiplier * level_multiplier
	#var final_value = base_value * level_multiplier
	return base_value * level_multiplier


func generate_name() -> String:
	var base_name = ""
	# var set_name_key = EquipmentConsts.EQUIPMENTS_SET_KEYS[equipment_set]
	# var equip_type_key = EquipmentConsts.EQUIPMENT_TYPE_KEYS[equipment_type]

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


func generate_equipment_descriptions() -> Array[String]:
	var set_name_key = EquipmentConsts.EQUIPMENTS_SET_KEYS[equipment_set]
	var base_description = LocalizationManager.get_equipment_text("base_set_description")

	var params = {}
	var complementary_desc = ""
	if self.equipment_group == GROUPS.UNIQUES:
		var base_desc = "uniques.%s.description" % set_name_key
		var base_name = "uniques.%s.set_name" % set_name_key
		params = {"set_name": LocalizationManager.get_equipment_text(base_name)}
		complementary_desc = LocalizationManager.get_equipment_text(base_desc)
	else:
		var base_desc = "commons.%s.description" % set_name_key
		var base_name = "commons.%s.set_name" % set_name_key
		params = {"set_name": LocalizationManager.get_equipment_text(base_name)}
		complementary_desc = LocalizationManager.get_equipment_text(base_desc)

	base_description = LocalizationManager.format_text_with_params(base_description, params)
	return [base_description, complementary_desc]


func setup_base_values() -> void:
	if self.item_subcategory == Item.SUBCATEGORY.WEAPON:
		generate_damage_stats()
	else:
		generate_defense_stats()


func generate_damage_stats() -> void:
	var base_damage = calculate_base_damage()
	var rarity_multiplier = 1.0 + (item_rarity * 0.001)

	self.damage = ItemAttribute.new(ItemAttribute.TYPE.DAMAGE, base_damage)
	var min_value = self.damage.get_min_value_range()
	var max_value = self.damage.get_max_value_range()
	self.damage.value = clamp(
		randf_range(min_value, max_value) * rarity_multiplier, min_value, max_value
	)


func generate_defense_stats() -> void:
	var base_defense = calculate_base_defense()
	var rarity_multiplier = 1.0 + (item_rarity * 0.001)

	self.defense = ItemAttribute.new(ItemAttribute.TYPE.DEFENSE, base_defense)
	var min_value = self.defense.get_min_value_range()
	var max_value = self.defense.get_max_value_range()
	self.defense.value = clamp(
		randf_range(min_value, max_value) * rarity_multiplier, min_value, max_value
	)


func calculate_base_damage() -> float:
	var attribute_type = ItemAttribute.TYPE.DAMAGE
	var base_value = EquipmentConsts.EQUIPMENTS_STATS_BASE_VALUES[attribute_type]["base_value"]
	var factor = EquipmentConsts.EQUIPMENTS_STATS_BASE_VALUES[attribute_type]["factor"]
	var level_multiplier = 1.0 + (min(item_level, 100.0) * factor)
	base_value += base_value * (item_level * 0.03) * level_multiplier

	# Bônus para itens únicos
	if is_unique:
		base_value *= 1.5

	return base_value


func calculate_base_defense() -> float:
	var attribute_type = ItemAttribute.TYPE.DEFENSE
	var base_value = EquipmentConsts.EQUIPMENTS_STATS_BASE_VALUES[attribute_type]["base_value"]
	var factor = EquipmentConsts.EQUIPMENTS_STATS_BASE_VALUES[attribute_type]["factor"]
	var level_multiplier = 1.0 + (min(item_level, 100.0) * factor)
	base_value += base_value * (item_level * 0.015) * level_multiplier

	# Diferentes tipos de armadura têm defesa diferente
	match equipment_type:
		TYPE.ARMOR:
			base_value *= 1.5
		TYPE.HELMET:
			base_value *= 1.2
		TYPE.BOOTS:
			base_value *= 0.8
		TYPE.GLOVES:
			base_value *= 0.7
		TYPE.RING, TYPE.AMULET:
			base_value *= 0.5

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
	return all_attributes


func calculate_equipment_power() -> float:
	var power: float = 0.0

	# 1. Pontuação base por raridade (maior peso)
	var rarity_points = calculate_rarity_points()
	power += rarity_points

	# 2. Bônus por ser item único
	var unique_bonus = calculate_unique_bonus()
	power += unique_bonus

	# 3. Pontos por nível do item
	var level_points = calculate_level_points()
	power += level_points

	# 4. Pontos por atributos (quantidade e qualidade)
	var attributes_points = calculate_attributes_points()
	power += attributes_points

	# 5. Pontos por dano/defesa base (se aplicável)
	var base_stats_points = calculate_base_stats_points()
	power += base_stats_points

	# 6. Pontos por sockets (potencial de melhoria)
	var sockets_points = calculate_sockets_points()
	power += sockets_points

	return max(0, power)


func calculate_rarity_points() -> float:
	# Pontuação base por raridade com crescimento exponencial
	var base_points = 100.0  # Pontos base para item comum

	match item_rarity:
		Item.RARITY.COMMON:
			return base_points
		Item.RARITY.UNCOMMON:
			return base_points * 1.5
		Item.RARITY.RARE:
			return base_points * 2.5
		Item.RARITY.EPIC:
			return base_points * 4.0
		Item.RARITY.LEGENDARY:
			return base_points * 6.5
		Item.RARITY.MYTHICAL:
			return base_points * 10.0
		_:
			return base_points


func calculate_unique_bonus() -> float:
	if is_unique:
		# Bônus significativo para itens únicos (equivalente a ~1 nível de raridade extra)
		return calculate_rarity_points() * 0.4
	return 0.0


func calculate_level_points() -> float:
	# Pontos por nível com crescimento logarítmico (diminui o ganho em níveis muito altos)
	var base_level_points = 5.0
	return base_level_points * log(item_level + 1) * 2.0


func calculate_attributes_points() -> float:
	var points: float = 0.0

	if item_attributes.is_empty():
		return points

	# Pontos por quantidade de atributos (peso moderado)
	var quantity_points = item_attributes.size() * 25.0

	# Pontos por qualidade dos atributos (maior peso)
	var quality_points = 0.0

	for attribute in item_attributes:
		var attribute_value = attribute.value
		var min_value = attribute.get_min_value_range()
		var max_value = attribute.get_max_value_range()
		var value_range = max_value - min_value

		if value_range > 0:
			# Calcula a porcentagem do valor em relação ao range máximo possível
			var percentage = (attribute_value - min_value) / value_range

			# Sistema de pontuação que recompensa valores altos exponencialmente
			# Valores abaixo de 50% dão poucos pontos, acima de 100% dão bônus
			var base_attribute_points = 15.0

			if percentage <= 0.5:
				# Crescimento linear para valores baixos
				points += base_attribute_points * percentage * 0.8
			elif percentage <= 1.0:
				# Crescimento acelerado para valores médios/altos
				points += base_attribute_points * (0.4 + (percentage - 0.5) * 1.2)
			else:
				# Bônus para valores acima do máximo (overcap)
				points += base_attribute_points * (1.0 + (percentage - 1.0) * 1.5)

	return quantity_points + quality_points


func calculate_base_stats_points() -> float:
	var points: float = 0.0

	# Pontos por dano (para armas)
	if damage != null and damage.value > 0:
		var base_damage_points = damage.value * 0.8
		points += base_damage_points

	# Pontos por defesa (para armaduras e acessórios)
	if defense != null and defense.value > 0:
		var base_defense_points = defense.value * 0.6
		points += base_defense_points

	return points


func calculate_sockets_points() -> float:
	# Pontos por sockets disponíveis (potencial de melhoria futura)
	var base_socket_points = 15.0
	return available_sockets * base_socket_points


func add_gem_on_sockets(gem: GemItem) -> bool:
	if available_sockets > gems_in_sockets.size():
		gems_in_sockets.append(gem)
		# Adiciona os atributos da gemas aos atributos do equipamento
		# for attr in gem.item_attributes:
		# 	item_attributes.append(attr)
		return true
	return false


func remove_gem_from_sockets(gem: GemItem) -> bool:
	if gems_in_sockets.has(gem):
		gems_in_sockets.erase(gem)
		# Remove os atributos da gemas dos atributos do equipamento
		# for attr in gem.item_attributes:
		# 	if item_attributes.has(attr):
		# 		item_attributes.erase(attr)
		return true
	return false


func setup_texture() -> void:
	var equip_type_key = EquipmentConsts.EQUIPMENT_TYPE_KEYS[equipment_type]
	var equip_name_key = EquipmentConsts.EQUIPMENTS_SET_KEYS[equipment_set]

	var file_path = (
		"res://assets/sprites/items/equipments/%s/%s.png" % [equip_type_key, equip_name_key]
	)
	var texture = load_texture_with_fallback(
		file_path, "", str(" ", equip_type_key, "/", equip_name_key)
	)
	self.item_texture = texture
