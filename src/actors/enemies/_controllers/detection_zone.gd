class_name EntityDetectionZone
extends Area2D

signal player_entered(player: CharacterBody2D)
signal player_exited(player: CharacterBody2D)

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@export var radius_range := 200.0 # Default 200.0

func _ready() -> void:
	collision_shape_2d.shape = CircleShape2D.new()
	collision_shape_2d.shape["radius"] = radius_range

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_entered.emit(body)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_exited.emit(body)
