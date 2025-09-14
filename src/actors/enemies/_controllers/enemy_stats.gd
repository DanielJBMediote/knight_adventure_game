class_name EnemyStats
extends Node

signal health_changed(health: float)
signal died(exp_amount: float)

enum ENEMY_TYPE {MOB, MINIBOSS, BOSS}
enum RACE {BATS, SKELETONS, ORCS}

const MAX_CRITICAL_RATE := 100.0 # 100% máximo
const MAX_CRITICAL_DAMAGE := 300.0 # 300% máximo
const MAX_STATUS_CHANCE := 100.0 # 100% máximo
const SPEED := 100.0

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
@export var base_min_damage := 1.0
## Base of maximum dmage
@export var base_max_damage := 1.0

## Base of Critical Damage: Determine the multiply of damage.
## Default is 1.0 (100%) of damage, it will increment per level and difficult. Percentage Values: 0.0 - 1.0.
@export var base_crit_damage := 1.0
## Base of Critical Damage:Determine the change to hit Critical.
## Default is (0.05) 5% of rate, it will increment per level and difficult. Percentage Values: 0.0 - 1.0.
@export var base_crit_rate := 0.05

## Base of Mob Experience
## Default is 10.0, it will increment per level and difficult.
@export var base_experience := 10.0
## Base of number of loots can be spawnable
@export var base_num_drops: int = 10
## Base Defense
@export var base_defense := 1.0

# Stats de status effects
## Chance to apply Bleed Status. Percentage Values: 0.0 - 1.0.
@export var base_bleed_chance := 0.0
## Duration of Bleed Status in seconds.
@export var base_bleed_duration := 0.0
## Base Bleed Damage = Damage * Bleed Damage. Values: 0.0 - 1.0
@export var base_bleed_damage := 0.0

## Chance to apply Poison Status. Percentage Values: 0.0 - 1.0.
@export var base_poison_chance := 0.0 # Chance de aplicar veneno
## Duration of Poison Status in seconds.
@export var base_poison_duration := 0.0
## Base Poison Damage = Damage * Poison Damage. Values: 0.0 - 1.0
@export var base_poison_damage := 0.0

# Stats de velocidade
## Base value of attack speed, min of 100%, max of 200%. Percentage Values: 0.0 - 2.0.
@export var base_attack_speed: float = 1.0
## Base value of speed, min of 100%, max of 200%. Percentage Values: 0.0 - 2.0.
@export var base_move_speed: float = 1.0

var health_points: float = 0.0
var health_regen_per_seconds: float = 0.0

var min_attack_damage: float = 0.0
var max_attack_damage: float = 0.0

var experience: float = 0.0

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
var num_drops := 0
var amount_coins := 0

func _init() -> void:
	pass

#region Setup Stats
func _ready() -> void:
	var difficultty = GameEvents.current_map.get_difficulty()
	var min_map_level = GameEvents.current_map.get_min_mob_level()
	var max_map_level = GameEvents.current_map.get_max_mob_level()

	var status_modificator = GameEvents.get_stats_modificator_by_difficult(difficultty)
	var additional_level = GameEvents.get_additional_levels_modificator_by_difficult(difficultty)

	level = randi_range(min_map_level, max_map_level) + additional_level

	var base_factor: float = generate_base_factor()

	# Fatores de escalonamento
	var level_factor := base_factor + (level - 1) * 0.10 # +10% de atributos por level
	var health_factor := base_factor + (level - 1) * 1.0 # +100% de atributos por level
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
	self.move_speed = SPEED * clamp(base_move_speed * status_modificator * level_factor * 0.02, base_move_speed, base_move_speed * 2.0)

	# Fórmulas balanceadas para CRITICAL RATE e CRITICAL DAMAGE
	calculate_critical_stats(level_factor, status_modificator)

	# Fórmulas balanceadas para STATUS EFFECTS
	calculate_status_effects_stats(level_factor, status_modificator)

	# Inicializa a vida atual
	self.current_health_points = health_points
	self.health_changed.emit(current_health_points)

	# Experiência
	self.experience = max(1, base_experience * exp_factor * status_modificator)

	# Número Drops
	self.num_drops = calculate_amount_drops()
	self.amount_coins = calculate_num_of_coins()

#endregion


func generate_base_factor() -> float:
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
	var crit_rate_growth = 0.25 # Taxa de crescimento (ajuste conforme necessário)
	var max_crit_level = 90 # Nível onde atinge o máximo

	if level >= max_crit_level:
		self.crit_rate = MAX_CRITICAL_RATE
	else:
		# Fórmula logarítmica para crescimento suave
		var crit_rate_factor = 1.0 + log(level + 1) * crit_rate_growth
		self.crit_rate = min(base_crit_rate * crit_rate_factor * difficulty_factor, MAX_CRITICAL_RATE)

	# Critical Damage - escala gradualmente até 300%
	var crit_damage_growth = 0.15 # % adicional por nível (ajuste conforme necessário)
	var max_crit_damage_level = 90 # Nível onde atinge 300%

	if level >= max_crit_damage_level:
		self.crit_damage = MAX_CRITICAL_DAMAGE
	else:
		# Crescimento linear controlado
		var crit_damage_bonus = (level - 1) * crit_damage_growth
		self.crit_damage = min(base_crit_damage + crit_damage_bonus, MAX_CRITICAL_DAMAGE)
		self.crit_damage *= difficulty_factor


func calculate_status_effects_stats(_level_factor: float, difficulty_factor: float) -> void:
	# Bleed Chance - escala até máximo de 100%
	var bleed_chance_growth = 1.5 # Multiplicador de crescimento

	if base_bleed_chance > 0: # Só escala se tiver chance base
		var bleed_chance_factor = 1.0 + (level - 1) * 0.08
		self.bleed_chance = min(
			base_bleed_chance * bleed_chance_factor * bleed_chance_growth * difficulty_factor, MAX_STATUS_CHANCE
		)

	# Bleed Damage - escala percentual do dano
	var bleed_damage_growth = 0.15 # 15% mais dano por nível
	if base_bleed_damage > 0:
		self.bleed_damage = base_bleed_damage * (1.0 + ((level - 1) * bleed_damage_growth) * difficulty_factor)
		self.bleed_damage = min(bleed_damage, 0.5) # Máximo de 50% do dano como bleed

	# Bleed Duration - escala leve
	self.bleed_duration = base_bleed_duration * (1.0 + ((level - 1) * 0.05) * difficulty_factor)

	# Poison Chance - escala até máximo de 100%
	var poison_chance_growth = 1.4 # Multiplicador de crescimento

	if base_poison_chance > 0: # Só escala se tiver chance base
		var poison_chance_factor = 1.0 + (level - 1) * 0.07
		self.poison_chance = min(
			base_poison_chance * poison_chance_factor * poison_chance_growth * difficulty_factor, MAX_STATUS_CHANCE
		)

	# Poison Damage - escala percentual do dano
	var poison_damage_growth = 0.12 # 12% mais dano por nível
	if base_poison_damage > 0:
		self.poison_damage = base_poison_damage * (1.0 + ((level - 1) * poison_damage_growth) * difficulty_factor)
		self.poison_damage = min(poison_damage, 0.3) # Máximo de 30% do dano como poison

	# Poison Duration - escala leve
	self.poison_duration = base_poison_duration * (1.0 + ((level - 1) * 0.06) * difficulty_factor)


func calculate_base_attack_damage() -> DamageData:
	var damage_data = DamageData.new()

	var damage = randf_range(min_attack_damage, max_attack_damage)

	# Critical hit
	if randf() * 1.0 <= base_crit_rate:
		damage *= min(1.0, base_crit_damage)
		damage_data.is_critical = true

	# Status effects com chances balanceadas
	if base_bleed_chance > 0 && randf() * 1.0 <= base_bleed_chance:
		var bleed_damage_per_second = damage * bleed_damage
		var bleed_effect = BleedEffectData.new(bleed_damage_per_second, bleed_duration)
		damage_data.status_effects.append(bleed_effect)

	if base_poison_chance > 0 && randf() * 1.0 <= base_poison_chance:
		var poison_damage_per_second = damage * poison_damage
		var poison_effect = PoisonEffectData.new(poison_damage_per_second, poison_duration)
		damage_data.status_effects.append(poison_effect)

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
