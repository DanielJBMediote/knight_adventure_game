class_name Bat
extends FlyingEnemy

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var enemy_hitbox: Area2D = $EnemyHitbox
@onready var enemy_hurtbox: EnemyHurtbox = $EnemyHurtbox
@onready var float_damage_control: FloatDamageControl = $FloatDamageControl
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var hit_flash_animation: AnimationPlayer = $HitFlashAnimation

@onready var debug_label: Label = $DebugLabel

# Controllers
@onready var wander_controller: WanderController = $WanderController
@onready var enemy_control_ui: EnemyControlUI = $EnemyControlUI

@export var min_time_state: float = 5.0
@export var max_time_state: float = 10.0
@export var close_range_hitbox_size := Vector2(80, 80)  # Tamanho maior para quando o jogador está muito perto
@export var close_range_offset := Vector2(0, 0)  # Centralizado quando muito perto

@export var navigation_update_interval := 0.2
var navigation_timer := 0.0

const BITE_HITBOX_SIZE := Vector2(96, 64)
const SLASH_HITBOX_SIZE := Vector2(96, 112)
const HITBOX_OFFSET := Vector2(48, 24)
const MAX_WALL_RETRIES := 3

enum STATES { IDLE, WANDER, CHASE, SLEEPING, AWAKING, ATTACKING }
var state: STATES = STATES.IDLE
var wall_retry_count := 0

func _ready() -> void:
	super._ready()
	pick_random_state([STATES.SLEEPING])
	wander_controller.start_position = global_position
	wander_controller.enemy_type = Enemy.ENEMY_TYPES.FLYING
	update_attack_speed()
	
	# Configuração do NavigationAgent
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 10.0
	navigation_agent.avoidance_enabled = true
	
	enemy_stats.trigged_dead.connect(_on_enemy_stats_trigged_dead)
	enemy_hitbox.area_entered.connect(_on_enemy_hitbox_area_entered)
	enemy_hitbox.area_exited.connect(_on_enemy_hitbox_area_exited)
	enemy_hurtbox.player_hitbox_entered.connect(_on_player_hurtbox_entered)
	hit_flash_animation.animation_finished.connect(_on_hit_flash_animation_animation_finished)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	update_navigation_path()
	
	distance_to_floor = get_distance_to_floor()
	
	# Aplica desaceleração durante o knockback
	if is_in_knockback:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta * 0.5)
		move_and_slide()
		return  # Sai do physics process durante knockback
	
	# Verifica se é hora de mudar de estado
	if wander_controller.is_timeout and not is_in_knockback:
		set_random_state()
	
	# Executa a lógica de cada estado
	match state:
		STATES.IDLE:
			debug_label.text = str("State: IDLE\n", "Position:", position)
			handle_idle_state(delta)
		STATES.WANDER:
			debug_label.text = str("State: WANDER\n", "Position:", position, "\nTarget Pos (Wander): ", wander_controller.target_position)
			handle_wander_state(delta)
		STATES.CHASE:
			debug_label.text = str("State: CHASE\n", "Position:", position, "\nTarget Pos (Player): ", target_player.position)
			handle_chase_state(delta)
		STATES.SLEEPING:
			handle_sleeping_state(delta)
		STATES.AWAKING:
			handle_awaking_state(delta)
		STATES.ATTACKING:
			debug_label.text = str("State: ATTACKING\n", "Position:", position, "\nTarget Pos (Player): ", target_player.position)
			handle_attacking_state(delta)
	
	play_animations()
	move_and_slide()

# Atualização do caminho em intervalos regulares
func update_navigation_path() -> void:
	if navigation_timer <= 0:
		var target_pos = (target_player.global_position if state == STATES.CHASE 
						else wander_controller.target_position)
		navigation_agent.target_position = target_pos
		navigation_timer = navigation_update_interval
	navigation_timer -= get_physics_process_delta_time()

func apply_navigation_movement(speed_multiplier: float = 1.0, delta: float = 0.0) -> void:
	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return
	
	var next_path_pos = navigation_agent.get_next_path_position()
	var direction = (next_path_pos - global_position).normalized()
	velocity = direction * enemy_stats.move_speed * speed_multiplier
	
	super.adjust_flight_height(delta)

func setup_wander_movement() -> void:
	wander_controller.update_wander_position()
	wander_controller.is_moving_to_target = true
	navigation_agent.target_position = wander_controller.target_position
	update_sprite_direction(wander_controller.target_position.x > global_position.x)

func set_random_state() -> void:
	if state == STATES.AWAKING:
		return
	if state == STATES.SLEEPING and wander_controller.is_timeout:
		state = STATES.AWAKING
		return
		
	wander_controller.start_wander_time(randf_range(min_time_state, max_time_state))
	
	match state:
		STATES.IDLE:
			state = STATES.WANDER
			setup_wander_movement()
		STATES.WANDER:
			state = STATES.IDLE
		_:
			state = pick_random_state([STATES.IDLE, STATES.WANDER])
			if state == STATES.WANDER:
				setup_wander_movement()
func update_attack_speed():
	var attk_speed = roundi(enemy_stats.attack_speed * 12)
	animated_sprite_2d.sprite_frames.set_animation_speed("attack_bite", attk_speed)
	animated_sprite_2d.sprite_frames.set_animation_speed("attack_slash", attk_speed)

func handle_idle_state(_delta: float) -> void:
	velocity = Vector2.ZERO
	position.y += sin(wander_controller.timer.time_left * 2) * 0.1
func handle_sleeping_state(_delta: float) -> void:
	velocity = Vector2.ZERO
	position.y += sin(wander_controller.timer.time_left * 2) * 0.1
	#animated_sprite_2d.play("sleeping")
func handle_awaking_state(_delta: float) -> void:
	velocity = Vector2.ZERO
	position.y += sin(wander_controller.timer.time_left * 2) * 0.1
func handle_attacking_state(delta: float) -> void:    
	if is_in_knockback or not is_attacking:
		state = STATES.CHASE
		return
	#super.disable_enemy_hitbox(false)
	
	# Mantém altura ideal durante o ataque
	if target_player:
		var target_y = target_player.global_position.y - ideal_flying_height
		position.y = lerp(position.y, target_y, delta * height_smoothing)
		
		var direction = (target_player.global_position - global_position).normalized()
		velocity = Vector2.ZERO
		adjust_flight_height(delta)
		update_enemy_hitbox_shape()
		update_sprite_direction(direction.x > 0)
		update_enemy_hitbox_position(direction.x > 0)

func handle_wander_state(delta: float) -> void:
	# Verifica se chegou ao destino
	if navigation_agent.is_navigation_finished():
		# Tempo mínimo em cada ponto antes de mudar
		if wander_controller.is_timeout:
			set_random_state()
		else:
			velocity = Vector2.ZERO
			return
	
	# Movimento normal de wander
	var next_path_pos = navigation_agent.get_next_path_position()
	var direction = (next_path_pos - global_position).normalized()
	velocity = direction * enemy_stats.move_speed
	
	apply_navigation_movement(1.0, delta)
	update_sprite_direction(direction.x > 0)
	
	# Ajuste de altura para wander (flutuação suave)
	var target_height = wander_controller.start_position.y - ideal_flying_height
	var height_variation = sin(Time.get_ticks_msec() * 0.001) * 20.0  + 10.0
	global_position.y = lerp(global_position.y, target_height + height_variation, delta * height_smoothing)
	
	var current_target = wander_controller.target_position if wander_controller.is_moving_to_target else wander_controller.start_position
	
	if global_position.distance_to(current_target) < 2.0:
		if wander_controller.is_moving_to_target:
			wander_controller.is_moving_to_target = false
		else:
			set_random_state()
func handle_chase_state(delta: float) -> void:
	if is_in_knockback:
		return
	
	if target_player and is_instance_valid(target_player):
		distance_to_player = global_position.distance_to(target_player.global_position)
		update_sprite_direction(
			navigation_agent.get_next_path_position().x > global_position.x
		)
		apply_navigation_movement(3.0, delta)
		if distance_to_player <= min_attack_distance:
			velocity = Vector2.ZERO
			if can_attack and attack_timer.time_left <= 0:
				start_attack()
		else:
			# O movimento horizontal já é tratado no _physics_process
			pass
	else:
		state = STATES.IDLE

func start_attack():
	if is_in_knockback or not can_attack:
		return
	is_attacking = true
	state = STATES.ATTACKING
	can_attack = false
	current_attack_animation = AnimationUtils.pick_random_animation(attack_names)
	#super.disable_enemy_hitbox(false)

func finish_attack():
	is_attacking = false
	can_attack = true
	state = STATES.CHASE

func update_enemy_hitbox_position(is_right: bool) -> void:
	var collision_shape: CollisionShape2D = enemy_hitbox.get_node("CollisionShape2D")
	if is_right:
		collision_shape.position = HITBOX_OFFSET
	else:
		collision_shape.position = Vector2(-HITBOX_OFFSET.x, HITBOX_OFFSET.y)
func update_enemy_hitbox_shape() -> void:
	var collision_shape: CollisionShape2D = enemy_hitbox.get_node("CollisionShape2D")
	if target_player and distance_to_player < 30.0:
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
	if is_in_knockback or is_hurting:
		#animated_sprite_2d.play("hurt")
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
			super.hit_player()
			can_attack = true
		else:
			# Se o player saiu do alcance, reseta o ataque mas mantém o cooldown
			can_attack = false
	if animated_sprite_2d.animation == "dying":
		enemy_control_ui.hide()

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

func _on_enemy_hitbox_area_entered(area: Area2D) -> void:
	if target_player:
		target_in_attack_range = true
		can_attack = true

func _on_enemy_hitbox_area_exited(area: Area2D) -> void:
	if target_player:
		target_in_attack_range = false
		can_attack = false

func _on_player_hurtbox_entered() -> void:
	self.hit_flash_animation.play("hit_flash")
	if self.target_player and take_hit_with_knockback():
		animated_sprite_2d.play("hurt")
		take_knockback(target_player.knockback_force, target_player.global_position)

func _on_enemy_stats_trigged_dead(exp_amount: float) -> void:
	animated_sprite_2d.play("dying")
	super._on_dead(exp_amount)


func _on_hit_flash_animation_animation_finished(_anim_name: StringName) -> void:
	is_hurting = false
	is_invulnerable = false
