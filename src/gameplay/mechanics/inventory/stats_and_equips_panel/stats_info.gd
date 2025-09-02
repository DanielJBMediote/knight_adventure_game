class_name StatsInfoUI
extends HBoxContainer

@onready var label: Label = $Label
@onready var value: Label = $Value

var stats_name: String = "":
	set(v):
		stats_name = v
		if label:
			label.text = v

var stats_value: String = "":
	set(v):
		stats_value = v
		if value:
			value.text = v

# Adicione esta propriedade para armazenar a chave original
var attribute_key: String = ""

func _ready() -> void:
	label.text = stats_name
	value.text = stats_value
