extends Node

signal language_changed

var current_language: String = "en"
var translations: Dictionary = {}

func _ready() -> void:
	load_language("en")  # Idioma padrão

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

func get_translation_format(key: String, params: Dictionary, default: String = "") -> String:
	var text = get_translation(key, default)
	
	for param_key in params:
		text = text.replace("{%s}" % param_key, str(params[param_key]))
	
	return text

# Métodos de conveniência para tipos específicos
func get_item_name(item_key: String) -> String:
	return get_translation("items." + item_key)

func get_item_rarity_name(rarity: int) -> String:
	var rarity_keys = ["common", "uncommon", "rare", "epic", "legendary", "mythical"]
	return get_translation("items.rarity." + rarity_keys[clamp(rarity, 0, rarity_keys.size() - 1)])

func get_item_attribute_name(attribute: String) -> String:
	return get_translation("items.descriptions.attributes." + attribute)

func get_ui_text(ui_key: String) -> String:
	return get_translation("ui." + ui_key)
