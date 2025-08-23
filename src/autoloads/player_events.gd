# autoloads/player_events.gd
extends Node

signal update_health_points(new_health_points: float)
signal update_mana_points(new_mana_points: float)
signal update_energy_points(new_energy_points: float)

signal energy_warning()

signal show_exp(amount: float)
signal add_exp(exp: float)
signal level_up(level: int)

signal add_status_effect(effect: StatusEffectData)
signal remove_status_effect(effect: StatusEffectData)
signal clear_status_effects()

signal trigged_player_dead()

func _ready() -> void:
	ItemManager.use_potion.connect(_on_use_potion)

func handle_event_spent_health(damage: float) -> void:
	var current_health = PlayerStats.health_points
	var new_health = current_health - damage
	
	PlayerStats.set_health(new_health)
	
	if new_health <= 0:
		trigged_player_dead.emit()
		return
	
	update_health_points.emit(new_health)

func handle_event_recovery_health(health: float) -> void:
	var current_health = PlayerStats.health_points
	var new_health = current_health + health
	
	if new_health >= PlayerStats.max_health_points:
		new_health = PlayerStats.max_health_points
	
	PlayerStats.set_health(new_health)
	update_health_points.emit(new_health)

func handle_event_spent_mana(value: float) -> void:
	var current_value = PlayerStats.mana_points
	var new_value = current_value - value
	
	if new_value <= 0.0:
		new_value = 0.0
	
	PlayerStats.set_mana(new_value)
	update_mana_points.emit(new_value)

func handle_event_recovery_mana(value: float) -> void:
	var current_value = PlayerStats.mana_points
	var new_value = current_value + value
	
	if new_value >= PlayerStats.max_mana_points:
		new_value = PlayerStats.max_mana_points
		
	PlayerStats.set_mana(new_value)
	update_mana_points.emit(new_value)

func handle_event_spent_energy(value: float) -> void:
	var current_value = PlayerStats.energy_points
	var new_value = current_value - value
	
	if new_value <= 0.0:
		new_value = 0.0
	
	PlayerStats.set_energy(new_value)
	update_energy_points.emit(new_value)

func handle_event_recovery_energy(value: float)-> void:
	var current_value = PlayerStats.energy_points
	var new_value = current_value + value
	
	if new_value >= PlayerStats.max_energy_points:
		new_value = PlayerStats.max_energy_points
		
	PlayerStats.set_energy(new_value)
	update_energy_points.emit(new_value)

func handle_event_add_experience(amount: float) -> void:
	var current_exp = PlayerStats.current_exp + amount
	add_exp.emit(current_exp)
	PlayerStats.add_experience(amount)
	show_exp.emit(amount)

func handle_event_level_up(level: int):
	level_up.emit(level)

func _on_use_potion(potion: PotionItem) -> bool:
	print("Potion use: ", potion.item_name)
	print("Effects: ", potion.item_description)
	
	return true
	
