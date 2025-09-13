class_name SocketButton
extends Button

const ADD_GEM_ICON = Rect2(304, 16, 32, 32)
const REMOVE_GEM_ICON = Rect2(336, 16, 32, 32)


func update_button_icon(has_gem: bool = false) -> void:
	if has_gem:
		self.icon.region = REMOVE_GEM_ICON
	else:
		self.icon.region = ADD_GEM_ICON
