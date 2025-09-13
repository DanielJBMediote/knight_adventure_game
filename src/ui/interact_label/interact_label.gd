class_name InteractLabel
extends Control

@onready var label: Label = $MarginContainer/Label
@export var text: String

func _ready() -> void:
	_on_hide()

func _on_show(new_text: String) -> void:
	label.text = new_text
	self.show()

func _on_hide() -> void:
	label.text = ""
	self.hide()
