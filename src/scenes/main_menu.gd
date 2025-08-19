# main_menu.gd
class_name MainMenu
extends Control

@onready var map_01: PackedScene = preload("res://src/world/maps/map_01/map01_graveward_at_night.tscn")

@onready var button_play: Button = $Buttons/VBoxContainer/ButtonPlay
@onready var button_load: Button = $Buttons/VBoxContainer/ButtonLoad

func _ready() -> void:
	button_play.pressed.connect(_on_play_clicked)
	button_load.pressed.connect(_on_load_clicked)

func _on_play_clicked():
	GameEvents.change_to_scene_with_transition(map_01, 2.0) # Slightly slower transition

func _on_load_clicked():
	pass
