class_name StatsInfoUI
extends HBoxContainer

@onready var label: Label = $Label
@onready var value: Label = $Value

var stats_name: String
var stats_value: String

func _ready() -> void:
	label.text = stats_name
	value.text = stats_value
