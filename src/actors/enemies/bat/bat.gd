class_name Bat
extends FlyingEnemy

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var enemy_hitbox: Area2D = $EnemyHitbox
@onready var enemy_stats: EnemyStats = $EnemyStats
@onready var float_damage_control: FloatDamageControl = $FloatDamageControl

# Controllers
@onready var wander_controller: WanderController = $WanderController
@onready var enemy_control_ui: EnemyControlUI = $EnemyControlUI

@export var min_time_state: float = 5.0
@export var max_time_state: float = 10.0
@export var close_range_hitbox_size := Vector2(80, 80)  # Tamanho maior para quando o jogador está muito perto
@export var close_range_offset := Vector2(0, 0)  # Centralizado quando muito perto

enum STATES { IDLE, WANDER, CHASE, SLEEPING, AWAKING, ATTACKING }
var state: STATES = STATES.IDLE

const BITE_HITBOX_SIZE := Vector2(60, 80)
const SLASH_HITBOX_SIZE := Vector2(60, 100)
const HITBOX_OFFSET := Vector2(40, 0)

var wall_retry_count := 0
const MAX_WALL_RETRIES := 3

func _ready() -> void:
	super._ready()
	get_tree().call_group("enemies", "_disable_enemy_hitbox", self)
	pick_random_state([STATES.SLEEPING])
	wander_controller.start_position = global_position
	update_attack_speed()
	
	#float_damage_control.trigged_hit.connect(_on_hit)

func _physics_process(delta: float) -> void:
	if is_dead:
		animated_sprite_2d.play("dying")
		return
	
	distance_to_floor = get_distance_to_floor()
	
	# Aplica desaceleração durante o knockback
	if is_in_knockback:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta * 0.5)
		move_and_slide()
		return  # Sai do physics process durante knockback
	
	#if not [STATES.CHASE, STATES.ATTACKING].has(state):
		# Ajusta a altura baseado no chão
	super.adjust_height_to_ground(delta)
	
	# Verifica se é hora de mudar de estado
	if wander_controller.is_timeout and not is_in_knockback:
		set_random_state()
	
	# Executa a lógica de cada estado
	match state:
		STATES.IDLE:
			handle_idle_state(delta)
		STATES.WANDER:
			handle_wander_state(delta)
		STATES.CHASE:
			handle_chase_state(delta)
		STATES.SLEEPING:
			handle_sleeping_state(delta)
		STATES.AWAKING:
			handle_awaking_state(delta)
		STATES.ATTACKING:
			handle_attacking_state(delta)
	
	play_animations()
	move_and_slide()

func can_climb() -> bool:
	if not target_player:
		return false
	
	# Verifica se o jogador está significativamente acima
	return target_player.global_position.y < global_position.y - 50.0

func setup_wander_movement() -> void:
	# Atualiza a posição target do wanderController
	wander_controller.update_wander_position()
	wander_controller.is_moving_to_target = true
	
	#animated_sprite_2d.play("moving")
	update_sprite_direction(wander_controller.target_position.x > global_position.x)

func set_random_state() -> void:
	if state == STATES.AWAKING:
		return
	if state == STATES.SLEEPING and wander_controller.is_timeout:
		state = STATES.AWAKING
		return
		
	# Define uma duração aleatória para o próximo estado
	wander_controller.start_wander_time(randf_range(min_time_state, max_time_state))
	
	if state == STATES.IDLE:
		state = STATES.WANDER
	elif state == STATES.WANDER:
		state = STATES.IDLE
	else:
		# Escolhe um estado aleatório
		var available_states = [STATES.IDLE, STATES.WANDER]
		state = pick_random_state(available_states)
	
	# Configurações específicas para cada estado
	match state:
		STATES.WANDER:
			setup_wander_movement()

func update_attack_speed():
	var attk_speed = roundi(enemy_stats.attack_speed * 12)
	animated_sprite_2d.sprite_frames.set_animation_speed("attack_bite", attk_speed)
	animated_sprite_2d.sprite_frames.set_animation_speed("attack_slash", attk_speed)

func handle_idle_state(_delta: float) -> void:
	velocity = Vector2.ZERO
	position.y += sin(wander_controller.timer.time_left * 2) * 0.1
	#animated_sprite_2d.play("idle")
func handle_sleeping_state(_delta: float) -> void:
	velocity = Vector2.ZERO
	position.y += sin(wander_controller.timer.time_left * 2) * 0.1
	#animated_sprite_2d.play("sleeping")
func handle_awaking_state(_delta: float) -> void:
	velocity = Vector2.ZERO
	position.y += sin(wander_controller.timer.time_left * 2) * 0.1
	#animated_sprite_2d.play("awaking")
func handle_chase_state(delta: float) -> void:
	if is_in_knockback:
		return
	
	var chase_speed = enemy_stats.move_speed * 4
	
	if target_player and is_instance_valid(target_player):
		var direction = (target_player.global_position - global_position).normalized()
		var distance_to_player = global_position.distance_to(target_player.global_position)
		
		update_sprite_direction(direction.x > 0)
		update_enemy_hitbox_position(direction.x > 0)
		
		# Verifica se há parede à frente
		is_near_wall = false
		for raycast in wall_raycasts:
			raycast.force_raycast_update()
			if raycast.is_colliding():
				is_near_wall = true
				break
		
		# Mantém altura ideal em relação ao jogador
		#var target_y = target_player.global_position.y - ideal_flying_height
		#position.y = lerp(position.y, target_y, delta * height_smoothing)
		
		# Se houver parede e o jogador estiver acima, tenta subir
		if is_near_wall and target_player.global_position.y < global_position.y:
			velocity = Vector2(0, -climb_speed*2)
		else:
			# Movimento normal de perseguição (apenas horizontal)
			if distance_to_player <= min_attack_distance:
				velocity = Vector2.ZERO
			else:
				velocity.x = direction.x * chase_speed
		
		if distance_to_player <= min_attack_distance and can_attack and attack_timer.time_left <= 0:
			start_attack()
			return
	else:
		state = STATES.IDLE
func handle_attacking_state(delta: float) -> void:    
	if is_in_knockback or not is_attacking:
		state = STATES.CHASE
		return
	super.disable_enemy_hitbox(false)
	#get_tree().call_group("enemies", "_disable_enemy_hitbox", self)
	
	if target_player:
		# Mantém altura ideal durante o ataque
		var target_y = target_player.global_position.y - ideal_flying_height
		position.y = lerp(position.y, target_y, delta * height_smoothing)
		
		var direction = (target_player.global_position - global_position).normalized()
		velocity.x = 0.0
		update_enemy_hitbox_shape()
		update_sprite_direction(direction.x > 0)
		update_enemy_hitbox_position(direction.x > 0)
func handle_wander_state(_delta: float) -> void: 
	# Verifica colisão com paredes
	is_near_wall = false
	for raycast in wall_raycasts:
		raycast.force_raycast_update()
		if raycast.is_colliding():
			is_near_wall = true
			break
	
	# Se houver parede, inverte a direção
	if is_near_wall:
		wander_controller.target_position = wander_controller.start_position  # Volta para a posição inicial
		wander_controller.is_moving_to_target = not wander_controller.is_moving_to_target  # Inverte o movimento
	
	# Lógica normal de wander
	var current_target = wander_controller.target_position if wander_controller.is_moving_to_target else wander_controller.start_position
	var direction: Vector2 = (current_target - global_position).normalized()
	velocity = direction * enemy_stats.move_speed
	
	if global_position.distance_to(current_target) < 2.0:
		if wander_controller.is_moving_to_target:
			wander_controller.is_moving_to_target = false
		else:
			set_random_state()
	
	update_sprite_direction(direction.x > 0)

func start_attack():
	if is_in_knockback or not can_attack:
		return
	is_attacking = true
	state = STATES.ATTACKING
	can_attack = false
	current_attack_animation = AnimationUtils.pick_random_animation(attack_names)
	super.disable_enemy_hitbox(false)
	
func finish_attack():
	is_attacking = false
	can_attack = true
	state = STATES.CHASE
	super.disable_enemy_hitbox()

func update_enemy_hitbox_position(is_right: bool) -> void:
	var collision_shape: CollisionShape2D = enemy_hitbox.get_node("CollisionShape2D")
	if is_right:
		collision_shape.position = HITBOX_OFFSET
	else:
		collision_shape.position = Vector2(-HITBOX_OFFSET.x, HITBOX_OFFSET.y)
func update_enemy_hitbox_shape() -> void:
	var collision_shape: CollisionShape2D = enemy_hitbox.get_node("CollisionShape2D")
	if target_player and global_position.distance_to(target_player.global_position) < 30.0:
		# Jogador muito perto - usar hitbox maior e centralizado
		collision_shape.shape.size = close_range_hitbox_size
		collision_shape.position = close_range_offset
	elif animated_sprite_2d.animation == "attack_bite":
		collision_shape.shape.size = BITE_HITBOX_SIZE
		collision_shape.position = HITBOX_OFFSET
	elif animated_sprite_2d.animation == "attack_slash":
		collision_shape.shape.size = SLASH_HITBOX_SIZE
		collision_shape.position = HITBOX_OFFSET

func update_sprite_direction(moving_right: bool) -> void:
	animated_sprite_2d.flip_h = moving_right

func play_animations()-> void:
	if is_in_knockback:
		animated_sprite_2d.play("hurt")
		return
	match state:
		STATES.IDLE:
			animated_sprite_2d.play("idle")
		STATES.WANDER:
			animated_sprite_2d.play("moving")
		STATES.CHASE:
			animated_sprite_2d.play("moving")
		STATES.SLEEPING:
			animated_sprite_2d.play("sleeping")
		STATES.AWAKING:
			animated_sprite_2d.play("awaking")
		STATES.ATTACKING:
			animated_sprite_2d.play(current_attack_animation)

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "awaking":
		state = pick_random_state([STATES.IDLE, STATES.WANDER])
	if animated_sprite_2d.animation == "hurt":
		is_hurting = false
		is_invulnerable = false
	if animated_sprite_2d.animation.begins_with("attack"):
		finish_attack()
		if target_in_attack_range:  # Só ataca se ainda estiver no alcance
			super.hit_player(enemy_stats)
		else:
			# Se o player saiu do alcance, reseta o ataque mas mantém o cooldown
			can_attack = false
	if animated_sprite_2d.animation == "dying":
		queue_free()
func _on_target_player_entered(body: Node2D) -> void:
	target_player = body
	state = STATES.CHASE
	can_attack = true
	wander_controller.pause_timer()  # Pausa o temporizador de wander
func _on_target_player_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null
		# Volta para um estado aleatório (idle ou wander)
		var active_states = [STATES.IDLE, STATES.WANDER]
		state = pick_random_state(active_states)
		wander_controller.resume_timer()  # Retoma o temporizador
		
		# Configura o novo estado
		if state == STATES.WANDER:
			setup_wander_movement()
		else:
			state = STATES.IDLE
func _on_enemy_hitbox_area_entered(_area: Area2D) -> void:
	if target_player:
		target_in_attack_range = true
func _on_enemy_hitbox_area_exited(_area: Area2D) -> void:
	if target_player:
		target_in_attack_range = false
func _on_player_hitbox_area_entered() -> void:
	if target_player and not is_in_knockback and not is_invulnerable:
		var data = PlayerStats.calculate_attack_damage()
		is_hurting = true
		take_knockback(target_player.knockback_force, target_player.global_position)
		animated_sprite_2d.play("hurt")
		enemy_stats.on_take_damage(data.damage)
		float_damage_control.set_damage(data)
