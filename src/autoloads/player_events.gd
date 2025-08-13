# autoloads/player_events.gd
extends Node

signal update_health_points(new_health_points: float)
signal update_mana_points(new_mana_points: float)
signal update_energy_points(new_energy_points: float)

signal energy_warning()

signal show_exp(amount: float)
signal update_exp(exp: float)
signal level_up(level: int)

signal add_status_effect(effect: StatusEffectData)
signal remove_status_effect(effect: StatusEffectData)
signal clear_status_effects()

signal trigged_player_dead()

func take_damage(damage: float) -> void:
	var current_health = PlayerStats.health_points
	var new_health = current_health - damage
	
	if new_health <= 0:
		print("Player die")
		trigged_player_dead.emit()
	
	PlayerStats.update_health(new_health)
	update_health_points.emit(new_health)
func recovery_health(health: float) -> void:
	var current_health = PlayerStats.health_points
	var new_health = current_health + health
	
	if new_health >= PlayerStats.max_health_points:
		new_health = PlayerStats.max_health_points
	
	PlayerStats.update_health(new_health)
	update_health_points.emit(new_health)

func spent_mana(value: float) -> void:
	var current_value = PlayerStats.mana_points
	var new_value = current_value - value
	
	if new_value <= 0.0:
		new_value = 0.0
	
	PlayerStats.update_mana(new_value)
	update_mana_points.emit(new_value)
func recovery_mana(value: float) -> void:
	var current_value = PlayerStats.mana_points
	var new_value = current_value + value
	
	if new_value >= PlayerStats.max_mana_points:
		new_value = PlayerStats.max_mana_points
		
	PlayerStats.update_mana(new_value)
	update_mana_points.emit(new_value)

func spent_energy(value: float) -> void:
	var current_value = PlayerStats.energy_points
	var new_value = current_value - value
	
	if new_value <= 0.0:
		new_value = 0.0
	
	PlayerStats.update_energy(new_value)
	update_energy_points.emit(new_value)
func recovery_energy(value: float)-> void:
	var current_value = PlayerStats.energy_points
	var new_value = current_value + value
	
	if new_value >= PlayerStats.max_energy_points:
		new_value = PlayerStats.max_energy_points
		
	PlayerStats.update_energy(new_value)
	update_energy_points.emit(new_value)

func add_experience(amount: float) -> void:
	PlayerStats.add_experience(amount)
	var current_exp = PlayerStats.current_exp
	update_exp.emit(current_exp)

func on_level_up(level: int):
	level_up.emit(level)
