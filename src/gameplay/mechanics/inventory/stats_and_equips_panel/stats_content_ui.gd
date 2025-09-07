class_name StatsContentUI
extends ScrollContainer

enum GROUP {OFFENSIVE, DEFENSIVE, MISCELLANEOUS}

@onready var stats_info_scene: PackedScene = preload("res://src/gameplay/mechanics/inventory/stats_and_equips_panel/stats_info.tscn")
@onready var container: VBoxContainer = $VBoxContainer

const GROUP_KEYS = {GROUP.OFFENSIVE: "offensive", GROUP.DEFENSIVE: "defensive", GROUP.MISCELLANEOUS: "miscellaneous"}

var stats_groups: Dictionary[GROUP, Array] = {GROUP.OFFENSIVE: [], GROUP.DEFENSIVE: [], GROUP.MISCELLANEOUS: []}
var player_attributes: Dictionary[String, Variant] = {}


func _ready() -> void:
	PlayerStats.attributes_changed.connect(_on_attributes_changed)
	player_attributes = get_player_attributes_formated(PlayerStats.get_attributes())
	create_list()


func create_list() -> void:
	# Limpa stats existentes - CORREÇÃO: limpa apenas o container, não todos os filhos
	for child in container.get_children():
		child.queue_free()

	stats_groups[GROUP.OFFENSIVE].clear()
	stats_groups[GROUP.DEFENSIVE].clear()
	stats_groups[GROUP.MISCELLANEOUS].clear()

	# Cria UI para cada atributo nas abas apropriadas
	for attribute_key in player_attributes:
		var attribute_data: Dictionary = player_attributes[attribute_key]
		var stat_info: StatsInfoUI = stats_info_scene.instantiate()
		var stat_category = attribute_data.get("stats_category", GROUP.MISCELLANEOUS) # Usa valor padrão

		# Configura nome e valor
		stat_info.stats_name = attribute_data.get("name", "MISSING_NAME")
		stat_info.stats_value = str(attribute_data.get("value", "MISSING_VALUE"))
		stat_info.attribute_key = attribute_key

		# Adiciona ao grupo correto
		stats_groups[stat_category].append(stat_info)

	# Adiciona todos os stats aos containers - CORREÇÃO: adiciona apenas uma vez
	for group in stats_groups:
		var title_label: StatsInfoUI = stats_info_scene.instantiate()
		var separator = " ---- "
		title_label.stats_name = separator + LocalizationManager.get_ui_text(GROUP_KEYS[group]) + separator
		container.add_child(title_label)
		title_label.label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_label.label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.label.add_theme_font_size_override("font_size", 24)
		title_label.value.hide()

		var stats_list = stats_groups[group] as Array[StatsInfoUI]
		for stat_info in stats_list:
			container.add_child(stat_info)

		if stats_list.size() > 0:
				var empty_label: Label = Label.new()
				empty_label.custom_minimum_size = Vector2(0, 8)
				container.add_child(empty_label)

func _update_stats_ui() -> void:
	player_attributes = get_player_attributes_formated(PlayerStats.get_attributes())
	
	# Atualiza todos os stats usando a chave original armazenada
	for group in stats_groups:
		for stat_info in stats_groups[group]:
			var attribute_key = stat_info.attribute_key
			if attribute_key != "" and attribute_key in player_attributes:
				var attribute_data = player_attributes[attribute_key]
				stat_info.stats_value = str(attribute_data.get("value", "MISSING_VALUE"))


func _find_attribute_data_by_name(stat_name: String) -> Dictionary:
	for attribute_data in player_attributes.values():
		if attribute_data.get("name", "") == stat_name:
			return attribute_data
	return {}


func _on_attributes_changed(new_attributes: PlayerAttributes) -> void:
	player_attributes = get_player_attributes_formated(new_attributes)
	_update_stats_ui()


func get_player_attributes_formated(new_attributes: PlayerAttributes) -> Dictionary[String, Variant]:
	return {
		"damage":
		{
			"name": LocalizationManager.get_ui_text("damage"),
			"value": str(roundi(new_attributes.min_damage), " - ", roundi(new_attributes.max_damage)),
			"stats_category": GROUP.OFFENSIVE
		},
		"critical_rate":
		{
			"name": LocalizationManager.get_ui_text("critical_rate"),
			"value": str(roundi(new_attributes.critical_points), " (", snapped(new_attributes.critical_rate * 100, 0.01), "%)"),
			"stats_category": GROUP.OFFENSIVE
		},
		"max_criticl_points": {
			"name": "Critical to Max %",
			"value": str(snapped(new_attributes.max_critical_points, 0.01)),
			"stats_category": GROUP.OFFENSIVE
		},
		"critical_damage":
		{
			"name": LocalizationManager.get_ui_text("critical_damage"),
			"value": str(snapped(new_attributes.critical_damage * 100, 0.01), "%"),
			"stats_category": GROUP.OFFENSIVE
		},
		"attack_speed":
		{
			"name": LocalizationManager.get_ui_text("attack_speed"),
			"value": str(snapped(new_attributes.attack_speed * 100, 0.01), "%"),
			"stats_category": GROUP.OFFENSIVE
		},
		"bleed_hit_rate":
		{
			"name": LocalizationManager.get_ui_text("bleed_hit_rate"),
			"value": str(snapped(new_attributes.bleed_hit_rate * 100, 0.01), "%"),
			"stats_category": GROUP.OFFENSIVE
		},
		"poison_hit_rate":
		{
			"name": LocalizationManager.get_ui_text("poison_hit_rate"),
			"value": str(snapped(new_attributes.poison_hit_rate * 100, 0.01), "%"),
			"stats_category": GROUP.OFFENSIVE
		},
		"health":
		{
			"name": LocalizationManager.get_ui_text("health"),
			"value": format_resources(new_attributes.health_points, new_attributes.max_health_points),
			"stats_category": GROUP.DEFENSIVE
		},
		"health_regen":
		{
			"name": LocalizationManager.get_ui_text("health_regen"),
			"value": str(new_attributes.health_regen_per_seconds, "/s"),
			"stats_category": GROUP.DEFENSIVE
		},
		"mana":
		{
			"name": LocalizationManager.get_ui_text("mana"),
			"value": format_resources(new_attributes.mana_points, new_attributes.max_mana_points),
			"stats_category": GROUP.DEFENSIVE
		},
		"mana_regen":
		{
			"name": LocalizationManager.get_ui_text("mana_regen"),
			"value": str(new_attributes.mana_regen_per_seconds, "/s"),
			"stats_category": GROUP.DEFENSIVE
		},
		"energy":
		{
			"name": LocalizationManager.get_ui_text("energy"),
			"value": format_resources(new_attributes.energy_points, new_attributes.max_energy_points),
			"stats_category": GROUP.DEFENSIVE
		},
		"energy_regen":
		{
			"name": LocalizationManager.get_ui_text("energy_regen"),
			"value": str(new_attributes.energy_regen_per_seconds, "/s"),
			"stats_category": GROUP.DEFENSIVE
		},
		"defense":
		{
			"name": LocalizationManager.get_ui_text("defense"),
			"value":
			str(snapped(new_attributes.defense_points, 0.01), " (", snapped(new_attributes.defense_rate, 0.01), "%)"),
			"stats_category": GROUP.DEFENSIVE
		},
		"max_defense_points":
		{
			"name": "Defense to Max %",
			"value":
			str(snapped(new_attributes.max_defense_points, 0.01)),
			"stats_category": GROUP.DEFENSIVE
		},
		"move_speed":
		{
			"name": LocalizationManager.get_ui_text("move_speed"),
			"value": str(snapped(new_attributes.move_speed * 100, 0.01), "%"),
			"stats_category": GROUP.DEFENSIVE
		},
		"knockback_resistance":
		{
			"name": LocalizationManager.get_ui_text("knockback_resistance"),
			"value": format_knockback_resistance(new_attributes.knockback_resistance),
			"stats_category": GROUP.DEFENSIVE
		},
		"level":
		{
			"name": LocalizationManager.get_ui_text("level"),
			"value": str(new_attributes.level),
			"stats_category": GROUP.MISCELLANEOUS
		},
		"experience":
		{
			"name": LocalizationManager.get_ui_text("experience"),
			"value": format_resources(new_attributes.current_exp, new_attributes.exp_to_next_level),
			"stats_category": GROUP.MISCELLANEOUS
		},
		"exp_buff":
		{
			"name": LocalizationManager.get_ui_text("exp_buff"),
			"value": str(new_attributes.exp_buff * 100, "%"),
			"stats_category": GROUP.MISCELLANEOUS
		},
	}


func format_resources(value: float, max_value: float) -> String:
	return "%s/%s" % [roundi(value), roundi(max_value)]


func format_knockback_resistance(knockback_resistance: float) -> String:
	var percentage = (1.0 - knockback_resistance) * 100
	if knockback_resistance < 1.0:
		return "%.1f%% %s" % [abs(percentage), LocalizationManager.get_ui_text("reduction")]
	elif knockback_resistance > 1.0:
		return "%.1f%% %s" % [percentage, LocalizationManager.get_ui_text("increase")]
	else:
		return LocalizationManager.get_ui_text("normal")
