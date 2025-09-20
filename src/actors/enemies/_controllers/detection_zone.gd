class_name EntityDetectionZone
extends Area2D

signal player_entered(player: Player)
signal player_exited(player: Player)

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@export var radius_range := 200.0 # Default 200.0

func _ready() -> void:
	collision_shape_2d.shape = CircleShape2D.new()
	collision_shape_2d.shape["radius"] = radius_range

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body is Player:
		player_entered.emit(body as Player)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body is Player:
		player_exited.emit(body as Player)
