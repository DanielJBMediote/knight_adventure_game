class_name EnemyHurtbox
extends Area2D

signal hurtbox_target_entered(target: Player)
signal hurtbox_target_exited(target: Player)
signal player_hitbox_entered()

@export var radius := 0.0
@export var height := 0.0
@export var colision_position := Vector2.ZERO

var collision_shape: CollisionShape2D = CollisionShape2D.new()
var capsule_shape: CapsuleShape2D = CapsuleShape2D.new()

func _ready() -> void:
	capsule_shape.radius = radius
	capsule_shape.height = height
	collision_shape.shape = capsule_shape
	collision_shape.position = colision_position
	collision_shape.modulate = Color.BROWN
	add_child(collision_shape)

func _on_area_entered(area: Area2D) -> void:
	player_hitbox_entered.emit()
