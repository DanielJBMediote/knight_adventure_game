extends Node

# Sinal para quando as moedas são atualizadas
signal currency_updated(gold: int, silver: int, bronze: int)

# Constantes de conversão
const GOLD_TO_SILVER = 1000
const SILVER_TO_BRONZE = 1000
const BRONZE_TO_SILVER = 1000
const SILVER_TO_GOLD = 1000

static var gold_coins: int = 0
static var silver_coins: int = 0
static var bronze_coins: int = 0


# Função para adicionar moedas (em bronze)
func add_coins(amount: int) -> void:
	var total_bronze = get_total_bronze() + amount
	set_total_bronze(total_bronze)


# Função para remover moedas (em bronze)
func remove_coins(amount: int) -> void:
	var total_bronze = max(0, get_total_bronze() - amount)
	set_total_bronze(total_bronze)


# Função principal para definir o valor total em bronze
func set_total_bronze(total_bronze: int) -> void:
	# Converter o valor total para o sistema de moedas
	convert_from_bronze(total_bronze)
	currency_updated.emit(gold_coins, silver_coins, bronze_coins)


# Função para obter o valor total em bronze
func get_total_bronze() -> int:
	return (gold_coins * GOLD_TO_SILVER * SILVER_TO_BRONZE) + (silver_coins * SILVER_TO_BRONZE) + bronze_coins


# Converter de bronze para o sistema de moedas
func convert_from_bronze(total_bronze: int) -> void:
	# Calcular gold coins
	gold_coins = total_bronze / (GOLD_TO_SILVER * SILVER_TO_BRONZE)
	var remainder = total_bronze % (GOLD_TO_SILVER * SILVER_TO_BRONZE)

	# Calcular silver coins
	silver_coins = remainder / SILVER_TO_BRONZE

	# Calcular bronze coins
	bronze_coins = remainder % SILVER_TO_BRONZE


# Funções para obter valores individuais (se necessário)
func get_gold() -> int:
	return gold_coins


func get_silver() -> int:
	return silver_coins


func get_bronze() -> int:
	return bronze_coins


static func convert_value_to_coins(amount: int) -> Array[int]:
	# Calcular gold coins
	var _gold_coins = amount / (GOLD_TO_SILVER * SILVER_TO_BRONZE)
	var remainder = amount % (GOLD_TO_SILVER * SILVER_TO_BRONZE)

	# Calcular silver coins
	var _silver_coins = remainder / SILVER_TO_BRONZE

	# Calcular bronze coins
	var _bronze_coins = remainder % SILVER_TO_BRONZE

	return [_gold_coins, _silver_coins, _bronze_coins]


# Função para verificar se tem moedas suficientes
func has_enough_coins(amount: int) -> bool:
	return get_total_bronze() >= amount


# Função estática para converter valores (útil para outras partes do código)
static func convert_to_bronze(gold: int, silver: int, bronze: int) -> int:
	return (gold * GOLD_TO_SILVER * SILVER_TO_BRONZE) + (silver * SILVER_TO_BRONZE) + bronze
