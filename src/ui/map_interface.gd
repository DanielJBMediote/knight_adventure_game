class_name MapInterface
extends CanvasLayer

@onready var map_name: Control = $Control/MapName
@export var typing_speed: float = 0.1 # Velocidade da digitação (segundos por letra)
@export var display_duration: float = 3.0 # Tempo que o nome fica visível após digitação

var timer: Timer

func show_map_name_animation() -> void:
	var texture_rect: TextureRect = map_name.get_node("TextureRect")
	var label: Label = map_name.get_node("Label")
	
	# Resetar estado inicial
	texture_rect.modulate.a = 0
	label.modulate.a = 0
	label.visible_characters = 0
	label.text = label.text # Força atualização do visible_characters
	
	timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(_on_timeout.bind(label, texture_rect))
	add_child(timer)
	timer.start()

func _on_timeout(label: Label, texture_rect: TextureRect) -> void:
	# Criar tweens
	var tween = create_tween().set_parallel(false) # Sequencial
	
	# Fade in da textura
	tween.tween_property(texture_rect, "modulate:a", 1.0, 1.0)
	tween.tween_interval(0.3) # Pequena pausa
	
	# Efeito de digitação
	var text_length = label.text.length()
	var typing_time = text_length * typing_speed
	tween.tween_property(label, "visible_characters", text_length, typing_time)
	tween.tween_property(label, "modulate:a", 1.0, typing_time * 0.5)
	
	# Manter na tela
	tween.tween_interval(display_duration)
	
	# Fade out de tudo
	tween.tween_property(texture_rect, "modulate:a", 0.0, 0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.set.bind("visible_characters", -1)) # Resetar visible_characters

func set_map_name(new_name: String) -> void:
	var label = map_name.get_node("Label")
	label.text = new_name
