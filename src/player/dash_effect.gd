class_name DashEffect
extends Sprite2D


func _ready() -> void:
	ghosting()

func set_property(tx_pos: Vector2, tx_scale: Vector2, tx_fliph: bool) -> void:
	position = tx_pos
	scale = tx_scale
	flip_h = tx_fliph
	#if tx_fliph:
		#offset = Vector2(-4, -13)
	#else:
		#offset = Vector2(-3, -13)

func ghosting() -> void:
	var teewn_fade = get_tree().create_tween()
	
	teewn_fade.tween_property(self, "self_modulate", Color(1,1,1), 0.75)
	await  teewn_fade.finished
	
	queue_free()
