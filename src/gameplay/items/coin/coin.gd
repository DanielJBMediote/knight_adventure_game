class_name Coin
extends Resource

const BRONZE_COIN = preload("res://assets/sprites/items/icons/bronze_coin.png")
const SILVER_COIN = preload("res://assets/sprites/items/icons/silver_coin.png")
const GOLD_COIN = preload("res://assets/sprites/items/icons/gold_coin.png")

const BRONZE_SMALL_COIN = preload("res://assets/sprites/items/icons/bronze_small_coin.png")
const SILVER_SMALL_COIN = preload("res://assets/sprites/items/icons/silver_small_coin.png")
const GOLD_SMALL_COIN = preload("res://assets/sprites/items/icons/gold_small_coin.png")

const BRONZE_HUGE_COIN = preload("res://assets/sprites/items/icons/bronze_huge_coin.png")
const SILVER_HUGE_COIN = preload("res://assets/sprites/items/icons/silver_huge_coin.png")
const GOLD_HUGE_COIN = preload("res://assets/sprites/items/icons/gold_huge_coin.png")

enum TYPE {BRONZE, SILVER, GOLD}
enum SIZE {SMALL, NORMAL, BIG}

const COIN_TYPE_WEIGHT = {
	TYPE.BRONZE: 90.0,
	TYPE.SILVER: 9.5,
	TYPE.GOLD: 0.5
}

const COIN_SIZE_WEIGHT = {
	SIZE.SMALL: 70,
	SIZE.NORMAL: 20,
	SIZE.BIG: 10
}

const COINS_VALUES = {
	TYPE.BRONZE: 1,
	TYPE.SILVER: 1000,
	TYPE.GOLD: 1000000
}

const COINS_SIZE_MULTIPLY = {
	SIZE.SMALL: 150,
	SIZE.NORMAL: 200,
	SIZE.BIG: 350
}

@export var coin_value: int
@export var coin_type: TYPE
@export var coin_size: SIZE
@export var coin_texture: Texture2D

func _init(_enemy_stats: EnemyStats = EnemyStats.new()) -> void:
	self.coin_type = generate_random_type()
	self.coin_size = generate_random_size()
	self.coin_value = calculate_value()
	setup_texture()

func generate_random_type() -> TYPE:
	#var enemy_level = enemy_stats.level
	#var difficulty = GameEvents.current_map.get_difficulty()
	var total_weight = 0

	for weight in COIN_TYPE_WEIGHT.values():
		total_weight += weight

	var random_value = randf_range(0, total_weight)
	var cumulative_weight = 0

	for _coin_type in COIN_TYPE_WEIGHT:
		cumulative_weight += COIN_TYPE_WEIGHT[_coin_type]
		if random_value < cumulative_weight:
			return _coin_type
	
	return TYPE.BRONZE
	
func generate_random_size() -> SIZE:
	#var enemy_level = enemy_stats.level
	#var difficulty = GameEvents.current_map.get_difficulty()
	var total_weight = 0

	for weight in COIN_SIZE_WEIGHT.values():
		total_weight += weight

	var random_value = randi() % total_weight
	var cumulative_weight = 0

	for _coin_size in COIN_SIZE_WEIGHT:
		cumulative_weight += COIN_SIZE_WEIGHT[_coin_size]
		if random_value < cumulative_weight:
			return _coin_size
	
	return SIZE.SMALL

func calculate_value() -> int:
	var base_value = COINS_SIZE_MULTIPLY[coin_size]
	var factor = min(base_value, randi_range(base_value * 0.8, base_value * 1.2))
	return COINS_VALUES[coin_type] * factor

func setup_texture() -> void:
	match coin_type:
		TYPE.BRONZE:
			match coin_size:
				SIZE.SMALL:
					self.coin_texture = BRONZE_SMALL_COIN
				SIZE.NORMAL:
					self.coin_texture = BRONZE_COIN
				SIZE.BIG:
					self.coin_texture = BRONZE_HUGE_COIN
		TYPE.SILVER:
			match coin_size:
				SIZE.SMALL:
					self.coin_texture = SILVER_SMALL_COIN
				SIZE.NORMAL:
					self.coin_texture = SILVER_COIN
				SIZE.BIG:
					self.coin_texture = SILVER_HUGE_COIN
		TYPE.GOLD:
			match coin_size:
				SIZE.SMALL:
					self.coin_texture = GOLD_SMALL_COIN
				SIZE.NORMAL:
					self.coin_texture = GOLD_COIN
				SIZE.BIG:
					self.coin_texture = GOLD_HUGE_COIN
		_:
			self.coin_texture = BRONZE_COIN
