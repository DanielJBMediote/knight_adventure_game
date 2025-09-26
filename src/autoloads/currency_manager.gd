extends Node

# Sinal para quando as moedas são atualizadas
signal currency_updated(gold: int, silver: int, bronze: int)

const BRONZE_COIN = preload("res://assets/sprites/items/icons/bronze_coin.png")
const SILVER_COIN = preload("res://assets/sprites/items/icons/silver_coin.png")
const GOLD_COIN = preload("res://assets/sprites/items/icons/gold_coin.png")

class CoinDictionary:
	var golds: int
	var silvers: int
	var bronzes: int

	func _init(_golds: int = 0, _silvers: int = 0, _bronzes: int = 0) -> void:
		golds = _golds
		silvers = _silvers
		bronzes = _bronzes

# Constantes de conversão
const GOLD_TO_SILVER = 1000
const SILVER_TO_BRONZE = 1000
const BRONZE_TO_SILVER = 1000
const SILVER_TO_GOLD = 1000

var gold_coins: int = 0
var silver_coins: int = 0
var bronze_coins: int = 0

# Função para adicionar moedas (em bronze)
func add_coins(amount: int) -> void:
	var total_bronze = get_total_coins() + amount
	set_total_coins(total_bronze)


# Função para remover moedas (em bronze)
func remove_coins(amount: int) -> void:
	var total_bronze = max(0, get_total_coins() - amount)
	set_total_coins(total_bronze)


# Função principal para definir o valor total em bronze
func set_total_coins(total_bronze: int) -> void:
	# Converter o valor total para o sistema de moedas
	convert_from_bronze(total_bronze)
	currency_updated.emit(gold_coins, silver_coins, bronze_coins)


# Função para obter o valor total em bronze
func get_total_coins() -> int:
	return (gold_coins * GOLD_TO_SILVER * SILVER_TO_BRONZE) + (silver_coins * SILVER_TO_BRONZE) + bronze_coins


# Converter de bronze para o sistema de moedas
func convert_from_bronze(total_bronze: int) -> void:
	# Calcular gold coins
	gold_coins = int(total_bronze / float(GOLD_TO_SILVER * SILVER_TO_BRONZE))
	var remainder = total_bronze % (GOLD_TO_SILVER * SILVER_TO_BRONZE)

	# Calcular silver coins
	silver_coins = int(float(remainder) / float(SILVER_TO_BRONZE))

	# Calcular bronze coins
	bronze_coins = remainder % SILVER_TO_BRONZE


# Funções para obter valores individuais (se necessário)
func get_gold() -> int:
	return gold_coins


func get_silver() -> int:
	return silver_coins


func get_bronze() -> int:
	return bronze_coins


func convert_value_to_coins(amount: int) -> CoinDictionary:
	# Calcular gold coins
	var _gold_coins = float(amount) / float(GOLD_TO_SILVER * SILVER_TO_BRONZE)
	var remainder = amount % (GOLD_TO_SILVER * SILVER_TO_BRONZE)

	# Calcular silver coins
	var _silver_coins = float(remainder) / float(SILVER_TO_BRONZE)

	# Calcular bronze coins
	var _bronze_coins = remainder % SILVER_TO_BRONZE

	return CoinDictionary.new(int(_gold_coins), int(_silver_coins), int(_bronze_coins))


# Função para verificar se tem moedas suficientes
func has_enough_coins(amount: int) -> bool:
	return get_total_coins() >= amount


# Função para converter valores (útil para outras partes do código)
func convert_to_bronze(gold: int, silver: int, bronze: int) -> int:
	return (gold * GOLD_TO_SILVER * SILVER_TO_BRONZE) + (silver * SILVER_TO_BRONZE) + bronze


func save_data() -> Dictionary:
	return {
		"gold_coins": gold_coins,
		"silver_coins": silver_coins,
		"bronze_coins": bronze_coins
	}

func load_data(data: Dictionary):
	gold_coins = data.get("gold_coins", 0)
	silver_coins = data.get("silver_coins", 0)
	bronze_coins = data.get("bronze_coins", 0)
