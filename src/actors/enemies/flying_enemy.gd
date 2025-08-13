class_name FlyingEnemy
extends Enemy

@export var knockback_air_force := -1.0 
@export var ideal_flying_height := 80.0  # Altura ideal acima do jogador

var height_adjust_speed: float = 150.0  # Velocidade de ajuste
var height_smoothing: float = 2.0  # Fator de suavização
var last_height = 0.0

func _ready() -> void:
	super._ready()
	enemy_type = ENEMY_TYPES.FLYING

func adjust_height_to_ground(delta: float):
	var target_adjustment = min_floor_distance - distance_to_floor
	var speed = height_adjust_speed
	var target_y = position.y
	
	if not is_near_wall:
		if distance_to_floor <= min_floor_distance:
			# Está muito baixo - subir suavemente
			target_y = position.y - (target_adjustment * speed * delta)
		else:
			if distance_to_floor >= min_floor_distance or distance_to_floor == 9999.0:
				# Está muito alto - descer suavemente
				target_y = position.y + (10 * delta)
			else:
				# Ajuste fino
				target_y = position.y + (target_adjustment * speed * delta)
	
	# Interpolação suave para a posição alvo
	position.y = lerp(position.y, target_y, delta * height_smoothing)
	
	last_height = position.y
	floor_raycast.force_raycast_update()

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
