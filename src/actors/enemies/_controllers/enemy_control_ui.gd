class_name EnemyControlUI
extends Control

@onready var float_label: PackedScene = preload("res://src/ui/float_label.tscn")

@onready var enemy_level: Label = $VBoxContainer/MainContainer/EnemyLevel
@onready var health_bar_bg: ProgressBar = $VBoxContainer/MainContainer/HealthBarContainer/HealthBarBG
@onready var health_bar: ProgressBar = $VBoxContainer/MainContainer/HealthBarContainer/HealthBar
@onready var status_effect_list: HBoxContainer = $VBoxContainer/StatusEffectList

@export var enemy_stats: EnemyStats

const BAR_ANIM_DURATION := 0.5
const BG_BAR_DELAY := 0.3
const BG_BAR_DURATION := 0.8

var timer_tick: Timer
var health_tween: Tween


func _ready() -> void:

	health_bar.max_value = enemy_stats.health_points
	health_bar.value = enemy_stats.current_health_points
	health_bar_bg.max_value = enemy_stats.health_points
	health_bar_bg.value = enemy_stats.current_health_points

	enemy_stats.health_changed.connect(on_update_health)
	if not timer_tick:
		timer_tick = Timer.new()
	
	timer_tick.autostart = true
	timer_tick.timeout.connect(_on_timeout)
	add_child(timer_tick)
	timer_tick.start(1.0)

	setup_labels()

func _on_timeout():
	var health_regen_per_seconds = enemy_stats.health_regen_per_seconds
	var health_points = enemy_stats.current_health_points
	var max_health_points = enemy_stats.health_points
	if health_regen_per_seconds > 0 and health_points < max_health_points:
		health_points += health_regen_per_seconds
		on_update_health(health_points)


func animate_bar_change(
	main_bar: ProgressBar, bg_bar: ProgressBar, new_value: float, is_increasing: bool, tween_ref: Tween
):
	if tween_ref:
		tween_ref.kill()  # Interrompe animações anteriores

	tween_ref = create_tween().set_parallel(true)

	if is_increasing:
		# Aumento: BG primeiro, depois barra principal
		tween_ref.tween_property(bg_bar, "value", new_value, BAR_ANIM_DURATION)
		tween_ref.tween_property(main_bar, "value", new_value, BAR_ANIM_DURATION).set_delay(BG_BAR_DELAY)
	else:
		# Redução: Barra principal primeiro, depois BG
		tween_ref.tween_property(main_bar, "value", new_value, BAR_ANIM_DURATION)
		tween_ref.tween_property(bg_bar, "value", new_value, BG_BAR_DURATION).set_delay(BG_BAR_DELAY)


func on_update_health(new_health: float) -> void:
	# Calcula se é aumento ou redução
	var is_increasing = new_health > enemy_stats.health_points
	var health_points = new_health
	# Atualiza as barras
	animate_bar_change(health_bar, health_bar_bg, health_points, is_increasing, health_tween)
	#print("Vida anterior: ", health_points, " | Nova vida: ", new_health)


func setup_labels() -> void:
	var mob_level = enemy_stats.level
	var player_level = PlayerStats.level
	var label_color: Color = Color.WHITE

	if mob_level <= (player_level - 5):
		label_color = Color.GREEN
	elif mob_level <= (player_level + 5):
		label_color = Color.ORANGE
	elif mob_level >= (player_level + 5):
		label_color = Color.RED

	enemy_level.text = str("Lv.", mob_level)
	#enemy_name.text = enemy_stats.enmey_name
	enemy_level.add_theme_color_override("font_color", label_color)
	#enemy_name.add_theme_color_override("font_color", label_color)
