class_name EnemyStats
extends Node

signal health_changed(new_health: float)
signal trigged_dead(exp_amount: float)
#signal show_exp_on_dead(exp: float)

@export var entity_name := ""
@export var entity_level := 1
@export var current_difficulty: GameEvents.Difficulty = GameEvents.Difficulty.NORMAL


# Stats básicos
@export var base_health_points := 0.0
@export var base_health_points_regen := 0.0
@export var base_min_damage := 0.0
@export var base_max_damage := 0.0
@export var base_crit_damage := 150.0 # 150% de dano (1.5x)
@export var base_crit_rate := 5.0 # 5% chance de crítico

@export var base_experience := 10.0

# Stats de status effects
@export var base_bleed_chance := 0.0 # Chance de aplicar sangramento
@export var base_bleed_duration := 3.0 # Duração em segundos
@export var base_bleed_damage := 0.1 # Dano por segundo (percentual da vida máxima)

@export var base_poison_chance := 0.0 # Chance de aplicar veneno
@export var base_poison_duration := 4.0 # Duração em segundos
@export var base_poison_damage := 0.05 # Dano por segundo (percentual da vida máxima)

# Stats de velocidade
@export var base_attack_speed: float = 1.0
@export var base_move_speed: float = 1.0

var health_points: float = 0.0
var health_regen_per_seconds: float = 0.0
var min_attack_damage: float = 0.0
var max_attack_damage: float = 0.0
var attack_speed: float = 1.0
var move_speed: float = 1.0
var current_health_points: float = 0.0

func _ready() -> void:
	setup_stats()


func setup_stats() -> void:
	# Escolhe o fator baseado se é jogador ou não
	var difficulty_factor = {
		GameEvents.Difficulty.NORMAL: 1.0,
		GameEvents.Difficulty.PAINFUL: 1.2,
		GameEvents.Difficulty.FATAL: 1.5,
		GameEvents.Difficulty.INFERNAL: 2.0
	}[current_difficulty]
	
	# Fórmula de escalonamento combinada (nível + dificuldade)
	var level_factor := 1.0 + (entity_level - 1) * 0.1
	var health_factor := 1.0 + (entity_level - 1) * 0.50
	var damage_factor := 1.0 + (entity_level - 1) * 0.25
	var speed_factor := 1.0 + (entity_level - 1) * 0.001
	#var combined_factor = level_factor * difficulty_factor
	
	# Calcula stats de vida
	health_points = base_health_points * (health_factor * difficulty_factor)
	health_regen_per_seconds = base_health_points_regen * (level_factor * difficulty_factor)
	
	# Calcula stats de dano
	min_attack_damage = base_min_damage * (damage_factor * difficulty_factor)
	max_attack_damage = base_max_damage * (damage_factor * difficulty_factor)
	
	# Calcula stats de velocidade
	attack_speed = base_attack_speed * difficulty_factor
	move_speed = base_move_speed * difficulty_factor
	
	# Inicializa a vida atual
	current_health_points = health_points
	health_changed.emit(current_health_points)
	
	# Ajusta dano crítico
	base_crit_damage *= level_factor * difficulty_factor
	base_crit_rate *= level_factor * difficulty_factor
	
	# Ajusta status effects
	base_bleed_chance *= level_factor * difficulty_factor
	base_bleed_damage *= level_factor * difficulty_factor
	
	base_poison_chance *= level_factor * difficulty_factor
	base_poison_damage *= level_factor * difficulty_factor
	
	base_experience *= level_factor * difficulty_factor

func calculate_base_attack_damage() -> DamageData:
	var damage_data = DamageData.new()
	
	var damage = randi_range(min_attack_damage, max_attack_damage)
	
	if randf() * 100 <= base_crit_rate:
		damage *= base_crit_damage / 100.0
		damage_data.is_critical = true
	
	# Chance normal de aplicar efeitos
	if randf() * 100 <= base_bleed_chance:
		var bleed_damage = base_bleed_damage * damage
		var bleed_effect = BleedEffectData.new(bleed_damage, base_bleed_duration)
		damage_data.status_effects.append(bleed_effect)
	
	if randf() * 100 <= base_poison_chance:
		var poison_damage = base_poison_damage * damage
		var poison_effect = PoisonEffectData.new(poison_damage, base_poison_duration)
		damage_data.status_effects.append(poison_effect)
	
	damage_data.damage = damage
	return damage_data

func on_take_damage(damage: float):
	current_health_points = max(current_health_points - damage, 0)
	health_changed.emit(current_health_points)
	if current_health_points <= 0:
		trigged_dead.emit()
		PlayerEvents.show_exp.emit(base_experience)
		#show_exp_on_dead.emit(base_experience)
