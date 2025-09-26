class_name InventoryItemDetailUI
extends Control

const PANEL_MIN_SIZE = Vector2(420, 420)
const PANEL_MAX_SIZE = Vector2(420, 620)

@onready var panel = $Panel
@onready var overlay: ColorRect = $Overlay
@onready var scroll_container: ScrollContainer = $Panel/MarginContainer/ScrollContainer
@onready var content_container: VBoxContainer = $Panel/MarginContainer/ScrollContainer/ContentContainer

# Header
@onready var advanced_view_button: Button = $Panel/MarginContainer/Buttons/AdvancedViewButton
@onready var close_button: Button = $Panel/MarginContainer/Buttons/CloseButton

@onready var item_name: Label = $Panel/MarginContainer/ScrollContainer/ContentContainer/Header/ItemName
@onready var item_type: Label = $Panel/MarginContainer/ScrollContainer/ContentContainer/Header/ItemType
@onready var level_container: HBoxContainer = $Panel/MarginContainer/ScrollContainer/ContentContainer/Header/LevelContainer
@onready var base_stats_container: HBoxContainer = $Panel/MarginContainer/ScrollContainer/ContentContainer/Header/BaseStatsContainer
@onready var item_quick_slot_selection: HBoxContainer = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/ItemQuickSlotSelection

# Content
@onready var attribute_list: VBoxContainer = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/MainAttributesContent/AttributeList
@onready var item_texture_rect: TextureRect = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/MainAttributesContent/ItemTextureRect
@onready var description_text: DescriptionText = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/DescriptionText
@onready var gem_available_slot_info: GemAvailableSlotInfoUI = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/GemAvailableSlotInfo
@onready var equipment_gem_sockets_slots: EquipmentGemSocketSlots = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/EquipmentGemSocketsSlots
@onready var set_bonus_attributes_content: VBoxContainer = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/SetBonusAttributesContent
@onready var potion_cooldown_info: HBoxContainer = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/PotionCooldownInfo
@onready var cooldown_label: DefaultLabel = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/PotionCooldownInfo/CooldownLabel
@onready var item_price: ItemPriceUI = $Panel/MarginContainer/ScrollContainer/ContentContainer/Content/ItemPrice

# Footer
@onready var action_button: Button = $Panel/MarginContainer/ScrollContainer/ContentContainer/Footer/ActionButton
@onready var trash_item_button: Button = $Panel/MarginContainer/ScrollContainer/ContentContainer/Footer/TrashItemButton

@onready var rarity_texture: TextureRect = $Panel/RarityTexture
@onready var unique_border: Panel = $Panel/UniqueBorder

const VIEW_ICON_CLOSE = Rect2(240, 64, 32, 32)
const VIEW_ICON_OPEN = Rect2(272, 64, 32, 32)

const SET_BONUS_COLORS = {1: Color.GREEN, 0: Color.SLATE_GRAY}

var showing_advanced = false
var target_mouse_entered = null


func _ready() -> void:
	base_stats_container.hide()
	item_quick_slot_selection.hide()
	gem_available_slot_info.hide()
	equipment_gem_sockets_slots.hide()
	advanced_view_button.hide()
	set_bonus_attributes_content.hide()

	overlay.mouse_entered.connect(func(): target_mouse_entered = true)
	overlay.mouse_exited.connect(func(): target_mouse_entered = false)

	if not close_button.pressed.is_connected(_on_close_button_pressed):
		close_button.pressed.connect(_on_close_button_pressed)
	if not trash_item_button.pressed.is_connected(_on_trash_item_button_pressed):
		trash_item_button.pressed.connect(_on_trash_item_button_pressed)
	if not advanced_view_button.pressed.is_connected(_on_advanced_view_button_pressed):
		advanced_view_button.pressed.connect(_on_advanced_view_button_pressed)
	action_button.pressed.connect(_on_action_button_pressed)

	panel.custom_minimum_size = PANEL_MIN_SIZE
	panel.size = PANEL_MIN_SIZE

	_setup()


func _setup() -> void:
	var item = ItemManager.current_selected_item
	if item == null:
		return

	scroll_container.scroll_vertical = 0
	showing_advanced = false
	_update_unique_border_texture(item.is_unique)

	# Configurar botões baseado no tipo de item
	_update_header_buttons_visibility(item)

	_update_header_information(item)

	match item.item_category:
		Item.CATEGORY.EQUIPMENTS:
			advanced_view_button.icon.region = VIEW_ICON_OPEN
			_update_equipment_information(item as EquipmentItem)
		Item.CATEGORY.CONSUMABLES:
			_update_consumables_information(item)
		Item.CATEGORY.LOOTS:
			_update_loot_information(item)
		_:
			pass

	# Configurar atributos e descrição
	_update_item_attributes_info(item)
	_update_item_descriptions(item.item_descriptions)

	# Configurar preço
	_update_sell_price_info(item.item_price, item.current_stack)

	# Configurar textura do item
	item_texture_rect.texture = item.item_texture
	# Configurar fundo baseado na raridade
	rarity_texture.texture = ItemManager.get_background_theme_by_rarity(item.item_rarity)

	# show()
	call_deferred("_adjust_panel_size")


func _update_header_information(item: Item) -> void:
	item_name.text = item.item_name
	item_name.add_theme_color_override("font_color", item.get_item_rarity_text_color())

	var category = Item.get_category_text(item.item_category)
	var subcategory = Item.get_subcategory_text(item.item_subcategory)
	item_type.text = str(category, " / ", subcategory)

	# Configurar level
	_setup_item_level(item.item_level)


func _setup_item_level(_item_level: int) -> void:
	var value_label = level_container.get_node("Value")
	value_label.text = str(" ", _item_level)
	if _item_level > PlayerStats.level:
		value_label.add_theme_color_override("font_color", Color.RED)
	else:
		if value_label.has_theme_color_override("font_color"):
			value_label.remove_theme_color_override("font_color")


func _update_unique_border_texture(is_unique: bool = false) -> void:
	unique_border.visible = is_unique


func _update_sell_price_info(price: int, _stacks: int) -> void:
	var total_price = price * _stacks
	var coins = CurrencyManager.convert_value_to_coins(total_price)
	item_price.update_golds(coins.golds)
	item_price.update_silvers(coins.silvers, coins.golds >= 1)
	item_price.update_bronzes(coins.bronzes, coins.silvers >= 1)


func _update_equipment_information(equipment: EquipmentItem) -> void:
	base_stats_container.show()
	advanced_view_button.show()
	equipment_gem_sockets_slots.show()
	
	_update_base_stats_info(equipment)
	_update_gem_sockets_info(equipment)
	_update_bonus_attributes_info(equipment)

	if PlayerEquipments.is_equipped(equipment):
		action_button.text = LocalizationManager.get_ui_text("unequip")
	else:
		action_button.text = LocalizationManager.get_ui_text("equip")


func _update_base_stats_info(item: EquipmentItem) -> void:
	var label_type: Label = base_stats_container.get_node("LabelType")
	var label_values: Label = base_stats_container.get_node("LabelValues")
	var power_value: Label = base_stats_container.get_node("PowerValue")

	var power_label = LocalizationManager.get_ui_text("power")
	power_value.text = str("%s: " % power_label, snappedi(item.equipment_power, 0))
	var color: Color
	if item.equipment_type == EquipmentItem.TYPE.WEAPON:
		if not item.damage:
			return
		label_type.text = LocalizationManager.get_attribute_text("damage")
		var min_damage = _format_attribute_value(item.damage.min_value, item.damage.type)
		var max_damage = _format_attribute_value(item.damage.max_value, item.damage.type)
		color = ItemAttribute.get_attribute_value_color(item.damage)
		label_values.text = str(min_damage, "-", max_damage)
	else:
		if not item.defense:
			return
		label_type.text = LocalizationManager.get_attribute_text("defense")
		color = ItemAttribute.get_attribute_value_color(item.defense)
		label_values.text = _format_attribute_value(item.defense.value, item.defense.type)
	label_values.add_theme_color_override("font_color", color)


func _update_bonus_attributes_info(equipment: EquipmentItem) -> void:
	if equipment.equipment_set not in EquipmentConsts.UNIQUES_SETS:
		set_bonus_attributes_content.hide()
		return

	set_bonus_attributes_content.show()
	var set_info: SetUIInfo = SetBonus.get_set_ui_info(equipment.equipment_set)

	var set_name_label = set_bonus_attributes_content.get_node("Label")
	var set_name_key = EquipmentConsts.EQUIPMENTS_SET_KEYS.get(equipment.equipment_set)
	set_name_label.text = LocalizationManager.get_equipment_text("uniques.%s.set_name" % set_name_key) + ":"

	for piece_info in set_info.get_equipped_pieces():
		var equip_name_label = DefaultLabel.new()
		set_bonus_attributes_content.add_child(equip_name_label)
		equip_name_label.text = str("  ", piece_info.get_name())
		equip_name_label.set_color(Color.ROYAL_BLUE if piece_info.is_equipped() else Color.DIM_GRAY)

	var bonus_label = DefaultLabel.new()
	set_bonus_attributes_content.add_child(bonus_label)
	bonus_label.text = LocalizationManager.get_ui_text("set_bonus") + ":"

	for attrib_info in set_info.get_active_bonuses():
		var bonus_attrib_label = DefaultLabel.new()
		set_bonus_attributes_content.add_child(bonus_attrib_label)
		bonus_attrib_label.text = str("  ", attrib_info.get_description())
		bonus_attrib_label.set_color(Color.ROYAL_BLUE if attrib_info.is_active() else Color.DIM_GRAY)


func _update_gem_sockets_info(equipment_item: EquipmentItem) -> void:
	var attached_gems = equipment_item.attached_gems
	for slot_index in equipment_item.available_sockets:
		if slot_index < attached_gems.size():
			var gem = attached_gems[slot_index]
			if gem:
				equipment_gem_sockets_slots.gems.append(gem)
			else:
				equipment_gem_sockets_slots.gems.append(null)
		else:
			equipment_gem_sockets_slots.gems.append(null)
	equipment_gem_sockets_slots.setup()


func _update_consumables_information(item: Item) -> void:
	item_quick_slot_selection.show()
	
	var is_item_assigned = InventoryManager.is_item_in_quick_slots(item)

	for child in item_quick_slot_selection.get_children():
		if child.name.contains("Button"):
			var button = child as Button
			var index = int(button.name.get_slice("Button", 1))
			
			if InventoryManager.quick_slots[index] == item:
				button.button_pressed = is_item_assigned

			button.pressed.connect(InventoryManager._assign_quick_slot_item.bind(item, index))

	if item.item_subcategory == Item.SUBCATEGORY.POTION:
		cooldown_label.show()
		var potion_item = item as PotionItem
		var cooldown_text = LocalizationManager.get_ui_text("cooldown")
		var cooldown_remaining = PlayerEvents.get_potion_cooldown_remaining(potion_item.item_id)
		cooldown_remaining = str(int(cooldown_remaining), "s")
		cooldown_label.text = str(cooldown_text, ": ", cooldown_remaining)

	action_button.text = LocalizationManager.get_ui_text("use")


func _update_loot_information(item: Item) -> void:
	match item.item_subcategory:
		Item.SUBCATEGORY.RESOURCE:
			action_button.text = LocalizationManager.get_ui_text("quick_sell")
		Item.SUBCATEGORY.GEM:
			_update_gem_information(item as GemItem)
		_:
			action_button.text = LocalizationManager.get_ui_text("quick_sell")


func _update_gem_information(gem: GemItem) -> void:
	var possible_equip_types = gem.available_equipments_type

	action_button.show()
	level_container.show()
	gem_available_slot_info.show()

	if gem.can_upgrade_gem():
		action_button.text = LocalizationManager.get_ui_text("upgrade")
	else:
		action_button.text = LocalizationManager.get_ui_text("maximized")
		action_button.disabled = true

	gem_available_slot_info.equip_slots = possible_equip_types
	gem_available_slot_info.display_names()


func _update_item_attributes_info(item: Item) -> void:
	var attributes: Array[ItemAttribute] = item.item_attributes
	var is_equipments = item.item_category == Item.CATEGORY.EQUIPMENTS

	for child in attribute_list.get_children():
		child.queue_free()

	# Caso sem atributos
	if attributes.is_empty():
		var attribute_label = DefaultLabel.new()
		attribute_list.add_child(attribute_label)
		attribute_label.text = LocalizationManager.get_ui_text("no_attributes")
		return

	for attribute in attributes:
		attribute_list.add_theme_constant_override("separation", 0)

		var main_attribute_label = DefaultLabel.new()
		attribute_list.add_child(main_attribute_label)

		var formatted_value = _format_attribute_value(attribute.value, attribute.type)
		var attribute_name = ItemAttribute.get_attribute_type_name(attribute.type)

		if is_equipments:
			var attribute_color = ItemAttribute.get_attribute_value_color(attribute)
			main_attribute_label.set_color(attribute_color)

		main_attribute_label.text = str("+", formatted_value, " ", attribute_name)

		if showing_advanced and is_equipments:
			var advanced_label = DefaultLabel.new()
			var min_formatted = _format_attribute_value(attribute.min_value, attribute.type)
			var max_formatted = _format_attribute_value(attribute.max_value, attribute.type)

			attribute_list.add_child(advanced_label)
			advanced_label.text = str("(", min_formatted, " - ", max_formatted, ")")
			advanced_label.set_color(Color.SLATE_GRAY)


func _update_item_descriptions(description: String) -> void:
	description_text.text = description

static func _format_attribute_value(value: float, attribute_type: ItemAttribute.TYPE) -> String:
	if attribute_type in ItemAttribute.PERCENTAGE_TYPES:
		return StringUtils.format_decimal(value)
	else:
		return "%.0f" % value


func _update_header_buttons_visibility(item: Item) -> void:
	var is_equippable = item.item_category == Item.CATEGORY.EQUIPMENTS
	advanced_view_button.visible = is_equippable


func _on_action_button_pressed() -> void:
	var current_item = ItemManager.current_selected_item
	if not current_item:
		return

	var is_usable = current_item.item_usable
	
	
	if is_usable:
		var category = current_item.item_category
		var subcategory = current_item.item_subcategory

		match category:
			Item.CATEGORY.CONSUMABLES:
				match subcategory:
					Item.SUBCATEGORY.POTION:
						PlayerEvents.use_potion(current_item as PotionItem)
					_:
						return

			Item.CATEGORY.EQUIPMENTS:
				PlayerEvents.equip_item(current_item as EquipmentItem)

			Item.CATEGORY.LOOTS:
				match subcategory:
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
		_update_item_attributes_info(current_item)


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
		rarity_texture.custom_minimum_size.y = PANEL_MAX_SIZE.y - 7
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	else:
		panel.custom_minimum_size.y = total_height
		rarity_texture.custom_minimum_size.y = total_height - 7
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
	var item = ItemManager.current_selected_item
	if InventoryManager.remove_item(item):
		ItemManager.update_selected_item(null)
		queue_free()


func _on_close_button_pressed() -> void:
	ItemManager.update_selected_item(null)
	queue_free()
