class_name MapData
extends Node2D

@onready var map_name_ui_scene: PackedScene = preload("res://src/ui/map_name_ui.tscn")
var map_name_ui: MapNameUI

@export var map_name := ""
@export var start_position: Marker2D
@export var level_mob_min := 0
@export var level_mob_max := 0
@export var boss_level := 0

func _ready() -> void:
	GameManager.current_map = self

	var player_ui = GameManager.get_player_ui()
	
	if player_ui:
		map_name_ui = map_name_ui_scene.instantiate()
		player_ui.add_child(map_name_ui)
		map_name_ui.set_map_name(map_name)
		map_name_ui.show_map_name_animation()

	_set_player_on_initial_position()


func _set_player_on_initial_position() -> void:
	var player = PlayerStats.player_ref
	if player and start_position:
		var checkpoint = GameManager.get_checkpoint()
		if checkpoint and checkpoint.player_position:
			player.position = Utils.deserialize_value(checkpoint.player_position)
		else:
			player.position = start_position.position


func get_min_mob_level() -> int:
	return level_mob_min


func get_max_mob_level() -> int:
	return level_mob_max


func get_boss_level() -> int:
	return boss_level
