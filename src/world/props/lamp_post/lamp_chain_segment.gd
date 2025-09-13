# chain_segment.gd
class_name LampChainSegment
extends RigidBody2D

signal player_hitbox_entered

func _on_vulnerable_zone_area_entered(area: Area2D) -> void:
	player_hitbox_entered.emit()
