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
	var angle = abs(rad_to_deg(collision_normal.angle_to(Vector2.UP)))
	
	# Considera como parede se o ângulo estiver entre 75-105 graus (aproximadamente vertical)
	return angle > 75 and angle < 105

func perform_wall_jump(direction_x: float, jump_speed: float):
	if not can_wall_jump or not is_on_floor():
		return
	
	# Verifica se há parede na direção do movimento
	var wall_in_front = false
	for raycast in wall_raycasts:
		raycast.force_raycast_update()
		if sign(raycast.target_position.x) == sign(direction_x) and raycast.is_colliding():
			wall_in_front = true
			break
	
	if not wall_in_front:
		return
	
	# Aplica força do pulo
	velocity.y = -wall_jump_force
	velocity.x = -direction_x * jump_speed  # Impulso para longe da parede
	
	# Ativa cooldown
	can_wall_jump = false
	wall_jump_timer.start(WALL_JUMP_COOLDOWN)

func _on_wall_jump_cooldown_finished():
	can_wall_jump = true
