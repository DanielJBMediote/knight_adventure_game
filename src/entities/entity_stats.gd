class_name EntityStats
extends Node

signal health_changed(new_health: float)
signal trigged_dead(exp_amount: float)
signal critical_hit(damage: float)  # Novo sinal para críticos
signal bleed_applied(duration: float)  # Novo sinal para sangramento
signal poison_applied(duration: float)  # Novo sinal para veneno

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

# Variáveis de status
var is_bleeding := false
var is_poisoned := false
var bleed_timer: Timer
var poison_timer: Timer
var bleed_damage: float = 0.0
var poison_damage: float = 0.0

func _ready() -> void:
	setup_stats()
	setup_status_timers()

func setup_status_timers():
	bleed_timer = Timer.new()
	bleed_timer.one_shot = true
	bleed_timer.timeout.connect(_on_bleed_finished)
	add_child(bleed_timer)
	
	poison_timer = Timer.new()
	poison_timer.one_shot = true
	poison_timer.timeout.connect(_on_poison_finished)
	add_child(poison_timer)

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

func calculate_damage() -> DamageData:
	var data = DamageData.new()
	
	var damage = randi_range(min_attack_damage, max_attack_damage)
	
	if randf() * 100 <= base_crit_rate:
		damage *= base_crit_damage / 100.0
		data.is_critical = true
	
	# Chance normal de aplicar efeitos
	if randf() * 100 <= base_bleed_chance:
		data.bleeding_dps = base_bleed_damage * damage
		data.bleeding_duration = base_bleed_duration
		if data.bleeding_dps >= 1:
			data.is_bleeding = true
	
	if randf() * 100 <= base_poison_chance:
		data.poisoning_dps = base_poison_damage * damage
		data.poisoning_duration = base_poison_duration
		if data.poisoning_dps >= 1:
			data.is_poisoning = true
	
	data.damage = damage
	return data

func apply_status_effects():
	# Aplica ambos os efeitos em um crítico
	if randf() * 100 <= base_bleed_chance * 2:  # Chance dobrada em crítico
		apply_bleed()
	
	if randf() * 100 <= base_poison_chance * 2:  # Chance dobrada em crítico
		apply_poison()

func apply_bleed():
	if is_bleeding:
		bleed_timer.stop()  # Reseta o timer se já estiver sangrando
	
	is_bleeding = true
	bleed_damage = health_points * base_bleed_damage
	bleed_timer.start(base_bleed_duration)
	bleed_applied.emit(base_bleed_duration)
	
	# Inicia o dano periódico
	var bleed_interval = Timer.new()
	bleed_interval.wait_time = 1.0
	bleed_interval.timeout.connect(_apply_bleed_damage)
	add_child(bleed_interval)
	bleed_interval.start()

func _apply_bleed_damage():
	if is_bleeding:
		on_take_damage(bleed_damage)

func _on_bleed_finished():
	is_bleeding = false

func apply_poison():
	if is_poisoned:
		poison_timer.stop()  # Reseta o timer se já estiver envenenado
	
	is_poisoned = true
	poison_damage = health_points * base_poison_damage
	poison_timer.start(base_poison_duration)
	poison_applied.emit(base_poison_duration)
	
	# Inicia o dano periódico
	var poison_interval = Timer.new()
	poison_interval.wait_time = 1.0
	poison_interval.timeout.connect(_apply_poison_damage)
	add_child(poison_interval)
	poison_interval.start()

func _apply_poison_damage():
	if is_poisoned:
		on_take_damage(poison_damage)

func _on_poison_finished():
	is_poisoned = false

func on_take_damage(damage: float):
	current_health_points = max(current_health_points - damage, 0)
	health_changed.emit(current_health_points)
	if current_health_points <= 0:
		trigged_dead.emit(base_experience)
