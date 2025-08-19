class_name WanderController
extends Node2D

@export var wander_range: Vector2 = Vector2.ZERO
@onready var timer : Timer = $Timer
@export var enemy_type: Enemy.ENEMY_TYPES 

var target_position = global_position
var start_position = global_position
var is_timeout : bool
var is_moving_to_target: bool = false

func _ready() -> void:
	timer.connect("timeout", _on_Timer_timeout)

func update_wander_position() -> void:
	if enemy_type == Enemy.ENEMY_TYPES.FLYING:
		# Para inimigos voadores (como o morcego)
		var random_angle = randf_range(0, 2 * PI)
		target_position = start_position + Vector2(
			cos(random_angle) * wander_range.x,
			sin(random_angle) * wander_range.y
		)
	else:
		# Para inimigos terrestres (como o esqueleto)
		var random_x = randf_range(-wander_range.x, wander_range.x)
		target_position = start_position + Vector2(random_x, 0)

func start_wander_time(value: float) ->void:
	timer.start(value)
	is_timeout = false

func _on_Timer_timeout():
	update_wander_position()
	is_timeout = true
	wander_range *= -1

func pause_timer() -> void:
	timer.paused = true

func resume_timer() -> void:
	timer.paused = false
