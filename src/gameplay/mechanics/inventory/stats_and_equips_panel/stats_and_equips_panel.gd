class_name StatsAndEquipsPanelUI
extends Panel

enum StatsCategory {
	Offensive,
	Defensive,
	Others
}

@onready var equipments_slots_grid: GridContainer = $MarginContainer/VBoxContainer/EquipmentsSlotsGrid
@onready var equip_and_stats_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/EquipAndStatsLabel
@onready var toggle_stats_equips_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/ToggleStatsEquipsButton
@onready var animated_sprite_2d: AnimatedSprite2D = $MarginContainer/VBoxContainer/AnimatedSprite2D

@onready var stats_info_scene: PackedScene = preload("res://src/gameplay/mechanics/inventory/stats_and_equips_panel/stats_info.tscn")
@onready var stats_content: VBoxContainer = $MarginContainer/VBoxContainer/StatsContent

@onready var tab_container: TabContainer = $MarginContainer/VBoxContainer/StatsContent/TabContainer

var show_equipment: bool = true
var offensive_stats_list: Array[StatsInfoUI] = []
var defensive_stats_list: Array[StatsInfoUI] = []
var others_stats_list: Array[StatsInfoUI] = []
var player_attributes: Dictionary[String, Variant] = {}

func _ready() -> void:
	animated_sprite_2d.play("default")
	toggle_stats_equips_button.pressed.connect(_toggle_content)
	tab_container.tab_changed.connect(_on_tab_changed)
	
	# Conecta ao sinal de mudança de atributos
	PlayerStats.attributes_changed.connect(_on_attributes_changed)
	
	# Configura as abas
	_setup_tabs()
	
	# Carrega os atributos iniciais
	player_attributes = get_player_attributes_formated(PlayerStats.get_attributes())
	_create_stats_ui()
	update_showing_content()

func _setup_tabs() -> void:
	var tabs = tab_container.get_tab_bar()
	# Limpa tabs existentes
	for i in range(tabs.tab_count, 0, -1):
		tabs.getremove_tab(i - 1)
	
	# Adiciona as novas tabs
	#tabs.add_tab(LocalizationManager.get_ui_text("offensive"))
	#tabs.add_tab(LocalizationManager.get_ui_text("defensive"))
	
	# Configura o TabContainer
	for i in range(tab_container.get_tab_count(), 0, -1):
		tab_container.remove_child(tab_container.get_child(i - 1))
	
	var offensive_container = VBoxContainer.new()
	offensive_container.name = str("   ", LocalizationManager.get_ui_text("stats.offensive"), "   ")
	tab_container.add_child(offensive_container)
	
	var defensive_container = VBoxContainer.new()
	defensive_container.name = str("   ", LocalizationManager.get_ui_text("stats.defensive"), "   ")
	tab_container.add_child(defensive_container)
	
	var others_container = VBoxContainer.new()
	others_container.name = str("   ", LocalizationManager.get_ui_text("stats.others"), "   ")
	tab_container.add_child(others_container)

func _on_tab_changed(tab_index: int) -> void:
	tab_container.current_tab = tab_index

func _on_attributes_changed(new_attributes: Dictionary) -> void:
	player_attributes = get_player_attributes_formated(new_attributes)
	_update_stats_ui()

func _create_stats_ui() -> void:
	# Limpa stats existentes
	for container in [tab_container.get_child(0), tab_container.get_child(1)]:
		for child in container.get_children():
			child.queue_free()
	
	offensive_stats_list.clear()
	defensive_stats_list.clear()
	others_stats_list.clear()
	
	# Cria UI para cada atributo nas abas apropriadas
	for attribute_key in player_attributes:
		var attribute_data: Dictionary = player_attributes[attribute_key]
		var stat_info: StatsInfoUI = stats_info_scene.instantiate()
		var stat_category = player_attributes[attribute_key].get("stats_category")
		# Adiciona à aba apropriada (Offensive ou Defensive)
		match stat_category:
			StatsCategory.Offensive:
				tab_container.get_child(0).add_child(stat_info)
				offensive_stats_list.append(stat_info)
			StatsCategory.Defensive:
				tab_container.get_child(1).add_child(stat_info)
				defensive_stats_list.append(stat_info)
			_:
				tab_container.get_child(2).add_child(stat_info)
				others_stats_list.append(stat_info)
		
		# Configura nome e valor
		stat_info.label.text = attribute_data.get("name", "MISSING_NAME")
		stat_info.value.text = str(attribute_data.get("value", "MISSING_VALUE"))

func _update_stats_ui() -> void:
	# Atualiza os valores dos stats ofensivos
	for i in range(offensive_stats_list.size()):
		var stat_info: StatsInfoUI = offensive_stats_list[i]
		var attribute_data = _find_attribute_data_by_name(stat_info.label.text)
		if attribute_data:
			stat_info.value.text = str(attribute_data.get("value", "MISSING_VALUE"))
	
	# Atualiza os valores dos stats defensivos
	for i in range(defensive_stats_list.size()):
		var stat_info: StatsInfoUI = defensive_stats_list[i]
		var attribute_data = _find_attribute_data_by_name(stat_info.label.text)
		if attribute_data:
			stat_info.value.text = str(attribute_data.get("value", "MISSING_VALUE"))

func _find_attribute_data_by_name(stat_name: String) -> Dictionary:
	for attribute_data in player_attributes.values():
		if attribute_data.get("name", "") == stat_name:
			return attribute_data
	return {}

#func _is_offensive_stat(attribute_key: String) -> bool:
	## Define quais atributos são considerados ofensivos
	#var offensive_stats = [
		#"damage", "critical_rate", "critical_damage", "attack_speed",
		#"energy", "mana"  # Recursos usados para habilidades ofensivas
	#]
	#
	#return attribute_key in offensive_stats

func _toggle_content():
	show_equipment = !show_equipment
	equip_and_stats_label.text = LocalizationManager.get_ui_text("equipments") if show_equipment else LocalizationManager.get_ui_text("stats._name")
	update_showing_content()
	update_toggle_button()
	
	# Atualiza os stats quando a aba é mostrada
	if !show_equipment:
		player_attributes = get_player_attributes_formated(PlayerStats.get_attributes())
		_update_stats_ui()

func update_showing_content():
	equipments_slots_grid.visible = show_equipment
	stats_content.visible = !show_equipment
	animated_sprite_2d.visible = show_equipment
	tab_container.visible = !show_equipment
	tab_container.visible = !show_equipment

func update_toggle_button():
	toggle_stats_equips_button.text = LocalizationManager.get_ui_text("equipments") if !show_equipment else LocalizationManager.get_ui_text("stats._name")

func get_player_attributes_formated(new_attributes: Dictionary) -> Dictionary[String, Variant]:
	return {
		"damage": {
			"name": LocalizationManager.get_ui_attribute_name("damage"),
			"value": str(roundi(new_attributes.min_damage), " - ", roundi(new_attributes.max_damage)),
			"stats_category": StatsCategory.Offensive
		},
		"critical_rate": {
			"name": LocalizationManager.get_ui_attribute_name("critical_rate"),
			"value": str(new_attributes.critical_rate, "%"),
			"stats_category": StatsCategory.Offensive
		},
		"critical_damage": {
			"name": LocalizationManager.get_ui_attribute_name("critical_damage"),
			"value": str(new_attributes.critical_damage, "%"),
			"stats_category": StatsCategory.Offensive
		},
		"attack_speed": {
			"name": LocalizationManager.get_ui_attribute_name("attack_speed"),
			"value": str((new_attributes.attack_speed*100), "%"),
			"stats_category": StatsCategory.Offensive
		},
		"bleed_hit_rate": {
			"name": LocalizationManager.get_ui_attribute_name("bleed_hit_rate"),
			"value": str((new_attributes.bleed_hit_rate*100), "%"),
			"stats_category": StatsCategory.Offensive
		},
		"poison_hit_rate": {
			"name": LocalizationManager.get_ui_attribute_name("poison_hit_rate"),
			"value": str((new_attributes.poison_hit_rate*100), "%"),
			"stats_category": StatsCategory.Offensive
		},
		
		"health": {
			"name": LocalizationManager.get_ui_attribute_name("health"),
			"value": format_resources(new_attributes.health_points,new_attributes.max_health_points),
			"stats_category": StatsCategory.Defensive
		},
		"health_regen": {
			"name": LocalizationManager.get_ui_attribute_name("health_regen"),
			"value": str(new_attributes.health_regen_per_seconds, "/s"),
			"stats_category": StatsCategory.Defensive
		},
		"mana": {
			"name": LocalizationManager.get_ui_attribute_name("mana"),
			"value": format_resources(new_attributes.mana_points, new_attributes.max_mana_points),
			"stats_category": StatsCategory.Defensive
		},
		"mana_regen": {
			"name": LocalizationManager.get_ui_attribute_name("mana_regen"),
			"value": str(new_attributes.mana_regen_per_seconds, "/s"),
			"stats_category": StatsCategory.Defensive
		},
		"energy": {
			"name": LocalizationManager.get_ui_attribute_name("energy"),
			"value": format_resources(new_attributes.energy_points, new_attributes.max_energy_points),
			"stats_category": StatsCategory.Defensive
		},
		"energy_regen": {
			"name": LocalizationManager.get_ui_attribute_name("energy_regen"),
			"value": str(new_attributes.energy_regen_per_seconds, "/s"),
			"stats_category": StatsCategory.Defensive
		},
		"defense": {
			"name": LocalizationManager.get_ui_attribute_name("defense"),
			"value": str(new_attributes.defense, "%"),
			"stats_category": StatsCategory.Defensive
		},
		"move_speed": {
			"name": LocalizationManager.get_ui_attribute_name("move_speed"),
			"value": str((new_attributes.move_speed*100), "%"),
			"stats_category": StatsCategory.Defensive
		},
		"knockback_resistance": {
			"name": LocalizationManager.get_ui_text("stats.knockback_resistance"),
			"value": format_knockback_resistance(new_attributes.knockback_resistance),
			"stats_category": StatsCategory.Defensive
		},
		
		"level": {
			"name": LocalizationManager.get_ui_text("level"),
			"value": str(new_attributes.level),
			"stats_category": StatsCategory.Others
		},
		"experience": {
			"name": LocalizationManager.get_ui_text("experience"),
			"value": format_resources(new_attributes.current_exp, new_attributes.exp_to_next_level),
			"stats_category": StatsCategory.Others
		},
		"exp_buff": {
			"name": LocalizationManager.get_ui_text("exp_buff"),
			"value": str((new_attributes.exp_buff*100), "%"),
			"stats_category": StatsCategory.Others
		},
	}
func format_resources(value: float, max_value: float) -> String:
	return "%s/%s" % [roundi(value), roundi(max_value)]
 
func format_knockback_resistance(knockback_resistance: float) -> String:
	var percentage = (1.0 - knockback_resistance) * 100
	if knockback_resistance < 1.0:
		return "%.1f%% %s" % [abs(percentage), LocalizationManager.get_ui_text("stats.reduction")]
	elif knockback_resistance > 1.0:
		return "%.1f%% %s" % [percentage, LocalizationManager.get_ui_text("stats.increase")]
	else:
		return LocalizationManager.get_ui_text("stats.normal")
