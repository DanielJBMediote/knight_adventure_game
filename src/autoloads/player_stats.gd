# autoload/player_stats.gd
extends Node

signal health_changed(health: float)
signal mana_changed(mana: float)
signal energy_changed(mana: float)
signal experiance_added(amount: float)
signal experience_update(exp: float)
signal level_updated(level: float)

signal attributes_changed(attributes)
signal player_dead

var player_ref: Player

const BASE_EXP = 1000
const EXP_SCALE_FACTOR = 1.15
const EXP_ADDITIVE = 50
const MAX_DEFENCE_REDUCTION = 0.8
const MAX_CRITICAL_RATE = 0.8
const MAX_CRITICAL_DAMAGE = 4.0


const GROWTH_DEFENSE_FACTOR_PER_LEVEL = 0.045  # 4.5%
const REDUCT_DEFENSE_FACTOR_PER_LEVEL = 0.03  # 3%


## 1 = normal, <1 = menos knockback, >1 = mais knockback
var knockback_resistance: float = 1.0
var knockback_force: float = 300.0
var knockback_chance: float = 1.0  # de 0% até 60%

var level: int = 1
var total_exp := 0.0
var current_exp := 0.0
var exp_to_next_level := 0.0
var exp_buff := 1.0  # 100% de Experincia

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
var energy_cost_to_attack: float = 5.0

var mana_cost_to_cast_skill_0: float = 0.0
var mana_cost_to_cast_skill_1: float = 0.0
var mana_cost_to_cast_skill_2: float = 0.0

var min_damage: float = 1.0
var max_damage: float = 1.0

var critical_rate: float = 0.0
var critical_damage: float = 1.0

var poison_hit_rate: float = 0.0
var poison_duration: float = 0.0
var poison_dps: float = 0.0

var bleed_hit_rate: float = 0.0
var bleed_duration: float = 0.0
var bleed_dps: float = 0.0

var defense_points: float = 0.0

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


func update_health(value: float) -> void:
	self.health_points += value

	if self.health_points >= self.max_health_points:
		self.health_points = self.max_health_points
	elif self.health_points <= 0:
		self.health_points = 0
		player_dead.emit()

	health_changed.emit(self.health_points)


func update_max_health(value: float) -> void:
	self.max_health_points += value


func update_mana(value: float) -> void:
	self.mana_points += value

	if self.mana_points >= self.max_mana_points:
		self.mana_points = self.max_mana_points
	elif self.mana_points <= 0:
		self.mana_points = 0

	mana_changed.emit(self.mana_points)


func update_max_mana(value: float) -> void:
	self.max_mana_points += value


func update_energy(value: float) -> void:
	self.energy_points += value

	if self.energy_points >= self.max_energy_points:
		self.energy_points = self.max_energy_points
	elif self.energy_points <= 0:
		self.energy_points = 0

	energy_changed.emit(self.energy_points)


func update_defense(value: float) -> void:
	self.defense_points = max(defense_points + value, 1)


func update_min_damage(value: float) -> void:
	self.min_damage = maxi(min_damage + value, 1)


func update_max_damage(value: float) -> void:
	self.max_damage = maxi(max_damage + value, 1)


func update_critical_rate(value: float) -> void:
	self.critical_rate = clampf(self.critical_rate + value, 0, MAX_CRITICAL_RATE)


func update_critical_damage(value: float) -> void:
	var crit_dmg = clampf(self.critical_damage + value, 1.0, MAX_CRITICAL_DAMAGE)
	self.critical_damage = crit_dmg


func update_attack_speed(value: float) -> void:
	self.attack_speed = clamp(self.attack_speed + value, 1.0, 3.0)


func update_move_speed(value: float) -> void:
	self.move_speed = clamp(self.move_speed + value, 1.0, 2.0)


func update_knockback_resistance(value: float) -> void:
	self.knockback_resistance = value


func update_knockback_force(value: float) -> void:
	self.knockback_force = value


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
	if defense_points > 0 and defense_factor < 1.0:
		final_damage *= defense_factor  # Multiplica pelo fator de redução

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

func calculate_defense_factor(enemy_level: int) -> float:
	var level_difference = level - enemy_level
	var defense_factor = 1.0  # Fator base (100%)
	
	# Calcula a efetividade máxima baseada no nível do jogador
	# No nível 1: 80% de defesa com 800 pontos (10x menos que nível 100)
	# No nível 100: 80% de defesa com 8000 pontos
	var max_defense_for_level = 800.0 + (level - 1) * (7200.0 / 99.0)  # Escala linear de 800 a 8000
	
	# Calcula o percentual atual de defesa baseado nos pontos e nível
	var defense_percentage = 0.0
	if defense_points > 0 and max_defense_for_level > 0:
		# Percentual base: 0% a 80% baseado nos pontos de defesa
		defense_percentage = min((defense_points / max_defense_for_level) * 0.8, 0.8)
	
	# Aplica o percentual de redução de dano
	defense_factor = 1.0 - defense_percentage
	
	# Modificador baseado na diferença de nível
	if level_difference > 0:
		# Bônus por nível maior que inimigo
		var bonus_factor = min(level_difference * GROWTH_DEFENSE_FACTOR_PER_LEVEL, 0.2)  # Máximo 20% de bônus
		defense_factor = max(defense_factor - bonus_factor, 0.0)  # Reduz ainda mais o dano
	elif level_difference < 0:
		# Penalidade por nível menor que inimigo
		var penalty_factor = min(abs(level_difference) * REDUCT_DEFENSE_FACTOR_PER_LEVEL, 0.5)  # Máximo 50% de penalidade
		defense_factor = min(defense_factor + penalty_factor, 1.0)  # Aumenta o dano recebido
	
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

# Função para obter a defesa máxima possível no nível atual
func get_max_defense_for_current_level() -> float:
	return 800.0 + (level - 1) * (7200.0 / 99.0)

# Atualize também a função get_defense_effectiveness_percentage
func get_defense_effectiveness_percentage(enemy_level: int) -> float:
	var factor = calculate_defense_factor(enemy_level)
	# Converte para percentual de redução (ex: 0.2 = 80% de redução)
	var reduction_percentage = (1.0 - factor) * 100.0
	return reduction_percentage
	
func get_defense_effectiveness_percentage_for_current_level() -> float:
	var factor = calculate_defense_factor(level)
	# Converte para percentual de redução (ex: 0.2 = 80% de redução)
	var reduction_percentage = (1.0 - factor) * 100.0
	return reduction_percentage


func calculate_health_at_level(target_level: int) -> float:
	# Health: 800-1200 no nível 1, 80k-85k no nível 100
	var min_target = 80000.0
	var max_target = 85000.0
	var growth_factor = pow(max_target / base_max_health, 1.0 / 99.0)
	return base_max_health * pow(growth_factor, target_level - 1)


func calculate_mana_at_level(target_level: int) -> float:
	# Mana: 25-50 no nível 1, 450-500 no nível 100
	var target_mana = 475.0  # Valor médio
	var growth_factor = pow(target_mana / base_max_mana, 1.0 / 99.0)
	return base_max_mana * pow(growth_factor, target_level - 1)


func calculate_energy_at_level(target_level: int) -> float:
	# Energy: 100 no nível 1, 150 no nível 100
	return base_max_energy + (target_level - 1) * 0.5  # +0.5 por nível


func calculate_damage_at_level(target_level: int) -> Dictionary:
	# Damage: 100-300 no nível 1, 10k-12k no nível 100
	var target_min = 10500.0  # Valor médio
	var target_max = 11000.0  # Valor médio

	var min_growth = pow(target_min / base_min_damage, 1.0 / 99.0)
	var max_growth = pow(target_max / base_max_damage, 1.0 / 99.0)

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
		var growth_factor = pow(target_exp / BASE_EXP, 1.0 / 99.0)
		exp_to_next_level = BASE_EXP * pow(growth_factor, level - 1)


func add_experience(amount: float) -> void:
	total_exp += amount * exp_buff
	current_exp += amount * exp_buff
	experiance_added.emit(amount)
	experience_update.emit(current_exp)

	# Verifica level up
	while current_exp >= exp_to_next_level and exp_to_next_level > 0:
		current_exp -= exp_to_next_level
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

	self.max_health_points = new_health
	self.health_points = new_health * health_ratio

	self.max_mana_points = new_mana
	self.mana_points = new_mana * mana_ratio

	self.max_energy_points = new_energy
	self.energy_points = new_energy * energy_ratio

	self.min_damage = new_damage["min"]
	self.max_damage = new_damage["max"]

	# Recalcula para o próximo nível
	calculate_exp_to_next_level()

	#level_updated.emit(level)
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
		"defense_points": defense_points,
		"defense_percent": get_defense_effectiveness_percentage_for_current_level(),
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
