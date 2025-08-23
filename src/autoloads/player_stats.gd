# autoload/player_stats.gd
extends Node

signal attributes_changed(attributes)

var player_ref: Player

const BASE_EXP = 1000
const EXP_SCALE_FACTOR = 1.15
const EXP_ADDITIVE = 50
const MAX_DEFENCE_REDUCTION = 0.8
const GROWTH_DEFENSE_FACTOR_PER_LEVEL = 0.045 # 4.5%
const REDUCT_DEFENSE_FACTOR_PER_LEVEL = 0.03 # 3%

## 1 = normal, <1 = menos knockback, >1 = mais knockback
var knockback_resistance: float = 1.0
var knockback_force: float = 300.0
var knockback_chance: float = 1.0 # de 0% até 60%

var level: int = 1
var total_exp := 0.0
var current_exp := 0.0
var exp_to_next_level := 0.0
var exp_buff := 1.0 # 100% de Experincia

# Valores base no nível 1
var base_max_health: float = 1000.0
var base_max_mana: float = 40.0
var base_max_energy: float = 100.0
var base_min_damage: float = 150.0
var base_max_damage: float = 250.0

# Valores atuais
var max_health_points: float = 1000.0
var health_points: float = 1000.0
var health_regen_per_seconds: float = 0.0

var max_mana_points: float = 40.0
var mana_points: float = 40.0
var mana_regen_per_seconds: float = 0.0

var max_energy_points: float = 100.0
var energy_points: float = 100.0
var energy_regen_per_seconds: float = 1.0

var energy_cost_to_roll: float = 20.0
var energy_cost_to_attack: float = 10.0

var mana_cost_to_cast_skill_0: float = 0.0
var mana_cost_to_cast_skill_1: float = 0.0
var mana_cost_to_cast_skill_2: float = 0.0

var min_damage: float = 150.0
var max_damage: float = 250.0

var critical_rate: float = 0.0
var critical_damage: float = 100.0

var poison_hit_rate: float = 0.0
var poison_duration: float = 0.0
var poison_dps: float = 0.0

var bleed_hit_rate: float = 0.0
var bleed_duration: float = 0.0
var bleed_dps: float = 0.0

## Defense, default is 0.0, it will increment by equip armor and gems. 
## The defence will decreased in take_damage.
var defense: float = 0.0

var attack_speed: float = 1.0
var move_speed: float = 1.0

# os valores serão instanciados por um arquivo onde eu vou armazenar
func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
	
	# Inicializa com valores base
	initialize_base_stats()
	calculate_exp_to_next_level()

func initialize_base_stats() -> void:
	# Valores aleatórios dentro dos ranges especificados
	base_max_health = randf_range(800.0, 1200.0)
	base_max_mana = randf_range(25.0, 50.0)
	base_max_energy = 100.0
	base_min_damage = randf_range(100.0, 200.0)
	base_max_damage = randf_range(200.0, 300.0)
	
	# Aplica valores base
	max_health_points = base_max_health
	health_points = base_max_health
	max_mana_points = base_max_mana
	mana_points = base_max_mana
	max_energy_points = base_max_energy
	energy_points = base_max_energy
	min_damage = base_min_damage
	max_damage = base_max_damage

func set_health(value: float) -> void:
	health_points = value
	emit_attributes_changed()
func set_mana(value: float) -> void:
	mana_points = value
	emit_attributes_changed()
func set_energy(value: float) -> void:
	energy_points = value
	emit_attributes_changed()
func set_defense(value: float) -> void:
	defense = value
	emit_attributes_changed()
func set_min_damage(value: float) -> void:
	min_damage = value
	emit_attributes_changed()
func set_max_damage(value: float) -> void:
	max_damage = value
	emit_attributes_changed()
func set_knockback_resistance(value: float) -> void:
	knockback_resistance = value
	emit_attributes_changed()
func set_knockback_force(value: float) -> void:
	knockback_force = value
	emit_attributes_changed()

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
	
	if randf() * 100 <= knockback_chance:
		data.is_knockback_hit = true
	
	# Chance normal de aplicar efeitos
	if randf() * 100 <= bleed_hit_rate:
		var bleed_effect = BleedEffectData.new(bleed_dps, bleed_duration)
		if bleed_effect.active:
			data.status_effects.append(bleed_effect)
	
	if randf() * 100 <= poison_hit_rate:
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

func calculate_health_at_level(target_level: int) -> float:
	# Health: 800-1200 no nível 1, 80k-85k no nível 100
	var min_target = 80000.0
	var max_target = 85000.0
	var growth_factor = pow((max_target / base_max_health), 1.0/99.0)
	return base_max_health * pow(growth_factor, target_level - 1)

func calculate_mana_at_level(target_level: int) -> float:
	# Mana: 25-50 no nível 1, 450-500 no nível 100
	var target_mana = 475.0  # Valor médio
	var growth_factor = pow((target_mana / base_max_mana), 1.0/99.0)
	return base_max_mana * pow(growth_factor, target_level - 1)

func calculate_energy_at_level(target_level: int) -> float:
	# Energy: 100 no nível 1, 150 no nível 100
	return base_max_energy + (target_level - 1) * 0.5  # +0.5 por nível

func calculate_damage_at_level(target_level: int) -> Dictionary:
	# Damage: 100-300 no nível 1, 10k-12k no nível 100
	var target_min = 10500.0  # Valor médio
	var target_max = 11000.0  # Valor médio
	
	var min_growth = pow((target_min / base_min_damage), 1.0/99.0)
	var max_growth = pow((target_max / base_max_damage), 1.0/99.0)
	
	return {
		"min": base_min_damage * pow(min_growth, target_level - 1),
		"max": base_max_damage * pow(max_growth, target_level - 1)
	}

func calculate_exp_to_next_level():
	if level == 1:
		exp_to_next_level = BASE_EXP
	else:
		# Experiência: 1000 no nível 1, ~925k no nível 100
		var target_exp = 925000.0
		var growth_factor = pow((target_exp / BASE_EXP), 1.0/99.0)
		exp_to_next_level = BASE_EXP * pow(growth_factor, level - 1)

func add_experience(amount: float) -> void:
	total_exp += amount * exp_buff
	current_exp += amount * exp_buff
	
	# Verifica level up
	while current_exp >= exp_to_next_level and exp_to_next_level > 0:
		current_exp -= exp_to_next_level
		add_level()
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
	
	max_mana_points = new_mana
	mana_points = new_mana * mana_ratio
	
	max_energy_points = new_energy
	energy_points = new_energy * energy_ratio
	
	min_damage = new_damage["min"]
	max_damage = new_damage["max"]
	
	# Notifica eventos de recuperação
	PlayerEvents.handle_event_recovery_health(health_points)
	PlayerEvents.handle_event_recovery_mana(mana_points)
	PlayerEvents.handle_event_recovery_energy(energy_points)
	
	# Recalcula para o próximo nível
	calculate_exp_to_next_level()
	
	PlayerEvents.on_level_up(level)
	emit_attributes_changed()
	return level

func emit_attributes_changed() -> void:
	attributes_changed.emit(get_attributes())

func get_attributes() -> Dictionary[String, Variant]: 
	return {
		"level": level,
		
		"health_points": health_points,
		"max_health_points": max_health_points,
		"health_regen_per_seconds": health_regen_per_seconds,
		
		"mana_points": mana_points,
		"max_mana_points": max_mana_points,
		"mana_regen_per_seconds": mana_regen_per_seconds,
		
		"energy_points": energy_points,
		"max_energy_points": max_energy_points,
		"energy_regen_per_seconds": energy_regen_per_seconds,
		
		"attack_speed": attack_speed,
		"move_speed": move_speed,
		
		"min_damage": min_damage,
		"max_damage": max_damage,
		
		"critical_rate": critical_rate,
		"critical_damage": critical_damage,
		
		"defense": defense,
		
		"current_exp": current_exp,
		"total_exp": total_exp,
		"exp_to_next_level": exp_to_next_level,
		"exp_buff": exp_buff,
		
		"bleed_hit_rate": bleed_hit_rate,
		"poison_hit_rate": poison_hit_rate,
		
		"knockback_resistance": knockback_resistance,
		"knockback_force": knockback_force,
		"knockback_chance": knockback_chance
	}
