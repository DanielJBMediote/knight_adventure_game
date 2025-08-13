class_name TransitionAnimationLayer
extends CanvasLayer

signal animation_finished()

@onready var color_rect: ColorRect = $ColorRect
@onready var animation: AnimationPlayer = $Animation

func set_speed_scale(speed_scale: float):
	animation.speed_scale = speed_scale
	
func fade_out():
	color_rect.color = Color(0, 0, 0, 1)
	animation.play("fade_out")
	
func fade_in():
	color_rect.color = Color(0, 0, 0, 0)
	animation.play("fade_in")

func set_color(color: Color):
	color_rect.color = color

func _on_animation_animation_finished(anim_name: StringName) -> void:
	animation_finished.emit()
	if anim_name == "fade_out":
		queue_free()
