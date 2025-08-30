extends Node

signal language_changed

var current_language: String = "en"
var translations: Dictionary = {}

func _ready() -> void:
	load_language("en") # Idioma padrão

func load_language(language_code: String) -> bool:
	var file_path = "res://localization/%s.json" % language_code
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		
		if error == OK:
			translations = json.data
			current_language = language_code
			language_changed.emit()
			return true
		else:
			printerr("Erro ao parsear JSON: ", error)
	
	return false

func get_translation(key: String, default: String = "") -> String:
	var keys = key.split(".")
	var value = translations
	
	for k in keys:
		if value.has(k):
			value = value[k]
		else:
			return default if default else "MISSING_TRANSLATION:" + key
	
	return str(value)

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

# Métodos de conveniência para tipos específicos
func get_item_name_text(item_key: String) -> String:
	return get_translation("items." + item_key)

func get_item_rarity_name_text(text_key: String) -> String:
	return get_translation("items.rarity." + text_key)

func get_item_rarity_prefix_text(text_key: String) -> String:
	return get_translation("items.rarity_prefix." + text_key)

func get_item_rarity_sufix_text(text_key: String) -> String:
	return get_translation("items.rarity_sufix." + text_key)

func get_item_category_name_text(text_key: String) -> String:
	return get_translation("items.category." + text_key)

func get_item_subcategory_name_text(text_key: String) -> String:
	return get_translation("items.subcategory." + text_key)
	
# Potions get functions
func get_potion_name_text(attribute: String) -> String:
	return get_translation("items.potions.names." + attribute)

func get_potion_base_description_text(attribute: String) -> String:
	return get_translation("items.potions.base_descriptions." + attribute)

# Gems get functions
func get_gem_name_text(attribute: String) -> String:
	return get_translation("items.gems.names." + attribute)

func get_gem_base_description_text(attribute: String) -> String:
	return get_translation("items.gems.base_descriptions." + attribute)

func get_gem_unique_description_text(attribute: String) -> String:
	return get_translation("items.gems.unique_descriptions." + attribute)

func get_gem_quality_text(quality: GemItem.QUALITY) -> String:
	return get_translation("items.gems.quality." + GemItem.GEM_QUALITY_KEY[quality])

#func get_equipment_amulet_name_text(attribute: String) -> String:
	#return get_translation("items.equipments.amulets." + attribute)
#
#func get_equipment_ring_name_text(attribute: String) -> String:
	#return get_translation("items.equipments.rings." + attribute)
#
#func get_equipment_weapon_name_text(attribute: String) -> String:
	#return get_translation("items.equipments.weapons." + attribute)

func get_equipment_common_item(set_key: EquipmentItem.SETS, equip_type: EquipmentItem.TYPE) -> String:
	var set_name = EquipmentConsts.EQUIPMENTS_SET_KEYS[set_key]
	var type_name = EquipmentConsts.EQUIPMENT_TYPE_KEYS[equip_type]
	var path = "items.equipments.commons.%s.%s" % [set_name, type_name]
	return get_translation(path)
	
func get_equipment_unique_item(set_key: EquipmentItem.SETS, equip_type: EquipmentItem.TYPE) -> String:
	var set_name = EquipmentConsts.EQUIPMENTS_SET_KEYS[set_key]
	var type_name = EquipmentConsts.EQUIPMENT_TYPE_KEYS[equip_type]
	var path = "items.equipments.uniques.%s.%s" % [set_name, type_name]
	return get_translation(path)


func get_equipment_text(attribute: String) -> String:
	return get_translation("items.equipments." + attribute)

func get_ui_text(ui_key: String) -> String:
	return get_translation("ui." + ui_key)
