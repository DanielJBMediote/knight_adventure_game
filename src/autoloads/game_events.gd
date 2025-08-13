# autoloads/game_events.gd
extends Node

enum Difficulty {
	NORMAL,    # 100% dos stats
	PAINFUL,   # 120% dos stats dos inimigos
	FATAL,     # 150% dos stats dos inimigos
	INFERNAL   # 200% dos stats dos inimigos
}

var is_paused := false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		is_paused = !is_paused

func change_to_scene_with_transition(new_scene: PackedScene, fade_suration: float = 0.5):
	TransitionManager.transition_to_scene(new_scene, fade_suration)
