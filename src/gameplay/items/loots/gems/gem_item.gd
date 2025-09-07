class_name GemItem
extends Item

enum QUALITY {
	FRAGMENTED, # Lv 15 (Common)
	COMMON, # Lv 30 (Uncommon)
	REFINED, # Lv 45 (Rare)
	FLAWLESS, # Lv 60 (Epic)
	EXQUISITE, # Lv 75 (Legendary)
	PRISTINE, # Lv 90 (Mythical)
}

@export var gem_type: ItemAttribute.TYPE
@export var gem_quality: QUALITY
@export var num_runes_to_upgrade: int = 0
@export var price_to_upgrade: int = 0
@export var equip_slot_sockets: Array[EquipmentItem.TYPE]

func _init() -> void:
	pass

func get_sort_value() -> int:
	return gem_quality

func setup(enemy_stats: EnemyStats) -> void:
	gem_type = get_random_gem_type()
	
	self.stackable = true
	self.max_stack = GemConsts.MAX_STACKS
	self.item_category = Item.CATEGORY.LOOTS
	self.item_subcategory = Item.SUBCATEGORY.GEM
	self.item_level = calculate_gem_level(enemy_stats.level)
	self.gem_quality = get_gem_quality()
	#self.can_upgrade = can_upgrade_gem()
	self.spawn_chance = calculate_spawn_chance(enemy_stats.level)
	self.item_rarity = get_gem_rarity()
	self.item_action = null
	self.is_unique = setup_gem_unique()
	self.item_attributes = setup_gem_attributes()
	self.equip_slot_sockets = get_available_equip_slots()
	self.item_name = generate_gem_name()
	self.item_descriptions = generate_gem_descriptions()
	self.item_id = generate_gem_id()
	self.item_price = calculate_item_price(int(GemConsts.BASE_GEM_PRICE))
	self.num_runes_to_upgrade = GemConsts.NUM_RUNES_TO_UPGRADE if can_upgrade_gem() else 0
	self.price_to_upgrade = calculate_price_to_upgrade() if can_upgrade_gem() else 0
	self.item_texture = generate_gem_texture()

func can_upgrade_gem() -> bool:
	return gem_quality >= QUALITY.FRAGMENTED and gem_quality < QUALITY.PRISTINE


func calculate_gem_level(enemy_level: int) -> int:
	return clampi(floori(enemy_level / float(GemConsts.LEVEL_INTERVAL)) * GemConsts.LEVEL_INTERVAL, GemConsts.MIN_LEVEL, GemConsts.MAX_LEVEL)


func get_random_gem_type() -> ItemAttribute.TYPE:
	var total_weight: float = 0.0
	for weight in GemConsts.GEM_WEIGHTS.values():
		total_weight += weight

	var random_value = randf() * total_weight
	var cumulative: float = 0.0

	for _gem_type in GemConsts.GEM_WEIGHTS:
		cumulative += GemConsts.GEM_WEIGHTS[_gem_type]
		if random_value <= cumulative:
			return _gem_type

	return ItemAttribute.TYPE.HEALTH


func generate_gem_id() -> String:
	var quality = self.gem_quality
	var quality_str = GemConsts.GEM_QUALITY_KEY[quality]
	var type_str = ItemAttribute.ATTRIBUTE_KEYS[gem_type]
	var unique_str = "UNIQUE" if is_unique else ""
	var gem_id = generate_item_id(["GEM", quality_str, type_str, unique_str])
	return gem_id


func generate_gem_name() -> String:
	var quality = self.gem_quality
	var quality_name = LocalizationManager.get_gem_quality_text(quality)
	var type_str = ItemAttribute.ATTRIBUTE_KEYS[gem_type]
	var gem_type_name = LocalizationManager.get_gem_name_text(type_str)
	var base_name = "%s %s" % [quality_name, gem_type_name]
	if is_unique and gem_quality == QUALITY.PRISTINE:
		var unique_label = LocalizationManager.get_ui_text("unique")
		base_name = "%s %s" % [unique_label, base_name]
	return base_name


func generate_gem_descriptions() -> Array[String]:
	var type_str = ItemAttribute.ATTRIBUTE_KEYS.get(gem_type)
	var base_Description = LocalizationManager.get_gem_base_description_text(type_str)

	var quality = self.gem_quality
	var quality_name = LocalizationManager.get_gem_quality_text(quality)

	base_Description = LocalizationManager.format_text_with_params(base_Description, {"quality": quality_name})

	var unique_description = ""
	if is_unique:
		if gem_type in GemConsts.UNIQUE_GEMS_KEYS:
			unique_description = LocalizationManager.get_gem_unique_description_text(type_str)
		else:
			unique_description = LocalizationManager.get_gem_base_description_text("unique_gem")

	return [base_Description, unique_description]


func get_gem_quality() -> QUALITY:
	var level = self.item_level
	if level >= 75:
		return QUALITY.PRISTINE
	elif level >= 60:
		return QUALITY.EXQUISITE
	elif level >= 45:
		return QUALITY.FLAWLESS
	elif level >= 30:
		return QUALITY.REFINED
	elif level >= 15:
		return QUALITY.COMMON
	else:
		return QUALITY.FRAGMENTED


func get_gem_rarity() -> Item.RARITY:
	match gem_quality:
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


func get_preview_next_gem() -> GemItem:
	var next_gem = self.duplicate() as GemItem
	next_gem.gem_quality = get_next_quality()
	next_gem.item_level = get_level_for_quality(next_gem.gem_quality)
	next_gem.item_rarity = next_gem.get_gem_rarity()
	# next_gem.is_unique = next_gem.setup_gem_unique()
	next_gem.item_attributes = next_gem.setup_gem_attributes()
	next_gem.item_name = next_gem.generate_gem_name()
	next_gem.item_descriptions = next_gem.generate_gem_descriptions()
	next_gem.item_id = next_gem.generate_gem_id()
	next_gem.num_runes_to_upgrade = GemConsts.NUM_RUNES_TO_UPGRADE if next_gem.can_upgrade_gem() else 0
	next_gem.price_to_upgrade = next_gem.calculate_price_to_upgrade() if next_gem.can_upgrade_gem() else 0
	next_gem.item_texture = next_gem.generate_gem_texture()
	return next_gem


func is_valid_rune_for_upgrade(rune: RuneItem) -> bool:
	if not can_upgrade_gem():
		return false
	
	# Verifica se a runa tem a raridade correta para o upgrade
	var required_rune_rarity = get_required_rune_rarity_for_upgrade()
	return rune.item_rarity == required_rune_rarity


# Função para obter a raridade necessária da runa para upgrade
func get_required_rune_rarity_for_upgrade() -> Item.RARITY:
	match gem_quality:
		QUALITY.FRAGMENTED: # Upgrade para COMMON
			return Item.RARITY.UNCOMMON # Runa Lv15
		QUALITY.COMMON: # Upgrade para REFINED
			return Item.RARITY.RARE # Runa Lv30
		QUALITY.REFINED: # Upgrade para FLAWLESS
			return Item.RARITY.EPIC # Runa Lv45
		QUALITY.FLAWLESS: # Upgrade para EXQUISITE
			return Item.RARITY.LEGENDARY # Runa Lv60
		QUALITY.EXQUISITE: # Upgrade para PRISTINE
			return Item.RARITY.MYTHICAL # Runa Lv75
		_:
			return Item.RARITY.COMMON


func get_required_preview_rune_for_upgrade() -> RuneItem:
	var rune = RuneItem.new()

	var rune_type_keys = RuneConsts.RUNE_TO_ATTRIBUTE_MAPPING.keys()

	for rune_type in rune_type_keys:
		if RuneConsts.RUNE_TO_ATTRIBUTE_MAPPING[rune_type].has(self.gem_type):
			rune.rune_type = rune_type
			break

	rune.item_rarity = get_required_rune_rarity_for_upgrade()
	rune.item_level = rune.get_level_by_rarity()
	rune.item_name = rune.generate_rune_name()
	rune.item_descriptions = rune.generate_rune_descriptions()
	rune.item_id = rune.generate_rune_id()
	rune.item_texture = rune.generate_rune_texture()
	# rune.item_price = rune.calculate_item_price(RuneConsts.BASE_PRICE)
	return rune


static func get_next_gem_quality_by_required_rune(rune_rarity: Item.RARITY) -> QUALITY:
	match rune_rarity:
		Item.RARITY.UNCOMMON: # Runa Lv150
			return QUALITY.COMMON # Upgrade para COMMON
		Item.RARITY.RARE: # Runa Lv30
			return QUALITY.REFINED # Upgrade para REFINED
		Item.RARITY.EPIC: # Runa Lv45
			return QUALITY.FLAWLESS # Upgrade para FLAWLESS
		Item.RARITY.LEGENDARY: # Runa Lv60
			return QUALITY.EXQUISITE # Upgrade para EXQUISITE
		Item.RARITY.MYTHICAL: # Runa Lv75
			return QUALITY.PRISTINE # Upgrade para PRISTINE
		_:
			return QUALITY.FRAGMENTED


func upgrade_gem(runes: Array[Item], gems: Array[Item], quanity: int = 1) -> bool:
	var amount_gems_in_inventory = gems.reduce(func(acc, _gem): return acc + _gem.current_stack, -1) * quanity
	var amount_runes_in_inventory = runes.reduce(func(acc, _rune): return acc + _rune.current_stack, 0) * quanity
	
	if amount_gems_in_inventory == 0:
		# var message = LocalizationManager.get_gem_alert_text("gem_upgrade_max_gem")
		var message = "Not enought Gems of same type to upgrade."
		GameEvents.show_instant_message(message, InstantMessage.TYPE.WARNING)
		return false

	# Verifica se tem runas suficientes
	if amount_runes_in_inventory < num_runes_to_upgrade:
		var message = LocalizationManager.get_gem_alert_text("gem_upgrade_no_runes")
		GameEvents.show_instant_message(message, InstantMessage.TYPE.WARNING)
		return false

	if not can_upgrade_gem():
		var message = LocalizationManager.get_gem_alert_text("gem_upgrade_max_gem")
		GameEvents.show_instant_message(message, InstantMessage.TYPE.WARNING)
		return false

	if CurrencyManager.get_total_coins() < price_to_upgrade:
		var message = LocalizationManager.get_gem_alert_text("gem_upgrade_no_money")
		GameEvents.show_instant_message(message, InstantMessage.TYPE.WARNING)
		return false

	# Verifica se o nível do jogador é suficiente
	if PlayerStats.level < self.item_level:
		var message = LocalizationManager.get_gem_alert_text("gem_upgrade_level_required")
		GameEvents.show_instant_message(message, InstantMessage.TYPE.DANGER)
		return false
	
	# Verifica se todas as runas são válidas
	for rune in runes:
		if not is_valid_rune_for_upgrade(rune):
			return false
	
	var new_gem: GemItem = clone()
	# Realiza o upgrade
	var next_quality = get_next_quality()
	if next_quality != null:
		new_gem.gem_quality = next_quality
		new_gem.item_level = new_gem.get_level_for_quality(next_quality)
		new_gem.item_rarity = new_gem.get_gem_rarity()
		new_gem.num_runes_to_upgrade = GemConsts.NUM_RUNES_TO_UPGRADE if new_gem.can_upgrade_gem() else 0
		new_gem.price_to_upgrade = new_gem.calculate_price_to_upgrade() if new_gem.can_upgrade_gem() else 0
		new_gem.item_id = new_gem.generate_gem_id()
		new_gem.item_name = new_gem.generate_gem_name()
		new_gem.item_descriptions = new_gem.generate_gem_descriptions()
		new_gem.is_unique = new_gem.setup_gem_unique()
		new_gem.item_attributes = new_gem.setup_gem_attributes()
		new_gem.item_texture = new_gem.generate_gem_texture()
		new_gem.current_stack = quanity
		
		
		if InventoryManager.add_item(new_gem):
			CurrencyManager.remove_coins(price_to_upgrade)
			InventoryManager.remove_items(runes, quanity * num_runes_to_upgrade)
			InventoryManager.remove_items(gems, quanity * 2)
			
			var message = LocalizationManager.get_gem_alert_text("gem_upgrade_success")
			message = LocalizationManager.format_text_with_params(message, {"amount": quanity, "gem": new_gem.item_name})
			GameEvents.show_instant_message(message, InstantMessage.TYPE.WARNING)
			return true
		else:
			var message = LocalizationManager.get_gem_alert_text("gem_no_slots_free")
			GameEvents.show_instant_message(message, InstantMessage.TYPE.WARNING)
			return false

	return false


func get_next_quality() -> QUALITY:
	match gem_quality:
		QUALITY.FRAGMENTED:
			return QUALITY.COMMON
		QUALITY.COMMON:
			return QUALITY.REFINED
		QUALITY.REFINED:
			return QUALITY.FLAWLESS
		QUALITY.FLAWLESS:
			return QUALITY.EXQUISITE
		QUALITY.EXQUISITE:
			return QUALITY.PRISTINE
		_:
			return QUALITY.COMMON # Não deveria acontecer


func get_level_for_quality(quality: QUALITY) -> int:
	match quality:
		QUALITY.FRAGMENTED:
			return 5
		QUALITY.COMMON:
			return 15
		QUALITY.REFINED:
			return 30
		QUALITY.FLAWLESS:
			return 45
		QUALITY.EXQUISITE:
			return 60
		QUALITY.PRISTINE:
			return 75
		_:
			return 5


func calculate_spawn_chance(enemy_level: int) -> float:
	var base_chance = 1.0 if enemy_level >= GemConsts.MIN_LEVEL else 0.0

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

	var calculated_spawn_chance = base_chance * quality_modifier * difficulty_modifier * level_modifier
	return clamp(calculated_spawn_chance, 0.01, 1.0)


func setup_gem_attributes() -> Array[ItemAttribute]:
	var attributes: Array[ItemAttribute] = []
	var attribute = ItemAttribute.new(gem_type, 0)
	attribute.type = gem_type
	attribute.value = calculate_final_attribute_value()

	if self.gem_quality == QUALITY.PRISTINE and is_unique:
		attribute.value *= 1.5

	attributes.append(attribute)
	return attributes


func calculate_final_attribute_value(_gem_type: ItemAttribute.TYPE = gem_type) -> float:
	var base_value = GemConsts.BASE_VALUES[_gem_type]
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


func get_number_of_runes_to_upgrade() -> int:
	return GemConsts.NUM_RUNES_TO_UPGRADE

func setup_gem_unique() -> bool:
	# Gemas dos tipos únicos são sempre únicas
	if gem_type in GemConsts.UNIQUE_GEMS_KEYS:
		return true

	# Gemas Mythical (PRISTINE) têm 50% de chance de serem únicase terem 1 atributo a mais
	if self.gem_quality == QUALITY.PRISTINE:
		return randf() <= 0.5

	return false


func calculate_price_to_upgrade() -> int:
	var base_price = self.item_price
	var quality_multiplier = get_quality_multiplier()
	var rune_cost = num_runes_to_upgrade * self.item_price * 0.1 # Cada runa custa 10% do preço da gema atual
	return int(base_price * quality_multiplier + rune_cost)


func generate_gem_texture() -> Texture2D:
	var color = GemConsts.GEM_COLOR_NAME_KEY.get(gem_type, "default")
	var quality_key = GemConsts.GEM_QUALITY_KEY[self.gem_quality]

	var file_path = ""
	if is_unique and gem_type in GemConsts.UNIQUE_GEMS_KEYS:
		var name_key = GemConsts.UNIQUE_GEMS_KEYS[gem_type]
		file_path = "res://assets/sprites/items/gems/gem_%s.png" % [name_key]
	else:
		file_path = "res://assets/sprites/items/gems/gem_%s_%s.png" % [quality_key, color]

	var attribute_key = ItemAttribute.ATTRIBUTE_KEYS[gem_type]
	return load_texture_with_fallback(file_path, "", attribute_key)


func get_available_equip_slots() -> Array[EquipmentItem.TYPE]:
	var available_slots: Array[EquipmentItem.TYPE] = []
	
	# Percorre todos os tipos de equipamento e verifica se este tipo de atributo (gem_type)
	# está na lista de atributos permitidos para cada tipo de equipamento
	for equipment_type in EquipmentConsts.ALLOWED_ATTRIBUTES_PER_TYPE:
		var allowed_attributes: Array = EquipmentConsts.ALLOWED_ATTRIBUTES_PER_TYPE[equipment_type]
		if gem_type in allowed_attributes:
			available_slots.append(equipment_type)
	
	# Garante que todas as gemas possam ser equipadas em anéis e amuletos
	# (já que a ALLOWED_ATTRIBUTES_PER_TYPE pode não incluir todos os atributos para estes slots)
	if gem_type in [
		ItemAttribute.TYPE.DAMAGE,
		ItemAttribute.TYPE.ENERGY,
		ItemAttribute.TYPE.CRITICAL_RATE,
		ItemAttribute.TYPE.CRITICAL_DAMAGE,
		ItemAttribute.TYPE.MANA
	]:
		if EquipmentItem.TYPE.RING not in available_slots:
			available_slots.append(EquipmentItem.TYPE.RING)
		if EquipmentItem.TYPE.AMULET not in available_slots:
			available_slots.append(EquipmentItem.TYPE.AMULET)
	
	return available_slots


static func get_gem_attribute_key(_gem_type: ItemAttribute.TYPE) -> String:
	return ItemAttribute.ATTRIBUTE_KEYS[_gem_type]
