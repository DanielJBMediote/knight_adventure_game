class_name FloatDamageControl
extends Control

signal trigged_hit(damage: float)

@onready var float_damage_label: PackedScene = preload("res://src/gui/float_label.tscn")
@onready var tick_timer: Timer = $TickTimer

const CRIT_DAMAGE_SIZE := 64

enum DMG_TYPE {NORMAL, BLOCK, BLEEDING, POISONING}
var damage_type = DMG_TYPE.NORMAL
var float_label: FloatLabel

var bleed_timer: Timer
var is_bleeding: bool = false
var bleed_dps: float = 0.0

var poison_timer: Timer
var is_poisoning: bool = false
var poison_dps: float = 0.0

func _ready() -> void:
	
	tick_timer.timeout.connect(_apply_damage_on_finish_tick)
	tick_timer.wait_time = 1.0
	tick_timer.start()
	
	bleed_timer = Timer.new()
	bleed_timer.one_shot = true
	bleed_timer.timeout.connect(_on_bleed_ended)
	add_child(bleed_timer)
	
	poison_timer = Timer.new()
	poison_timer.one_shot = true
	poison_timer.timeout.connect(_on_poison_ended)
	add_child(poison_timer)

func set_damage(data: DamageData):
	var damage_text: String = str(roundi(data.damage))
	
	if data.is_poisoning and not is_poisoning:
		is_poisoning = true
		poison_dps = data.poisoning_dps
		poison_timer.start(data.poisoning_duration)
	
	if data.is_bleeding and not is_bleeding:
		is_bleeding = true
		bleed_dps = data.bleeding_dps
		bleed_timer.start(data.bleeding_duration)
	
	float_label = float_damage_label.instantiate()
	if data.is_critical:
		float_label.modulate = Color.CHOCOLATE
		float_label.add_theme_font_size_override("font_size", CRIT_DAMAGE_SIZE)  # Tamanho maior para crítico

	float_label.text = damage_text
	
	add_child(float_label)
	trigged_hit.emit(data.damage)

func _on_poison_ended():
	is_poisoning = false
	poison_dps = 0.0
	
func _on_bleed_ended():
	is_bleeding = false
	bleed_dps = 0.0

func _apply_damage_on_finish_tick():
	if is_poisoning:
		_apply_poison_damage()
	if is_bleeding:
		_apply_bleed_damage()

func _apply_bleed_damage():
	float_label = float_damage_label.instantiate()
	float_label.text = str(bleed_dps)
	float_label.modulate = Color.DARK_RED
	add_child(float_label)
	trigged_hit.emit(bleed_dps)
	
func _apply_poison_damage():
	float_label = float_damage_label.instantiate()
	float_label.text = str(roundi(poison_dps))
	float_label.modulate = Color.FOREST_GREEN
	add_child(float_label)
	trigged_hit.emit(poison_dps)
