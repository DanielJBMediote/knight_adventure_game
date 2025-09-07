class_name QuickSlot
extends Panel

@onready var item_texture: TextureRect = $ItemTexture
@onready var stacks: Label = $Stacks
@onready var background_texture: TextureRect = $BGTexture
@onready var unique_border: Panel = $UniqueBorder

const BG_GRADIENT_ITEM_COMMOM = preload("res://src/ui/themes/items_themes/bg_gradient_item_common.tres")
const BG_GRADIENT_ITEM_UNCOMMON = preload("res://src/ui/themes/items_themes/bg_gradient_item_uncommon.tres")
const BG_GRADIENT_ITEM_RARE = preload("res://src/ui/themes/items_themes/bg_gradient_item_rare.tres")
const BG_GRADIENT_ITEM_EPIC = preload("res://src/ui/themes/items_themes/bg_gradient_item_epic.tres")
const BG_GRADIENT_ITEM_LEGENDARY = preload("res://src/ui/themes/items_themes/bg_gradient_item_legendary.tres")
const BG_GRADIENT_ITEM_MITICAL = preload("res://src/ui/themes/items_themes/bg_gradient_item_mitical.tres")

var item: Item
var slot_key: int

func set_slot_key(key: int):
	slot_key = key

func setup_item(new_item: Item) -> void:
	if new_item != null:
		stacks.text = str(new_item.current_stack) if new_item.stackable else ""
		item_texture.texture = new_item.item_texture
		stacks.visible = new_item.stackable
		set_item_background_texture(new_item.item_rarity)
	else:
		stacks.text = ""
		item_texture.texture = null
		stacks.visible = false
		background_texture.texture = null
		unique_border.remove_theme_stylebox_override("panel")
		unique_border.hide()

func set_item_background_texture(rarity: Item.RARITY) -> void:
	match rarity:
		Item.RARITY.COMMON:
			# Azul para itens Normais
			background_texture.texture = BG_GRADIENT_ITEM_COMMOM
		
		Item.RARITY.UNCOMMON:
			# Azul para itens Bons
			background_texture.texture = BG_GRADIENT_ITEM_UNCOMMON
		
		Item.RARITY.RARE:
			# Azul para itens Mágicos
			background_texture.texture = BG_GRADIENT_ITEM_RARE
		
		Item.RARITY.EPIC:
			# Roxo para itens Épicos
			background_texture.texture = BG_GRADIENT_ITEM_EPIC
		
		Item.RARITY.LEGENDARY:
			# Laranja para itens lendários
			background_texture.texture = BG_GRADIENT_ITEM_LEGENDARY
		
		Item.RARITY.MYTHICAL:
			# Dourado para itens Míticos
			background_texture.texture = BG_GRADIENT_ITEM_MITICAL
		
		_:
			background_texture.texture = null

func _input(_event: InputEvent) -> void:
	pass
	#if event.is_action_pressed(str("slot_key_", slot_key)):
		#item.use()
