# autoload/player_stats.gd
extends Node

signal health_changed(health: float)
signal max_health_changed(max_health: float, health: float)

signal mana_changed(mana: float)
signal max_mana_changed(max_mana: float, mana: float)

signal energy_changed(energy: float)
signal max_energy_changed(max_energy: float, energy: float)

signal attack_speed_updated(value: float)
signal move_speed_updated(value: float)

signal experiance_added(amount: float)
signal experience_update(exp: float)
signal level_updated(level: float)

signal passive_status_effect_changed(status_effect: StatusEffect)

signal attributes_changed(attributes)
signal player_dead

class DamageStats:
	var min_damage: float
	var max_damage: float

	func _init(_min: float, _max: float):
		min_damage = _min
		max_damage = _max

static var player_ref: Player

const MAX_LEVEL = 100
const BASE_EXP = 1000
const EXP_SCALE_FACTOR = 1.15
const EXP_ADDITIVE = 50
const MAX_DEFENCE_REDUCTION = 0.8

const MAX_CRITICAL_RATE = 0.8 # 80% Crit. Rate
const MAX_CRITICAL_DAMAGE = 4.0 # 400% Damage

const BASE_CRITICAL_POINTS_FOR_MAX = 800.0 # 800pts para 80% no nível 1
const MAX_CRITICAL_POINTS_FOR_MAX = 8000.0 # 8000pts para 80% no nível 100
const CRITICAL_GROWTH_FACTOR_PER_LEVEL = (MAX_CRITICAL_POINTS_FOR_MAX - BASE_CRITICAL_POINTS_FOR_MAX) / 99.0

const GROWTH_DEFENSE_FACTOR_PER_LEVEL = 0.045 # 4.5%
const REDUCT_DEFENSE_FACTOR_PER_LEVEL = 0.03 # 3%

const MAX_TARGET_HEALTH = 85000.0
const MAX_TARGET_MANA = 450.0
const MAX_TARGET_ENERGY = 150

# Base values References
var BASE_HEALTH: float = 1200.0
var BASE_MANA: float = 50.0
var BASE_ENERGY: float = 100.0
var BASE_MIN_DAMAGE: float = 150.0
var BASE_MAX_DAMAGE: float = 250.0

## 1 = normal, <1 = menos knockback, >1 = mais knockback
var knockback_resistance: float = 1.0
var knockback_force: float = 300.0
var knockback_chance: float = 1.0 # de 0% até 60%


var level: int = 1:
	get: return level
	set(value): level = clampi(value, 1, 100)
var exp_total := 0.0
var exp_current := 0.0
var exp_to_next_level := 0.0
var exp_boost := 1.0: # 100% Experincia
	get: return exp_boost
	set(value): exp_boost = maxf(1.0, value)
# Health
var max_health_points: float = BASE_HEALTH:
	get: return max_health_points
	set(value): max_health_points = maxf(0.0, value)
var health_points: float = BASE_HEALTH:
	get(): return health_points
	set(value): health_points = clampf(value, 0.0, max_health_points)
var health_regen: float = 1.0:
	get: return health_regen
	set(value): health_regen = clampf(value, 1.0, max_health_points)
# Mana
var max_mana_points: float = BASE_MANA:
	get: return max_mana_points
	set(value): max_mana_points = maxf(0.0, value)
var mana_points: float = BASE_MANA:
	get(): return mana_points
	set(value): mana_points = clampf(value, 0.0, max_mana_points)
var mana_regen: float = 1.0:
	get: return mana_regen
	set(value): mana_regen = clampf(value, 1.0, max_mana_points)
# Energy
var max_energy_points: float = 100.0:
	get: return max_energy_points
	set(value): max_energy_points = maxf(100.0, value)
var energy_points: float = 100.0:
	get(): return energy_points
	set(value): energy_points = clampf(value, 0.0, max_energy_points)
var energy_regen: float = 1.0:
	get(): return energy_regen
	set(value): energy_regen = clampf(value, 1.0, max_energy_points)

var energy_cost_to_roll: float = 20.0
var energy_cost_to_attack: float = 5.0

var mana_cost_to_cast_skill_0: float = 0.0
var mana_cost_to_cast_skill_1: float = 0.0
var mana_cost_to_cast_skill_2: float = 0.0

var min_damage: float = 0.0:
	get: return min_damage + aditional_attribute.get(StatusEffect.EFFECT.DAMAGE_BOOST, 0.0)
	set(value): min_damage = maxf(0.0, value)
var max_damage: float = 0.0:
	get: return max_damage + aditional_attribute.get(StatusEffect.EFFECT.DAMAGE_BOOST, 0.0)
	set(value): max_damage = maxf(0.0, value)
## Critical Points or Critical Rate is used to determine the chance to Critical Hit
var critical_points: float = 0.0:
	get: return critical_points + aditional_attribute.get(StatusEffect.EFFECT.CRITICAL_RATE_BOOST, 0.0)
	set(value): critical_points = maxf(0.0, value)
## Critical Damage is used to determine the times os damage
var critical_damage: float = 1.0:
	get: return critical_damage + aditional_attribute.get(StatusEffect.EFFECT.CRITICAL_DAMAGE_BOOST, 0.0)
	set(value): critical_damage = clampf(value, 1.0, MAX_CRITICAL_DAMAGE)
var defense_points: float = 0.0:
	get: return defense_points + aditional_attribute.get(StatusEffect.EFFECT.DEFENSE_BOOST, 0.0)
	set(value): defense_points = maxf(0.0, value)
var attack_speed: float = 1.0:
	get: return attack_speed
	set(value): attack_speed = clampf(value, 1.0, 2.0)
var move_speed: float = 1.0:
	get: return move_speed
	set(value): move_speed = clampf(value, 1.0, 2.0)

var hit_rate_status_effects: Dictionary[StatusEffect.EFFECT, StatusEffect] = {}
var active_status_effect: Dictionary[StatusEffect.EFFECT, StatusEffect] = {}
var aditional_attribute: Dictionary[StatusEffect.EFFECT, float] = {}

# os valores serão instanciados por um arquivo onde eu vou armazenar
func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

	# Inicializa com valores base
	initialize_base_stats()
	calculate_exp_to_next_level()


func initialize_base_stats() -> void:
	# Aplica valores base
	max_health_points = randf_range(BASE_HEALTH * 0.75, BASE_HEALTH * 1.25)
	health_points = max_health_points
	max_mana_points = randf_range(BASE_MANA * 0.75, BASE_MANA * 1.25)
	mana_points = max_mana_points
	max_energy_points = 100.0
	energy_points = max_energy_points
	min_damage = randf_range(BASE_MIN_DAMAGE * 0.75, BASE_MIN_DAMAGE * 1.25)
	max_damage = randf_range(BASE_MAX_DAMAGE * 0.75, BASE_MAX_DAMAGE * 1.25)

	# max_health_points = calculate_health_at_level(level)
	# health_points = max_health_points
	# max_mana_points = calculate_mana_at_level(level)
	# mana_points = max_mana_points
	# max_energy_points = calculate_energy_at_level(level)
	# energy_points = max_energy_points
	# min_damage = calculate_damage_at_level(level).min_damage
	# max_damage = calculate_damage_at_level(level).max_damage


func update_max_health(value: float) -> void:
	var new_max_health_points = max_health_points + value
	max_health_points = new_max_health_points
	max_health_changed.emit(max_health_points, health_points)

func update_health(value: float) -> void:
	var new_health_points = health_points + value
	health_points = new_health_points
	if health_points <= 0:
		player_dead.emit()
	health_changed.emit(health_points)

func update_health_regen(value: float) -> void:
	var new_health_regen = health_regen + value
	health_regen = new_health_regen


func update_max_mana(value: float) -> void:
	var new_max_mana_points = max_mana_points + value
	max_mana_points = new_max_mana_points
	max_mana_changed.emit(max_mana_points, mana_points)

func update_mana(value: float) -> void:
	var new_mana_points = mana_points + value
	mana_points = new_mana_points
	mana_changed.emit(mana_points)

func update_mana_regen(value: float) -> void:
	var new_mana_regen = mana_regen + value
	mana_regen = new_mana_regen


func update_max_energy(value: float) -> void:
	var new_max_energy_points = max_energy_points + value
	max_energy_points = new_max_energy_points
	max_energy_changed.emit(max_energy_points, energy_points)

func update_energy(value: float) -> void:
	var new_energy_points = energy_points + value
	energy_points = new_energy_points
	energy_changed.emit(energy_points)

func update_energy_regen(value: float) -> void:
	var new_energy_regen = energy_regen + value
	energy_regen = new_energy_regen


func update_defense_points(value: float) -> void:
	var new_defense_points = defense_points + value
	defense_points = new_defense_points


func update_min_damage(value: float) -> void:
	var new_damage = min_damage + value
	min_damage = new_damage

func update_max_damage(value: float) -> void:
	var new_damage = max_damage + value
	max_damage = new_damage
	

func update_critical_rate(value: float) -> void:
	var new_critical_points = critical_points + value
	critical_points = new_critical_points


func update_critical_damage(value: float) -> void:
	var new_critical_damage = critical_damage + value
	critical_damage = new_critical_damage


func update_attack_speed(value: float) -> void:
	var new_attack_speed = attack_speed + value
	attack_speed = new_attack_speed
	attack_speed_updated.emit(attack_speed)

func update_move_speed(value: float) -> void:
	var new_move_speed = move_speed + value
	move_speed = new_move_speed
	move_speed_updated.emit(move_speed)


func update_hit_rate_status_effects(attribute_type: ItemAttribute.TYPE, rate_value: float) -> void:
	var effect = StatusEffect.get_debuff_effect_by_equipment_attribute_type(attribute_type)
	if hit_rate_status_effects.has(effect):
		hit_rate_status_effects[effect].rate_chance += rate_value
		hit_rate_status_effects[effect].duration = hit_rate_status_effects[effect].base_duration + ((level - 1) * 0.01)
	else:
		var new_status_effect = StatusEffect.new(effect)
		new_status_effect.effect = effect
		new_status_effect.type = StatusEffect.TYPE.ACTIVE
		new_status_effect.category = StatusEffect.CATEGORY.DEBUFF
		new_status_effect.duration = new_status_effect.base_duration + ((level - 1) * 0.01)
		new_status_effect.rate_chance = rate_value
		hit_rate_status_effects[effect] = new_status_effect

# Quando ativado por poções
func update_active_status_effects(attribute_type: ItemAttribute.TYPE, duration: float, value: float) -> void:
	var effect = StatusEffect.get_effect_by_potion_atrtibute_type(attribute_type)
	if active_status_effect.has(effect):
		active_status_effect[effect].duration = duration
		active_status_effect[effect].value = value
	else:
		var new_status_effect = StatusEffect.new(effect, duration)
		new_status_effect.effect = effect
		new_status_effect.value = value
		new_status_effect.rate_chance = 1.0
		new_status_effect.type = StatusEffect.TYPE.ACTIVE
		new_status_effect.category = StatusEffect.CATEGORY.BUFF
		active_status_effect[effect] = new_status_effect
	
	aditional_attribute[effect] = value
	PlayerEvents.add_new_status_effect(active_status_effect[effect])

func update_knockback_resistance(value: float) -> void:
	knockback_resistance = value


func update_knockback_force(value: float) -> void:
	knockback_force = value


func has_energy_to_roll() -> bool:
	return energy_points >= energy_cost_to_roll


func has_energy_to_attack() -> bool:
	return energy_points >= energy_cost_to_attack


func calculate_attack_damage() -> DamageData:
	var damage_data = DamageData.new()
	var damage = randf_range(min_damage, max_damage)
	
	var current_critical_rate = get_critical_rate()
	if randf() * 1.0 <= current_critical_rate:
		damage *= critical_damage
		damage_data.is_critical = true

	if randf() * 100 <= knockback_chance:
		damage_data.is_knockback_hit = true

	for status_effect in hit_rate_status_effects.values():
		if randf() * 1.0 <= status_effect.rate_chance:
			status_effect.is_active = true
			damage_data.status_effects.append(status_effect)

	damage_data.damage = damage

	return damage_data


func calculate_damage_taken(damage_data: DamageData, enemy_level: int) -> DamageData:
	var final_damage = damage_data.damage
	var defense_factor = calculate_defense_factor(enemy_level)
	
	# Aplica a redução de dano baseada na defesa
	if defense_points > 0 and defense_factor < 1.0:
		final_damage *= defense_factor # Multiplica pelo fator de redução

	# Aplica dano crítico do inimigo (se houver)
	if damage_data.is_critical:
		# Dano crítico ignora parte da defesa (25% extra)
		final_damage *= 1.25

	# Cria uma nova DamageData com o dano calculado
	var calculated_damage = DamageData.new()
	calculated_damage.damage = final_damage
	calculated_damage.is_critical = damage_data.is_critical
	calculated_damage.is_knockback_hit = damage_data.is_knockback_hit
	calculated_damage.status_effects = damage_data.status_effects.duplicate()
	
	return calculated_damage

func get_critical_rate() -> float:
	var max_critical_points = get_max_critical_points_for_current_level()
	if critical_points <= 0 or max_critical_points <= 0:
		return 0.0
	
	# Calcula o percentual baseado nos pontos (0% a 80%)
	return min((critical_points / max_critical_points) * MAX_CRITICAL_RATE, MAX_CRITICAL_RATE)

func get_max_critical_points_for_current_level() -> float:
	var difficulty = GameEvents.current_map.difficulty
	var difficulty_factor = 1.0 + (difficulty * 0.25)
	
	# Pontos necessários escalam linearmente com o nível
	var critical_points_for_max = BASE_CRITICAL_POINTS_FOR_MAX + (level - 1) * CRITICAL_GROWTH_FACTOR_PER_LEVEL
	return critical_points_for_max * difficulty_factor

# Função para obter o percentual atual de critical rate
func get_critical_rate_percentage() -> float:
	return get_critical_rate() * 100.0

#region Defense Stats
func calculate_defense_factor(enemy_level: int) -> float:
	var level_difference = level - enemy_level
	var defense_factor = 1.0 # Fator base (100%)
	
	# Calcula a efetividade máxima baseada no nível do jogador
	# No nível 1: 80% de defesa com 800 pontos (10x menos que nível 100)
	# No nível 100: 80% de defesa com 8000 pontos
	var max_defense_for_level = get_max_defense_for_current_level()
	
	# Calcula o percentual atual de defesa baseado nos pontos e nível
	var defense_percentage = 0.0
	if defense_points > 0 and max_defense_for_level > 0:
		# Percentual base: 0% a 80% baseado nos pontos de defesa
		defense_percentage = min((defense_points / max_defense_for_level) * MAX_DEFENCE_REDUCTION, MAX_DEFENCE_REDUCTION)
	
	# Aplica o percentual de redução de dano
	defense_factor = 1.0 - defense_percentage
	
	# Modificador baseado na diferença de nível
	if level_difference > 0:
		# Bônus por nível maior que inimigo
		var bonus_factor = min(level_difference * GROWTH_DEFENSE_FACTOR_PER_LEVEL, 0.2) # Máximo 20% de bônus
		defense_factor = max(defense_factor - bonus_factor, 0.0) # Reduz ainda mais o dano
	elif level_difference < 0:
		# Penalidade por nível menor que inimigo
		var penalty_factor = min(abs(level_difference) * REDUCT_DEFENSE_FACTOR_PER_LEVEL, 0.5) # Máximo 50% de penalidade
		defense_factor = min(defense_factor + penalty_factor, 1.0) # Aumenta o dano recebido
	
	return defense_factor

# Nova função para obter o percentual de defesa atual
func get_defense_percentage() -> float:
	# Calcula a defesa máxima para o nível atual
	var max_defense_for_level = 800.0 + (level - 1) * (7200.0 / 99.0)
	
	if defense_points <= 0:
		return 0.0
	if max_defense_for_level <= 0:
		return 0.0
	
	# Retorna o percentual de 0% a 80%
	return min((defense_points / max_defense_for_level) * 80.0, 80.0)

## Escala linear de 800 a 8000.
## Função para obter a defesa máxima possível no nível atual
func get_max_defense_for_current_level() -> float:
	var difficulty = GameEvents.current_map.difficulty
	var difficulty_factor = 1.0 + (difficulty * 0.25)
	
	var defense_to_hit_max = 800.0 + (level - 1) * (7200.0 / 99.0)
	return defense_to_hit_max * difficulty_factor

func get_defense_effectiveness_percentage(target_level: int) -> float:
	var factor = calculate_defense_factor(target_level)
	var reduction_percentage = (1.0 - factor)
	return reduction_percentage
#endregion


func calculate_health_at_level(target_level: int) -> float:
	# Polinominal Progress
	var growth_factor = float(target_level - 1) / (MAX_LEVEL - 1)
	return BASE_HEALTH + (MAX_TARGET_HEALTH - BASE_HEALTH) * pow(growth_factor, 1.5)

	# Exponencial Progress
	# var growth_factor = pow(MAX_TARGET_HEALTH / BASE_MAX_HEALTH, 1.0 / 99.0)
	# return BASE_MAX_HEALTH * pow(growth_factor, target_level - 1)


func calculate_mana_at_level(target_level: int) -> float:
	# Mana: 25-50 no nível 1, 450-500 no nível 100
	var growth_factor = pow(MAX_TARGET_MANA / BASE_MANA, 1.0 / 99.0)
	return BASE_MANA * pow(growth_factor, target_level - 1)


func calculate_energy_at_level(target_level: int) -> float:
	# +1.5 a cada nível par (níveis ímpares mantêm o valor do nível anterior)
	var bonus_levels = floor(float(target_level) / 2)
	return BASE_ENERGY + bonus_levels * 1.5


func calculate_damage_at_level(target_level: int) -> DamageStats:
	# Damage: 100-300 no nível 1, 10k-12k no nível 100
	var target_min = 10500.0 # Valor médio
	var target_max = 11000.0 # Valor médio

	var min_growth = pow(target_min / BASE_MIN_DAMAGE, 1.0 / 99.0)
	var max_growth = pow(target_max / BASE_MAX_DAMAGE, 1.0 / 99.0)

	var min_damage_value = BASE_MIN_DAMAGE * pow(min_growth, target_level - 1)
	var max_damage_value = BASE_MAX_DAMAGE * pow(max_growth, target_level - 1)

	return DamageStats.new(min_damage_value, max_damage_value)


func calculate_exp_to_next_level():
	if level == 1:
		exp_to_next_level = BASE_EXP
	else:
		# Experiência: 1000 no nível 1, ~925k no nível 100
		var target_exp = 925000.0
		var growth_factor = pow(target_exp / BASE_EXP, 1.0 / 99.0)
		exp_to_next_level = BASE_EXP * pow(growth_factor, level - 1)


func add_experience(amount: float) -> void:
	exp_total += amount * exp_boost
	exp_current += amount * exp_boost
	experiance_added.emit(amount)
	experience_update.emit(exp_current)

	# Verifica level up
	while exp_current >= exp_to_next_level and exp_to_next_level > 0:
		exp_current -= exp_to_next_level
		add_level()

	emit_attributes_changed()

func add_level() -> int:
	level += 1

	# Calcula novos valores baseados no nível
	var new_health = calculate_health_at_level(level)
	var new_mana = calculate_mana_at_level(level)
	var new_energy = calculate_energy_at_level(level)
	var new_damage = calculate_damage_at_level(level)

	# Aplica os novos valores mantendo a proporção atual de recursos
	var health_ratio = health_points / max_health_points
	var mana_ratio = mana_points / max_mana_points
	var energy_ratio = energy_points / max_energy_points

	max_health_points = new_health
	health_points = new_health * health_ratio
	max_health_changed.emit(max_health_points, health_changed)

	max_mana_points = new_mana
	mana_points = new_mana * mana_ratio


	max_energy_points = new_energy
	energy_points = new_energy * energy_ratio

	min_damage = new_damage.min_damage
	max_damage = new_damage.max_damage

	# Recalcula para o próximo nível
	calculate_exp_to_next_level()
	emit_attributes_changed()
	return level

func emit_level_updated() -> void:
	level_updated.emit(level)

func emit_attributes_changed() -> void:
	attributes_changed.emit(get_attributes())


func get_attributes() -> PlayerAttributes:
	var player_attributes = PlayerAttributes.new()

	player_attributes.level = level
	player_attributes.health_points = health_points
	player_attributes.max_health_points = max_health_points
	player_attributes.health_regen_per_seconds = health_regen
	player_attributes.mana_points = mana_points
	player_attributes.max_mana_points = max_mana_points
	player_attributes.mana_regen_per_seconds = mana_regen
	player_attributes.energy_points = energy_points
	player_attributes.max_energy_points = max_energy_points
	player_attributes.energy_regen_per_seconds = energy_regen
	player_attributes.attack_speed = attack_speed
	player_attributes.move_speed = move_speed
	
	player_attributes.min_damage = min_damage
	player_attributes.max_damage = max_damage
	
	player_attributes.critical_points = critical_points
	player_attributes.critical_rate = get_critical_rate()
	player_attributes.max_critical_points = get_max_critical_points_for_current_level()
	player_attributes.critical_damage = critical_damage
	
	player_attributes.defense_points = defense_points
	player_attributes.defense_rate = get_defense_effectiveness_percentage(level)
	player_attributes.max_defense_points = get_max_defense_for_current_level()
	
	player_attributes.current_exp = exp_current
	player_attributes.total_exp = exp_total
	player_attributes.exp_to_next_level = exp_to_next_level
	player_attributes.exp_boost = exp_boost

	player_attributes.knockback_resistance = knockback_resistance
	player_attributes.knockback_force = knockback_force
	player_attributes.knockback_chance = knockback_chance

	player_attributes.hit_rate_status_effects = hit_rate_status_effects.values()

	return player_attributes


func _load_stats_data() -> void:
	pass

func _save_stats_data() -> void:
	pass
