# autoload/player_stats.gd
extends Node

var player_ref: Player

const BASE_EXP = 100
const EXP_SCALE_FACTOR = 1.15
const EXP_ADDITIVE = 50
const MAX_DEFENCE_REDUCTION = 0.8
const GROWTH_DEFENSE_FACTOR_PER_LEVEL = 0.045 # 4.5%
const REDUCT_DEFENSE_FACTOR_PER_LEVEL = 0.03 # 3%

var level: int = 1
var total_exp := 0.0
var current_exp := 0.0
var exp_to_next_level := 0.0

var max_health_points: float = 100.0
var health_points: float = 100.0
var health_regen_per_seconds: float = 0.0

var max_mana_points: float = 100.0
var mana_points: float = 100.0
var mana_regen_per_seconds: float = 0.0

var max_energy_points: float = 100.0
var energy_points: float = 100.0
var energy_regen_per_seconds: float = 1.0

var energy_cost_to_roll: float = 20.0
var energy_cost_to_attack: float = 10.0

var mana_cost_to_cast_skill_0: float = 0.0
var mana_cost_to_cast_skill_1: float = 0.0
var mana_cost_to_cast_skill_2: float = 0.0

var min_damage: float = 100.0
var max_damage: float = 100.0

var critical_rate: float = 0.0
var critical_damage: float = 100.0

var poison_rate_chance: float = 0.0
var poison_duration: float = 0.0
var poison_dps: float = 0.0

var bleed_rate_chance: float = 0.0
var bleed_duration: float = 0.0
var bleed_dps: float = 0.0

## Defense, default is 0.0, it will increment by equip armor and gems. 
## The defence will decreased in take_damage.
var defense: float = 0.0

var attack_speed: float = 1.0
var move_speed: float = 1.0

var knock_back_chance: float = 10.0 # de 0% até 60%

# os valores serão instanciados por um arquivo onde eu vou armazenar
func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
	
	calculate_exp_to_next_level()

func update_health(value: float) -> void:
	health_points = value
func update_mana(value: float) -> void:
	mana_points = value
func update_energy(value: float) -> void:
	energy_points = value

func has_energy_to_roll() -> bool:
	return energy_points >= energy_cost_to_roll

func has_energy_to_attack() -> bool:
	return energy_points >= energy_cost_to_attack

func calculate_attack_damage() -> DamageData:
	var data = DamageData.new()
	var damage = randf_range(min_damage, max_damage)
	
	if randf() * 100 <= critical_rate:
		damage *= (critical_damage / 100.0) + 1.0
		data.is_critical = true
	
	if randf() * 100 <= knock_back_chance:
		data.is_knockback_hit = true
	
	# Chance normal de aplicar efeitos
	if randf() * 100 <= bleed_rate_chance:
		var bleed_effect = BleedEffectData.new(bleed_dps, bleed_duration)
		if bleed_effect.active:
			data.status_effects.append(bleed_effect)
	
	if randf() * 100 <= poison_rate_chance:
		var poison_effect = PoisonEffectData.new(poison_dps, poison_duration)
		if poison_effect.active:
			data.status_effects.append(poison_effect)
	
	data.damage = damage
	
	return data

func calculate_damage_taken(damage_data: DamageData, enemy_level: int) -> DamageData:
	var final_damage = damage_data.damage
	var defense_factor = calculate_defense_factor(enemy_level)
	
	# Aplica a redução de dano baseada na defesa
	if defense > 0 and defense_factor > 0:
		var damage_reduction = defense * defense_factor
		final_damage = max(final_damage - damage_reduction, 0)
	
	# Aplica dano crítico do inimigo (se houver)
	if damage_data.is_critical:
		# Dano crítico ignora parte da defesa
		final_damage *= 1.25  # 25% extra de dano crítico
	
	# Cria uma nova DamageData com o dano calculado
	var calculated_damage = DamageData.new()
	calculated_damage.damage = final_damage
	calculated_damage.is_critical = damage_data.is_critical
	calculated_damage.is_knockback_hit = damage_data.is_knockback_hit
	calculated_damage.status_effects = damage_data.status_effects.duplicate()
	
	return calculated_damage

func calculate_defense_factor(enemy_level: int) -> float:
	var level_difference = level - enemy_level
	var defense_factor = 1.0  # Fator base (100%)
	
	# Se jogador tem nível maior que inimigo - defesa é mais efetiva
	if level_difference > 0:
		# Aumenta a efetividade da defesa em 5% por nível de diferença
		var bonus_factor = min(level_difference * GROWTH_DEFENSE_FACTOR_PER_LEVEL, MAX_DEFENCE_REDUCTION)  # Máximo 80% de bônus
		defense_factor += bonus_factor
	
	# Se inimigo tem nível maior que jogador - defesa é menos efetiva
	elif level_difference < 0:
		# Reduz a efetividade da defesa em 3% por nível de diferença
		var penalty_factor = min(abs(level_difference) * REDUCT_DEFENSE_FACTOR_PER_LEVEL, 1.0)  # Máximo 100% de penalidade
		defense_factor = max(defense_factor - penalty_factor, 0.0)  # Mínimo 0% de efetividade
	
	return defense_factor

func get_defense_effectiveness_percentage(enemy_level: int) -> float:
	var factor = calculate_defense_factor(enemy_level)
	return factor * 100.0

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
		add_level()

func add_level() -> int:
	level += 1
	
	var level_factor := 1.0 + (level - 1) * 0.1
	
	max_health_points += 20 * level_factor
	health_points = max_health_points
	PlayerEvents.handle_event_recovery_health(health_points)
	
	var mana_factor := 1.0 + (level - 1) * 0.2
	max_mana_points += 10 * mana_factor
	mana_points = max_mana_points
	PlayerEvents.handle_event_recovery_mana(mana_points)
	
	var energy_factor := 1.0 + (level - 1) * 0.05
	max_energy_points += 2 * energy_factor
	energy_points = max_energy_points
	PlayerEvents.handle_event_recovery_energy(energy_points)
	
	var damage_factor = 1.0 + (level - 1) * 0.025
	# Aumenta stats de combate
	min_damage += 2 * damage_factor
	max_damage += 3 * damage_factor
	
	# Recalcula para o próximo nível
	calculate_exp_to_next_level()
	#get_tree().call_group("player_stats_ui", "on_player_level_up", level)
	
	#PlayerEvents.on_level_up(level)
	return level
