class_name InventoryItemInfoUI
extends Control

@onready var use_equip_item_button: Button = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Footer/UseEquipItemButton
@onready var trash_item_button: Button = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Footer/TrashItemButton
@onready var close_button: Button = $Panel/MarginContainer/CloseButton

@onready var item_name: Label = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Header/ItemName
@onready var item_type: Label = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Header/ItemType

@onready var item_attributes: Label = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Content/HBoxContainer/ItemAttributes
@onready var item_description: Label = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Content/ItemDescription

@onready var item_texture_rect: TextureRect = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Content/HBoxContainer/ItemTextureRect
@onready var background_texture_rect: TextureRect = $Panel/TextureMargin/BackgroundTextureRect
@onready var border_texture_rect: Panel = $Panel/TextureMargin/BorderTextureRect

const UNIQUE_BORDER = preload("res://src/ui/themes/items_themes/unique_border.tres")

const BG_GRADIENT_ITEM_COMMOM = preload("res://src/ui/themes/items_themes/bg_gradient_item_common.tres")
const BG_GRADIENT_ITEM_UNCOMMON = preload("res://src/ui/themes/items_themes/bg_gradient_item_uncommon.tres")
const BG_GRADIENT_ITEM_RARE = preload("res://src/ui/themes/items_themes/bg_gradient_item_rare.tres")
const BG_GRADIENT_ITEM_EPIC = preload("res://src/ui/themes/items_themes/bg_gradient_item_epic.tres")
const BG_GRADIENT_ITEM_LEGENDARY = preload("res://src/ui/themes/items_themes/bg_gradient_item_legendary.tres")
const BG_GRADIENT_ITEM_MITICAL = preload("res://src/ui/themes/items_themes/bg_gradient_item_mitical.tres")

const ItemNameRarityColors = {
	Item.ItemRarity.COMMON: Color.WHITE_SMOKE,
	Item.ItemRarity.UNCOMMON: Color.WEB_GREEN,
	Item.ItemRarity.RARE: Color(0.5, 1.0, 1.0, 1.0),
	Item.ItemRarity.EPIC: Color(0.5, 0.0, 0.85, 1.0),
	Item.ItemRarity.LEGENDARY: Color.ORANGE_RED,
	Item.ItemRarity.MYTHICAL: Color.RED,
}

func _ready() -> void:
	#InventoryManager.update_inventory_visible.connect(_on_inventory_visible_change)
	InventoryManager.update_item_information.connect(_update_item_information)
	close_button.pressed.connect(hide)
	trash_item_button.pressed.connect(_on_trash_item_button_pressed)
	use_equip_item_button.pressed.connect(_on_use_equip_item_button_pressed)

func _update_item_information(item: Item) -> void:
	ItemManager.current_selected_item = item
	
	if item.is_unique:
		border_texture_rect.add_theme_stylebox_override("panel", UNIQUE_BORDER)
	else:
		if border_texture_rect.has_theme_stylebox_override("panel"):
			border_texture_rect.remove_theme_stylebox_override("panel")
	
	# Configurar nome do item com cor baseada na raridade
	item_name.text = item.item_name
	item_name.add_theme_color_override("font_color", ItemNameRarityColors.get(item.item_rarity, Color.WHITE_SMOKE))
	
	# Configurar tipo do item
	item_type.text = str(Item.get_caategory_name(item.item_category), " / ", Item.get_sub_Category_name(item.item_subcategory))
	
	# Configurar atributos e descrição
	item_attributes.text = format_attributes(item.item_attributes)
	item_description.text = item.item_description
	
	# Configurar textura do item
	item_texture_rect.texture = item.item_texture
	
	# Configurar fundo baseado na raridade
	_set_background_based_on_rarity(item.item_rarity)
	
	# Configurar botões baseado no tipo de item
	_update_button_visibility(item)
	
	show()

func format_attributes(attributes: Array[ItemAttribute]) -> String: 
	if attributes.is_empty():
		return LocalizationManager.get_ui_text("no_attributes")
	
	var attribute_text = ""
	for attribute in attributes:
		var formatted_value = _format_attribute_value(attribute.value, attribute.type)
		var attribute_name = ItemAttribute.get_attribute_type_name(attribute.type)
		attribute_text += str("+", formatted_value, " ", attribute_name, "\n")
	
	return attribute_text

func _format_attribute_value(value: float, attribute_type: ItemAttribute.Type) -> String:
	# Tipos que devem ser exibidos como porcentagem
	
	if attribute_type in ItemAttribute.PERCENTAGE_TYPES:
		return "%.1f%%" % value
	else:
		return "%.0f" % value

func _set_background_based_on_rarity(rarity: Item.ItemRarity) -> void:
	match rarity:
		Item.ItemRarity.COMMON:
			background_texture_rect.texture = BG_GRADIENT_ITEM_COMMOM
		Item.ItemRarity.UNCOMMON:
			background_texture_rect.texture = BG_GRADIENT_ITEM_UNCOMMON
		Item.ItemRarity.RARE:
			background_texture_rect.texture = BG_GRADIENT_ITEM_RARE
		Item.ItemRarity.EPIC:
			background_texture_rect.texture = BG_GRADIENT_ITEM_EPIC
		Item.ItemRarity.LEGENDARY:
			background_texture_rect.texture = BG_GRADIENT_ITEM_LEGENDARY
		Item.ItemRarity.MYTHICAL:
			background_texture_rect.texture = BG_GRADIENT_ITEM_MITICAL
		_:
			background_texture_rect.texture = BG_GRADIENT_ITEM_COMMOM

func _update_button_visibility(item: Item) -> void:
	# Mostrar botão de usar/equipar apenas para itens usáveis ou equipáveis
	var is_usable = item.item_action != null
	var is_equipable = item.item_category == Item.ItemCategory.EQUIPMENT
	
	use_equip_item_button.visible = is_usable or is_equipable
	
	if is_usable:
		use_equip_item_button.text = LocalizationManager.get_ui_text("use_item")
	elif is_equipable:
		use_equip_item_button.text = LocalizationManager.get_ui_text("equip_item")
	
	# Sempre mostrar botão de descartar
	trash_item_button.visible = true

func _on_use_equip_item_button_pressed() -> void:
	var current_item = ItemManager.current_selected_item
	var is_consumable = current_item.item_category == Item.ItemCategory.CONSUMABLES
	var is_equipable = current_item.item_category == Item.ItemCategory.EQUIPMENT
	# Lógica para usar ou equipar o item
	if current_item:
		if current_item.item_action != null and is_consumable:
			ItemManager.consume_item(current_item)
		elif is_equipable:
			ItemManager.equip_item(current_item)
		hide()

func _on_trash_item_button_pressed() -> void:
	ItemManager.current_selected_item = null
	# Lógica para descartar o item
	if ItemManager.current_selected_item:
		ItemManager.remove_item(ItemManager.current_selected_item)
		hide()

#func _on_inventory_visible_change(is_open: bool)-> void:
	#visible = is_open
	#pass
