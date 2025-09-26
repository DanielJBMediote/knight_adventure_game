class_name StatusEffectUITooltip
extends PanelContainer

@onready var description_text: DescriptionText = $MarginContainer/DescriptionText


const OFFSET = Vector2.ONE * 25.0
var opacity_tween: Tween = null


func _ready() -> void:
	hide()


func setup_description(effect_description: String) -> void:
	description_text.text = effect_description

	var width = description_text.get_content_width()
	var height = description_text.get_content_height()
	self.size = Vector2(width, height)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position() + OFFSET


func toggle(on: bool) -> void:
	if on:
		modulate.a = 0.0
		tween_opacity(1.0, 0.2)
		show()
	else:
		tween_opacity(0.0, 0.2)
		hide()


func tween_opacity(to: float, duration: float) -> void:
	if opacity_tween:
		opacity_tween.kill()

	opacity_tween = create_tween()
	opacity_tween.tween_property(self, "modulate:a", to, duration)
