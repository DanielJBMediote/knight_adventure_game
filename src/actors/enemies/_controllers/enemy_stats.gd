class_name EnemyStats
extends Node

signal health_changed(health: float)
signal died(exp_amount: float)

enum ENEMY_TYPE {MOB, MINIBOSS, BOSS}
enum RACE {BATS, SKELETONS, ORCS}

const MAX_CRITICAL_RATE := 1.0 # 100% máximo
const MAX_CRITICAL_DAMAGE := 3.0 # 300% máximo
const BASE_SPEED := 100.0

## Define the name of Entity
@export var enemy_name := ""
## Define the Level of Entity (Based on game difficult and map levels)
@export var level: int = 0
## Enemy type: Mobs Miniboss or Boss
@export var enemy_type: ENEMY_TYPE = ENEMY_TYPE.MOB

# Stats básicos
## Base of Health Points
@export var base_health_points := 100.0
## Base of Health Regen per seconds
@export var base_health_points_regen := 1.0
## Base of minimum dmage
@export var base_min_damage := 100.0
## Base of maximum dmage
@export var base_max_damage := 100.0

## Base of Critical Damage: Determine the multiply of damage.
## Default is 1.0 (100%) of damage, it will increment per level and difficult. Percentage Values: 0.0 - 1.0.
@export_range(0.0, 3.0) var base_crit_damage := 1.0
## Base of Critical Damage:Determine the change to hit Critical.
## Default is (0.05) 5% of rate, it will increment per level and difficult. Percentage Values: 0.0 - 1.0.
@export_range(0.0, 1.0) var base_crit_rate := 0.05

## Base of Mob Experience
## Default is 10.0, it will increment per level and difficult.
@export var base_experience := 100.0
## Base of number of loots can be spawnable
@export var base_num_drops: int = 10
## Base Defense
@export var base_defense := 1.0

# Stats de velocidade
## Base value of attack speed, min of 100%, max of 200%. Percentage Values: 0.0 - 2.0.
@export_range(1.0, 2.0) var base_attack_speed: float = 1.0
## Base value of speed, max of 200%. Percentage Values: 0.0 - 2.0.
@export_range(0.5, 2.0) var base_move_speed: float = 1.0

@export var status_effects: Array[StatusEffect] = []

var health_points: float = 0.0
var health_regen_per_seconds: float = 0.0

var min_attack_damage: float = 0.0
var max_attack_damage: float = 0.0

var experience: float = 0.0

var crit_damage := 0.0
var crit_rate := 0.0

var attack_speed: float = 1.0
var move_speed: float = 1.0

var current_health_points: float = 0.0
var num_drops := 0
var amount_coins := 0

func _init() -> void:
	pass

func _ready() -> void:
	# var difficultty = GameEvents.current_map.get_difficulty()
	var min_map_level = GameEvents.current_map.get_min_mob_level()
	var max_map_level = GameEvents.current_map.get_max_mob_level()

	var status_modificator = GameEvents.get_stats_modificator_by_difficult()
	var additional_level = GameEvents.get_additional_levels_modificator_by_difficult()

	level = randi_range(min_map_level, max_map_level) + additional_level

	var base_factor: float = _enemy_type_factor()

	# Fatores de escalonamento
	var level_factor := base_factor + (level - 1) * 0.10 # +10% de atributos por level
	var health_factor := base_factor + (level - 1) * 0.95 # +100% de atributos por level
	var damage_factor := base_factor + (level - 1) * 0.50 # +50% de atributos por level
	var exp_factor := base_factor + (level - 1) * 0.65 # +65% de atributos por level

	# Calcula stats de vida
	self.health_points = base_health_points * (health_factor * status_modificator)
	self.health_regen_per_seconds = base_health_points_regen * (level_factor * status_modificator)

	# Calcula stats de dano
	self.min_attack_damage = max(base_min_damage * (damage_factor * status_modificator), 1)
	self.max_attack_damage = max(base_max_damage * (damage_factor * status_modificator), 1)

	# Calcula stats de velocidade
	self.attack_speed = clamp(base_attack_speed * status_modificator * level_factor * 0.02, 1.0, 2.0)
	self.move_speed = BASE_SPEED * clamp(base_move_speed * status_modificator * level_factor * 0.02, base_move_speed, base_move_speed * 2.0)

	# Fórmulas balanceadas para CRITICAL RATE e CRITICAL DAMAGE
	calculate_critical_stats(level_factor, status_modificator)

	# Fórmulas balanceadas para STATUS EFFECTS
	update_status_effect_values(status_modificator)

	# Inicializa a vida atual
	self.current_health_points = health_points
	self.health_changed.emit(current_health_points)

	# Experiência
	self.experience = max(1, base_experience * exp_factor * status_modificator)

	# Número Drops
	self.num_drops = calculate_amount_drops()
	self.amount_coins = calculate_num_of_coins()


func _enemy_type_factor() -> float:
	match enemy_type:
		ENEMY_TYPE.BOSS:
			return 5.0
		ENEMY_TYPE.MINIBOSS:
			return 3.0
		_:
			return 1.0


func calculate_amount_drops() -> int:
	var difficulty_multiply: float = GameEvents.get_drop_modificator_by_difficult()
	var level_factor = clampi(ceili(float(level * 0.1)), 1, 10)
	var amount_drops = base_num_drops + maxi(difficulty_multiply * level_factor, 1)
	return amount_drops


func calculate_num_of_coins() -> int:
	var base_amount = 1
	var difficulty_factor = 1.0 + GameEvents.get_drop_modificator_by_difficult()
	var level_factor = ceili(1 + (self.level * 0.25))
	var type_factor = 1 + (enemy_type * 1.0)
	var _amount_coins = base_amount + ceili(level_factor * type_factor * difficulty_factor)
	return _amount_coins

func calculate_critical_stats(_level_factor: float, difficulty_factor: float) -> void:
	# Critical Rate - escala suavemente até o máximo
	var crit_rate_growth = 0.75 # Taxa de crescimento (ajuste conforme necessário)
	var max_crit_level = 100 # Nível onde atinge 75%
	var crit_rate_factor = 1.0 + log(level + 1) * crit_rate_growth
	crit_rate = min(base_crit_rate * crit_rate_factor * difficulty_factor, MAX_CRITICAL_RATE)
	if level >= max_crit_level and crit_rate >= MAX_CRITICAL_RATE:
		crit_rate = MAX_CRITICAL_RATE
	
	# Critical Damage - escala gradualmente até 300%
	var crit_damage_growth = 0.00445 # % adicional por nível (ajuste conforme necessário)
	var max_crit_damage_level = 100 # Nível onde atinge 300%
	var crit_damage_bonus = (level - 1) * crit_damage_growth
	crit_damage = min(base_crit_damage + (crit_damage_bonus * difficulty_factor), MAX_CRITICAL_DAMAGE)
	if level >= max_crit_damage_level and crit_damage >= MAX_CRITICAL_DAMAGE:
		crit_damage = MAX_CRITICAL_DAMAGE

func update_status_effect_values(difficulty_factor: float) -> void:
	for status in status_effects:
		if status.category == StatusEffect.CATEGORY.DEBUFF:
			if status.base_value:
				var damage = randf_range(min_attack_damage, max_attack_damage)
				status.value = damage * (status.base_value * (1.0 + ((level - 1) * 0.001) * difficulty_factor))
			if status.base_duration:
				status.duration = status.base_duration * (1.0 + ((level - 1) * 0.05) * difficulty_factor)
			if status.base_rate_chance > 0.0:
				status.rate_chance = min(status.base_rate_chance * (1.0 + (level - 1) * 0.005) * difficulty_factor, 1.0)


func calculate_base_attack_damage() -> DamageData:
	var damage_data = DamageData.new()

	var damage = randf_range(min_attack_damage, max_attack_damage)

	# Critical hit
	if randf() * 1.0 <= crit_rate:
		damage *= min(1.0, crit_damage)
		damage_data.is_critical = true

	for status in status_effects:
		if status.category == StatusEffect.CATEGORY.DEBUFF:
			if randf() * 1.0 <= status.rate_chance:
				status.is_active = true
				damage_data.status_effects.append(status)
			
	damage_data.damage = damage
	return damage_data


func calculate_damage_taken(damage: float) -> float:
	return damage


func on_take_damage(damage: float):
	damage = calculate_damage_taken(damage)
	self.current_health_points = max(current_health_points - damage, 0)
	self.health_changed.emit(self.current_health_points)
	if current_health_points <= 0:
		died.emit(self.experience)
