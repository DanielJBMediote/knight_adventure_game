class_name AttributeLabel
extends Label

const ATTRBUTE_FONT = preload("res://assets/fonts/alagard.ttf")

@export var value_text: String:
	set(value): value_text = value


@export var label_color: Color:
	set(value): label_color = value


func _ready() -> void:
	self.add_theme_font_override("font", ATTRBUTE_FONT)
	self.add_theme_font_size_override("font_size", 16)
	self.add_theme_constant_override("outline_size", 2)
	self.add_theme_color_override("outline_color", Color.BLACK)
	
	self.text = value_text
	if label_color:
		self.add_theme_color_override("font_color", label_color)
