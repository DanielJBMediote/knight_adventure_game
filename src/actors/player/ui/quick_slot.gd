class_name QuickSlot
extends Panel

@onready var rarity_texture: TextureRect = $RarityTexture
@onready var unique_border: Panel = $UniqueBorder
@onready var button_ui: TextureRect = $MarginContainer/ButtonUI
@onready var item_texture: TextureRect = $MarginContainer/ItemTexture
@onready var stacks: DefaultLabel = $MarginContainer/Statcks


var item: Item
var slot_key: int

func set_slot_key(key: int):
	slot_key = key

func setup_item(new_item: Item) -> void:
	if new_item != null:
		stacks.text = str(new_item.current_stack) if new_item.stackable else ""
		item_texture.texture = new_item.item_texture
		stacks.visible = new_item.stackable
		rarity_texture.texture = ItemManager.get_bg_gradient_by_rarity(new_item.item_rarity)
		unique_border.visible = new_item.is_unique
	else:
		stacks.text = ""
		item_texture.texture = null
		stacks.visible = false
		rarity_texture.texture = null
		unique_border.hide()

func _input(_event: InputEvent) -> void:
	pass
	#if event.is_action_pressed(str("slot_key_", slot_key)):
		#item.use()
