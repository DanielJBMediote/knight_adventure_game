# bleed_effect_status_ui.gd
class_name BleedStatusEffectUI
extends StatusEffectUI

const TEXTURE_ICON = preload("res://assets/ui/status_effect_icons/bleed.png")
const BAR_COLOR_FILL = Color(0.65, 0.12, 0.12, 1.0)
const BAR_COLOR_BG = Color(0.21, 0.07, 0.07, 1.0)

func setup_effect(effect_data: StatusEffectData) -> void:
	super(effect_data)  # Chama a implementação base
	setup_appearance()   # Configura a aparência específica

func setup_appearance() -> void:
	set_icon_texture(TEXTURE_ICON)
	set_progress_bar_color(BAR_COLOR_FILL, BAR_COLOR_BG)
