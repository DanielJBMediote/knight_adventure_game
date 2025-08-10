extends Node

const BASE_EXP = 100
const EXP_SCALE_FACTOR = 1.15
const EXP_ADDITIVE = 50

var level: int = 1
var total_exp := 0.0
var current_exp := 0.0
var exp_to_next_level := 0.0

var max_health_points: float = 100.0
var health_points: float = 100.0
var health_regen_per_seconds: float = 1.0

var max_mana_points: float = 100.0
var mana_points: float = 100.0
var mana_regen_per_seconds: float = 1.0

var max_energy_points: float = 100.0
var energy_points: float = 100.0
var energy_regen_per_seconds: float = 1.0

var energy_cost_to_roll: float = 20.0
var energy_cost_to_attack: float = 10.0

var mana_cost_to_cast_skill_0: float = 10.0
var mana_cost_to_cast_skill_1: float = 25.0
var mana_cost_to_cast_skill_2: float = 50.0

var min_damage: float = 5.0
var max_damage: float = 10.0

var critical_rate: float = 0.0
var critical_damage: float = 0.0

var poison_rate_chance: float = 0.0
var poison_duration: float = 0.0
var poison_dps: float = 0.0

var bleed_rate_chance: float = 0.0
var bleed_duration: float = 0.0
var bleed_dps: float = 0.0

var attack_speed: float = 1.0
var move_speed: float = 1.0

# os valores serão instanciados por um arquivo onde eu vou armazenar
func _ready() -> void:
	calculate_exp_to_next_level()

func update_health(value: float) -> void:
	health_points = value
func update_mana(value: float) -> void:
	mana_points = value
func update_energy(value: float) -> void:
	energy_points = value

func can_roll() -> bool:
	return energy_points >= energy_cost_to_roll

func can_attack() -> bool:
	return energy_points >= energy_cost_to_attack

func calculate_damage() -> DamageData:
	var data = DamageData.new()
	var damage = randf_range(min_damage, max_damage)
	
	data.damage = damage
	
	return data

func calculate_exp_to_next_level():
	if level == 1:
		exp_to_next_level = BASE_EXP
	else:
		exp_to_next_level = round((exp_to_next_level * EXP_SCALE_FACTOR) + (EXP_ADDITIVE * level))

func add_experience(amount: float) -> void:
	total_exp += amount
	current_exp += amount
	
	# Verifica level up
	while current_exp >= exp_to_next_level and exp_to_next_level > 0:
		current_exp -= exp_to_next_level
		on_level_up()
	
	# Atualiza UI ou dispara eventos conforme necessário

func on_level_up() -> int:
	level += 1
	
	var level_factor := 1.0 + (level - 1) * 0.1
	
	# Aumenta atributos
	var health_factor := 1.0 + (level - 1) * 0.3
	max_health_points += 20 * health_factor
	health_points = max_health_points
	PlayerEvents.recovery_health(health_points)
	
	var mana_factor := 1.0 + (level - 1) * 0.2
	max_mana_points += 10 * mana_factor
	mana_points = max_mana_points
	PlayerEvents.recovery_mana(mana_points)
	
	var energy_factor := 1.0 + (level - 1) * 0.05
	max_energy_points += 2 * energy_factor
	energy_points = max_energy_points
	PlayerEvents.recovery_energy(energy_points)
	
	var damage_factor = 1.0 + (level - 1) * 0.025
	# Aumenta stats de combate
	min_damage += 2 * damage_factor
	max_damage += 3 * damage_factor
	
	# Recalcula para o próximo nível
	calculate_exp_to_next_level()
	get_tree().call_group("player_stats_ui", "on_player_level_up", level)
	
	PlayerEvents.on_level_up(level)
	return level
