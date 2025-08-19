class_name FlyingEnemy
extends Enemy

@export var knockback_air_force := -1.0 

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

func take_knockback(knock_force: float, attacker_position: Vector2):
	if is_invulnerable or is_in_knockback:
		return
	
	# Configura estado de knockback
	is_in_knockback = true
	is_hurting = true
	is_invulnerable = true
	
	# Interrompe qualquer ataque em andamento
	is_attacking = false
	can_attack = false
	
	super.disable_enemy_hitbox()
	
	# Calcula direção do knockback
	var knockback_direction = (global_position - attacker_position).normalized()
	knockback_direction.y = knockback_air_force  # Mais para cima para um efeito melhor
	
	# Aplica o knockback
	velocity = knockback_direction * knock_force * knockback_resistance
	
	# Configura timer para recuperação
	if knockback_timer:
		knockback_timer.stop()
	else:
		knockback_timer = Timer.new()
		add_child(knockback_timer)
		knockback_timer.timeout.connect(_on_knockback_finished)
	
	knockback_timer.start(0.3)  # Duração do knockback

func _on_knockback_finished():
	is_in_knockback = false
	is_hurting = false
	is_invulnerable = false
	can_attack = true
