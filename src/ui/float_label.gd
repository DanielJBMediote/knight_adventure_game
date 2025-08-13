# float_label.gd
class_name FloatLabel
extends Label

@export var fade_duration: float = 1.0	# Duração do fade out
@export var float_speed: float = 50.0	# Velocidade de subida
@export var lifetime: float = 2.0	# Tempo total antes de desaparecer

var tween: Tween

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	# Configuração inicial
	modulate.a = 0  # Começa transparente
	scale = Vector2(0.5, 0.5)  # Começa pequeno
	
	# Animação de entrada
	var enter_tween = create_tween()
	enter_tween.tween_property(self, "modulate:a", 1.0, 0.1)
	enter_tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Animação de flutuação e fade out
	tween = create_tween()
	tween.tween_interval(lifetime - fade_duration)  # Espera antes de começar a desaparecer
	tween.tween_callback(start_fade_out)

func start_fade_out():
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	fade_tween.parallel().tween_property(self, "position:y", position.y - float_speed * fade_duration, fade_duration)
	fade_tween.tween_callback(queue_free)  # Remove o nó após o fade

func _process(delta):
	# Movimento constante para cima
	position.y -= float_speed * delta
