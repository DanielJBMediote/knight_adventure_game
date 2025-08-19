class_name PotionItem
extends Item

enum PotionResource { 
	HEALTH, 
	MANA, 
	ENERGY,
	DEFENSE, 
	CRITICAL_RATE, 
	CRITICAL_DAMAGE, 
	DAMAGE,
	ATTACK_SPEED,
	MOVE_SPEED
}

const POTION_RESOURCE_NAMES := {
	PotionResource.HEALTH: "Health",
	PotionResource.MANA: "Mana",
	PotionResource.ENERGY: "Energy",
	PotionResource.DEFENSE: "Defense",
	PotionResource.DAMAGE: "Damage",
	PotionResource.CRITICAL_RATE: "Critical Rate",
	PotionResource.CRITICAL_DAMAGE: "Critical Damage",
	PotionResource.ATTACK_SPEED: "Attack Speed", 
	PotionResource.MOVE_SPEED: "Move Speed", 
}

const POTION_WEIGHTS := {
	PotionResource.HEALTH: 			40,		# 40% de chance
	PotionResource.MANA:			15,		# 15% de chance  
	PotionResource.ENERGY:			10,		# 10% de chance
	PotionResource.DEFENSE: 		5,		# 5% de chance
	PotionResource.DAMAGE: 			5,		# 5% de chance
	PotionResource.CRITICAL_RATE:	5,		# 5% de chance
	PotionResource.CRITICAL_DAMAGE:	5,		# 5% de chance
	PotionResource.ATTACK_SPEED: 	5,		# 5% de chance
	PotionResource.MOVE_SPEED:	 	5,		# 5% de chance
}

const ATTRIBUTE_KEYS := {
	PotionResource.HEALTH: "health",
	PotionResource.MANA: "mana",
	PotionResource.ENERGY: "energy",
	PotionResource.DEFENSE: "defense",
	PotionResource.DAMAGE: "damage",
	PotionResource.CRITICAL_RATE: "critical_rate",
	PotionResource.CRITICAL_DAMAGE: "critical_damage",
	PotionResource.ATTACK_SPEED: "attack_speed",
	PotionResource.MOVE_SPEED: "move_speed",
}

const MAX_STACK = 99
const LEVEL_INTERVAL = 10  # A cada 10 níveis aumenta o tier

@export var potion_resource: PotionResource

func _init() -> void:
	potion_resource = get_random_potion_type()
	
	setup_values()
	setup_texture()

func setup_values() -> void:
	self.stackable = true
	self.max_stack = MAX_STACK
	self.item_category = ItemCategory.CONSUMABLES
	self.item_subcategory = ItemSubCategory.POTION
	
	self.item_name = set_item_name()
	self.item_level = calculate_potion_level()
	self.spawn_chance = calculate_spawn_chance()
	self.item_rarity = Item.calculate_rarity(GameEvents.current_map.difficulty)
	self.item_action = setup_action()
	self.item_description = setup_description()
	
	self.item_id = generate_potion_id()

func generate_potion_id() -> String:
	var resource_name = POTION_RESOURCE_NAMES.get(potion_resource, "UNKNOWN")
	var rarity_name = get_rarity_name().to_upper()
	return "POTION_%s_%s_L%d" % [resource_name, rarity_name, item_level]

func get_random_potion_type() -> PotionResource:
	var total_weight = 0
	for weight in POTION_WEIGHTS.values():
		total_weight += weight
	
	var random_value = randi() % total_weight
	var cumulative_weight = 0
	
	for potion_type in POTION_WEIGHTS:
		cumulative_weight += POTION_WEIGHTS[potion_type]
		if random_value < cumulative_weight:
			#print("Creating potion of ", get_potion_resource_key(potion_type))
			return potion_type
	
	# Fallback (nunca deve acontecer)
	return PotionResource.HEALTH

func set_item_name() -> String:
	var base_name = POTION_RESOURCE_NAMES.get(potion_resource, "Unknown")
	var rarity_prefix = get_rarity_prefix_name()
	
	return rarity_prefix + " " + base_name + " Potion"

func setup_description() -> String:
	var action = setup_action()
	var description_key = ""
	var params = {}
	
	if action.action_type == ItemAction.ActionType.INSTANTLY:
		description_key = "descriptions.potion_instant"
		params = {
			"amount": action.amount,
			"attribute": LocalizationManager.get_item_attribute_name(action.attribute_key)
		}
	else:
		description_key = "descriptions.potion_buff"
		params = {
			"amount": action.amount,
			"attribute": LocalizationManager.get_item_attribute_name(action.attribute_key),
			"duration": action.duration
		}
	
	var description = LocalizationManager.get_translation_format(description_key, params)
	
	# Adiciona informações adicionais
	var info_text = "\n\n{level}: {level_value} | {rarity}: {rarity_value}"
	var info_params = {
		"level": LocalizationManager.get_ui_text("level"),
		"level_value": item_level,
		"rarity": LocalizationManager.get_ui_text("rarity"),
		"rarity_value": LocalizationManager.get_item_rarity_name(item_rarity),
		#"id": LocalizationManager.get_ui_text("id"),
		#"id_value": item_id
	}
	
	description += LocalizationManager.get_translation_format(info_text, info_params)
	
	return description

func calculate_instant_amount() -> float:
	var base_amount = 0.0
	var level_multiplier = 1.0 + (item_level / float(LEVEL_INTERVAL)) * 0.5
	
	match potion_resource:
		PotionResource.HEALTH:
			base_amount = 20.0
		PotionResource.MANA:
			base_amount = 15.0
		PotionResource.ENERGY:
			base_amount = 10.0
	
	# Aumenta pela raridade
	var rarity_multiplier = 1.0 + item_rarity * 0.2
	
	return round(base_amount * level_multiplier * rarity_multiplier)

func calculate_buff_percentage() -> float:
	var base_percentage = 0.0
	var level_bonus = (item_level / float(LEVEL_INTERVAL)) * 5.0
	
	match potion_resource:
		PotionResource.DEFENSE:
			base_percentage = 20.0
		PotionResource.DAMAGE:
			base_percentage = 10.0
		PotionResource.CRITICAL_RATE:
			base_percentage = 10.0
		PotionResource.CRITICAL_DAMAGE:
			base_percentage = 10.0
		PotionResource.ATTACK_SPEED:
			base_percentage = 10.0
		PotionResource.MOVE_SPEED:
			base_percentage = 10.0
	
	# Aumenta pela raridade
	var rarity_bonus = item_rarity * 5.0
	
	return base_percentage + level_bonus + rarity_bonus

func calculate_buff_duration() -> float:
	var base_duration = 30.0  # 30 segundos base
	var level_bonus = (item_level / float(LEVEL_INTERVAL)) * 10.0
	var rarity_bonus = item_rarity * 15.0
	
	return base_duration + level_bonus + rarity_bonus

func calculate_potion_level() -> int:
	var map_level = GameEvents.current_map.level_mob_min
	# Arredonda para baixo para o múltiplo de 10 mais próximo (1, 10, 20...)
	var potion_level = max(1, (floori(map_level / float(LEVEL_INTERVAL)) * LEVEL_INTERVAL))
	return potion_level

func calculate_spawn_chance() -> float:
	var base_chance = 0.25  # 25% de chance base
	# Diminui a chance em 5% por tier de nível
	var level_penalty = min(0.5, (self.item_level / float(LEVEL_INTERVAL)) * 0.05)
	# Ajusta pela dificuldade
	var difficulty_multiplier = {
		GameEvents.Difficulty.NORMAL: 1.0,
		GameEvents.Difficulty.PAINFUL: 0.9,
		GameEvents.Difficulty.FATAL: 0.8,
		GameEvents.Difficulty.INFERNAL: 0.7
	}[GameEvents.current_map.difficulty]
	
	return clamp(base_chance - level_penalty, 0.1, 1.0) * difficulty_multiplier

func setup_action() -> ItemAction:
	var action = ItemAction.new()
	action.attribute_key = ATTRIBUTE_KEYS.get(potion_resource, "")
	
	# Define se é instantâneo ou buff
	if potion_resource in [PotionResource.HEALTH, PotionResource.MANA, PotionResource.ENERGY]:
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
	var potion_resource_name = get_potion_resource_key(potion_resource)
	var potion_rank = get_potion_rank()
	
	var file_path = str("res://assets/sprites/items/potions/"+potion_resource_name+potion_rank+".png")
	var texture = load_texture_with_fallback(file_path)
	self.item_texture = texture

func get_potion_rank() -> String:
	if item_level >= 60:
		return "_potion_03"
	elif item_level >= 30:
		return "_potion_02"
	else:
		return "_potion_01"

func load_texture_with_fallback(file_path: String) -> Texture2D:
	# Primeiro tenta carregar a textura específica
	if FileAccess.file_exists(file_path):
		var texture = load(file_path)
		if texture is Texture2D:
			return texture
		else:
			printerr("Arquivo encontrado mas não é uma textura válida: ", file_path)
	
	# Fallback 1: Tenta a versão básica sem rank
	var basic_path = "res://assets/sprites/items/potions/%s_potion_01.png" % get_potion_resource_key(potion_resource)
	if FileAccess.file_exists(basic_path):
		var texture = load(basic_path)
		if texture is Texture2D:
			print("Usando fallback básico para: ", get_potion_resource_key(potion_resource))
			return texture
	
	# Fallback 2: Textura de placeholder genérico
	#var placeholder_path = "res://assets/sprites/items/potions/placeholder_potion.png"
	#if FileAccess.file_exists(placeholder_path):
		#var texture = load(placeholder_path)
		#if texture is Texture2D:
			#printerr("Usando placeholder para poção: ", get_potion_resource_key(potion_resource))
			#return texture
	
	# Fallback 3: Textura programática vermelha de erro
	printerr("Nenhuma textura encontrada para poção: ", get_potion_resource_key(potion_resource))
	return create_error_texture()

func create_error_texture() -> Texture2D:
	# Cria uma textura vermelha de erro programaticamente
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func get_potion_resource_key(potion_res: PotionResource) -> String:
	match potion_res:
		PotionResource.HEALTH: return "health"
		PotionResource.MANA: return "mana"
		PotionResource.ENERGY: return "energy"
		PotionResource.DEFENSE: return "defense"
		PotionResource.DAMAGE: return "damage"
		PotionResource.CRITICAL_RATE: return "critical_rate"
		PotionResource.CRITICAL_DAMAGE: return "critical_damage"
		PotionResource.ATTACK_SPEED: return "attack_speed" 
		PotionResource.MOVE_SPEED: return "move_speed" 
		_: return ""
