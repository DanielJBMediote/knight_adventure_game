# freeze_effect_status_ui.gd
class_name FreezeStatusEffectUI
extends StatusEffectUI

@onready var timer_label: Label = $VBoxContainer/HBoxContainer/TimerLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar

func _init() -> void:
	self.effect = EFFECT.FREEZE
