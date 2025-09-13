class_name Wheat
extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D

@export var shake_intensity := 2.0
@export var shake_duration := 0.6

var tween: Tween
var is_shaking := false
var original_position: Vector2


func _ready() -> void:
	sprite_2d.flip_h = randi_range(0, 1)
	original_position = sprite_2d.position


func _shake_wheat(direction: int) -> void:
	if is_shaking:
		return

	is_shaking = true
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_parallel(true)  # Anima múltiplas propriedades simultaneamente

	# Valores mais suaves para uma animação natural

	# Animação de posição (balanço suave)
	tween.tween_method(_apply_shake_position.bind(direction, shake_intensity), 0.0, 1.0, shake_duration)

	# Animação de rotação leve (skew mais suave)
	var target_skew := direction * 0.15  # Valor mais suave
	tween.tween_property(sprite_2d, "skew", target_skew, shake_duration * 0.3)
	tween.chain().tween_property(sprite_2d, "skew", 0.0, shake_duration * 0.7)

	# Animação de escala leve (efeito de "ondulação")
	tween.tween_property(sprite_2d, "scale", Vector2(1.05, 0.95), shake_duration * 0.2)
	tween.chain().tween_property(sprite_2d, "scale", Vector2(1.0, 1.0), shake_duration * 0.8)

	tween.finished.connect(_on_shake_finished)


func _apply_shake_position(progress: float, direction: int, intensity: float) -> void:
	# Função suave de easing para movimento natural
	var time = progress * PI * 2.0
	var offset = sin(time * 3.0) * cos(time * 2.0)  # Movimento orgânico

	# Aplica o movimento com direção e intensidade
	sprite_2d.position.x = original_position.x + (offset * intensity * direction)
	sprite_2d.position.y = original_position.y + (abs(offset) * intensity * 0.5)


func _on_shake_finished() -> void:
	# Garante que volte à posição original
	sprite_2d.position = original_position
	sprite_2d.skew = 0.0
	sprite_2d.scale = Vector2(1.0, 1.0)
	is_shaking = false


func _on_player_area_entered(area: Area2D) -> void:
	if is_shaking:
		return

	var body = area.get_parent()
	if body is Player:
		var player = body as Player
		_shake_wheat(player.face_direction)  # 1 = Right -1 Left
