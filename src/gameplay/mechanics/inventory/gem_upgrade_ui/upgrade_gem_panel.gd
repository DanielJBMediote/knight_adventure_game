class_name GemUpgradePreviewUI
extends Control

@onready var attribute_label: AttributeLabel = $AttributeLabel
@onready var rarity_texture: TextureRect = $HBoxContainer/RarityTexture
@onready var icon_texture: TextureRect = $HBoxContainer/IconTexture
@onready var gem_name: AttributeLabel = $GemName
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $HBoxContainer/Sprite2D

func setup(gem: GemItem) -> void:
	icon_texture.texture = gem.item_texture
	if gem.gem_type not in GemConsts.UNIQUE_GEMS_KEYS:
		var gem_quality_key = GemConsts.GEM_QUALITY_KEY[gem.gem_quality]
		animation_player.play(gem_quality_key)
	else:
		sprite_2d.hide()
		animation_player.stop()
		animation_player.seek(0.0, true)

	# rarity_texture.texture = ItemManager.get_bg_gradient_by_rarity(gem.item_rarity)
	gem_name.text = gem.item_name
	gem_name.add_theme_color_override("font_color", gem.get_item_rarity_text_color())
	
	if gem.item_attributes.is_empty():
		return

	for attribute in gem.item_attributes:
		var formatted_value = InventoryItemInfoUI._format_attribute_value(attribute.value, attribute.type)
		var attribute_name = ItemAttribute.get_attribute_type_name(attribute.type)
		attribute_label.text = str("+", formatted_value, " ", attribute_name)
