class_name SocketButton
extends Button

const ADD_GEM_ICON = Rect2(304, 16, 32, 32)
const REMOVE_GEM_ICON = Rect2(336, 16, 32, 32)


func _ready() -> void:
	update_button_icon()


func update_button_icon(has_gem: bool = false) -> void:
	if has_gem:
		self.icon.region = REMOVE_GEM_ICON
		self.text = LocalizationManager.get_ui_text("remove")
	else:
		self.icon.region = ADD_GEM_ICON
		self.text = LocalizationManager.get_ui_text("attach")
