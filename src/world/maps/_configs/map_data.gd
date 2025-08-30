class_name MapData
extends Node2D

@onready var map_interface_scene: PackedScene = preload("res://src/ui/map_interface.tscn")
var map_interface: MapInterface

@export var map_name := ""
@export var level_mob_min := 0
@export var level_mob_max := 0
@export var boss_level := 0
@export var difficulty: GameEvents.DIFFICULTY

func _init():
	GameEvents.set_current_map(self)

func _ready() -> void:
	map_interface = map_interface_scene.instantiate()
	add_child(map_interface)

	map_interface.set_map_name(map_name)
	map_interface.show_map_name_animation()
	
func get_min_mob_level() -> int:
	return level_mob_min
func get_max_mob_level() -> int:
	return level_mob_max
func get_boss_level() -> int:
	return boss_level
func get_difficulty() -> GameEvents.DIFFICULTY:
	return difficulty
