class_name ESGSGemSocketUI
extends Panel

@onready var attribute_value: DefaultLabel = $MarginContainer/HBoxContainer/Names/AttributeValue
@onready var gem_name: DefaultLabel = $MarginContainer/HBoxContainer/Names/GemName
@onready var socket_button: SocketButton = $MarginContainer/HBoxContainer/SocketButton
@onready var gem_texture: TextureRect = $MarginContainer/HBoxContainer/GemTexture
@onready var rarity_texture: TextureRect = $RarityTexture

func _ready() -> void:
	socket_button.pressed.connect(func(): socket_button.release_focus())

func update_gem(gem: GemItem) -> void:
	
	socket_button.update_button_icon(gem != null)

	if gem:
		rarity_texture.texture = ItemManager.get_bg_gradient_by_rarity(gem.item_rarity)
		gem_texture.texture = gem.item_texture
		socket_button.text = LocalizationManager.get_ui_text("remove")
		attribute_value.show()
		for attribute in gem.item_attributes:
			var value_str = ItemAttribute.format_value(attribute.type, attribute.value)
			var attrib_name = ItemAttribute.get_attribute_type_name(attribute.type)
			attribute_value.text = "+ %s %s" % [value_str, attrib_name]
			gem_name.text = gem.item_name
			gem_name.add_theme_color_override("font_color", gem.get_item_rarity_text_color())
	else:
		attribute_value.hide()
		rarity_texture.texture = null
		gem_texture.texture = load("res://assets/sprites/items/gems/gem_refined_blue.png")
		gem_texture.modulate = Color.BLACK
		socket_button.text = LocalizationManager.get_ui_text("attach")
		gem_name.text = LocalizationManager.get_ui_text("empty_slot")
		if gem_name.has_theme_color_override("font_color"):
			gem_name.remove_theme_color_override("font_color")
