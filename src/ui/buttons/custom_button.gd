class_name CustomButton
extends Button

# Cores personalizadas
@export_group("Colors")
@export var normal_color: Color = Color("#18181b")
@export var hover_color: Color = Color("#262324")
@export var pressed_color: Color = Color("#18181b")
@export var disabled_color: Color = Color("#666666")

# Efeitos visuais
@export_group("Visual Effects")
@export var enable_effects: bool = true
@export var enable_shadow: bool = true
@export var shadow_color: Color = Color(0, 0, 0, 0.3)
@export var enable_glow: bool = false
@export var glow_color: Color = Color("#00ffff")
@export var glow_intensity: float = 0.5

# Animações
@export_group("Animations")
@export var hover_scale: Vector2 = Vector2(1.05, 1.05)
@export var press_scale: Vector2 = Vector2(0.95, 0.95)
@export var animation_speed: float = 0.2

# Bordas e cantos
@export_group("Borders")
@export var corner_radius: int = 8
@export var border_width: int = 2
@export var border_color: Color = Color("#ffffff")

# Ícone
@export_group("Ícons")
@export var icon_texture: Texture2D
@export var icon_size: Vector2 = Vector2(16, 16)
@export var icon_margin: int = 8

# Som
@export_group("Sounds")
@export var hover_sound: AudioStream
@export var click_sound: AudioStream

# Variáveis privadas
var _tween: Tween
var _original_scale: Vector2
var _original_pivot_offset: Vector2


func _ready():
	_original_scale = scale
	_original_pivot_offset = pivot_offset
	pivot_offset = size / 2

	_setup_button()
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	connect("pressed", Callable(self, "_on_pressed"))

	resized.connect(_on_resized)


func _on_resized():
	pivot_offset = size / 2


func _setup_button():
	# Configurar estilo básico
	add_theme_stylebox_override("normal", _create_stylebox(normal_color))
	add_theme_stylebox_override("hover", _create_stylebox(hover_color))
	add_theme_stylebox_override("pressed", _create_stylebox(pressed_color))
	add_theme_stylebox_override("disabled", _create_stylebox(disabled_color))
	add_theme_stylebox_override("focus", _create_stylebox(hover_color))

	# Configurar fonte
	var font = get_theme_font("font")
	var font_size = get_theme_font_size("font_size")
	add_theme_font_override("font", font)
	add_theme_font_size_override("font_size", font_size)


func _create_stylebox(bg_color: Color) -> StyleBoxFlat:
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = bg_color
	stylebox.corner_radius_top_left = corner_radius
	stylebox.corner_radius_top_right = corner_radius
	stylebox.corner_radius_bottom_right = corner_radius
	stylebox.corner_radius_bottom_left = corner_radius
	stylebox.border_width_bottom = border_width
	stylebox.border_width_top = border_width
	stylebox.border_width_left = border_width
	stylebox.border_width_right = border_width
	stylebox.border_color = border_color

	if enable_shadow:
		stylebox.shadow_size = 4
		stylebox.shadow_color = shadow_color

	return stylebox


func _on_mouse_entered():
	if disabled:
		return

	_animate_scale(hover_scale)
	_play_hover_sound()

	if enable_glow:
		_start_glow_effect()


func _on_mouse_exited():
	if disabled:
		return
	_animate_scale(_original_scale)
	_stop_glow_effect()


func _on_pressed():
	_animate_scale(press_scale, animation_speed * 0.5)
	_animate_scale(_original_scale, animation_speed * 0.5, animation_speed * 0.5)
	_play_click_sound()


func _animate_scale(target_scale: Vector2, duration: float = animation_speed, delay: float = 0.0) -> void:
	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(self, "scale", target_scale, duration)\
		.set_delay(delay)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_CUBIC)


func _start_glow_effect():
	# Implementar efeito de glow se necessário
	pass


func _stop_glow_effect():
	# Remover efeito de glow
	pass


func _play_hover_sound():
	if hover_sound:
		# Implementar reprodução de som
		pass


func _play_click_sound():
	if click_sound:
		# Implementar reprodução de som
		pass


# Métodos públicos para controle programático
func set_button_colors(normal: Color, hover: Color, pressed: Color, disabled_col: Color):
	normal_color = normal
	hover_color = hover
	pressed_color = pressed
	disabled_color = disabled_col
	_setup_button()


func set_corner_radius(radius: int):
	corner_radius = radius
	_setup_button()


func set_border(width: int, color: Color):
	border_width = width
	border_color = color
	_setup_button()


# Método para adicionar ícone
func set_icon(texture: Texture2D, size: Vector2 = Vector2(16, 16)):
	icon_texture = texture
	icon_size = size
	# Implementar lógica de ícone se necessário
