class_name DescriptionText
extends RichTextLabel

const FONT = preload("res://assets/fonts/alagard.ttf")

func _init() -> void:
  self.bbcode_enabled = true
  self.fit_content = true
  self.add_theme_font_override("normal_font", FONT)
  self.add_theme_font_override("mono_font", FONT)
  self.add_theme_font_override("italics_font", FONT)
  self.add_theme_font_override("bold_italics_font", FONT)
  self.add_theme_font_override("bold_font", FONT)
  self.add_theme_color_override("font_outline_color", Color.BLACK)
  self.add_theme_constant_override("outline_size", 2)