class_name GameSavingLoading
extends Control

@onready var loading_label: DefaultLabel = $LoadingLabel

var _tween: Tween

func _ready() -> void:
	loading_label.text = ""
	hide()


func show_animation(text: String = "Saving...") -> void:
	show()

	loading_label.text = text
	loading_label.visible_ratio = 0.7
	
	# Reiniciar e parar qualquer animação anterior
	if _tween:
		_tween.kill()
	
	loading_label.modulate.a = 0
	
	_tween = create_tween()
	_tween.set_parallel(true)
	
	_tween.tween_property(loading_label, "modulate:a", 1.0, 0.5)
	_tween.tween_property(loading_label, "visible_ratio", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	
	_tween.chain().tween_interval(1.0)
	
	_tween.chain().set_parallel(true)
	_tween.tween_property(loading_label, "modulate:a", 0.0, 0.5)
	_tween.tween_property(loading_label, "visible_ratio", 0.7, 0.5).set_ease(Tween.EASE_IN)
	
	_tween.chain().tween_callback(Callable(self, "hide"))
