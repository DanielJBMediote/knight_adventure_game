class_name EquipmentSlotUI
extends Panel

@onready var rarity_texture: TextureRect = $MarginContainer/RarityTexture
@onready var unique_border: Panel = $UniqueBorder
@onready var equipment_level: Label = $MarginContainer/MarginContainer/TextureRect/EquipmentLevel
@onready var equipment_texture: TextureRect = $MarginContainer/EquipmentTexture
@onready var background_item: TextureRect = $BackgroundItem

const ITEM_SLOT_STYLEBOX_HOVER = preload("res://src/ui/themes/item_slot_stylebox_hover.tres")
const ITEM_SLOT_STYLEBOX_NORMAL = preload("res://src/ui/themes/item_slot_stylebox_normal.tres")

const BG_GRADIENT_ITEM_COMMOM = preload("res://src/ui/themes/items_themes/bg_gradient_item_common.tres")
const BG_GRADIENT_ITEM_UNCOMMON = preload("res://src/ui/themes/items_themes/bg_gradient_item_uncommon.tres")
const BG_GRADIENT_ITEM_RARE = preload("res://src/ui/themes/items_themes/bg_gradient_item_rare.tres")
const BG_GRADIENT_ITEM_EPIC = preload("res://src/ui/themes/items_themes/bg_gradient_item_epic.tres")
const BG_GRADIENT_ITEM_LEGENDARY = preload("res://src/ui/themes/items_themes/bg_gradient_item_legendary.tres")
const BG_GRADIENT_ITEM_MITICAL = preload("res://src/ui/themes/items_themes/bg_gradient_item_mitical.tres")

@export var default_texture: Texture2D

var equipment: EquipmentItem
var target_mouse_entered := false

func _ready() -> void:
	if default_texture:
		background_item.texture = default_texture
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)
	self.focus_entered.connect(_on_focus_entered)
	self.focus_exited.connect(_on_focus_exited)
	setup_equipment(null)

func setup_equipment(new_equipment: EquipmentItem) -> void:
	if new_equipment:
		equipment = new_equipment
		equipment_texture.texture = new_equipment.item_texture
		equipment_level.visible = true
		background_item.visible = false
		equipment_level.text = str(new_equipment.item_level)
		setup_equipment_rarity_texture(new_equipment.item_rarity)
		update_border_style(new_equipment.is_unique)
	else:
		equipment = null
		equipment_texture.texture = null
		background_item.visible = true
		equipment_level.text = ""
		equipment_level.visible = false
		rarity_texture.texture = null
		update_border_style()

func setup_equipment_rarity_texture(rarity: Item.RARITY) -> void:
	match rarity:
		Item.RARITY.COMMON:
			# Azul para itens Normais
			rarity_texture.texture = BG_GRADIENT_ITEM_COMMOM
		
		Item.RARITY.UNCOMMON:
			# Azul para itens Bons
			rarity_texture.texture = BG_GRADIENT_ITEM_UNCOMMON
		
		Item.RARITY.RARE:
			# Azul para itens Mágicos
			rarity_texture.texture = BG_GRADIENT_ITEM_RARE
		
		Item.RARITY.EPIC:
			# Roxo para itens Épicos
			rarity_texture.texture = BG_GRADIENT_ITEM_EPIC
		
		Item.RARITY.LEGENDARY:
			# Laranja para itens lendários
			rarity_texture.texture = BG_GRADIENT_ITEM_LEGENDARY
		
		Item.RARITY.MYTHICAL:
			# Dourado para itens Míticos
			rarity_texture.texture = BG_GRADIENT_ITEM_MITICAL
		
		_:
			rarity_texture.texture = null

func update_border_style(is_unique: bool = false):
	unique_border.visible = is_unique

func _input(event: InputEvent) -> void:
	if target_mouse_entered and equipment:
		if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT :
			InventoryManager.update_item_information.emit(equipment)

func _on_mouse_entered() -> void:
	target_mouse_entered = true
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_HOVER)

func _on_mouse_exited() -> void:
	target_mouse_entered = false
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_NORMAL)

func _on_focus_entered() -> void:
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_HOVER)

func _on_focus_exited() -> void:
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_NORMAL)
