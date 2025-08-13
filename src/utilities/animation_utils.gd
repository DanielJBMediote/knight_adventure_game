# animation_utils.gd
class_name AnimationUtils
extends Node

static func has_animations_in_animated_sprite(animated_sprite_2d: AnimatedSprite2D, animations_list: Array) -> bool:
	var current_animation = animated_sprite_2d.animation
	var has_animation = false
	
	for animation_name in animations_list:
		if animation_name == current_animation:
			has_animation = true
			break
			
	return has_animation

static func pick_random_animation(animations_list: Array) -> String:
	return animations_list[randi() % animations_list.size()]
