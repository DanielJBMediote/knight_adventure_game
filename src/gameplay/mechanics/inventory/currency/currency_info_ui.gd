class_name CurrencyInfoUI
extends HBoxContainer

@onready var gold_value: Label = $GoldSection/ValueGold
@onready var silver_value: Label = $SilverSection/ValueSilver
@onready var bronze_value: Label = $BronzeSection/ValueBronze


func _ready() -> void:
	_update_display(CurrencyManager.gold_coins, CurrencyManager.silver_coins, CurrencyManager.bronze_coins)
	CurrencyManager.currency_updated.connect(_update_display)


# Atualizar a exibição na UI
func _update_display(gold: int, silver: int, bronze: int) -> void:
	var formatted_gols = ""
	if gold < pow(10, 3):
		formatted_gols = str(gold).lpad(3, "0")
	else:
		formatted_gols = StringUtils.format_currency(gold)
	gold_value.text = formatted_gols
	silver_value.text = str(silver).lpad(3, "0")
	bronze_value.text = str(bronze).lpad(3, "0")
