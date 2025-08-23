# status_effect_ui.gd
class_name StatusEffectUI
extends Control

@export var effect_type: StatusEffectData.EFFECT

@onready var icon_texture: TextureRect = $IconTexture
@onready var label: Label = $VBoxContainer/HBoxContainer/Label
@onready var timer_label: Label = $VBoxContainer/HBoxContainer/TimerLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar

var effect_timer: Timer
var current_duration: float = 0.0
var progress_tween: Tween
var label_tween: Tween

# Configurações básicas que todas as classes terão
func setup_effect(effect_data: StatusEffectData) -> void:
	label.text = effect_data.get_effect_name()
	effect_type = effect_data.effect
	update_ui(effect_data.duration)

func setup_appearance() -> void:
	# Isso será sobrescrito pelas classes filhas
	pass

# Métodos auxiliares para as classes filhas
func set_icon_texture(texture: Texture2D) -> void:
	if icon_texture:
		icon_texture.texture = texture

func set_progress_bar_color(fill_color: Color, bg_color: Color) -> void:
	if progress_bar:
		var stylbox_bg = StyleBoxFlat.new()
		var stylbox_fill = StyleBoxFlat.new()
		stylbox_bg.bg_color = bg_color
		stylbox_fill.bg_color = fill_color
		progress_bar.add_theme_stylebox_override("background", stylbox_bg)
		progress_bar.add_theme_stylebox_override("fill", stylbox_fill)

func start_timer(effect_data: StatusEffectData) -> void:
	if effect_timer:
		effect_timer.stop()
		effect_timer.queue_free()
	
	effect_timer = Timer.new()
	current_duration = effect_data.duration
	effect_timer.wait_time = effect_data.duration
	effect_timer.one_shot = true
	effect_timer.timeout.connect(_on_timer_timeout.bind(effect_data))
	add_child(effect_timer)
	effect_timer.start()
	
	update_ui(effect_data.duration)

func extend_effect_duration(new_duration: float) -> void:
	if effect_timer:
		var remaining = effect_timer.time_left
		effect_timer.stop()
		effect_timer.wait_time = new_duration
		current_duration = new_duration
		effect_timer.start()
		update_ui(new_duration)

func update_ui(duration: float) -> void:
	if progress_bar:
		progress_bar.max_value = duration
		progress_bar.value = duration
		
		# Interrompe qualquer tween existente da barra de progresso
		if progress_tween:
			progress_tween.kill()
		
		# Cria um novo tween para a barra de progresso
		progress_tween = create_tween()
		progress_tween.tween_property(progress_bar, "value", 0, duration)
	
	if timer_label:
		timer_label.text = format_timer(duration)
		
		# Interrompe qualquer tween existente do timer_label
		if label_tween:
			label_tween.kill()
		
		# Cria um novo tween para atualizar o label do tempo
		label_tween = create_tween()
		label_tween.set_loops()
		label_tween.tween_interval(1.0)
		label_tween.tween_callback(_update_timer_label)

func _update_timer_label() -> void:
	if progress_bar and timer_label:
		var remaining_time = progress_bar.value
		timer_label.text = format_timer(remaining_time)

func _on_timer_timeout(effect_data: StatusEffectData) -> void:
	PlayerEvents.remove_status_effect.emit(effect_data)

func format_timer(seconds: float) -> String:
	var minutes = int(seconds / 60)
	var secs = int(seconds) % 60
	return "%02d:%02d" % [minutes, secs]
