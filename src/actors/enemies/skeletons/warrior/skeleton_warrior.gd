class_name SkeletonWarrior
extends TerrestrialEnemy

@onready var float_Damage_control: FloatDamageControl = $FloatDamageControl
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var enemy_hitbox: Area2D = $EnemyHitbox
@onready var enemy_stats: EnemyStats = $EnemyStats

# Controllers
@onready var wander_controller: WanderController = $WanderController
@onready var enemy_control_ui: EnemyControlUI = $EnemyControlUI

@export var min_time_state: float = 5.0
@export var max_time_state: float = 10.0

const SPRITE_OFFSET_FIX := 10
const HITBOX_POSITION := Vector2(72, -60)
const HITBOX_OFFSET := Vector2(72, -60)

enum STATES { IDLE, WANDER, CHASE, ATTACKING }
var state: STATES = STATES.IDLE

var is_first_attack_after_chase := false

var body_timer_on_dead: Timer

func _ready() -> void:
	super._ready()
	get_tree().call_group("enemies", "_disable_enemy_hitbox", self)
	pick_random_state([STATES.IDLE, STATES.WANDER])
	wander_controller.start_position = global_position
	attack_names = ["attack_1", "attack_2", "attack_3"]
	update_attack_speed()
	
	enemy_stats.trigged_dead.connect(_on_skeleton_death)
	
	body_timer_on_dead = Timer.new()
	body_timer_on_dead.one_shot = true
	body_timer_on_dead.timeout.connect(_on_body_timer_on_dead_timeout)
	add_child(body_timer_on_dead)

func update_attack_speed():
	var attk_speed = roundi(enemy_stats.attack_speed * 12)
	animated_sprite_2d.sprite_frames.set_animation_speed("attack_1", attk_speed)
	animated_sprite_2d.sprite_frames.set_animation_speed("attack_2", attk_speed)
	animated_sprite_2d.sprite_frames.set_animation_speed("attack_3", attk_speed)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
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
			handle_idle_state(delta)
		STATES.WANDER:
			handle_wander_state(delta)
		STATES.CHASE:
			handle_chase_state(delta)
		STATES.ATTACKING:
			handle_attacking_state(delta)
	
	#if Input.is_action_just_pressed("jump"):
		#velocity.y = -jump_force
	super.apply_gravity(delta)
	play_animations()
	move_and_slide()

func play_animations()-> void:
	if is_in_knockback:
		animated_sprite_2d.play("hurt")
		return
	match state:
		STATES.IDLE:
			animated_sprite_2d.play("idle")
		STATES.WANDER:
			animated_sprite_2d.play("walk")
		STATES.CHASE:
			if distance_to_player <= min_attack_distance:
				animated_sprite_2d.play("idle")
			else:
				animated_sprite_2d.play("run")
		STATES.ATTACKING:
			animated_sprite_2d.play(current_attack_animation)

func set_random_state() -> void:
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
func setup_wander_movement() -> void:
	wander_controller.update_wander_position()
	wander_controller.is_moving_to_target = true
	
	var move_direction = super.get_direction_to(wander_controller.target_position, global_position)
	update_sprite_direction(move_direction == Vector2.RIGHT)

func update_sprite_direction(is_right: bool) -> void:
	animated_sprite_2d.flip_h = !is_right
	if animated_sprite_2d.animation == "run":
		if !is_right:
			animated_sprite_2d.offset.x = -SPRITE_OFFSET_FIX
		else:
			animated_sprite_2d.offset.x = SPRITE_OFFSET_FIX
	else:
		animated_sprite_2d.offset.x = 0

func update_enemy_hitbox_position(is_right: bool) -> void:
	var collision_shape: CollisionShape2D = enemy_hitbox.get_node("CollisionShape2D")
	if is_right:
		collision_shape.position = HITBOX_OFFSET
	else:
		collision_shape.position = Vector2(-HITBOX_OFFSET.x, HITBOX_OFFSET.y)
func update_enemy_hitbox_shape() -> void:
	pass

func handle_idle_state(_delta: float) -> void:
	velocity = Vector2.ZERO
	position.y += sin(wander_controller.timer.time_left * 2) * 0.1
func handle_chase_state(delta: float) -> void:
	if is_in_knockback:
		return
	
	var chase_speed = enemy_stats.move_speed * 2
	if target_player and is_instance_valid(target_player):
		var direction = (target_player.global_position - global_position).normalized()
		distance_to_player = super.get_distance_to_player()
		
		update_sprite_direction(direction.x > 0)
		update_enemy_hitbox_position(direction.x > 0)
		
		# Verifica se há parede à frente
		is_near_wall = false
		for raycast in wall_raycasts:
			raycast.force_raycast_update()
			if super.is_colliding_with_wall(raycast):
				is_near_wall = true
				break
		
		# Movimento normal de perseguição
		if distance_to_player <= min_attack_distance:
			velocity = Vector2.ZERO
		else: 
			# Aplica movimento horizontal normalmente
			velocity.x = direction.x * chase_speed
			
			# Se houver parede e puder pular, executa o pulo
			if is_near_wall and can_wall_jump and is_on_floor():
				super.perform_wall_jump(direction.x, chase_speed)
			
			# Mantém a gravidade ativa para rampas
			super.apply_gravity(delta)
		
		if distance_to_player <= min_attack_distance and can_attack and attack_timer.time_left <= 0:
			start_attack()
			return
	else:
		state = STATES.IDLE

func handle_attacking_state(_delta: float) -> void:	
	if is_in_knockback or not is_attacking:
		state = STATES.CHASE
		return
	super.disable_enemy_hitbox(false)
	
	var move_direction = super.get_direction_to(target_player.global_position, global_position)
	velocity = Vector2.ZERO
	update_enemy_hitbox_shape()
	update_sprite_direction(move_direction == Vector2.RIGHT)
	update_enemy_hitbox_position(move_direction == Vector2.RIGHT)
func handle_wander_state(_delta: float) -> void: 
	# Verifica colisão com paredes
	is_near_wall = false
	for raycast in wall_raycasts:
		raycast.force_raycast_update()
		if is_colliding_with_wall(raycast):
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
	var move_direction = Vector2.RIGHT if direction.x > 0 else Vector2.LEFT
	update_sprite_direction(move_direction == Vector2.RIGHT)

func start_attack():
	if is_in_knockback and not can_attack:
		return
	is_attacking = true
	state = STATES.ATTACKING
	can_attack = false
	if is_first_attack_after_chase:
		current_attack_animation = "run_and_attack"
		is_first_attack_after_chase = false
	else:
		current_attack_animation = AnimationUtils.pick_random_animation(attack_names)
	super.disable_enemy_hitbox(false)
func finish_attack():
	is_attacking = false
	can_attack = true
	state = STATES.CHASE
	is_first_attack_after_chase = false
	super.disable_enemy_hitbox()

func _on_detection_zone_trigger_player_entered(player: CharacterBody2D) -> void:
	target_player = player
	state = STATES.CHASE
	can_attack = true
	wander_controller.pause_timer()
	is_first_attack_after_chase = true
func _on_detection_zone_trigger_player_exited(player: CharacterBody2D) -> void:
	if player == target_player:
		target_player = null
		var active_states = [STATES.IDLE, STATES.WANDER]
		state = pick_random_state(active_states)
		wander_controller.resume_timer()
		
		# Configura o novo estado
		if state == STATES.WANDER:
			setup_wander_movement()
		else:
			state = STATES.IDLE

func _on_animated_sprite_2d_animation_finished() -> void:
	var animation_name = animated_sprite_2d.animation
	if animation_name.begins_with("attack") or animation_name == "run_and_attack":
		finish_attack()
		if target_in_attack_range:
			super.hit_player(enemy_stats)
		else:
			can_attack = false
	if animation_name == "dead":
		enemy_control_ui.visible = false
		body_timer_on_dead.start(10.0)

func _on_enemy_hitbox_body_entered(body: Node2D) -> void:
	if target_player and target_player == body:
		target_in_attack_range = true
func _on_enemy_hitbox_body_exited(body: Node2D) -> void:
	if target_player and target_player == body:
		target_in_attack_range = false

func _on_enemy_hurtbox_player_hitbox_entered() -> void:
	if target_player and not is_in_knockback and not is_dead:
		var data = PlayerStats.calculate_attack_damage()
		super.take_knockback(target_player.knockback_force, target_player.global_position)
		enemy_stats.on_take_damage(data.damage)
		float_Damage_control.set_damage(data)

func _on_skeleton_death():
	super._on_dead()
	animated_sprite_2d.play("dead")
	
func _on_body_timer_on_dead_timeout():
	queue_free()
