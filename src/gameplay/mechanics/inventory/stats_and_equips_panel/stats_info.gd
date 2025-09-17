class_name StatsInfoUI
extends HBoxContainer

@onready var name_label: Label = $Label
@onready var value_label: Label = $Value

var stats_name: String = "":
	set(value):
		stats_name = value
		if name_label:
			name_label.text = str(value)

var stats_value: String = "":
	set(value):
		stats_value = value
		if value_label:
			value_label.text = str(value)

# Adicione esta propriedade para armazenar a chave original
var attribute_key: String = ""

func _ready() -> void:
	name_label.text = stats_name
	value_label.text = stats_value
