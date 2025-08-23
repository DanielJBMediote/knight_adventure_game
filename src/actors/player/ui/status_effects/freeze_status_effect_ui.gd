# freeze_effect_status_ui.gd
class_name FreezeStatusEffectUI
extends StatusEffectUI

const TEXTURE_ICON = preload("res://assets/ui/status_effect_icons/freeze.png")
const BAR_COLOR_FILL = Color(0.43, 0.78, 0.85, 1.0)
const BAR_COLOR_BG = Color(0.08, 0.29, 0.38, 1.0)

func setup_effect(effect_data: StatusEffectData) -> void:
	super(effect_data)  # Chama a implementação base
	setup_appearance()   # Configura a aparência específica

func setup_appearance() -> void:
	set_icon_texture(TEXTURE_ICON)
	set_progress_bar_color(BAR_COLOR_FILL, BAR_COLOR_BG)
