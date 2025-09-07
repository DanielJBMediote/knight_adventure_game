class_name InventoryItemDetailUI
extends Control

const PANEL_MIN_SIZE = Vector2(460, 420)
const PANEL_MAX_SIZE = Vector2(460, 620)

@onready var panel = $Panel
@onready var overlay: ColorRect = $Overlay
@onready var scroll_container: ScrollContainer = $Panel/MarginContainer/ScrollContainer
@onready var content_container: VBoxContainer = $Panel/MarginContainer/ScrollContainer/ContentContainer

# Header
@onready var advanced_view_button: Button = $Panel/MarginContainer/Buttons/AdvancedViewButton
@onready var close_button: Button = $Panel/MarginContainer/Buttons/CloseButton

@onready var item_name: Label = $Panel/MarginContainer/ScrollContainer/ContentContainer/Header/ItemName
@onready var item_type: Label = $Panel/MarginContainer/ScrollContainer/ContentContainer/Header/ItemType
@onready var base_stats_container: HBoxContainer = $Panel/MarginContainer/ScrollContainer/ContentContainer/Header/BaseStatsContainer

# Content
@onready var attribute_container: VBoxContainer = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/HBoxContainer/AttributeContainer
@onready var description_container: VBoxContainer = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/DescriptionContainer
@onready var gem_available_slot_info: GemAvailableSlotInfoUI = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/GemAvailableSlotInfo
@onready var equipment_gem_sockets_slots: EquipmentGemSocketSlots = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/EquipmentGemSocketsSlots

@onready var attribute_bonus_container: VBoxContainer = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/AttributeBonusContainer
@onready var level_container: HBoxContainer = $Panel/MarginContainer/ScrollContainer/ContentContainer/Header/LevelContainer

@onready var item_price: ItemPriceUI = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/ItemPrice

# Footer
@onready var action_button: Button = $Panel/MarginContainer/ScrollContainer/ContentContainer/Footer/ActionButton
@onready var trash_item_button: Button = $Panel/MarginContainer/ScrollContainer/ContentContainer/Footer/TrashItemButton

@onready var item_texture_rect: TextureRect = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/HBoxContainer/ItemTextureRect
@onready var unique_texture: TextureRect = $Panel/TextureMargin/UniqueTexture
@onready var rarity_background_texture: TextureRect = $Panel/TextureMargin/RarityBackgroundTexture


const VIEW_ICON_OPEN = Rect2(241, 65, 31, 21)
const VIEW_ICON_CLOSE = Rect2(273, 78, 31, 18)

const SET_BONUS_COLORS = {1: Color.GREEN, 0: Color.SLATE_GRAY}

var showing_advanced = false
var target_mouse_entered = null

func _ready() -> void:
	overlay.mouse_entered.connect(func(): target_mouse_entered = true)
	overlay.mouse_exited.connect(func(): target_mouse_entered = false)
	close_button.pressed.connect(_on_close_button_pressed)
	trash_item_button.pressed.connect(_on_trash_item_button_pressed)
	advanced_view_button.pressed.connect(_on_advanced_view_button_pressed)
	action_button.pressed.connect(_on_action_button_pressed)

	panel.custom_minimum_size = PANEL_MIN_SIZE
	panel.size = PANEL_MIN_SIZE

func setup(item: Item) -> void:
	scroll_container.scroll_vertical = 0
	showing_advanced = false
	update_unique_border_texture(item.is_unique)

	# Configurar nome do item com cor baseada na raridade
	item_name.text = item.item_name
	item_name.add_theme_color_override("font_color", item.get_item_rarity_text_color())

	# Configurar tipo do item
	item_type.text = str(
		Item.get_category_text(item.item_category), " / ", Item.get_subcategory_text(item.item_subcategory)
	)
	
	# Configurar level
	setup_item_level(item.item_level)

	match item.item_category:
		Item.CATEGORY.EQUIPMENTS:
			advanced_view_button.icon.region = VIEW_ICON_OPEN
			update_equipment_informations(item as EquipmentItem)
		Item.CATEGORY.CONSUMABLES:
			update_consumables_informations(item)
		Item.CATEGORY.LOOTS:
			update_loot_informations(item)
		_:
			pass


	# Configurar atributos e descrição
	update_item_attributes_info(item)
	update_item_descriptions(item.item_descriptions)
	
	# Configurar preço
	update_sell_price_info(item.item_price, item.current_stack)

	# Configurar textura do item
	item_texture_rect.texture = item.item_texture

	# Configurar fundo baseado na raridade
	_set_background_based_on_rarity(item.item_rarity)

	# Configurar botões baseado no tipo de item
	update_header_butons_visibility(item)

	# show()
	call_deferred("_adjust_panel_size")

func update_unique_border_texture(is_unique: bool = false) -> void:
	unique_texture.visible = is_unique


func update_sell_price_info(price: int, _stacks: int) -> void:
	var total_price = price * _stacks
	var coins = CurrencyManager.convert_value_to_coins(total_price)
	item_price.update_golds(coins.golds)
	item_price.update_silvers(coins.silvers, coins.golds >= 1)
	item_price.update_bronzes(coins.bronzes, coins.silvers >= 1)


func setup_item_level(_item_level: int) -> void:
	var value_label = level_container.get_node("Value")
	value_label.text = str(" ", _item_level)
	if _item_level > PlayerStats.level:
		value_label.add_theme_color_override("font_color", Color.RED)
	else:
		if value_label.has_theme_color_override("font_color"):
			value_label.remove_theme_color_override("font_color")


func update_equipment_informations(equipment: EquipmentItem) -> void:
	gem_available_slot_info.hide()
	equipment_gem_sockets_slots.show()
	base_stats_container.show()
	trash_item_button.show()
	advanced_view_button.show()
	update_base_stats_info(equipment)
	update_gem_sockets_info(equipment)
	update_bonus_attributes_info(equipment)

	if PlayerEquipments.is_equipped(equipment):
		action_button.text = LocalizationManager.get_ui_text("unequip")
	else:
		action_button.text = LocalizationManager.get_ui_text("equip")

func update_base_stats_info(item: EquipmentItem) -> void:
	var label_type: Label = base_stats_container.get_node("LabelType")
	var label_values: Label = base_stats_container.get_node("LabelValues")
	var power_value: Label = base_stats_container.get_node("PowerValue")

	var power_label = LocalizationManager.get_ui_text("power")
	power_value.text = str("%s: " % power_label, snappedi(item.equipment_power, 0))
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

func update_bonus_attributes_info(equipment: EquipmentItem) -> void:
	if equipment.equipment_set not in EquipmentConsts.UNIQUES_SETS:
		attribute_bonus_container.hide()
		return
	
	attribute_bonus_container.show()
	var set_info: SetUIInfo = SetBonus.get_set_ui_info(equipment.equipment_set)

	var set_name_label = attribute_bonus_container.get_node("Label")
	var set_name_key = EquipmentConsts.EQUIPMENTS_SET_KEYS.get(equipment.equipment_set)
	set_name_label.text = LocalizationManager.get_equipment_text("uniques.%s.set_name" % set_name_key) + ":"

	for piece_info in set_info.get_equipped_pieces():
		var equip_name_label = AttributeLabel.new()
		equip_name_label.custom_text = str("  ", piece_info.get_name())
		equip_name_label.custom_color = Color.ROYAL_BLUE if piece_info.is_equipped() else Color.DIM_GRAY
		attribute_bonus_container.add_child(equip_name_label)
	
	var bonus_label = AttributeLabel.new()
	bonus_label.custom_text = LocalizationManager.get_ui_text("set_bonus") + ":"
	attribute_bonus_container.add_child(bonus_label)

	for attrib_info in set_info.get_active_bonuses():
		var bonus_attrib_label = AttributeLabel.new()
		bonus_attrib_label.custom_text = str("  ", attrib_info.get_description())
		bonus_attrib_label.custom_color = Color.ROYAL_BLUE if attrib_info.is_active() else Color.DIM_GRAY
		attribute_bonus_container.add_child(bonus_attrib_label)


func update_gem_sockets_info(equipment: EquipmentItem) -> void:
	var gems = equipment.gems_in_sockets
	for slot_index in equipment.available_sockets:
		if slot_index < gems.size():
			var gem = gems[slot_index]
			if gem:
				equipment_gem_sockets_slots.gems.append(gem)
			else:
				equipment_gem_sockets_slots.gems.append(null)
		else:
			equipment_gem_sockets_slots.gems.append(null)
	equipment_gem_sockets_slots.setup()

func update_consumables_informations(_item: Item) -> void:
	base_stats_container.hide()
	trash_item_button.show()
	equipment_gem_sockets_slots.hide()
	advanced_view_button.hide()
	gem_available_slot_info.hide()
	attribute_bonus_container.hide()

	action_button.text = LocalizationManager.get_ui_text("use")


func update_loot_informations(item: Item) -> void:
	equipment_gem_sockets_slots.hide()
	attribute_bonus_container.hide()
	base_stats_container.hide()
	advanced_view_button.hide()
	trash_item_button.show()
	
	match item.item_subcategory:
		Item.SUBCATEGORY.RESOURCE:
			action_button.text = LocalizationManager.get_ui_text("quick_sell")
		Item.SUBCATEGORY.GEM:
			update_gem_informations(item as GemItem)
		_:
			action_button.text = LocalizationManager.get_ui_text("quick_sell")
	
	action_button.show()


func update_gem_informations(gem: GemItem) -> void:
	var possible_equip_types = gem.equip_slot_sockets

	level_container.show()
	gem_available_slot_info.show()
		
	if gem.can_upgrade_gem():
		action_button.text = LocalizationManager.get_ui_text("upgrade")
	else:
		action_button.text = LocalizationManager.get_ui_text("maximized")
		action_button.disabled = true

	gem_available_slot_info.equip_slots = possible_equip_types
	gem_available_slot_info.display_names()


func update_item_attributes_info(item: Item) -> void:
	var attributes: Array[ItemAttribute] = item.item_attributes
	var is_equipments = item.item_category == Item.CATEGORY.EQUIPMENTS
	
	for child in attribute_container.get_children():
		child.queue_free()
	
	# Caso sem atributos
	if attributes.is_empty():
		var attribute_label = AttributeLabel.new()
		attribute_label.custom_text = LocalizationManager.get_ui_text("no_attributes")
		attribute_container.add_child(attribute_label)
		return
	
	for attribute in attributes:
		attribute_container.add_theme_constant_override("separation", 0)
		
		var main_attribute_label = AttributeLabel.new()
		var formatted_value = _format_attribute_value(attribute.value, attribute.type)
		var attribute_name = ItemAttribute.get_attribute_type_name(attribute.type)
		
		if is_equipments:
			var attribute_color = ItemAttribute.get_attribute_value_color(attribute)
			main_attribute_label.custom_color = attribute_color
		
		main_attribute_label.custom_text = str("+", formatted_value, " ", attribute_name)
		attribute_container.add_child(main_attribute_label)
		
		if showing_advanced and is_equipments:
			var advanced_label = AttributeLabel.new()
			var min_formatted = _format_attribute_value(attribute.min_value, attribute.type)
			var max_formatted = _format_attribute_value(attribute.max_value, attribute.type)
			
			advanced_label.custom_text = str("(", min_formatted, " - ", max_formatted, ")")
			advanced_label.custom_color = Color.SLATE_GRAY
			attribute_container.add_child(advanced_label)

func update_item_descriptions(descriptions: Array[String]) -> void:
	for desc in descriptions:
		var new_label = AttributeLabel.new()
		new_label.custom_text = desc
		description_container.add_child(new_label)
		new_label.add_theme_color_override("font_color", Color.WHITE)
		new_label.custom_minimum_size.y = 24
		new_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


static func _format_attribute_value(value: float, attribute_type: ItemAttribute.TYPE) -> String:
	# Tipos que devem ser exibidos como porcentagem
	if attribute_type in ItemAttribute.PERCENTAGE_TYPES:
		return "%.2f%%" % (value * 100)
	else:
		return "%.0f" % value


func _set_background_based_on_rarity(rarity: Item.RARITY) -> void:
	match rarity:
		Item.RARITY.COMMON:
			rarity_background_texture.texture = ItemManager.BG_GRADIENT_ITEM_COMMOM
		Item.RARITY.UNCOMMON:
			rarity_background_texture.texture = ItemManager.BG_GRADIENT_ITEM_UNCOMMON
		Item.RARITY.RARE:
			rarity_background_texture.texture = ItemManager.BG_GRADIENT_ITEM_RARE
		Item.RARITY.EPIC:
			rarity_background_texture.texture = ItemManager.BG_GRADIENT_ITEM_EPIC
		Item.RARITY.LEGENDARY:
			rarity_background_texture.texture = ItemManager.BG_GRADIENT_ITEM_LEGENDARY
		Item.RARITY.MYTHICAL:
			rarity_background_texture.texture = ItemManager.BG_GRADIENT_ITEM_MITICAL
		_:
			rarity_background_texture.texture = ItemManager.BG_GRADIENT_ITEM_COMMOM


func update_header_butons_visibility(item: Item) -> void:
	var is_equipable = item.item_category == Item.CATEGORY.EQUIPMENTS
	advanced_view_button.visible = is_equipable


func _on_action_button_pressed() -> void:
	var current_item = ItemManager.current_selected_item
	var is_consumable = current_item.item_category == Item.CATEGORY.CONSUMABLES
	var is_equipable = current_item.item_category == Item.CATEGORY.EQUIPMENTS
	var is_loots = current_item.item_category == Item.CATEGORY.LOOTS

	# Lógica para usar ou equipar o item
	if current_item:
		if current_item.item_action != null and is_consumable:
			ItemManager.consume_item(current_item)
		elif is_equipable:
			ItemManager.equip_item(current_item)
		elif is_loots:
			match current_item.item_subcategory:
				Item.SUBCATEGORY.RESOURCE:
					pass
				Item.SUBCATEGORY.GEM:
					handle_gem_action(current_item as GemItem)
	
	queue_free()
		
func handle_gem_action(gem: GemItem) -> void:
	if gem.can_upgrade_gem():
		var gem_upgrade_ui_scene: PackedScene = load("res://src/gameplay/mechanics/inventory/gem_upgrade_ui/gem_upgrade_ui.tscn")
		var gem_upgrade_ui = gem_upgrade_ui_scene.instantiate() as GemUpgradeUI
		var player_ui_node = get_parent()
		player_ui_node.add_child(gem_upgrade_ui)
		gem_upgrade_ui.setup(gem)

func _on_advanced_view_button_pressed() -> void:
	var current_item = ItemManager.current_selected_item
	showing_advanced = !showing_advanced
	# Atualiza o texto do botão
	if showing_advanced:
		advanced_view_button.icon.region = VIEW_ICON_CLOSE
		advanced_view_button.tooltip_text = LocalizationManager.get_ui_text("advanced_view")
	else:
		advanced_view_button.icon.region = VIEW_ICON_OPEN
		advanced_view_button.tooltip_text = LocalizationManager.get_ui_text("advanced_view")
	# Atualiza a visualização dos atributos
	if current_item:
		update_item_attributes_info(current_item)


func _adjust_panel_size():
	# Forçar atualização do layout
	content_container.queue_redraw()
	await get_tree().process_frame
	
	# Calcular altura necessária para o conteúdo
	var content_height = content_container.get_combined_minimum_size().y
	var margins = panel.get_theme_constant("margin_top", "Panel") + panel.get_theme_constant("margin_bottom", "Panel")
	var scroll_margins = scroll_container.get_theme_constant("margin_top", "ScrollContainer") + scroll_container.get_theme_constant("margin_bottom", "ScrollContainer")
	
	var total_height = content_height + margins + scroll_margins + 40 # Adicionar um pouco de padding
	
	# Limitar a altura máxima
	if total_height > PANEL_MAX_SIZE.y:
		panel.custom_minimum_size.y = PANEL_MAX_SIZE.y
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	else:
		panel.custom_minimum_size.y = total_height
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	# Centralizar o painel na tela
	var viewport_size = get_viewport().get_visible_rect().size
	panel.position.x = (viewport_size.x - panel.size.x) / 2
	panel.position.y = (viewport_size.y - panel.size.y) / 2


func _input(event: InputEvent) -> void:
	if target_mouse_entered:
		if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			ItemManager.update_selected_item(null)
			queue_free()


func _on_trash_item_button_pressed() -> void:
	ItemManager.update_selected_item(null)
	queue_free()


func _on_close_button_pressed() -> void:
	ItemManager.update_selected_item(null)
	queue_free()
