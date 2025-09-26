# transition_manager.gd
extends Node

signal transition_started()
signal transition_completed()

const TRANSITION_SCENE = preload("res://src/systems/transitions/transition_layer.tscn")

var current_transition: TransitionAnimationLayer = null

func transition_to_scene(new_scene: PackedScene, fade_duration: float = 0.5) -> void:
	transition_started.emit()
	
	# Create and setup transition
	current_transition = TRANSITION_SCENE.instantiate()
	get_tree().root.add_child(current_transition)
	
	current_transition.set_speed_scale(1.0 / fade_duration)
	current_transition.fade_in()
	
	await current_transition.animation_finished
	current_transition.queue_free()
	
	# Change scene
	if new_scene:
		await get_tree().process_frame # Ensure new scene is loaded
		get_tree().change_scene_to_packed(new_scene)
		
		# Fade in new scene
		current_transition = TRANSITION_SCENE.instantiate()
		get_tree().root.add_child(current_transition)
		current_transition.animation.speed_scale = 1.0 / fade_duration
		current_transition.fade_out()
		await current_transition.animation_finished
		current_transition.queue_free()
		
	
	transition_completed.emit()
