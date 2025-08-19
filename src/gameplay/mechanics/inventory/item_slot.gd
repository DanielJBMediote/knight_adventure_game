class_name InventoryItemSlot
extends Panel

const ITEM_SLOT_STYLEBOX_HOVER = preload("res://src/ui/themes/item_slot_stylebox_hover.tres")
const ITEM_SLOT_STYLEBOX_NORMAL = preload("res://src/ui/themes/item_slot_stylebox_normal.tres")

const UNIQUE_BORDER = preload("res://src/ui/themes/items_themes/unique_border.tres")

const BG_GRADIENT_ITEM_COMMOM = preload("res://src/ui/themes/items_themes/bg_gradient_item_common.tres")
const BG_GRADIENT_ITEM_UNCOMMON = preload("res://src/ui/themes/items_themes/bg_gradient_item_uncommon.tres")
const BG_GRADIENT_ITEM_RARE = preload("res://src/ui/themes/items_themes/bg_gradient_item_rare.tres")
const BG_GRADIENT_ITEM_EPIC = preload("res://src/ui/themes/items_themes/bg_gradient_item_epic.tres")
const BG_GRADIENT_ITEM_LEGENDARY = preload("res://src/ui/themes/items_themes/bg_gradient_item_legendary.tres")
const BG_GRADIENT_ITEM_MITICAL = preload("res://src/ui/themes/items_themes/bg_gradient_item_mitical.tres")

@onready var background_texture: TextureRect = $MarginContainer/BackgroundTexture
@onready var item_texture: TextureRect = $MarginContainer/ItemTexture
@onready var stacks: Label = $MarginContainer/Stacks
@onready var unique_border: Panel = $UniqueBorder

const ItemRarity = Item.ItemRarity

func _ready() -> void:
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_NORMAL)
	
func set_item(item: Item):
	if item != null:
		stacks.text = str(item.current_stack) if item.stackable else ""
		item_texture.texture = item.item_texture
		stacks.visible = item.stackable
		set_item_background_texture(item.item_rarity, item.is_unique)
	else:
		stacks.text = ""
		item_texture.texture = null
		stacks.visible = false
		background_texture.texture = null
		unique_border.remove_theme_stylebox_override("panel")

func set_item_background_texture(rarity: ItemRarity, is_unique: bool) -> void:
	
	if is_unique:
		unique_border.add_theme_stylebox_override("panel", UNIQUE_BORDER)
	
	match rarity:
		ItemRarity.COMMON:
			# Azul para itens Normais
			background_texture.texture = BG_GRADIENT_ITEM_COMMOM
		
		ItemRarity.UNCOMMON:
			# Azul para itens Bons
			background_texture.texture = BG_GRADIENT_ITEM_UNCOMMON
		
		ItemRarity.RARE:
			# Azul para itens Mágicos
			background_texture.texture = BG_GRADIENT_ITEM_RARE
		
		ItemRarity.EPIC:
			# Roxo para itens Épicos
			background_texture.texture = BG_GRADIENT_ITEM_EPIC
		
		ItemRarity.LEGENDARY:
			# Laranja para itens lendários
			background_texture.texture = BG_GRADIENT_ITEM_LEGENDARY
		
		ItemRarity.MYTHICAL:
			# Dourado para itens Míticos
			background_texture.texture = BG_GRADIENT_ITEM_MITICAL
		
		_:
			background_texture.texture = null


func _on_mouse_entered() -> void:
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_HOVER)

func _on_mouse_exited() -> void:
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_NORMAL)

func _on_focus_entered() -> void:
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_HOVER)

func _on_focus_exited() -> void:
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_NORMAL)
