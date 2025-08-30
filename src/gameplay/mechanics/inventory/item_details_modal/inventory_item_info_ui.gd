class_name InventoryItemInfoUI
extends Control

const ATTRBUTE_FONT = preload("res://assets/fonts/alagard.ttf")

const BRONZE_COIN = preload("res://assets/sprites/items/icons/bronze_coin.png") 
const SILVER_COIN = preload("res://assets/sprites/items/icons/silver_coin.png") 
const GOLD_COIN = preload("res://assets/sprites/items/icons/gold_coin.png") 


@onready var panel: Panel = $Panel
@onready var overlay: ColorRect = $Overlay

# Header
@onready var advanced_view_button: Button = $Panel/MarginContainer/Buttons/AdvancedViewButton
@onready var close_button: Button = $Panel/MarginContainer/Buttons/CloseButton

@onready var item_name: Label = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Header/ItemName
@onready var item_type: Label = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Header/ItemType
@onready var item_base_stats: HBoxContainer = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Header/ItemBaseStats
@onready var scroll_container: ScrollContainer = $Panel/MarginContainer/ScrollContainer

# Content
@onready var attribute_container: VBoxContainer = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Content/HBoxContainer/ItemAttributes
@onready var item_description: Label = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Content/ItemDescription
@onready var item_bonus_attributes: VBoxContainer = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Content/BonusAttributes
@onready var level_container: HBoxContainer = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Header/LevelContainer

@onready var item_price: ItemPriceUI = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Content/ItemPrice

# Footer
@onready var trash_item_button: Button = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Footer/TrashItemButton
@onready var action_button: Button = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Footer/ActionButton

@onready var item_texture_rect: TextureRect = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Content/HBoxContainer/ItemTextureRect
@onready var unique_border_texture: Panel = $Panel/TextureMargin/UniqueBorderTexture
@onready var rarity_background_texture: TextureRect = $Panel/TextureMargin/RarityBackgroundTexture

const BG_GRADIENT_ITEM_COMMOM = preload("res://src/ui/themes/items_themes/bg_gradient_item_common.tres")
const BG_GRADIENT_ITEM_UNCOMMON = preload("res://src/ui/themes/items_themes/bg_gradient_item_uncommon.tres")
const BG_GRADIENT_ITEM_RARE = preload("res://src/ui/themes/items_themes/bg_gradient_item_rare.tres")
const BG_GRADIENT_ITEM_EPIC = preload("res://src/ui/themes/items_themes/bg_gradient_item_epic.tres")
const BG_GRADIENT_ITEM_LEGENDARY = preload("res://src/ui/themes/items_themes/bg_gradient_item_legendary.tres")
const BG_GRADIENT_ITEM_MITICAL = preload("res://src/ui/themes/items_themes/bg_gradient_item_mitical.tres")

const ItemNameRarityColors = {
	Item.RARITY.COMMON: Color.WHITE_SMOKE,
	Item.RARITY.UNCOMMON: Color.WEB_GREEN,
	Item.RARITY.RARE: Color(0.5, 1.0, 1.0, 1.0),
	Item.RARITY.EPIC: Color(0.5, 0.0, 0.85, 1.0),
	Item.RARITY.LEGENDARY: Color.ORANGE_RED,
	Item.RARITY.MYTHICAL: Color.RED,
}

const PLUS_BTN_REGION = Rect2(148, 20, 25, 25)
const MINUS_BTN_REGION = Rect2(180, 29, 25, 6)

const SET_BONUS_COLORS = {1: Color.GREEN, 0: Color.SLATE_GRAY}

var showing_advanced = false
var target_mouse_entered = null

func _init() -> void:
	self.hide()


func _ready() -> void:
	#InventoryManager.update_inventory_visible.connect(_on_inventory_visible_change)
	InventoryManager.update_item_information.connect(_update_item_information)
	overlay.mouse_entered.connect(func(): target_mouse_entered = true)
	overlay.mouse_exited.connect(func(): target_mouse_entered = false)
	close_button.pressed.connect(_on_close_button_pressed)
	trash_item_button.pressed.connect(_on_trash_item_button_pressed)
	advanced_view_button.pressed.connect(_on_advanced_view_button_pressed)
	action_button.pressed.connect(_on_use_equip_item_button_pressed)
	advanced_view_button.icon.region = PLUS_BTN_REGION


func _input(event: InputEvent) -> void:
	if target_mouse_entered:
		if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT :
			hide()

func _update_item_information(item: Item) -> void:
	ItemManager.current_selected_item = item
	scroll_container.scroll_vertical= 0
	showing_advanced = false
	update_unique_border_texture(item.is_unique)

	# Configurar nome do item com cor baseada na raridade
	item_name.text = item.item_name
	item_name.add_theme_color_override("font_color", ItemNameRarityColors.get(item.item_rarity, Color.WHITE_SMOKE))

	# Configurar tipo do item
	item_type.text = str(
		Item.get_category_text(item.item_category), " / ", Item.get_subcategory_text(item.item_subcategory)
	)
	
	# Configurar level
	setup_item_level(item.item_level)

	if item.item_category == Item.CATEGORY.EQUIPMENTS and item is EquipmentItem:
		item_base_stats.show()
		setup_base_stats_label(item)
		setup_bonus_attributes(item)
	else:
		item_base_stats.hide()

	# Configurar atributos e descrição
	setup_item_attributes(item.item_attributes)
	item_description.text = item.item_description
	
	# Configurar preço
	setup_sell_price(item.item_price, item.current_stack)

	# Configurar textura do item
	item_texture_rect.texture = item.item_texture

	# Configurar fundo baseado na raridade
	_set_background_based_on_rarity(item.item_rarity)

	# Configurar botões baseado no tipo de item
	update_header_butons_visibility(item)
	update_action_button_visibility(item)

	show()

func update_unique_border_texture(is_unique: bool = false) -> void:
	unique_border_texture.visible = is_unique

func setup_sell_price(price: float, stacks: int) -> void:
	item_price.update_item_price(price * stacks)

func setup_item_level(_item_level: int) -> void:
	var value_label = level_container.get_node("Value")
	value_label.text = str(" ", _item_level)
	if _item_level > PlayerStats.level:
		value_label.add_theme_color_override("font_color", Color.RED)
	else:
		if value_label.has_theme_color_override("font_color"):
			value_label.remove_theme_color_override("font_color")


func setup_base_stats_label(item: EquipmentItem) -> void:
	var label_type: Label = item_base_stats.get_node("LabelType")
	var label_values: Label = item_base_stats.get_node("LabelValues")

	var color: Color
	if item.equipment_type == EquipmentItem.TYPE.WEAPON:
		if not item.damage:
			return
		label_type.text = LocalizationManager.get_ui_text("damage")
		var min_damage = _format_attribute_value(item.damage.min_value, item.damage.type)
		var max_damage = _format_attribute_value(item.damage.max_value, item.damage.type)
		color = ItemAttribute.get_attribute_value_color(item.damage)
		label_values.text = str(min_damage, "-", max_damage)
	else:
		if not item.defense:
			return
		label_type.text = LocalizationManager.get_ui_text("defense")
		color = ItemAttribute.get_attribute_value_color(item.defense)
		label_values.text = _format_attribute_value(item.defense.value, item.defense.type)
	label_values.add_theme_color_override("font_color", color)

func setup_item_attributes(attributes: Array[ItemAttribute]) -> void:
	var item = ItemManager.current_selected_item
	var is_equipments = item.item_category == Item.CATEGORY.EQUIPMENTS
	# Limpa children existentes
	for child in attribute_container.get_children():
		child.queue_free()
	
	# Caso sem atributos
	if attributes.is_empty():
		var attribute_label = Label.new()
		attribute_label.text = LocalizationManager.get_ui_text("no_attributes")
		attribute_label.add_theme_font_override("font", ATTRBUTE_FONT)
		attribute_label.add_theme_font_size_override("font_size", 16)  # Tamanho fixo
		attribute_container.add_child(attribute_label)
		return
	
	for attribute in attributes:
		attribute_container.add_theme_constant_override("separation", 0)
		
		# Label principal do atributo
		var main_attribute_label = Label.new()
		
		# Formata o texto
		var formatted_value = _format_attribute_value(attribute.value, attribute.type)
		var attribute_name = ItemAttribute.get_attribute_type_name(attribute.type)
		
		main_attribute_label.add_theme_font_override("font", ATTRBUTE_FONT)
		main_attribute_label.add_theme_font_size_override("font_size", 16)
		
		if is_equipments:
			var attribute_color = ItemAttribute.get_attribute_value_color(attribute)
			main_attribute_label.add_theme_color_override("font_color", attribute_color)
		
		main_attribute_label.text = str("+", formatted_value, " ", attribute_name)
		attribute_container.add_child(main_attribute_label)
		
		if showing_advanced and is_equipments:
			var advanced_label = Label.new()
			var min_formatted = _format_attribute_value(attribute.min_value, attribute.type)
			var max_formatted = _format_attribute_value(attribute.max_value, attribute.type)
			
			advanced_label.text = str("(", min_formatted, " - ", max_formatted, ")")
			advanced_label.add_theme_color_override("font_color", Color.SLATE_GRAY)
			advanced_label.add_theme_font_override("font", ATTRBUTE_FONT)
			advanced_label.add_theme_font_size_override("font_size", 14)
			attribute_container.add_child(advanced_label)


static func _format_attribute_value(value: float, attribute_type: ItemAttribute.TYPE) -> String:
	# Tipos que devem ser exibidos como porcentagem

	if attribute_type in ItemAttribute.PERCENTAGE_TYPES:
		return "%.2f%%" % (value * 100)
	else:
		return "%.0f" % value


func setup_bonus_attributes(item: EquipmentItem) -> void:
	var text = ""
	var attributes = item.set_bonus_attributes
	var label: Label = item_bonus_attributes.get_node("Label")
	var attribute_label: Label = item_bonus_attributes.get_node("AttributeLabel")

	if item.equipment_group == EquipmentItem.GROUPS.COMMON:
		item_bonus_attributes.hide()
	else:
		if attributes.is_empty():
			item_bonus_attributes.hide()
			return
		item_bonus_attributes.show()
		for attribute in attributes:
			var attribute_name = LocalizationManager.get_ui_text(attribute.ATTRIBUTE_KEYS[attribute.type])
			var formatted_value = _format_attribute_value(attribute.value, attribute.type)
			text += str("\n+", formatted_value, " ", attribute_name)
		label.text = LocalizationManager.get_ui_text("set_bonus") + ":"
		attribute_label.text = text


func _set_background_based_on_rarity(rarity: Item.RARITY) -> void:
	match rarity:
		Item.RARITY.COMMON:
			rarity_background_texture.texture = BG_GRADIENT_ITEM_COMMOM
		Item.RARITY.UNCOMMON:
			rarity_background_texture.texture = BG_GRADIENT_ITEM_UNCOMMON
		Item.RARITY.RARE:
			rarity_background_texture.texture = BG_GRADIENT_ITEM_RARE
		Item.RARITY.EPIC:
			rarity_background_texture.texture = BG_GRADIENT_ITEM_EPIC
		Item.RARITY.LEGENDARY:
			rarity_background_texture.texture = BG_GRADIENT_ITEM_LEGENDARY
		Item.RARITY.MYTHICAL:
			rarity_background_texture.texture = BG_GRADIENT_ITEM_MITICAL
		_:
			rarity_background_texture.texture = BG_GRADIENT_ITEM_COMMOM


func update_action_button_visibility(item: Item) -> void:
	# Mostrar botão de usar/equipar apenas para itens usáveis ou equipáveis
	var is_usable = item.item_action != null
	var is_equipable = item.item_category == Item.CATEGORY.EQUIPMENTS
	var is_gem = item.item_subcategory == Item.SUBCATEGORY.GEM
	action_button.visible = is_usable or is_equipable or is_gem

	if is_usable:
		action_button.text = LocalizationManager.get_ui_text("use")
	elif is_equipable:
		if PlayerEquipments.is_equipped(item):
			action_button.text = LocalizationManager.get_ui_text("unequip")
		else:
			action_button.text = LocalizationManager.get_ui_text("equip")
	elif is_gem:
		action_button.text = LocalizationManager.get_ui_text("upgrade")
		
	# Sempre mostrar botão de descartar
	trash_item_button.visible = true

func update_header_butons_visibility(item: Item) -> void:
	var is_equipable = item.item_category == Item.CATEGORY.EQUIPMENTS
	advanced_view_button.visible = is_equipable

func _on_use_equip_item_button_pressed() -> void:
	var current_item = ItemManager.current_selected_item
	var is_consumable = current_item.item_category == Item.CATEGORY.CONSUMABLES
	var is_equipable = current_item.item_category == Item.CATEGORY.EQUIPMENTS

	# Lógica para usar ou equipar o item
	if current_item:
		if current_item.item_action != null and is_consumable:
			ItemManager.consume_item(current_item)
		elif is_equipable:
			ItemManager.equip_item(current_item)
		hide()


func _on_advanced_view_button_pressed() -> void:
	var current_item = ItemManager.current_selected_item
	showing_advanced = !showing_advanced
	# Atualiza o texto do botão
	if showing_advanced:
		advanced_view_button.icon.region = MINUS_BTN_REGION
		advanced_view_button.tooltip_text = LocalizationManager.get_ui_text("advanced_view")
	else:
		advanced_view_button.icon.region = PLUS_BTN_REGION
		advanced_view_button.tooltip_text = LocalizationManager.get_ui_text("advanced_view")
	# Atualiza a visualização dos atributos
	if current_item:
		setup_item_attributes(current_item.item_attributes)

func _on_trash_item_button_pressed() -> void:
	ItemManager.current_selected_item = null
	# Lógica para descartar o item
	if ItemManager.current_selected_item:
		ItemManager.remove_item(ItemManager.current_selected_item)
		hide()


func _on_close_button_pressed() -> void:
	ItemManager.current_selected_item = null
	hide()
