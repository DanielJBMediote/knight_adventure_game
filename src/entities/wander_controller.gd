class_name WanderController
extends Node2D

@export var wander_range: Vector2 = Vector2.ZERO
@onready var timer : Timer = $Timer

var target_position = global_position
var start_position = global_position
var is_timeout : bool
var is_moving_to_target: bool = false

func _ready() -> void:
	timer.connect("timeout", _on_Timer_timeout)

func update_wander_position():
	var x = wander_range.x
	var y = wander_range.y
	var target_vector = Vector2(x, y)
	target_position = start_position + target_vector

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
