class_name EnemyStats
extends Node

signal health_changed(new_health: float)
signal trigged_dead(exp_amount: float)
#signal show_exp_on_dead(exp: float)

const MAX_CRITICAL_RATE := 100.0  # 100% máximo
const MAX_CRITICAL_DAMAGE := 300.0  # 300% máximo
const MAX_STATUS_CHANCE := 100.0  # 100% máximo

@export var entity_name := ""
@export var entity_level := 1

# Stats básicos
## Base of Health Points
@export var base_health_points := 0.0
## Base of Health Regen per seconds
@export var base_health_points_regen := 0.0
## Base of minimum dmage
@export var base_min_damage := 0.0
## Base of maximum dmage
@export var base_max_damage := 0.0
## Base of Critical Damage, default is 100% of damage, it will increment per level and difficult.
@export var base_crit_damage := 100.0
## Base of Critical Damage, default is 5% of rate, it will increment per level and difficult.
@export var base_crit_rate := 5.0 
## Base of Mob Experience, default is 10.0, it will increment per level and difficult.
@export var base_experience := 10.0

# Stats de status effects
@export var base_bleed_chance := 0.0 # Chance de aplicar sangramento
@export var base_bleed_duration := 0.0 # Duração em segundos
@export var base_bleed_damage := 0.0 # Dano por segundo (percentual da vida máxima)

@export var base_poison_chance := 0.0 # Chance de aplicar veneno
@export var base_poison_duration := 0.0 # Duração em segundos
@export var base_poison_damage := 0.0 # Dano por segundo (percentual da vida máxima)

# Stats de velocidade
@export var base_attack_speed: float = 1.0
@export var base_move_speed: float = 1.0

var current_difficulty: GameEvents.Difficulty = GameEvents.Difficulty.NORMAL

var health_points: float = 0.0
var health_regen_per_seconds: float = 0.0

var min_attack_damage: float = 0.0
var max_attack_damage: float = 0.0

var crit_damage := 0.0
var crit_rate := 0.0

var attack_speed: float = 1.0
var move_speed: float = 1.0

var poison_chance: float = 0.0
var poison_duration: float = 0.0
var poison_damage: float = 0.0

var bleed_chance: float = 0.0
var bleed_damage: float = 0.0
var bleed_duration: float = 0.0

var current_health_points: float = 0.0

func _ready() -> void:
	current_difficulty = GameEvents.current_map.difficulty
	setup_stats()

func setup_stats() -> void:
	var map_enemy_level = GameEvents.get_map_enemy_levels()
	var min_map_level = map_enemy_level["mobs"][0]
	var max_map_level = map_enemy_level["mobs"][1]
	
	var difficulty_factor = {
		GameEvents.Difficulty.NORMAL: 1.0,
		GameEvents.Difficulty.PAINFUL: 1.2,
		GameEvents.Difficulty.FATAL: 1.5,
		GameEvents.Difficulty.INFERNAL: 2.0
	}[current_difficulty]
	
	var level_increment = {
		GameEvents.Difficulty.NORMAL: 0.0,
		GameEvents.Difficulty.PAINFUL: 5.0,
		GameEvents.Difficulty.FATAL: 15.0,
		GameEvents.Difficulty.INFERNAL: 25.0
	}[current_difficulty]
		
	entity_level = randi_range(min_map_level, max_map_level) + level_increment
	
	# Fatores de escalonamento
	var level_factor := 1.0 + (entity_level - 1) * 0.1
	var health_factor := 1.0 + (entity_level - 1) * 0.75
	var damage_factor := 1.0 + (entity_level - 1) * 0.50
	
	# Calcula stats de vida
	health_points = base_health_points * (health_factor * difficulty_factor)
	health_regen_per_seconds = base_health_points_regen * (level_factor * difficulty_factor)
	
	# Calcula stats de dano
	min_attack_damage = base_min_damage * (damage_factor * difficulty_factor)
	max_attack_damage = base_max_damage * (damage_factor * difficulty_factor)
	
	# Calcula stats de velocidade
	attack_speed = base_attack_speed * difficulty_factor
	move_speed = base_move_speed * difficulty_factor
	
	# Fórmulas balanceadas para CRITICAL RATE e CRITICAL DAMAGE
	calculate_critical_stats(level_factor, difficulty_factor)
	
	# Fórmulas balanceadas para STATUS EFFECTS
	calculate_status_effects_stats(level_factor, difficulty_factor)
	
	# Inicializa a vida atual
	current_health_points = health_points
	health_changed.emit(current_health_points)
	
	# Experiência
	var exp_factor = 1.0 + (entity_level - 1) * 0.65
	base_experience *= exp_factor * difficulty_factor

func calculate_critical_stats(level_factor: float, difficulty_factor: float) -> void:
	# Critical Rate - escala suavemente até o máximo
	var crit_rate_growth = 0.25  # Taxa de crescimento (ajuste conforme necessário)
	var max_crit_level = 90     # Nível onde atinge o máximo
	
	if entity_level >= max_crit_level:
		crit_rate = MAX_CRITICAL_RATE
	else:
		# Fórmula logarítmica para crescimento suave
		var crit_rate_factor = 1.0 + log(entity_level + 1) * crit_rate_growth
		crit_rate = min(base_crit_rate * crit_rate_factor * difficulty_factor, MAX_CRITICAL_RATE)
	
	# Critical Damage - escala gradualmente até 300%
	var crit_damage_growth = 0.5  # % adicional por nível (ajuste conforme necessário)
	var max_crit_damage_level = 90  # Nível onde atinge 300%
	
	if entity_level >= max_crit_damage_level:
		crit_damage = MAX_CRITICAL_DAMAGE
	else:
		# Crescimento linear controlado
		var crit_damage_bonus = (entity_level - 1) * crit_damage_growth
		crit_damage = min(base_crit_damage + crit_damage_bonus, MAX_CRITICAL_DAMAGE)
		crit_damage *= difficulty_factor

func calculate_status_effects_stats(level_factor: float, difficulty_factor: float) -> void:
	# Bleed Chance - escala até máximo de 100%
	var bleed_chance_growth = 1.5  # Multiplicador de crescimento
	
	if base_bleed_chance > 0:  # Só escala se tiver chance base
		var bleed_chance_factor = 1.0 + (entity_level - 1) * 0.08
		bleed_chance = min(base_bleed_chance * bleed_chance_factor * bleed_chance_growth * difficulty_factor, MAX_STATUS_CHANCE)
	
	# Bleed Damage - escala percentual do dano
	var bleed_damage_growth = 0.15  # 15% mais dano por nível
	if base_bleed_damage > 0:
		bleed_damage = base_bleed_damage * (1.0 + ((entity_level - 1) * bleed_damage_growth) * difficulty_factor)
		bleed_damage = min(bleed_damage, 0.5)  # Máximo de 50% do dano como bleed
	
	# Bleed Duration - escala leve
	bleed_duration = base_bleed_duration * (1.0 + ((entity_level - 1) * 0.05) * difficulty_factor)
	
	# Poison Chance - escala até máximo de 100%
	var poison_chance_growth = 1.4  # Multiplicador de crescimento
	
	if base_poison_chance > 0:  # Só escala se tiver chance base
		var poison_chance_factor = 1.0 + (entity_level - 1) * 0.07
		poison_chance = min(base_poison_chance * poison_chance_factor * poison_chance_growth * difficulty_factor, MAX_STATUS_CHANCE)
	
	# Poison Damage - escala percentual do dano
	var poison_damage_growth = 0.12  # 12% mais dano por nível
	if base_poison_damage > 0:
		poison_damage = base_poison_damage * (1.0 + ((entity_level - 1) * poison_damage_growth) * difficulty_factor)
		poison_damage = min(poison_damage, 0.3)  # Máximo de 30% do dano como poison
	
	# Poison Duration - escala leve
	poison_duration = base_poison_duration * (1.0 + ((entity_level - 1) * 0.06) * difficulty_factor)

func calculate_base_attack_damage() -> DamageData:
	var player_defense = PlayerStats.get("defense")
	var damage_data = DamageData.new()
	
	var damage = randf_range(min_attack_damage, max_attack_damage)
	
	# Critical hit
	if randf() * 100 <= base_crit_rate:
		damage *= (base_crit_damage / 100.0)  # Converte porcentagem para multiplicador
		damage_data.is_critical = true
	
	# Status effects com chances balanceadas
	if base_bleed_chance > 0 && randf() * 100 <= base_bleed_chance:
		var bleed_damage_per_second = damage * bleed_damage
		var bleed_effect = BleedEffectData.new(bleed_damage_per_second, bleed_duration)
		damage_data.status_effects.append(bleed_effect)
	
	if base_poison_chance > 0 && randf() * 100 <= base_poison_chance:
		var poison_damage_per_second = damage * poison_damage
		var poison_effect = PoisonEffectData.new(poison_damage_per_second, poison_duration)
		damage_data.status_effects.append(poison_effect)
	
	damage_data.damage = damage
	return damage_data

func on_take_damage(damage: float):
	current_health_points = max(current_health_points - damage, 0)
	health_changed.emit(current_health_points)
	if current_health_points <= 0:
		trigged_dead.emit()
		PlayerEvents.handle_event_add_experience(base_experience)
