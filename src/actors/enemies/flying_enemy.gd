class_name FlyingEnemy
extends Enemy

@export var ideal_flying_height := 80.0
@export var height_smoothing := 2.0
@export var min_flight_height := 50.0

var height_adjust_speed: float = 150.0  # Velocidade de ajuste
var last_height = 0.0

func _ready() -> void:
	super._ready()
	enemy_type = ENEMY_TYPES.FLYING

func adjust_flight_height(delta: float):
	if not target_player:
		return
	
	var target_height = target_player.global_position.y - ideal_flying_height
	var new_height = lerp(global_position.y, target_height, delta * height_smoothing)
	
	# Limita a altura mínima em relação ao chão
	var floor_dist = get_distance_to_floor()
	if floor_dist < min_floor_distance:
		new_height = min(new_height, global_position.y - (min_floor_distance - floor_dist))
	
	global_position.y = new_height
