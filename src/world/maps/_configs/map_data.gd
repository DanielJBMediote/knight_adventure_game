class_name MapData
extends Node2D

@onready var map_interface_scene: PackedScene = preload("res://src/world/maps/map_interface.tscn")
var map_interface: MapInterface

@export var map_name := ""
@export var level_mob_min := 0
@export var level_mob_max := 0
@export var boss_level := 0
@export var difficulty: GameEvents.Difficulty

func _init():
	GameEvents.set_current_map(self)

func _ready() -> void:
	map_interface = map_interface_scene.instantiate()
	add_child(map_interface)

	map_interface.set_map_name(map_name)
	map_interface.show_map_name_animation()
	
