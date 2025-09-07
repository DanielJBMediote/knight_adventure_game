class_name ItemPriceUI
extends HBoxContainer

@onready var label: Label = $Label

@onready var gold_label: Label = $Golds
@onready var gold_coin: TextureRect = $GoldCoin

@onready var silver_label: Label = $Silvers
@onready var silver_coin: TextureRect = $SilverCoin

@onready var bronze_label: Label = $Bronzes
@onready var bronze_coin: TextureRect = $BronzeCoin

@export var label_text_key: String = "item_value":
	get: return label_text_key
	set(value): label_text_key = value
@export var golds: int:
	get: return golds
	set(value): golds = value
@export var silvers: int:
	get: return silvers
	set(value): silvers = value
@export var bronzes: int:
	get: return bronzes
	set(value): bronzes = value

func _ready() -> void:
	label.text = LocalizationManager.get_ui_text(label_text_key) + ": "
	update_golds(golds)
	update_silvers(silvers, golds != 0)
	update_bronzes(bronzes, silvers != 0)


func update_golds(coins: int) -> void:
	var gold_coins = coins
	gold_label.visible = gold_coins != 0
	gold_coin.visible = gold_coins != 0
	gold_label.text = StringUtils.format_currency(gold_coins)


func update_silvers(coins: int, show_zeros: bool = false) -> void:
	var formatted = ""
	if show_zeros:
		formatted = StringUtils.format_currency(coins).lpad(3, "0")
	else:
		formatted = StringUtils.format_currency(coins)
	silver_label.visible = coins != 0
	silver_coin.visible = coins != 0
	silver_label.text = formatted


func update_bronzes(coins: int, show_zeros: bool = false) -> void:
	var formatted = ""
	if show_zeros:
		formatted = StringUtils.format_currency(coins).lpad(3, "0")
	else:
		formatted = StringUtils.format_currency(coins)
	bronze_label.visible = coins != 0
	bronze_coin.visible = coins != 0
	bronze_label.text = formatted
