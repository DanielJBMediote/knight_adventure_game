class_name RequirementContentUI
extends HBoxContainer

@onready var icon_texture: TextureRect = $Panel/Icon
@onready var rarity_texture: TextureRect = $Panel/Rarity
@onready var quantity_label: Label = $Panel/QuantityLabel
@onready var item_description: Label = $Label


@export var quantity_needed: int:
	get: return quantity_needed
	set(value):
		quantity_needed = value

@export var quantity: int:
	get: return quantity
	set(value):
		quantity = value

func setup(rune: Item) -> void:
	rarity_texture.texture = ItemManager.get_background_theme_by_rarity(rune.item_rarity)
	icon_texture.texture = rune.item_texture
	item_description.text = rune.item_name
	quantity_label.text = "%s / %s" % [quantity, quantity_needed]
