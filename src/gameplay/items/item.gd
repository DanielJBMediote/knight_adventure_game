class_name Item
extends Resource

enum RARITY {COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHICAL}
const RARITY_KEYS = {
	RARITY.COMMON: "common",
	RARITY.UNCOMMON: "uncommon",
	RARITY.RARE: "rare",
	RARITY.EPIC: "epic",
	RARITY.LEGENDARY: "legendary",
	RARITY.MYTHICAL: "mythical",
}

enum CATEGORY {CONSUMABLES, EQUIPMENTS, LOOTS, QUEST, MISCELLANEOUS}
const CATEGORY_KEYS = {
	CATEGORY.CONSUMABLES: "consumables",
	CATEGORY.EQUIPMENTS: "equipments",
	CATEGORY.LOOTS: "loots",
	CATEGORY.QUEST: "quest",
	CATEGORY.MISCELLANEOUS: "miscellaneous",
}

enum SUBCATEGORY {POTION, WEAPON, ARMOR, ACCESSORY, FOOD, EQUIPMENTS, GEM, RESOURCE}
const SUBCATEGORY_KEYS = {
	SUBCATEGORY.POTION: "potion",
	SUBCATEGORY.FOOD: "food",
	SUBCATEGORY.WEAPON: "weapon",
	SUBCATEGORY.ARMOR: "armor",
	SUBCATEGORY.ACCESSORY: "accessory",
	SUBCATEGORY.GEM: "gem",
	SUBCATEGORY.RESOURCE: "resource",
}

@export var item_id: String = ""
@export var item_name: String = ""
@export var item_descriptions: String = ""
@export var item_category: CATEGORY = CATEGORY.MISCELLANEOUS
@export var item_subcategory: SUBCATEGORY = SUBCATEGORY.RESOURCE
@export var item_rarity: RARITY = RARITY.COMMON
@export var item_texture: Texture2D = null
@export var item_price: int = 0
@export var item_level: int = 0
@export var item_usable: bool = false

@export var spawn_chance: float = 1.0
@export var stackable: bool = false
@export var max_stack: int = 1
@export var current_stack: int = 1
@export var is_unique: bool = false

## Reference of Inventory Slots
var slot_index_ref: int = -1

var _item_action: ItemAction
@export var item_action: ItemAction:
	get():
		return _item_action
	set(value):
		_item_action = value

var _item_attributes: Array[ItemAttribute] = []
@export var item_attributes: Array[ItemAttribute]:
	get():
		return _item_attributes
	set(value):
		_item_attributes = value


func setup(_enemy_stats: EnemyStats) -> void:
	return


## Use this instead duplicate() native function
func clone() -> Item:
	var copy = self.duplicate()

	copy.slot_index_ref = self.slot_index_ref

	if self.item_attributes:
		copy.item_attributes = self.item_attributes

	if self.item_action:
		copy.item_action = self.item_action.duplicate()
	
	return copy


func get_sort_value() -> int:
	return self.item_subcategory


func _generate_item_id(strings: Array[String]) -> String:
	var joined_strings = "_".join(strings)
	return ("ITEM_ID_" + joined_strings).to_upper()


func _calculate_item_price(base_value: int = 1) -> int:
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
		ItemAttribute.TYPE.EXP_BOOST: 4.0,
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


func get_item_action(_item: Item = self) -> ItemAction:
	return _item.item_action


func get_item_attributes(_item: Item = self) -> Array[ItemAttribute]:
	return _item.item_attributes

## Return de corresponding Color of item rarity
func get_item_rarity_text_color() -> Color:
	match item_rarity:
		RARITY.COMMON:
			return Color.WHITE_SMOKE
		RARITY.UNCOMMON:
			return Color.WEB_GREEN
		RARITY.RARE:
			return Color(0.2, 0.4, 0.6, 1.0)
		RARITY.EPIC:
			return Color(0.5, 0.0, 0.85, 1.0) # Roxo
		RARITY.LEGENDARY:
			return Color.ORANGE_RED
		RARITY.MYTHICAL:
			return Color.RED
		_:
			return Color.WHITE_SMOKE


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
			print("Using fallback to: ", attribute_key)
			return texture

	# Fallback 3: Textura programática vermelha de erro
	printerr("No texture found for: ", get_category_text(item_category), " ", attribute_key)
	return create_error_texture()


## Cria uma textura vermelha de erro programaticamente
func create_error_texture() -> Texture2D:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)

	var texture = ImageTexture.create_from_image(image)
	return texture

func save_data() -> Dictionary:
	return Utils.serialize_object(self)

static func load_data(data: Dictionary) -> Item:
	return Utils.deserialize_object(data) as Item

# func save_data() -> Dictionary:
# 	var saved_data = {
# 		"__resource_type": "Item",
# 		"item_id": item_id,
# 		"item_name": item_name,
# 		"item_descriptions": item_descriptions,
# 		"item_category": item_category,
# 		"item_subcategory": item_subcategory,
# 		"item_rarity": item_rarity,
# 		"item_price": item_price,
# 		"item_level": item_level,
# 		"item_usable": item_usable,
# 		"spawn_chance": spawn_chance,
# 		"stackable": stackable,
# 		"max_stack": max_stack,
# 		"current_stack": current_stack,
# 		"is_unique": is_unique,
# 		"slot_index_ref": slot_index_ref
# 	}
	
# 	# Adiciona a textura se existir
# 	if item_texture and item_texture.resource_path:
# 		saved_data["item_texture_path"] = item_texture.resource_path
	
# 	# Serializa o item_action
# 	if item_action:
# 		saved_data["item_action"] = item_action.save()
	
# 	# Serializa os atributos
# 	if not item_attributes.is_empty():
# 		var attributes_data = []
# 		for attr in item_attributes:
# 			attributes_data.append(attr.save())
# 		saved_data["item_attributes"] = attributes_data
	
# 	return saved_data

# func load_data(data: Dictionary) -> void:
# 	if data.is_empty():
# 		return
	
# 	# Carrega propriedades básicas
# 	item_id = data.get("item_id", "")
# 	item_name = data.get("item_name", "")
# 	item_descriptions = data.get("item_descriptions", [])
# 	item_category = data.get("item_category", CATEGORY.MISCELLANEOUS)
# 	item_subcategory = data.get("item_subcategory", SUBCATEGORY.RESOURCE)
# 	item_rarity = data.get("item_rarity", RARITY.COMMON)
# 	item_price = data.get("item_price", 0)
# 	item_level = data.get("item_level", 0)
# 	item_usable = data.get("item_usable", false)
# 	spawn_chance = data.get("spawn_chance", 1.0)
# 	stackable = data.get("stackable", false)
# 	max_stack = data.get("max_stack", 1)
# 	current_stack = data.get("current_stack", 1)
# 	is_unique = data.get("is_unique", false)
# 	slot_index_ref = data.get("slot_index_ref", -1)
	
# 	# Carrega a textura se existir caminho
# 	if data.has("item_texture_path"):
# 		var texture_path = data["item_texture_path"]
# 		if ResourceLoader.exists(texture_path):
# 			item_texture = load(texture_path)
	
# 	# Carrega o item_action
# 	if data.has("item_action"):
# 		var action_data = data["item_action"]
# 		if item_action == null:
# 			item_action = ItemAction.new()
# 		item_action.load_data(action_data)
	
# 	# Carrega os atributos
# 	if data.has("item_attributes"):
# 		var attributes_data = data["item_attributes"]
# 		item_attributes.clear()
# 		for attr_data in attributes_data:
# 			var attr = ItemAttribute.new()
# 			attr.load_data(attr_data)
# 			item_attributes.append(attr)


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
	if level_difference > 10: # +10 níveis acima do mapa
		return 1.5 # +50% de chance de raridade melhor

	elif level_difference > 5: # +5 níveis acima
		return 1.25 # +25%

	# Jogador em mapa difícil: menor chance de itens de qualidade
	elif level_difference < -10: # -10 níveis abaixo
		return 0.6 # -40%

	elif level_difference < -5: # -5 níveis abaixo
		return 0.8 # -20%

	# Níveis similares: neutro
	return 1.0


## Calculate the Rarity of Item based on difficulty and player level
static func get_item_rarity_by_difficult_and_player_level(
	player_level: int, map_level: int, difficulty: int
) -> RARITY:
	var rand_val = randf()

	# Ajusta as chances baseado na diferença de nível do jogador
	var quality_modifier = get_quality_level_modifier(player_level, map_level)

	# Chances base para cada dificuldade
	var base_thresholds = {
		GameManager.DIFFICULTY.NORMAL: [0.70, 0.20, 0.07, 0.025, 0.004, 0.001],
		GameManager.DIFFICULTY.PAINFUL: [0.50, 0.30, 0.12, 0.05, 0.025, 0.005],
		GameManager.DIFFICULTY.FATAL: [0.30, 0.35, 0.20, 0.10, 0.04, 0.01],
		GameManager.DIFFICULTY.INFERNAL: [0.15, 0.25, 0.30, 0.15, 0.10, 0.05]
	}

	# Aplica o modificador de qualidade (reduz chance de comum, aumenta chance de raro)
	var adjusted_thresholds = []
	for i in range(base_thresholds[difficulty].size()):
		var base_chance = base_thresholds[difficulty][i]

		if i == 0: # Common - reduz com bônus de qualidade
			adjusted_thresholds.append(base_chance / quality_modifier)
		else: # Raridades melhores - aumenta com bônus de qualidade
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


static func get_rarity_suffix_text(_rarity: RARITY) -> String:
	var rarity_key = RARITY_KEYS[_rarity]
	return LocalizationManager.get_item_rarity_suffix_text(rarity_key)


static func get_random_rarity() -> RARITY:
	return RARITY.get(randi() % RARITY.values().size())
