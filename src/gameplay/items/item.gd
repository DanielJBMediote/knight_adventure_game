class_name Item
extends Resource

enum RARITY { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHICAL }
const RARITY_KEYS = {
	RARITY.COMMON: "common",
	RARITY.UNCOMMON: "uncommon",
	RARITY.RARE: "rare",
	RARITY.EPIC: "epic",
	RARITY.LEGENDARY: "legendary",
	RARITY.MYTHICAL: "mythical",
}

enum CATEGORY { CONSUMABLES, EQUIPMENTS, LOOTS, QUEST, OTHERS }
const CATEGORY_KEYS = {
	CATEGORY.CONSUMABLES: "consumables",
	CATEGORY.EQUIPMENTS: "equipments",
	CATEGORY.LOOTS: "loots",
	CATEGORY.QUEST: "quest",
	CATEGORY.OTHERS: "others",
}

enum SUBCATEGORY { POTION, WEAPON, ARMOR, ACCESSORY, FOOD, EQUIPMENTS, GEM, RESOURCE }
const SUBCATEGORY_KEYS = {
	SUBCATEGORY.POTION: "potion",
	SUBCATEGORY.FOOD: "food",
	SUBCATEGORY.WEAPON: "weapon",
	SUBCATEGORY.ARMOR: "armor",
	SUBCATEGORY.ACCESSORY: "accessory",
	SUBCATEGORY.GEM: "gem",
	SUBCATEGORY.RESOURCE: "resource",
}

@export var item_id: String
@export var item_name: String
@export var item_description: String
@export var item_category: CATEGORY = CATEGORY.OTHERS
@export var item_subcategory: SUBCATEGORY = SUBCATEGORY.RESOURCE
@export var item_rarity: RARITY = RARITY.COMMON
@export var spawn_chance: float = 1.0  # 0-1 (0% a 100%)
@export var item_texture: Texture2D
@export var stackable: bool = false
@export var max_stack: int = 1
@export var current_stack: int = 1
@export var is_unique: bool = false
@export var item_price: int= 0
@export var item_level: int = 0
@export var item_usable: bool = false

var _item_action: ItemAction
var item_action: ItemAction:
	get():
		return _item_action
	set(value):
		_item_action = value

var _item_attributes: Array[ItemAttribute] = []
var item_attributes: Array[ItemAttribute]:
	get():
		return _item_attributes
	set(value):
		_item_attributes = value


func setup(enemy_stats: EnemyStats) -> void:
	return


func clone() -> Item:
	var clone = self.duplicate()

	if self.item_attributes:
		clone.item_attributes = self.item_attributes

	if self.item_action:
		clone.item_action = self.item_action.duplicate()

	return clone


func get_sort_value() -> int:
	return self.item_subcategory


static func generate_item_id(strings: Array[String]) -> String:
	return ("ITEM_ID_" + "".join(strings)).to_upper()


func calculate_item_price(base_value: int = 1) -> int:
	var value = base_value * 1000

	# Aplica o multiplicador de raridade
	value *= (1.0 + item_rarity * 0.5)

	# Aplica o multiplicador de nível (ex: nível 30 = +30%, nível 90 = +90%)
	var level_multiplier = 1.0 + (item_level * 0.1)
	value *= level_multiplier

	var attribute_multiplier := {
		ItemAttribute.TYPE.HEALTH: 1.0,
		ItemAttribute.TYPE.MANA: 1.2,
		ItemAttribute.TYPE.ENERGY: 1.5,
		ItemAttribute.TYPE.DEFENSE: 1.3,
		ItemAttribute.TYPE.DAMAGE: 1.8,
		ItemAttribute.TYPE.CRITICAL_RATE: 2.0,
		ItemAttribute.TYPE.CRITICAL_DAMAGE: 2.2,
		ItemAttribute.TYPE.ATTACK_SPEED: 2.5,
		ItemAttribute.TYPE.MOVE_SPEED: 1.7,
		ItemAttribute.TYPE.HEALTH_REGEN: 3.0,
		ItemAttribute.TYPE.MANA_REGEN: 2.8,
		ItemAttribute.TYPE.ENERGY_REGEN: 2.9,
		ItemAttribute.TYPE.EXP_BUFF: 4.0,
	}

	if is_unique:
		value *= 2.0

	if item_action:
		var attrib = item_action.attribute
		value *= attribute_multiplier.get(attrib, 1.0)

	if not item_attributes.is_empty():
		# Fator influenciado pelo valor do atributo, quanto maior o valor, mais caro
		var factor_attribute_quality = 0.0
		for attrib in item_attributes:
			value *= attribute_multiplier.get(attrib, 1.0)
			var percentage = attrib.value / attrib.base_value
			if percentage < 0.95:
				factor_attribute_quality += 0.0
			elif percentage < 1.15:
				factor_attribute_quality += 0.15
			elif percentage < 1.25:
				factor_attribute_quality += 0.35
			else:
				factor_attribute_quality += 0.50
		value *= (1.0 + factor_attribute_quality)

	# Garante que o valor seja pelo menos 1 e arredonda para 2 casas decimais
	value = max(1.0, value)
	return roundi(value)


## Calcula um modificador baseado na diferença entre nível do jogador e nível do mapa
static func get_player_level_modifier(player_level: int, map_level: int) -> float:
	var level_difference = player_level - map_level

	# Se jogador está em mapa de nível mais baixo: bônus
	if level_difference > 0:
		# +2% por nível de diferença, máximo +50% (25 níveis de diferença)
		return 1.0 + min(level_difference * 0.02, 0.5)

	# Se jogador está em mapa de nível mais alto: penalidade
	elif level_difference < 0:
		# -1% por nível de diferença, máximo -30%
		return 1.0 + max(level_difference * 0.01, -0.3)

	# Mesmo nível: neutro
	return 1.0


## Calcula um modificador de qualidade baseado na diferença de nível
static func get_quality_level_modifier(player_level: int, map_level: int) -> float:
	var level_difference = player_level - map_level

	# Jogador em mapa fácil: maior chance de itens de qualidade
	if level_difference > 10:  # +10 níveis acima do mapa
		return 1.5  # +50% de chance de raridade melhor

	elif level_difference > 5:  # +5 níveis acima
		return 1.25  # +25%

	# Jogador em mapa difícil: menor chance de itens de qualidade
	elif level_difference < -10:  # -10 níveis abaixo
		return 0.6  # -40%

	elif level_difference < -5:  # -5 níveis abaixo
		return 0.8  # -20%

	# Níveis similares: neutro
	return 1.0


## Calculate the Rarity of Item based on difficulty and player level
static func get_item_rarity_by_difficult_and_player_level(player_level: int, map_level: int, difficulty: int) -> RARITY:
	var rand_val = randf()

	# Ajusta as chances baseado na diferença de nível do jogador
	var quality_modifier = get_quality_level_modifier(player_level, map_level)

	# Chances base para cada dificuldade
	var base_thresholds = {
		GameEvents.DIFFICULTY.NORMAL: [0.70, 0.20, 0.07, 0.025, 0.004, 0.001],
		GameEvents.DIFFICULTY.PAINFUL: [0.50, 0.30, 0.12, 0.05, 0.025, 0.005],
		GameEvents.DIFFICULTY.FATAL: [0.30, 0.35, 0.20, 0.10, 0.04, 0.01],
		GameEvents.DIFFICULTY.INFERNAL: [0.15, 0.25, 0.30, 0.15, 0.10, 0.05]
	}

	# Aplica o modificador de qualidade (reduz chance de comum, aumenta chance de raro)
	var adjusted_thresholds = []
	for i in range(base_thresholds[difficulty].size()):
		var base_chance = base_thresholds[difficulty][i]

		if i == 0:  # Common - reduz com bônus de qualidade
			adjusted_thresholds.append(base_chance / quality_modifier)
		else:  # Raridades melhores - aumenta com bônus de qualidade
			adjusted_thresholds.append(base_chance * quality_modifier)

	# Normaliza para garantir que a soma seja 1.0
	var total = 0.0
	for chance in adjusted_thresholds:
		total += chance

	var normalized_thresholds = []
	for chance in adjusted_thresholds:
		normalized_thresholds.append(chance / total)

	# Escolhe a raridade baseado nas chances ajustadas
	var cumulative = 0.0
	var rarities = RARITY.values()

	for i in range(rarities.size()):
		cumulative += normalized_thresholds[i]
		if rand_val <= cumulative:
			return rarities[i]

	return RARITY.COMMON


func get_item_action(_item: Item = self) -> ItemAction:
	return _item.item_action


func get_item_attributes(_item: Item = self) -> Array[ItemAttribute]:
	return _item.item_attributes


## Returns the Category name of Item
static func get_category_text(_category_key: CATEGORY) -> String:
	var category_key = CATEGORY_KEYS[_category_key]
	return LocalizationManager.get_item_category_name_text(category_key)


static func get_subcategory_text(_subcategory_key: SUBCATEGORY) -> String:
	var subcategory_key = SUBCATEGORY_KEYS[_subcategory_key]
	return LocalizationManager.get_item_subcategory_name_text(subcategory_key)


## Returns de Rarity name of Item
static func get_rarity_text(_rarity: RARITY) -> String:
	var rarity_key = RARITY_KEYS[_rarity]
	return LocalizationManager.get_item_rarity_name_text(rarity_key)


static func get_rarity_prefix_text(_rarity: RARITY) -> String:
	var rarity_key = RARITY_KEYS[_rarity]
	return LocalizationManager.get_item_rarity_prefix_text(rarity_key)


static func get_rarity_sufix_text(_rarity: RARITY) -> String:
	var rarity_key = RARITY_KEYS[_rarity]
	return LocalizationManager.get_item_rarity_sufix_text(rarity_key)


func load_texture_with_fallback(file_path: String, fallback_path: String, attribute_key: String) -> Texture2D:
	# Primeiro tenta carregar a textura específica
	if FileAccess.file_exists(file_path):
		var texture = load(file_path)
		if texture is Texture2D:
			return texture
		else:
			printerr("-- File founded! But invalid texture: ", file_path)

	# Fallback 1: Tenta a versão básica sem rank
	if FileAccess.file_exists(fallback_path):
		var texture = load(fallback_path)
		if texture is Texture2D:
			print("Usando fallback básico para: ", attribute_key)
			return texture

	# Fallback 2: Textura de placeholder genérico
	#var placeholder_path = "res://assets/sprites/items/potions/placeholder_potion.png"
	#if FileAccess.file_exists(placeholder_path):
	#var texture = load(placeholder_path)
	#if texture is Texture2D:
	#printerr("Usando placeholder para poção: ", get_potion_resource_key(potion_type))
	#return texture

	# Fallback 3: Textura programática vermelha de erro
	printerr("Nenhuma textura encontrada para ", get_category_text(self.item_category), attribute_key)
	return create_error_texture()


## Cria uma textura vermelha de erro programaticamente
func create_error_texture() -> Texture2D:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)

	var texture = ImageTexture.create_from_image(image)
	return texture


static func get_random_rarity() -> RARITY:
	return randi() % RARITY.values().size()
