class_name TerrestrialEnemy
extends Enemy

const GRAVITY := 2000.0
const WALL_JUMP_COOLDOWN := 1.0

@export var wall_jump_force := 800.0
var can_wall_jump := true
var wall_jump_timer: Timer

func _ready() -> void:
	super._ready()
	enemy_type = ENEMY_TYPES.TERRESTRIAL
	wall_jump_timer = Timer.new()
	wall_jump_timer.wait_time = WALL_JUMP_COOLDOWN
	wall_jump_timer.one_shot = true
	wall_jump_timer.timeout.connect(_on_wall_jump_cooldown_finished)
	add_child(wall_jump_timer)

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = min(velocity.y, 0)

func is_colliding_with_wall(raycast: RayCast2D) -> bool:
	if not raycast.is_colliding():
		return false
		
	var collision_normal = raycast.get_collision_normal()
	var angle = rad_to_deg(collision_normal.angle_to(Vector2.UP))
	
	# Considera como parede se o ângulo estiver entre 75-105 graus (aproximadamente vertical)
	return angle > 75 and angle < 105

func perform_wall_jump(direction_x: float, jump_speed: float):
	if not can_wall_jump or not is_on_floor():
		return
	
	var wall_in_front = false
	for raycast in wall_raycasts:
		raycast.force_raycast_update()
		# Verifica se o raycast está apontando na mesma direção do movimento
		if sign(raycast.target_position.x) == sign(direction_x):
			if raycast.is_colliding():
				wall_in_front = true
				break
	
	if not wall_in_front:
		return
	
	# Aplica força do pulo
	velocity.y = -wall_jump_force
	
	# Aplica um pequeno impulso para longe da parede
	velocity.x = -direction_x * jump_speed
	
	# Ativa cooldown
	can_wall_jump = false
	wall_jump_timer.start(WALL_JUMP_COOLDOWN)

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

func _on_wall_jump_cooldown_finished():
	can_wall_jump = true
