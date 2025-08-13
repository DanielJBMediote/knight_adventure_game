# player_stats_ui.gd
class_name PlayerStatsUI
extends Control

@onready var player_status_effect_list_ui: PlayerStatusEffectListUI = $MarginContainer/VBoxContainer/PlayerStatusEffectListUI

@onready var health_control: Control = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/HealthControl
@onready var health_bar: ProgressBar = health_control.get_node("ProgressBar")
@onready var health_bar_bg: ProgressBar = health_control.get_node("ProgressBarBG")
@onready var health_points_label: Label = health_control.get_node("Points")

@onready var mana_control: Control = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/ManaControl
@onready var mana_bar: ProgressBar = mana_control.get_node("ProgressBar")
@onready var mana_bar_bg: ProgressBar = mana_control.get_node("ProgressBarBG")
@onready var mana_points_label: Label = mana_control.get_node("Points")

@onready var energy_control: Control = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/EnergyControl
@onready var energy_bar: ProgressBar = energy_control.get_node("ProgressBar")
@onready var energy_bar_bg: ProgressBar = energy_control.get_node("ProgressBarBG")

@onready var exp_control: Control = $MarginContainer/VBoxContainer/HBoxContainer/ExpControl
@onready var exp_bar: TextureProgressBar = exp_control.get_node("TextureProgressBar")

@onready var level_label: Label = $MarginContainer/VBoxContainer/LevelLabel

@onready var animation_player: AnimationPlayer = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/AnimationPlayer

const BAR_ANIM_DURATION := 0.5
const BG_BAR_DELAY := 0.3
const BG_BAR_DURATION := 0.8

const DEFAULT_CONTROL_SIZE := Vector2(400, 16)
const DEFAULT_BAR_SIZE := Vector2(400, 16)
const DEFAULT_POINTS_VALUE := 100.0
const MAX_BAR_WIDTH := 800  # Largura máxima absoluta para as barras
const MIN_BAR_WIDTH := 200  # Largura mínima absoluta para as barras

var timer_tick: Timer
var health_tween: Tween
var mana_tween: Tween
var energy_tween: Tween

func _ready() -> void:
	# Inicializa o timer
	setup_timer()
	add_to_group("player_stats_ui")
	
	animation_player.connect("animation_finished", _on_animation_player_finished)
	
	 # Conecta aos sinais do PlayerEvents
	PlayerEvents.update_health_points.connect(_on_health_updated)
	PlayerEvents.update_mana_points.connect(_on_mana_updated)
	PlayerEvents.update_energy_points.connect(_on_energy_updated)
	PlayerEvents.update_exp.connect(_on_exp_update)
	PlayerEvents.level_up.connect(_on_level_up)
	PlayerEvents.energy_warning.connect(_on_energy_warning_emmited)
	
	# Inicializa com os valores atuais
	_update_health_bar(PlayerStats.max_health_points, PlayerStats.health_points)
	_update_mana_bar(PlayerStats.max_mana_points, PlayerStats.mana_points)
	_update_energy_bar(PlayerStats.max_energy_points, PlayerStats.energy_points)
	_update_exp_bar(PlayerStats.exp_to_next_level, PlayerStats.current_exp)
	
	_on_health_updated(PlayerStats.health_points)
	_on_mana_updated(PlayerStats.mana_points)
	_on_energy_updated(PlayerStats.energy_points)
	
	level_label.text = str("Lv. ", PlayerStats.level)

func setup_timer():
	timer_tick = Timer.new()
	add_child(timer_tick)
	timer_tick.autostart = true
	timer_tick.wait_time = 1.0
	timer_tick.timeout.connect(_on_regen_tick)
	timer_tick.start()

func _on_regen_tick():
	var max_health = PlayerStats.max_health_points
	var current_health = PlayerStats.health_points
	var health_regen_amount = PlayerStats.health_regen_per_seconds
	if health_regen_amount > 0 and current_health < max_health:
		PlayerEvents.recovery_health(health_regen_amount)
	
	var max_mana = PlayerStats.max_mana_points
	var current_mana = PlayerStats.mana_points
	var mana_regen_amount = PlayerStats.mana_regen_per_seconds
	if mana_regen_amount > 0 and current_mana < max_mana:
		PlayerEvents.recovery_mana(mana_regen_amount)
		
	var max_energy = PlayerStats.max_energy_points
	var current_energy = PlayerStats.energy_points
	var energy_regen_amount = PlayerStats.energy_regen_per_seconds
	if energy_regen_amount > 0 and current_energy < max_energy:
		PlayerEvents.recovery_energy(energy_regen_amount)

func animate_bar_change(main_bar: ProgressBar, bg_bar: ProgressBar, new_value: float, is_increasing: bool, tween_ref: Tween):
	if tween_ref:
		tween_ref.kill()
	
	tween_ref = create_tween().set_parallel(true)
	
	if is_increasing:
		tween_ref.tween_property(bg_bar, "value", new_value, BAR_ANIM_DURATION)
		tween_ref.tween_property(main_bar, "value", new_value, BAR_ANIM_DURATION)
	else:
		# Redução: Barra principal primeiro, depois a barra Amarela
		tween_ref.tween_property(main_bar, "value", new_value, BAR_ANIM_DURATION)
		tween_ref.tween_property(bg_bar, "value", new_value, BG_BAR_DURATION).set_delay(BG_BAR_DELAY)

func _update_health_bar(max_value: float, value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = value
	health_bar_bg.max_value = max_value
	health_bar_bg.value = value
	
	# Ajusta o tamanho do container e das barras
	var new_width = _calculate_bar_width(max_value)
	_apply_bar_widths(health_control, health_bar, health_bar_bg, new_width)
	
	update_health_points_label(value)

func _update_mana_bar(max_value: float, value: float) -> void:
	mana_bar.max_value = max_value
	mana_bar.value = value
	mana_bar_bg.max_value = max_value
	mana_bar_bg.value = value
	
	# Ajusta o tamanho do container e das barras
	var new_width = _calculate_bar_width(max_value)
	_apply_bar_widths(mana_control, mana_bar, mana_bar_bg, new_width)
	update_mana_points_label(value)

func _update_energy_bar(max_value: float, value: float) -> void:
	energy_bar.max_value = max_value
	energy_bar.value = value
	energy_bar_bg.max_value = max_value
	energy_bar_bg.value = value
	
	# Ajusta o tamanho do container e das barras
	var new_width = _calculate_bar_width(max_value)
	_apply_bar_widths(energy_control, energy_bar, energy_bar_bg, new_width)

func _update_exp_bar(max_value: float, value: float) -> void:
	exp_bar.max_value = max_value
	exp_bar.value = value

func _calculate_bar_width(max_value: float, base_value: float = DEFAULT_POINTS_VALUE, base_width: float = DEFAULT_BAR_SIZE.x) -> float:
	var scale_factor = max_value / base_value
	var desired_width = base_width * scale_factor
	
	# Aplica os limites mínimo e máximo
	var clamped_width = clamp(desired_width, MIN_BAR_WIDTH, MAX_BAR_WIDTH)
	
	# Arredonda para evitar problemas de subpixel
	return round(clamped_width)

# Função para aplicar os tamanhos de forma consistente
func _apply_bar_widths(control: Control, bar: ProgressBar, bg_bar: ProgressBar, width: float):
	# Ajusta o container
	control.custom_minimum_size.x = width
	control.size.x = width
	
	# Ajusta as barras
	bar.size.x = width
	bg_bar.size.x = width
	
	# Garante que as barras herdem o mesmo tamanho do container
	bar.custom_minimum_size.x = width
	bg_bar.custom_minimum_size.x = width

func update_health_points_label(value: float):
	var max_value = PlayerStats.max_health_points
	health_points_label.text = str( roundi(value), "/", roundi(max_value))
func update_mana_points_label(value: float):
	var max_value = PlayerStats.max_mana_points
	mana_points_label.text = str( roundi(value), "/", roundi(max_value))

func _on_health_updated(new_value: float):
	var is_increasing = new_value > health_bar.value
	animate_bar_change(health_bar, health_bar_bg, new_value, is_increasing, health_tween)
	update_health_points_label(new_value)

func _on_mana_updated(new_value: float):
	var is_increasing = new_value > mana_bar.value
	animate_bar_change(mana_bar, mana_bar_bg, new_value, is_increasing, mana_tween)
	update_mana_points_label(new_value)

func _on_energy_updated(new_value: float):
	var is_increasing = new_value > energy_bar.value
	animate_bar_change(energy_bar, energy_bar_bg, new_value, is_increasing, energy_tween)

func _on_exp_update(new_value: float):
	var tween = create_tween().set_parallel(true)
	tween.tween_property(exp_bar, "value", new_value, 1.0)

func _on_level_up(new_level: int):
	level_label.text = str("Lv.", new_level)
	_update_exp_bar(PlayerStats.exp_to_next_level, PlayerStats.current_exp)

func _on_energy_warning_emmited():
	animation_player.play("energy_bar_warning")

func _on_animation_player_finished(anim_name: String):
	if anim_name.contains("bar_warning"):
		animation_player.stop()
