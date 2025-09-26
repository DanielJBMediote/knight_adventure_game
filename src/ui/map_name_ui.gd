class_name MapNameUI
extends Control

@onready var map_name: Label = $Label

@export var typing_speed: float = 0.1 # Velocidade da digitação (segundos por letra)
@export var display_duration: float = 3.0 # Tempo que o nome fica visível após digitação

var timer: Timer

func show_map_name_animation() -> void:
	# Reset estado inicial
	map_name.modulate.a = 0
	map_name.visible_ratio = 0.0
	
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(_on_timeout)
	add_child(timer)
	timer.start()

func _on_timeout() -> void:
	var tween: Tween = create_tween().set_parallel(false)
	
	var text_length = map_name.text.length()
	var typing_time = text_length * typing_speed
	
	tween.tween_property(map_name, "modulate:a", 1.0, typing_time * 0.5)
	tween.tween_property(map_name, "visible_ratio", 0.0, typing_time)
	tween.tween_property(map_name, "visible_ratio", 1.0, typing_time)
	
	# Manter na tela
	tween.tween_interval(display_duration)
	
	# Fade out de tudo
	tween.tween_property(map_name, "visible_ratio", 0.0, 0.5)
	tween.tween_property(map_name, "modulate:a", 0.0, 0.5)
	
	tween.finished.connect(queue_free)

func set_map_name(new_name: String) -> void:
	var welcome = LocalizationManager.get_ui_text("welcome_to")
	map_name.text = welcome + "\n" + new_name
