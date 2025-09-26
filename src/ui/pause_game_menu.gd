class_name PauseGameMenu
extends Control

@onready var default_label: DefaultLabel = $PanelContainer/DefaultLabel
@onready var resume_button: CustomButton = $PanelContainer/VBoxContainer/ResumeButton
@onready var settings_button: CustomButton = $PanelContainer/VBoxContainer/SettingsButton
@onready var exit_button: CustomButton = $PanelContainer/VBoxContainer/ExitButton


func _ready() -> void:
	default_label.text = LocalizationManager.get_ui_text("game_paused")
	resume_button.text = LocalizationManager.get_ui_text("resume")
	settings_button.text = LocalizationManager.get_ui_text("settings")
	exit_button.text = LocalizationManager.get_ui_text("exit")


func _on_resume_button_pressed() -> void:
	GameManager.resume_game()
	queue_free()


func _on_exit_button_pressed() -> void:
	GameManager.resume_game()
	GameManager.back_to_main_menu()
