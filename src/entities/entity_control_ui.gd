class_name EntityControlUI
extends Control

@onready var progress_bar: ProgressBar = $Background/ProgressBar
@onready var progress_bar_bg: ProgressBar = $Background/ProgressBarBG
@onready var enemy_name: Label = $EnemyName
@onready var enemy_level: Label = $EnemyLevel

@export var entity_stats: EntityStats

const BAR_ANIM_DURATION := 0.5
const BG_BAR_DELAY := 0.3
const BG_BAR_DURATION := 0.8

var timer_tick: Timer
var health_tween: Tween

func _ready() -> void:
	if entity_stats == null:
		printerr("Entity Stats Node not defined!")
		
	progress_bar.max_value = entity_stats.health_points
	progress_bar.value = entity_stats.current_health_points
	progress_bar_bg.max_value = entity_stats.health_points
	progress_bar_bg.value = entity_stats.current_health_points
	
	setup_labels()
	
	timer_tick = Timer.new()
	timer_tick.autostart = true
	timer_tick.start(1.0)
	timer_tick.timeout.connect(_on_timeout)
	add_child(timer_tick)
	
	entity_stats.health_changed.connect(on_update_health)

func _on_timeout():
	var health_regen_per_seconds = entity_stats.health_regen_per_seconds
	var health_points = entity_stats.current_health_points
	var max_health_points = entity_stats.health_points
	if health_regen_per_seconds > 0 and health_points < max_health_points:
		health_points += health_regen_per_seconds
		on_update_health(health_points)

func animate_bar_change(main_bar: ProgressBar, bg_bar: ProgressBar, new_value: float, is_increasing: bool, tween_ref: Tween):
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
	var is_increasing = new_health > entity_stats.health_points
	var health_points = new_health
	# Atualiza as barras
	animate_bar_change(progress_bar, progress_bar_bg, health_points, is_increasing, health_tween)
	#print("Vida anterior: ", health_points, " | Nova vida: ", new_health)

func setup_labels() -> void:
	var mob_level = entity_stats.entity_level
	var player_level = PlayerStats.level
	var label_color: Color = Color.WHITE
	
	if mob_level <= (player_level - 5):
		label_color = Color.GREEN
	#elif mob_level <= player_level:
		#label_color = Color.WHITE
	elif mob_level <= (player_level + 5):
		label_color = Color.ORANGE
	elif mob_level >= (player_level + 5):
		label_color = Color.RED
		
	enemy_level.text = str("Lv.", mob_level)
	enemy_level.modulate = label_color
	enemy_name.text = entity_stats.entity_name
	
