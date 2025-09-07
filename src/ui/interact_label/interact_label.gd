class_name InteractLabel
extends Control

@onready var label: Label = $Label

@export var control_size: Vector2 = Vector2(96, 16)
@export var text: String


func _ready() -> void:
  self.size = control_size
  label.text = text
