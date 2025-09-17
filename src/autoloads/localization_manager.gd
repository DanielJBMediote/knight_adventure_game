extends Node
signal language_changed
signal translation_loaded(category)

var current_language: String = "en"
var loaded_translations: Dictionary = {} # Dicionário de categorias carregadas

func _ready() -> void:
	load_language("en")

func load_language(language_code: String) -> bool:
	current_language = language_code
	loaded_translations.clear()
	load_translation_category("ui")
	load_translation_category("items_general")
	language_changed.emit()
	return true

func load_translation_category(category: String) -> bool:
	var file_path = "res://localization/%s/%s.json" % [current_language, category]
	
	if ResourceLoader.exists(file_path):
		var translation_data = ResourceLoader.load(file_path)
		loaded_translations[category] = translation_data.data
		translation_loaded.emit(category)
		return true
	
	return false

func get_translation(category: String, key: String, default: String = "") -> String:
	var keys = key.split(".")
	
	# Carrega a categoria se não estiver carregada
	if not loaded_translations.has(category):
		if not load_translation_category(category):
			if default:
				return default
			else:
				printerr("CATEGORY_NOT_FOUND:" + category)
				return "MISSING:" + key
	
	var value = loaded_translations.get(category, {})
	
	for k in keys:
		if value.has(k):
			value = value[k]
		else:
			if default:
				return default
			else:
				printerr("MISSING_TRANSLATION:" + key)
				return "MISSING:" + key
	
	return str(value)

# Função para descarregar categorias não usadas
func unload_translation_category(category: String) -> void:
	if loaded_translations.has(category):
		loaded_translations.erase(category)

# Pré-carregar categorias que serão usadas em breve
func preload_categories(categories: Array) -> void:
	for category in categories:
		if not loaded_translations.has(category):
			load_translation_category(category)

## Return the formatted string, and replace the params 
## with the respective string inside braces {}
func get_translation_format(key: String, params: Dictionary, default: String = "") -> String:
	var text = get_translation(key, default)
	
	for param_key in params:
		text = text.replace("{%s}" % param_key, str(params[param_key]))
	
	return text

## Format text replacing all charactes/words inside braces {}
func format_text_with_params(text: String, params: Dictionary) -> String:
	var result = text
	for param_key in params:
		result = result.replace("{%s}" % param_key, str(params[param_key]))
	return result

func get_item_name_text(key: String) -> String:
	return get_translation("items_general", key)

func get_item_rarity_name_text(key: String) -> String:
	return get_translation("items_general", "rarity." + key)

func get_item_rarity_prefix_text(key: String) -> String:
	return get_translation("items_general", "rarity_prefix." + key)

func get_item_rarity_sufix_text(key: String) -> String:
	return get_translation("items_general", "rarity_sufix." + key)

func get_item_category_name_text(key: String) -> String:
	return get_translation("items_general", "category." + key)

func get_item_subcategory_name_text(key: String) -> String:
	return get_translation("items_general", "subcategory." + key)
	
# Potions get functions
func get_potion_name_text(key: String) -> String:
	return get_translation("items_potions", "names." + key)

func get_potion_base_description_text(key: String) -> String:
	return get_translation("items_potions", "base_descriptions." + key)


# Gems get functions
func get_gem_name_text(key: String) -> String:
	return get_translation("items_gems", "names." + key)

func get_gem_base_description_text(key: String) -> String:
	return get_translation("items_gems", "base_descriptions." + key)

func get_gem_alert_text(key: String) -> String:
	return get_translation("items_gems", "alert_messages." + key)

func get_gem_unique_description_text(key: String) -> String:
	return get_translation("items_gems", "unique_descriptions." + key)

func get_gem_quality_text(key: String) -> String:
	return get_translation("items_gems", "quality." + key)


# Runes Section
func get_rune_name_text(key: String) -> String:
	return get_translation("items_runes", "names." + key)

func get_rune_description_text(key: String) -> String:
	return get_translation("items_runes", "base_descriptions." + key)


func get_attribute_text(key: String) -> String:
	return get_translation("attributes", key)

# Equipment Section
func get_equipment_common_item(set_key: EquipmentItem.SETS, equip_type: EquipmentItem.TYPE) -> String:
	var _set_name = EquipmentConsts.EQUIPMENTS_SET_KEYS[set_key]
	var type_name = EquipmentConsts.EQUIPMENT_TYPE_KEYS[equip_type]
	var path_key = "commons.%s.%s" % [_set_name, type_name]
	return get_translation("items_equipments", path_key)
	
func get_equipment_unique_item(set_key: EquipmentItem.SETS, equip_type: EquipmentItem.TYPE) -> String:
	var _set_name = EquipmentConsts.EQUIPMENTS_SET_KEYS[set_key]
	var type_name = EquipmentConsts.EQUIPMENT_TYPE_KEYS[equip_type]
	var path_key = "uniques.%s.%s" % [_set_name, type_name]
	return get_translation("items_equipments", path_key)

func get_equipment_text(attribute: String) -> String:
	return get_translation("items_equipments", attribute)

func get_equipment_type_name(equip_type: EquipmentItem.TYPE) -> String:
	var type_key = EquipmentConsts.EQUIPMENT_TYPE_KEYS[equip_type]
	return get_translation("items_equipments", "types." + type_key)


func get_npc_data(npc_name: String) -> Dictionary:
	var data = {}
	if loaded_translations.get("npcs", {}).is_empty():
		preload_categories(["npcs"])
		data = loaded_translations.get("npcs", {}).get(npc_name, {})
		unload_translation_category("npcs")
	else:
		data = loaded_translations.get("npcs", {}).get(npc_name, {})
		unload_translation_category("npcs")
	return data

func get_ui_text(ui_key: String) -> String:
	return get_translation("ui", ui_key)

func get_ui_esgs_text(ui_key: String) -> String:
	return get_translation("ui", "gem_socket_system_ui." + ui_key)

func get_ui_alerts_text(ui_key: String) -> String:
	return get_translation("ui", "alerts." + ui_key)
