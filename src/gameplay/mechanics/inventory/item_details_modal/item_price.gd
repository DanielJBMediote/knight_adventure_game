class_name ItemPriceUI
extends HBoxContainer

@onready var label: Label = $Label

@onready var gold_label: Label = $Golds
@onready var gold_coin: TextureRect = $GoldCoin

@onready var silver_label: Label = $Silvers
@onready var silver_coin: TextureRect = $SilverCoin

@onready var bronze_label: Label = $Bronzes
@onready var bronze_coin: TextureRect = $BronzeCoin


func _ready() -> void:
	label.text = LocalizationManager.get_ui_text("item_value") + ": "


func update_item_price(value: int) -> void:
	var coins = CurrencyManager.convert_value_to_coins(value)

	set_gold(coins)
	set_silver(coins)
	set_bronze(coins)


func set_gold(coins: Array) -> void:
	var gold_coins = coins[0]
	gold_label.visible = gold_coins != 0
	gold_coin.visible = gold_coins != 0
	gold_label.text = StringUtils.format_currency(gold_coins)


func set_silver(coins: Array) -> void:
	var silver_coins = coins[1]
	var formatted = ""
	if coins[0] >= 1:
		formatted = StringUtils.format_currency(silver_coins).lpad(3, "0")
	else:
		formatted = StringUtils.format_currency(silver_coins)
	silver_label.visible = silver_coins != 0
	silver_coin.visible = silver_coins != 0
	silver_label.text = formatted


func set_bronze(coins: Array) -> void:
	var bronze_coins = coins[2]
	var formatted = ""
	if coins[1] >= 1:
		formatted = StringUtils.format_currency(bronze_coins).lpad(3, "0")
	else:
		formatted = StringUtils.format_currency(bronze_coins)
	bronze_label.visible = bronze_coins != 0
	bronze_coin.visible = bronze_coins != 0
	bronze_label.text = formatted
