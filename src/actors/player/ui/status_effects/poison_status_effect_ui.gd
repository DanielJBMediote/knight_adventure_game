class_name PoisonStatusEffectUI
extends StatusEffectUI

const TEXTURE_ICON = preload("res://assets/ui/status_effect_icons/poison.png")
const BAR_COLOR_FILL = Color(0.5, 0.63, 0.18, 1.0)
const BAR_COLOR_BG = Color(0.10, 0.16, 0.08, 1.0)

func setup_effect(effect_data: StatusEffectData) -> void:
	super(effect_data)  # Chama a implementação base
	setup_appearance()   # Configura a aparência específica

func setup_appearance() -> void:
	set_icon_texture(TEXTURE_ICON)
	set_progress_bar_color(BAR_COLOR_FILL, BAR_COLOR_BG)
