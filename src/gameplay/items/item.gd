class_name Item
extends Node

enum ItemCategory { CONSUMABLES, EQUIPMENT, LOOTS, QUEST, OTHERS }
enum ItemSubCategory { POTION, FOOD, WEAPON, ARMOR, ACCESSORY, GEM, RESOURCE }
enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHICAL }

@export var item_id: String
@export var item_name: String
@export var item_description: String
@export var item_category: ItemCategory = ItemCategory.OTHERS
@export var item_subcategory: ItemSubCategory = ItemSubCategory.RESOURCE
@export var item_rarity: ItemRarity = ItemRarity.COMMON
@export var spawn_chance: float = 1.0  # 0-1 (0% a 100%)
@export var item_texture: Texture2D
@export var stackable: bool = false
@export var max_stack: int = 1
@export var current_stack: int = 1
@export var is_unique: bool = false
@export var item_value: float = 0.0
@export var item_level: int = 0
@export var item_usable: bool = false

var _item_action: ItemAction
var item_action: ItemAction:
	get(): return _item_action
	set(value): _item_action = value
	
var _item_attributes: Array[ItemAttribute]
var item_attributes: Array[ItemAttribute]:
	get(): return _item_attributes
	set(value): _item_attributes = value

func _duplicate(_item: Item = self) -> Item:
	var copy = _item.duplicate()
	if _item.item_attributes:
		copy.item_attributes = _item.item_attributes.duplicate()
	return copy

func calculate_item_value(base_value: float = 1.0) -> float:
	var value = base_value
	
	var rarity_multiply := {
		ItemRarity.COMMON: 1.0,
		ItemRarity.UNCOMMON: 1.5,
		ItemRarity.RARE: 2.0,
		ItemRarity.EPIC: 2.5,
		ItemRarity.LEGENDARY: 3.0,
		ItemRarity.MYTHICAL: 4.0,
	}
	
	# Aplica o multiplicador de raridade
	value *= rarity_multiply[item_rarity]
	
	# Aplica o multiplicador de nível (ex: nível 30 = 1.3x, nível 90 = 1.9x)
	var level_multiplier = 1.0 + (item_level / 100.0)
	value *= level_multiplier
	
	# Adiciona bônus para gemas únicas
	if is_unique:
		value *= 2.0
	
	if not item_attributes.is_empty():
		var attribute_multiplier := {
			ItemAttribute.Type.HEALTH: 1.0,
			ItemAttribute.Type.MANA: 1.2,
			ItemAttribute.Type.ENERGY: 1.5,
			ItemAttribute.Type.DEFENSE: 1.3,
			ItemAttribute.Type.DAMAGE: 1.8,
			ItemAttribute.Type.CRITICAL_RATE: 2.0,
			ItemAttribute.Type.CRITICAL_DAMAGE: 2.2,
			ItemAttribute.Type.ATTACK_SPEED: 2.5,
			ItemAttribute.Type.MOVE_SPEED: 1.7,
			ItemAttribute.Type.HEALTH_REGEN: 3.0,
			ItemAttribute.Type.MANA_REGEN: 2.8,
			ItemAttribute.Type.ENERGY_REGEN: 2.9,
			ItemAttribute.Type.EXP_BUFF: 4.0,
		}
		for attrib in item_attributes:
			value *= attribute_multiplier.get(attrib, 1.0)
	
	# Garante que o valor seja pelo menos 1 e arredonda para 2 casas decimais
	value = max(1.0, value)
	return snapped(value, 0.01)

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

## Retorna um fator para spawn de acordo com a dificuldade.
## Ajustado pela dificuldade, quanto maior mais chance se spawn
func get_factor_item_spawn_chance_by_difficult() -> float:
	var base_chance = 1.0
	
	var difficulty_multiplier = {
		GameEvents.Difficulty.NORMAL: 0.5,
		GameEvents.Difficulty.PAINFUL: 0.6,
		GameEvents.Difficulty.FATAL: 0.7,
		GameEvents.Difficulty.INFERNAL: 0.8
	}[GameEvents.current_map.difficulty]
	
	return clamp(base_chance - difficulty_multiplier, 0.1, 1.0)

## Calculate the Rarity of Item based on difficulty and player level
func get_item_rarity_by_difficult_and_player_level(player_level: int = PlayerStats.level) -> ItemRarity:
	var difficulty: GameEvents.Difficulty = max(GameEvents.current_map.difficulty, GameEvents.Difficulty.NORMAL)
	var map_level = GameEvents.current_map.level_mob_min
	
	var rand_val = randf()
	
	# Ajusta as chances baseado na diferença de nível do jogador
	var quality_modifier = get_quality_level_modifier(player_level, map_level)
	
	# Chances base para cada dificuldade
	var base_thresholds = {
		GameEvents.Difficulty.NORMAL: [0.70, 0.20, 0.07, 0.025, 0.004, 0.001],
		GameEvents.Difficulty.PAINFUL: [0.50, 0.30, 0.12, 0.05, 0.025, 0.005],
		GameEvents.Difficulty.FATAL: [0.30, 0.35, 0.20, 0.10, 0.04, 0.01],
		GameEvents.Difficulty.INFERNAL: [0.15, 0.25, 0.30, 0.15, 0.10, 0.05]
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
	var rarities = ItemRarity.values()
	
	for i in range(rarities.size()):
		cumulative += normalized_thresholds[i]
		if rand_val <= cumulative:
			return rarities[i]
	
	return ItemRarity.COMMON

func get_item_action(_item: Item = self) -> ItemAction:
	return _item.item_action

func get_item_attributes(_item: Item = self) -> Array[ItemAttribute]:
	return _item.item_attributes


## Returns the Category name of Item 
static func get_caategory_name(_category: ItemCategory) -> String:
	match _category:
		ItemCategory.CONSUMABLES: return LocalizationManager.get_item_name("category.consumables")
		ItemCategory.EQUIPMENT: return LocalizationManager.get_item_name("category.equipments")
		ItemCategory.LOOTS: return LocalizationManager.get_item_name("category.loots")
		ItemCategory.QUEST: return LocalizationManager.get_item_name("category.quest")
		ItemCategory.OTHERS: return LocalizationManager.get_item_name("category.others")
		_: return ""

static func get_sub_Category_name(_sub_category: ItemSubCategory) -> String:
	match _sub_category:
		ItemSubCategory.POTION: return LocalizationManager.get_item_name("sub_category.potion")
		ItemSubCategory.FOOD: return LocalizationManager.get_item_name("sub_category.food")
		ItemSubCategory.WEAPON: return LocalizationManager.get_item_name("sub_category.weapon")
		ItemSubCategory.ARMOR : return LocalizationManager.get_item_name("sub_category.armor")
		ItemSubCategory.ACCESSORY: return LocalizationManager.get_item_name("sub_category.accessory")
		ItemSubCategory.GEM: return LocalizationManager.get_item_name("sub_category.gem")
		ItemSubCategory.RESOURCE: return LocalizationManager.get_item_name("sub_category.resource")
		_: return ""
	
## Returns de Rarity name of Item 
static func get_rarity_name(_item_rarity: ItemRarity) -> String:
	match _item_rarity:
		ItemRarity.UNCOMMON: return LocalizationManager.get_item_name("rarity.uncommon")
		ItemRarity.RARE: return LocalizationManager.get_item_name("rarity.rare")
		ItemRarity.EPIC: return LocalizationManager.get_item_name("rarity.epic")
		ItemRarity.LEGENDARY: return LocalizationManager.get_item_name("rarity.legendary")
		ItemRarity.MYTHICAL: return LocalizationManager.get_item_name("rarity.mythical")
		_: return ""
		
## Returns the Rarity prefix name of Item base on Localizations/{local}.json file.
## Default is setted en.json: [ "", "Improved", "Superior", "Epic", "Legendary", "Mythical" ]
static func get_rarity_prefix_name(_rarity: ItemRarity) -> String:
	match _rarity:
		ItemRarity.UNCOMMON: return LocalizationManager.get_item_name("rarity_prefix.uncommon")
		ItemRarity.RARE: return LocalizationManager.get_item_name("rarity_prefix.rare")
		ItemRarity.EPIC: return LocalizationManager.get_item_name("rarity_prefix.epic")
		ItemRarity.LEGENDARY: return LocalizationManager.get_item_name("rarity_prefix.legendary")
		ItemRarity.MYTHICAL: return LocalizationManager.get_item_name("rarity_prefix.mythical")
		_: return ""

func load_texture_with_fallback(file_path: String, fallback_path: String, attribute_key: String) -> Texture2D:
	# Primeiro tenta carregar a textura específica
	if FileAccess.file_exists(file_path):
		var texture = load(file_path)
		if texture is Texture2D:
			return texture
		else:
			printerr("Arquivo encontrado mas não é uma textura válida: ", file_path)
	
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
	printerr("Nenhuma textura encontrada para ", get_caategory_name(self.item_category) , attribute_key)
	return create_error_texture()

## Cria uma textura vermelha de erro programaticamente
func create_error_texture() -> Texture2D:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func get_random_rarity() -> ItemRarity:
	return randi() % ItemRarity.values().size()
