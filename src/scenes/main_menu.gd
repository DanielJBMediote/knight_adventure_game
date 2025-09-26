# main_menu.gd
class_name MainMenu
extends CanvasLayer


@onready var game_title: DefaultLabel = $Container/PanelContainer/GameTitle
@onready var new_game_button: CustomButton = $Container/PanelContainer/VBoxContainer/NewGameButton
@onready var load_game_button: CustomButton = $Container/PanelContainer/VBoxContainer/LoadGameButton
@onready var settings_button: CustomButton = $Container/PanelContainer/VBoxContainer/SettingsButton
@onready var exit_button: CustomButton = $Container/PanelContainer/VBoxContainer/ExitButton


func _ready() -> void:
	game_title.text = LocalizationManager.get_ui_text("game_name")
	new_game_button.text = LocalizationManager.get_ui_text("new_game")
	load_game_button.text = LocalizationManager.get_ui_text("load_game")
	settings_button.text = LocalizationManager.get_ui_text("settings")
	exit_button.text = LocalizationManager.get_ui_text("exit")
	
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	load_game_button.pressed.connect(_on_load_game_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)


func _on_new_game_button_pressed():
	var map_01: PackedScene = preload("res://src/world/maps/map_03/map_village.tscn")
	GameManager.change_to_scene_with_transition(map_01, 2.0)

func _on_load_game_button_pressed():
	var success = GameManager.load_game()
	if success:
		var checkpoint = GameManager.get_checkpoint()
		var map = load(checkpoint.scene_path)
		GameManager.change_to_scene_with_transition(map, 2.0)

	
func _on_settings_button_pressed():
	pass

func _on_exit_button_pressed():
	GameManager.exit_game()
