class_name EquipGemSocketSlot
extends HBoxContainer

const EMPTY_GEM_SOCKET = preload("res://src/ui/themes/empty_gem_socket_panel_style.tres")

@onready var panel: Panel = $Panel
@onready var gem_texture: TextureRect = $Panel/GemTexture

@onready var attribute_label: AttributeLabel = $VBoxContainer/AttributeLabel
@onready var gem_name_label: AttributeLabel = $VBoxContainer/GemNameLabel

var gem: GemItem

func _ready() -> void:
	if gem:
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		gem_texture.texture = gem.item_texture
		for attribute in gem.item_attributes:
			var value_str = ItemAttribute.format_value(attribute.type, attribute.value)
			var attrib_name = ItemAttribute.get_attribute_type_name(gem.attribute.type)
			attribute_label.value_text = "+ %s %s" % [value_str, attrib_name]
			gem_name_label.text = gem.item_name
			gem_name_label.add_theme_color_override("font_color", gem.get_item_rarity_text_color())

	else:
		gem_texture.texture = null
		gem_name_label.text = LocalizationManager.get_ui_text("empty_slot")
		attribute_label.hide()
		panel.add_theme_stylebox_override("panel", EMPTY_GEM_SOCKET)
