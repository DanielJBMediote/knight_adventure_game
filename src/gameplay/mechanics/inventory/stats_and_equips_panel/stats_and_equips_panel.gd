class_name StatsAndEquipsPanelUI
extends Panel

@onready var equipments_slots_ui: EquipmentContentUI = $MarginContainer/MainConteiner/EquipmentsSlotsUI
@onready var stats_content_ui: StatsContentUI = $MarginContainer/MainConteiner/StatsContentUI

@onready var equip_and_stats_label: Label = $MarginContainer/MainConteiner/Header/EquipAndStatsLabel
@onready var toggle_stats_equips_button: Button = $MarginContainer/MainConteiner/Header/ToggleStatsEquipsButton

var show_equipment: bool = true


func _ready() -> void:
	toggle_stats_equips_button.pressed.connect(_toggle_content)
	update_showing_content()


func _toggle_content():
	show_equipment = !show_equipment

	if show_equipment:
		equip_and_stats_label.text = LocalizationManager.get_ui_text("equipments")
	else:
		equip_and_stats_label.text = LocalizationManager.get_ui_text("stats")

	update_showing_content()
	update_toggle_button()


func update_showing_content():
	equipments_slots_ui.visible = show_equipment
	stats_content_ui.visible = !show_equipment


func update_toggle_button():
	if show_equipment:
		toggle_stats_equips_button.text = LocalizationManager.get_ui_text("stats")
	else:
		toggle_stats_equips_button.text = LocalizationManager.get_ui_text("equipments")
