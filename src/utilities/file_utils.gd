class_name FileUtils


static func load_texture_with_fallback(file_path: String) -> Texture2D:
	# Primeiro tenta carregar a textura específica
	if FileAccess.file_exists(file_path):
		var texture = load(file_path)
		if texture is Texture2D:
			return texture
		else:
			printerr("-- File founded! But invalid texture: ", file_path)

	# Fallback 3: Textura programática vermelha de erro
	printerr("No texture finded in path ", file_path)
	return create_error_texture()


## Cria uma textura vermelha de erro programaticamente
static func create_error_texture() -> Texture2D:
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)

	var texture = ImageTexture.create_from_image(image)
	return texture