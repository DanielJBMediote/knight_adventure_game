# floor_limit.gd
class_name FloorLimit
extends Area2D

@export var map_init_position := Vector2.ZERO
var player_target: CharacterBody2D

func _on_body_entered(body: Node2D) -> void:
	if body and body.is_in_group("player"):
		player_target = body
		update_body_position()

func update_body_position() -> void:
	if player_target:
		player_target.global_position = map_init_position
	else:
		printerr("Player is null")
