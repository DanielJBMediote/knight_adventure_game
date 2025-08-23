class_name PotionItem
extends Item

const POTION_RESOURCE_NAMES := ItemAttribute.ATTRIBUTE_NAMES
const POTION_ATTRIBUTE_KEYS := ItemAttribute.ATTRIBUTE_KEYS

const POTION_WEIGHTS := {
	ItemAttribute.Type.HEALTH: 			60,		# 60% de chance
	ItemAttribute.Type.MANA:			15,		# 15% de chance  
	ItemAttribute.Type.ENERGY:			9,		# 9% de chance
	ItemAttribute.Type.DEFENSE: 		5,		# 5% de chance
	ItemAttribute.Type.DAMAGE: 			5,		# 5% de chance
	ItemAttribute.Type.CRITICAL_RATE:	2.5,	# 2,5% de chance
	ItemAttribute.Type.CRITICAL_DAMAGE:	2.5,	# 2,5% de chance
	ItemAttribute.Type.ATTACK_SPEED: 	0.5,	# 0.5% de chance
	ItemAttribute.Type.MOVE_SPEED:	 	0.5,	# 0.5% de chance
}

const BONUS_TABLE = {
	1: 0,    # nível 1
	10: 5,    # nível 10
	20: 15,   # nível 20
	30: 25,   # nível 30
	40: 30,   # nível 40
	50: 35,   # nível 50
	60: 40,   # nível 60
	70: 45,   # nível 70
	80: 50,   # nível 80
	90: 55,   # nível 90
	100: 60   # nível 100
}

const MAX_STACK = 99
const LEVEL_INTERVAL = 10
const BASE_POTION_VALUE := 100.0

@export var potion_type: ItemAttribute.Type

func _init() -> void:
	potion_type = get_random_potion_type()
	setup_values()
	setup_texture()

func setup_values() -> void:
	self.item_usable = true
	self.stackable = true
	self.max_stack = MAX_STACK
	self.item_category = ItemCategory.CONSUMABLES
	self.item_subcategory = ItemSubCategory.POTION
	self.item_level = calculate_potion_level()
	self.item_rarity = get_item_rarity_by_difficult_and_player_level()
	self.spawn_chance = calculate_potion_spawn_chance()
	self.item_action = setup_potion_action()
	self.item_name = set_potion_name()
	self.item_description = setup_potion_description()
	self.item_id = generate_potion_id()
	self.item_value = calculate_item_value(BASE_POTION_VALUE)

func calculate_potion_spawn_chance() -> float:
	var base_chance = 0.3  # 30% de chance base
	
	# Multiplicador baseado na raridade
	var rarity_multiplier = {
		ItemRarity.COMMON: 1.0,
		ItemRarity.UNCOMMON: 0.7,
		ItemRarity.RARE: 0.4,
		ItemRarity.EPIC: 0.2,
		ItemRarity.LEGENDARY: 0.1,
		ItemRarity.MYTHICAL: 0.05
	}
	
	# Multiplicador baseado no nível do item
	var level_multiplier = 1.0 - (item_level / 100)
	
	# Multiplicador baseado na diferença do nível do jogador
	var player_level = PlayerStats.level  # Assumindo que você tem acesso ao nível do jogador
	var map_level = GameEvents.current_map.level_mob_min
	var player_level_modifier = Item.get_player_level_modifier(player_level, map_level)
	
	# Calcula a chance final
	var current_difficulty = GameEvents.current_map.difficulty
	var difficulty_factor = GameEvents.get_drop_modificator(current_difficulty)
	var rarity_factor = rarity_multiplier.get(item_rarity, 1.0)
	
	var final_chance = base_chance * difficulty_factor * rarity_factor * level_multiplier * player_level_modifier
	
	# Garante que a chance esteja entre 1% e 100%
	return clamp(final_chance, 0.01, 1.0)

func generate_potion_id() -> String:
	var resource_name = str(POTION_RESOURCE_NAMES.get(potion_type, "UNKNOWN")).to_upper()
	var rarity_name = get_rarity_name(self.item_rarity).to_upper()
	return "POTION_%s_%s_L%d" % [resource_name, rarity_name, item_level]

func get_random_potion_type() -> ItemAttribute.Type:
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
	return ItemAttribute.Type.HEALTH

func set_potion_name() -> String:
	var potion_key = str("potion_", POTION_ATTRIBUTE_KEYS[potion_type])
	var base_name = LocalizationManager.get_item_name(potion_key)
	var rarity_prefix = get_rarity_prefix_name(self.item_rarity)
	
	return rarity_prefix + " " + base_name

func setup_potion_description() -> String:
	var action: ItemAction = get_item_action()
	var description_key = ""
	var params = {}
	
	if action.action_type == ItemAction.ActionType.INSTANTLY:
		description_key = "items.descriptions.potion_instant"
		params = {
			"amount": action.amount,
			"attribute": LocalizationManager.get_ui_attribute_name(action.attribute_key)
		}
	else:
		description_key = "items.descriptions.potion_buff"
		params = {
			"amount": action.amount,
			"attribute": LocalizationManager.get_ui_attribute_name(action.attribute_key),
			"duration": action.duration
		}
	
	var description = LocalizationManager.get_translation_format(description_key, params)
	
	# Adiciona informações adicionais
	var info_text = "\n\n{level_required}: {level_value}\n{rarity}: {rarity_value}"
	var info_params = {
		"level_required": LocalizationManager.get_ui_text("level_required"),
		"level_value": item_level,
		"rarity": LocalizationManager.get_ui_text("rarity"),
		"rarity_value": LocalizationManager.get_item_rarity_name(item_rarity),
	}
	
	description += LocalizationManager.format_text_with_params(info_text, info_params)
	
	return description

func calculate_instant_amount() -> float:
	var base_multiply = 1.0 if potion_type == ItemAttribute.Type.ENERGY else 5.0
	
	# Valores base para poção nível 1 comum
	var base_values = {
		ItemAttribute.Type.HEALTH: 600.0,
		ItemAttribute.Type.MANA: 10.0,
		ItemAttribute.Type.ENERGY: 15.0
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
		ItemAttribute.Type.DEFENSE:
			base_percentage = 15.0
		ItemAttribute.Type.DAMAGE:
			base_percentage = 15.0
		ItemAttribute.Type.CRITICAL_RATE:
			base_percentage = 15.0
		ItemAttribute.Type.CRITICAL_DAMAGE:
			base_percentage = 15.0
		ItemAttribute.Type.ATTACK_SPEED:
			base_percentage = 5.0
		ItemAttribute.Type.MOVE_SPEED:
			base_percentage = 0.0
	
	if [ItemAttribute.Type.ATTACK_SPEED, ItemAttribute.Type.MOVE_SPEED].has(potion_type):
		level_bonus = level_bonus / 2.0
	
	var total = base_percentage + level_bonus + rarity_bonus
	
	# Se for unico adiciona +50% do buff
	total += (total * 0.5) if is_unique else 0.0
	
	return total

func calculate_buff_level_bonus() -> float:
	var level_index: int = item_level
	if BONUS_TABLE.has(level_index):
		return min(100.0, BONUS_TABLE[level_index])
	else:
		return min(100.0, 60.0)  # Fallback

func calculate_buff_duration() -> float:
	# 30s de base
	var duration = 30.0 
	# Aumento de 30s por raidade - 0/30/60/90/120/150 segundos
	var rarity_bonus = item_rarity * 30.0
	# Se for unico adiciona 60s
	var unique_bonus = 60.0 if is_unique else 0.0 
	
	return duration + rarity_bonus + unique_bonus

func calculate_potion_level() -> int:
	var map_level = GameEvents.current_map.level_mob_min
	#var map_level = randi() % 100
	# Arredonda para baixo para o múltiplo de 10 mais próximo (1, 10, 20...)
	var potion_level = max(1, (floori(map_level / float(LEVEL_INTERVAL)) * LEVEL_INTERVAL))
	return potion_level

func setup_potion_action() -> ItemAction:
	var action = ItemAction.new()
	action.attribute_key = POTION_ATTRIBUTE_KEYS.get(potion_type, "")
	
	# Define se é instantâneo ou buff
	if potion_type in [ItemAttribute.Type.HEALTH, ItemAttribute.Type.MANA, ItemAttribute.Type.ENERGY]:
		action.action_type = ItemAction.ActionType.INSTANTLY
		action.amount = calculate_instant_amount()
		action.is_percentage = false
	else:
		action.action_type = ItemAction.ActionType.BUFF
		action.amount = calculate_buff_percentage()
		action.duration = calculate_buff_duration()
		action.is_percentage = true
	
	return action

func setup_texture() -> void:
	var potion_resource_name = get_potion_attribute_key(potion_type)
	var potion_rank = get_potion_rank()
	
	var file_path = str("res://assets/sprites/items/potions/"+potion_resource_name+potion_rank+".png")
	var basic_path = "res://assets/sprites/items/potions/%s_potion_01.png" % get_potion_attribute_key(potion_type)
	var resource_key = get_potion_attribute_key(potion_type)
	var texture = load_texture_with_fallback(file_path, basic_path, resource_key)
	self.item_texture = texture

func get_potion_rank() -> String:
	if item_level >= 60:
		return "_potion_03"
	elif item_level >= 30:
		return "_potion_02"
	else:
		return "_potion_01"

static func get_potion_attribute_key(potion_res: ItemAttribute.Type) -> String:
	match potion_res:
		ItemAttribute.Type.HEALTH: return "health"
		ItemAttribute.Type.MANA: return "mana"
		ItemAttribute.Type.ENERGY: return "energy"
		ItemAttribute.Type.DEFENSE: return "defense"
		ItemAttribute.Type.DAMAGE: return "damage"
		ItemAttribute.Type.CRITICAL_RATE: return "critical_rate"
		ItemAttribute.Type.CRITICAL_DAMAGE: return "critical_damage"
		ItemAttribute.Type.ATTACK_SPEED: return "attack_speed" 
		ItemAttribute.Type.MOVE_SPEED: return "move_speed" 
		_: return ""

static func sort_by_type(a: PotionItem, b: PotionItem, mode := "ASC"):
	if a.potion_type == b.potion_type:
		if mode == "ASC":
			return a.potion_type < b.potion_type
		else:
			return a.potion_type > b.potion_type
	return
