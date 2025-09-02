class_name RequerimentContentUI
extends HBoxContainer

@onready var icon_texture: TextureRect = $Panel/Icon
@onready var rarity_texture: TextureRect = $Panel/Rarity
@onready var quatity_label: Label = $Panel/QuatityLabel
@onready var item_description: Label = $Label


@export var quantity_needed: int:
	get: return quantity_needed
	set(value):
		quantity_needed = value

@export var quanity: int:
	get: return quanity
	set(value):
		quanity = value

func setup(rune: Item) -> void:
	rarity_texture.texture = ItemManager.get_bg_gradient_by_rarity(rune.item_rarity)
	icon_texture.texture = rune.item_texture
	item_description.text = rune.item_name
	quatity_label.text = "%s / %s" % [quanity, quantity_needed]
