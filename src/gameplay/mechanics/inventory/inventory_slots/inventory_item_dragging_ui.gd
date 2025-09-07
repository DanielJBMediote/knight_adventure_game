class_name InventoryItemDragingUI
extends Control

@onready var rarity_texture: TextureRect = $Panel/MarginContainer/RarityTexture
@onready var item_texture: TextureRect = $Panel/MarginContainer/ItemTexture
@onready var stacks: Label = $Panel/MarginContainer/Stacks
@onready var unique_border: Panel = $UniqueBorder

func _ready() -> void:
	add_to_group("inventory_slots")

func setup(item: Item) -> void:
	item_texture.texture = item.item_texture
	set_item_rarity_texture(item.item_rarity)
	unique_border.visible = item.is_unique
	if item.stackable:
		stacks.text = str(item.current_stack)
		stacks.visible = true
	else:
		stacks.visible = false

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position() - size / 2

func set_item_rarity_texture(rarity: Item.RARITY) -> void:
	match rarity:
		Item.RARITY.COMMON:
			# Azul para itens Normais
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_COMMOM
		
		Item.RARITY.UNCOMMON:
			# Azul para itens Bons
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_UNCOMMON
		
		Item.RARITY.RARE:
			# Azul para itens Mágicos
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_RARE
		
		Item.RARITY.EPIC:
			# Roxo para itens Épicos
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_EPIC
		
		Item.RARITY.LEGENDARY:
			# Laranja para itens lendários
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_LEGENDARY
		
		Item.RARITY.MYTHICAL:
			# Dourado para itens Míticos
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_MITICAL
		
		_:
			rarity_texture.texture = null
