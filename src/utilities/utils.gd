class_name Utils


class PropertyData:
	var name: String
	var type: Variant

	func _init(_name, _type) -> void:
		self.name = _name
		self.type = _type


static func get_regular_variables(object: Object) -> Array[PropertyData]:
	var script = object.get_script()
	var regular_vars: Array[PropertyData] = []

	if script:
		for property in script.get_script_property_list():
			var prop_name: StringName = property.name

			# Ignora propriedades especiais que começam com @
			if prop_name.begins_with("@") or prop_name.ends_with(".gd"):
				continue

			# Ignora enums (normalmente em maiúsculas e são dicionários)
			if property.type == PROPERTY_USAGE_CLASS_IS_ENUM and prop_name == prop_name.to_upper():
				continue

			# Ignorar constantes
			if prop_name == prop_name.to_upper():
				continue

			# Ignora sinais (começam com "signal")
			if prop_name.begins_with("signal"):
				continue

			# Filtra apenas variáveis de script regulares
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				regular_vars.append(PropertyData.new(prop_name, property.type))

	return regular_vars

static func serialize_object(obj: Object) -> Dictionary:
	if obj == null:
		return {}
	
	var data = {}
	
	# Salva o caminho do script para reconstrução
	if obj.get_script():
		data["__script_path"] = obj.get_script().resource_path
	
	var properties = get_regular_variables(obj)
	
	for prop in properties:
		var value = obj.get(prop.name)
		data[prop.name] = serialize_value(value)
	
	return data

static func serialize_value(value) -> Variant:
	if value == null:
		return null
	elif value is Resource:
		# Para texturas, salva apenas o caminho
		if value is Texture2D or value is CompressedTexture2D:
			return value.resource_path if value.resource_path else ""
		# Para outros recursos, serializa completamente
		else:
			return serialize_resource(value)
	elif value is Array:
		return serialize_array(value)
	elif value is Dictionary:
		return serialize_dictionary(value)
	elif value is Object:
		return serialize_object(value)
	else:
		return _serialize_type(value)

static func _serialize_type(value) -> Variant:
	match typeof(value):
		TYPE_NIL:
			return null
		TYPE_VECTOR2:
			return {"x": value.x, "y": value.y}
		TYPE_RECT2:
			return {"position": _serialize_type(value.position), "size": _serialize_type(value.size)}
		TYPE_VECTOR4:
			return {"x": value.x, "y": value.y, "z": value.z, "w": value.w}
		TYPE_COLOR:
			return {"r": value.r, "g": value.g, "b": value.b, "a": value.a}
		_:
			return value

static func serialize_resource(resource: Resource) -> Dictionary:
	if resource == null:
		return {}
	
	var data = {"__resource_type": "Resource"}
	
	# Salva o caminho do script se for um recurso customizado
	if resource.get_script():
		data["__script_path"] = resource.get_script().resource_path
	# Senão, salva o caminho do recurso
	elif resource.resource_path:
		data["__resource_path"] = resource.resource_path
	
	var properties = get_regular_variables(resource)
	for prop in properties:
		var value = resource.get(prop.name)
		data[prop.name] = serialize_value(value)
	
	return data

static func serialize_dictionary(data: Dictionary) -> Array:
	if data == null or data.is_empty():
		return []

	var result = []
	for key in data.keys():
		var value = serialize_value(data[key])
		result.append({"__dictionary_key": key, "value": value})
	
	return result

static func serialize_array(array: Array) -> Array:
	var result = []
	for item in array:
		result.append(serialize_value(item))
	return result


static func deserialize_object(data: Dictionary) -> Object:
	if data.is_empty() or not data.has("__script_path"):
		return null
	
	var script_path = data["__script_path"]
	if not ResourceLoader.exists(script_path):
		printerr("Script não encontrado: ", script_path)
		return null

	var script = load(script_path)
	var instance = script.new()
	var properties_keys = Utils.get_regular_variables(instance).map(func(p): return p.name)
	
	for key in data:
		if key in ["__script_path", "__resource_type", "__resource_path"]:
			continue
		
		if properties_keys.has(key):
			var value = deserialize_value(data[key])
			instance.set(key, value)
		
	return instance

static func deserialize_value(value) -> Variant:
	if value == null:
		return null
	elif value is Dictionary:
		if value.has("__script_path"):
			return deserialize_object(value)
		elif value.has("__resource_path"):
			var resource_path = value["__resource_path"]
			return load(resource_path) if ResourceLoader.exists(resource_path) else null
		elif value.has("__resource_type"):
			return deserialize_resource(value)
		else:
			return _deserialize_type(value)
	elif value is Array:
		if value and not value.is_empty() and value[0].has("__dictionary_key"):
			return deserialize_dictionary(value)
		else:
			return deserialize_array(value)
	elif value is String and (value.ends_with(".png") or value.ends_with(".jpg") or value.ends_with(".tres") or value.ends_with(".res")):
		return load(value) if ResourceLoader.exists(value) else null
	else:
		return value

static func _deserialize_type(value: Dictionary) -> Variant:
	if value.has_all(["x", "y", "z", "w"]):
		return Vector4(value.x, value.y, value.z, value.w)
	elif value.has_all(["x", "y"]):
		return Vector2(value.x, value.y)
	elif value.has_all(["r", "g", "b", "a"]):
		return Color(value.r, value.g, value.b, value.a)
	elif value.has_all(["position", "size"]):
		var position = Vector2(value.position.x, value.position.y)
		var size = Vector2(value.size.x, value.size.y)
		return Rect2(position, size)
	else:
		return value
			

static func deserialize_resource(data: Dictionary) -> Resource:
	if not data.has("__resource_type"):
		return null
	
	# Se tem caminho de recurso, carrega diretamente
	if data.has("__resource_path"):
		var resource_path = data["__resource_path"]
		if ResourceLoader.exists(resource_path):
			return load(resource_path)
		else:
			return null
	
	# Se tem script, cria uma instância
	if data.has("__script_path"):
		var script_path = data["__script_path"]
		if ResourceLoader.exists(script_path):
			var script = load(script_path)
			var resource = script.new()
			
			# Preenche as propriedades
			for key in data:
				if key in ["__script_path", "__resource_type", "__resource_path"]:
					continue
				
				if resource.has_property(key):
					var value = data[key]
					resource.set(key, deserialize_value(value))
			
			return resource
	
	return null

static func deserialize_dictionary(array: Array) -> Dictionary:
	if array == null or array.is_empty():
		return {}

	var result = {}
	for data in array:
		var key = data.get("__dictionary_key")
		var value = data["value"]

		value = deserialize_value(value)
		result[key] = value

	return result
static func deserialize_array(data: Array) -> Array:
	var result = []
	for item in data:
		result.append(deserialize_value(item))
	return result

static func save_to_json(data: Dictionary, file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		printerr("Erro ao abrir arquivo para escrita: ", file_path)
		return false
	
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

static func load_from_json(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Erro ao abrir arquivo para leitura: ", file_path)
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		printerr("Erro ao parsear JSON: ", json.get_error_message())
		return {}
	
	return json.get_data()
