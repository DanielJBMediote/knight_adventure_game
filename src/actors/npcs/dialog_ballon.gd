class_name DialogBallon
extends Control

signal dialog_started
signal dialog_finished

@onready var dialog_text: Label = $MarginContainer/DialogText
@onready var timer: Timer = $Timer
@onready var background: ColorRect = $Background
@onready var margin_container: MarginContainer = $MarginContainer

@export var dialog: String
@export var characters_per_second: float = 20.0
@export var max_width: float = 250.0
@export var padding: Vector2 = Vector2(6, 6)
@export var timer_before_exit: float = 3.0

var tween: Tween
var is_playing := false

func _ready():
	hide()
	timer.one_shot = true
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialog_text.custom_minimum_size.x = max_width
	timer.timeout.connect(_on_timer_timeout)

func show_dialog(text: String) -> void:
	if is_playing:
		return
	show()
	is_playing = true
	dialog_text.text = text
	dialog_text.visible_ratio = 0
	dialog_started.emit()

	if tween:
		tween.kill()

	tween = create_tween()
	var duration = text.length() / characters_per_second
	tween.tween_property(dialog_text, "visible_ratio", 1.0, duration)
	tween.finished.connect(_on_tween_finished)

func skip_animation() -> void:
	if tween and tween.is_valid():
		tween.kill()
	dialog_text.visible_ratio = 1.0

func _on_tween_finished() -> void:
	timer.start(timer_before_exit)
	dialog_finished.emit()

func _on_timer_timeout() -> void:
	dialog_text.text = ""
	is_playing = false
	hide()
