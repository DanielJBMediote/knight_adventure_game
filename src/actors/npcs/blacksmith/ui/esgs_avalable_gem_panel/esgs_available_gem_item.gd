class_name ESGSAvailableGemItem
extends Panel

signal select_pressed()

@onready var rarity_texture: TextureRect = $MarginContainer/RarityTexture
@onready var gem_texture: TextureRect = $MarginContainer/HBoxContainer/GemTexture
@onready var gem_name: DefaultLabel = $MarginContainer/HBoxContainer/VBoxContainer/GemName
@onready var gem_attribute: DefaultLabel = $MarginContainer/HBoxContainer/VBoxContainer/GemAttribute
@onready var gem_level: DefaultLabel = $MarginContainer/HBoxContainer/VBoxContainer/Level
@onready var quantity: DefaultLabel = $MarginContainer/HBoxContainer/GemTexture/Quantity
@onready var socket_button: SocketButton = $MarginContainer/HBoxContainer/MarginContainer/SocketButton

var target_mouse = false
var gem: GemItem


func _ready() -> void:
	socket_button.pressed.connect(_on_select)
	
	rarity_texture.texture = ItemManager.get_bg_gradient_by_rarity(gem.item_rarity)
	gem_texture.texture = gem.item_texture
	gem_level.text = str("Lv. ", gem.item_level)
	gem_level.set_color(get_level_color())
	var qnt = InventoryManager.find_many_items_by_id(gem.item_id).reduce(func(acc: int, item: Item): return acc + item.current_stack, 0)
	quantity.text = "x%d" % qnt
	for attribute in gem.item_attributes:
		var value_str = ItemAttribute.format_value(attribute.type, attribute.value)
		var attrib_name = ItemAttribute.get_attribute_type_name(attribute.type)
		gem_attribute.text = "+ %s %s" % [value_str, attrib_name]
		gem_name.text = gem.item_name
		gem_name.set_color(gem.get_item_rarity_text_color())


func get_level_color() -> Color:
	var item_level = gem.item_level
	if item_level > PlayerStats.level:
		return Color.RED
	else:
		return Color.WHITE

func _on_select() -> void:
	if gem:
		select_pressed.emit()
