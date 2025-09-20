# status_effect_ui.gd
class_name StatusEffectUI
extends VBoxContainer

@export var timer_label: Label
@export var icon_texture: TextureRect
@export var timer_progress: TextureProgressBar


var effect_type: StatusEffect.EFFECT
var effect_timer: Timer
var current_duration: float = 0.0
var progress_tween: Tween
var label_tween: Tween

# Configurações básicas que todas as classes terão
func setup_effect(effect_data: StatusEffect) -> void:
	#label.text = effect_data.get_effect_name()
	effect_type = effect_data.effect
	update_ui(effect_data.duration)

func set_icon(texture: Texture2D) -> void:
	if icon_texture:
		icon_texture.texture = texture

func start_timer(effect_data: StatusEffect) -> void:
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

func updated_effect_duration(duartion: float) -> void:
	if effect_timer:
		# var remaining = effect_timer.time_left
		effect_timer.stop()
		effect_timer.wait_time = duartion
		current_duration = duartion
		effect_timer.start()
		update_ui(duartion)

func update_ui(duration: float) -> void:
	if timer_progress:
		timer_progress.max_value = duration
		timer_progress.value = duration
		
		# Interrompe qualquer tween existente da barra de progresso
		if progress_tween:
			progress_tween.kill()
		
		# Cria um novo tween para a barra de progresso
		progress_tween = create_tween()
		progress_tween.tween_property(timer_progress, "value", 0, duration)
	
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
	if timer_progress and timer_label:
		var remaining_time = timer_progress.value
		timer_label.text = format_timer(remaining_time)

func _on_timer_timeout(effect_data: StatusEffect) -> void:
	PlayerEvents.remove_status_effect(effect_data)

func format_timer(seconds: float) -> String:
	var minutes = int(seconds / 60)
	var secs = int(seconds) % 60
	return "%02d:%02d" % [minutes, secs]
