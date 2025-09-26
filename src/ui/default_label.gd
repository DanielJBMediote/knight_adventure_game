class_name DefaultLabel
extends Label

const FONT = preload("res://assets/fonts/alagard.ttf")

func _ready() -> void:
	self.add_theme_font_override("font", FONT)
	self.add_theme_constant_override("outline_size", 2)
	self.add_theme_color_override("outline_color", Color.BLACK)

func set_color(new_color: Color) -> void:
	self.add_theme_color_override("font_color", new_color)
