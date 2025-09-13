class_name ESGSEquipmentItemUI
extends Panel

@onready var rarity_texture: TextureRect = $RarityTexture
@onready var equipment_texture: TextureRect = $MarginContainer/HBoxContainer/EquipmentTexture
@onready var equipment_name: Label = $MarginContainer/HBoxContainer/Labels/EquipmentName
@onready var equipment_level: Label = $MarginContainer/HBoxContainer/Labels/EquipmentLevel
@onready var equipment_rarity: Label = $MarginContainer/HBoxContainer/Labels/EquipmentRarity

@onready var gems_list: HBoxContainer = $MarginContainer/HBoxContainer/GemList
@onready var choose_button: Button = $MarginContainer/HBoxContainer/ChooseButton


func _ready() -> void:
	choose_button.pressed.connect(_on_choose_button_pressed)


func setup_equipment(equipment: EquipmentItem) -> void:
	equipment_name.text = equipment.item_name
	equipment_texture.texture = equipment.item_texture
	equipment_level.text = "Lv.%d" % equipment.item_level
	equipment_rarity.text = Item.get_rarity_text(equipment.item_rarity)
	equipment_rarity.add_theme_color_override("font_color", equipment.get_item_rarity_text_color())
	rarity_texture.texture = ItemManager.get_bg_gradient_by_rarity(equipment.item_rarity)

	load_equipments_gems(equipment)


func load_equipments_gems(equipment: EquipmentItem) -> void:
	var available_sockets = equipment.available_sockets
	var gems = equipment.attached_gems

	for g in available_sockets:
		var tx_rect = TextureRect.new()
		tx_rect.custom_minimum_size = Vector2(48, 48)

		var tx: Texture2D
		if gems[g] != null:
			tx = gems[g].item_texture
		else:
			tx = load("res://assets/sprites/items/gems/gem_refined_blue.png")
			tx_rect.modulate = Color.BLACK
		tx_rect.texture = tx
		gems_list.add_child(tx_rect)


func _on_choose_button_pressed() -> void:
	pass
