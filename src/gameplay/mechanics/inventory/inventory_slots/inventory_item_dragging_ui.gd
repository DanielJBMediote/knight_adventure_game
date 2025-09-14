class_name InventoryItemDragingUI
extends Control

@onready var rarity_texture: TextureRect = $Panel/MarginContainer/RarityTexture
@onready var item_texture: TextureRect = $Panel/MarginContainer/ItemTexture
@onready var unique_border: Panel = $UniqueBorder
@onready var stacks: DefaultLabel = $Panel/MarginContainer/DetailContainer/Footer/Stacks
@onready var preview_gems_attached: VBoxContainer = $Panel/MarginContainer/DetailContainer/PreviewGemsAttached
@onready var level_label: DefaultLabel = $Panel/MarginContainer/DetailContainer/Footer/Level


func _ready() -> void:
	add_to_group("inventory_slots")


func setup(item: Item) -> void:
	item_texture.texture = item.item_texture
	set_item_rarity_texture(item.item_rarity)
	_update_gems_attached(item)
	_update_equipment_level(item)
	unique_border.visible = item.is_unique
	if item.stackable:
		stacks.text = str(item.current_stack)
		stacks.visible = true
	else:
		stacks.visible = false


func _process(_delta: float) -> void:
	global_position = get_global_mouse_position() - size / 2


func _update_equipment_level(item: Item) -> void:
	if item.item_category != Item.CATEGORY.EQUIPMENTS:
		level_label.hide()
		return

	level_label.show()
	level_label.text = "Lv.%d" % item.item_level

	if item.item_level > PlayerStats.level:
		level_label.add_theme_color_override("font_color", Color.RED)
	else:
		level_label.add_theme_color_override("font_color", Color.WHITE)

func _update_gems_attached(item: Item) -> void:
	for child in preview_gems_attached.get_children():
		child.queue_free()

	if item.item_category != Item.CATEGORY.EQUIPMENTS:
		preview_gems_attached.hide()
		return
	
	preview_gems_attached.show()
	var equipment = item as EquipmentItem
	var attached_gems = equipment.attached_gems
	for slot_key in attached_gems:
		var gem = attached_gems.get(slot_key)
		if gem:
			var tx_rect = TextureRect.new()
			tx_rect.texture = gem.item_texture
			tx_rect.custom_minimum_size = Vector2(12, 12)
			tx_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tx_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			preview_gems_attached.add_child(tx_rect)

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
