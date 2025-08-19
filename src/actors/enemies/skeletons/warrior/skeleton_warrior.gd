class_name SkeletonWarrior
extends TerrestrialEnemy

@onready var float_Damage_control: FloatDamageControl = $FloatDamageControl
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var enemy_hitbox: Area2D = $EnemyHitbox
@onready var enemy_stats: EnemyStats = $EnemyStats
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

@onready var debug_label: Label = $DebugLabel

# Controllers
@onready var wander_controller: WanderController = $WanderController
@onready var enemy_control_ui: EnemyControlUI = $EnemyControlUI

@export var min_time_state: float = 5.0
@export var max_time_state: float = 10.0
@export var navigation_update_interval := 0.2

const SPRITE_OFFSET_FIX := 10
const HITBOX_POSITION := Vector2(72, -60)
const HITBOX_OFFSET := Vector2(72, -60)

enum STATES {IDLE, WANDER, CHASE, ATTACKING}
var state: STATES = STATES.IDLE

var is_first_attack_after_chase := false
var navigation_timer := 0.0

func _ready() -> void:
	super._ready()
	#disable_enemy_hitbox()
	pick_random_state([STATES.IDLE, STATES.WANDER])
	wander_controller.start_position = global_position
	wander_controller.enemy_type = Enemy.ENEMY_TYPES.FLYING
	attack_names = ["attack_1", "attack_2", "attack_3"]
	update_attack_speed()
	
	enemy_stats.trigged_dead.connect(_on_skeleton_death)
		
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 10.0
	navigation_agent.avoidance_enabled = true
	
	enemy_hitbox.area_entered.connect(_on_enemy_hitbox_area_entered)
	enemy_hitbox.area_exited.connect(_on_enemy_hitbox_area_exited)

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
		return # Sai do physics process durante knockback
	
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
		STATES.ATTACKING:
			handle_attacking_state(delta)
	
	super.apply_gravity(delta)
	play_animations()
	move_and_slide()

func update_navigation_path() -> void:
	if navigation_timer <= 0:
		var target_pos = (target_player.global_position if state == STATES.CHASE
						else wander_controller.target_position)
		navigation_agent.target_position = target_pos
		navigation_timer = navigation_update_interval
	navigation_timer -= get_physics_process_delta_time()

func apply_navigation_movement(speed_multiplier: float = 1.0) -> void:
	if navigation_agent.is_navigation_finished():
		velocity.x = 0
		return
	
	var next_path_pos = navigation_agent.get_next_path_position()
	var direction = Vector2(
		sign(next_path_pos.x - global_position.x),
		0
	)
	velocity.x = direction.x * enemy_stats.move_speed * speed_multiplier

func play_animations() -> void:
	if is_in_knockback or is_hurting:
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
	navigation_agent.target_position = wander_controller.target_position
	update_sprite_direction(wander_controller.target_position.x > global_position.x)

func update_sprite_direction(is_right: bool) -> void:
	animated_sprite_2d.flip_h = !is_right
	if animated_sprite_2d.animation == "run":
		if !is_right:
			animated_sprite_2d.offset.x = - SPRITE_OFFSET_FIX
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
	
	if target_player and is_instance_valid(target_player):
		distance_to_player = global_position.distance_to(target_player.global_position)
		var target_direction = super.get_direction_to(target_player.global_position, global_position)
		
		# Atualiza o caminho de navegação
		update_navigation_path()
		apply_navigation_movement(3.0)
		
		# Atualiza direção do sprite
		update_sprite_direction(target_direction == Vector2.RIGHT)
		update_enemy_hitbox_position(target_direction == Vector2.RIGHT)
		
		# Verifica se há parede à frente
		is_near_wall = false
		var wall_direction = 0
		for raycast in wall_raycasts:
			raycast.force_raycast_update()
			if super.is_colliding_with_wall(raycast):
				is_near_wall = true
				wall_direction = sign(raycast.target_position.x) # 1 para direita, -1 para esquerda
				break
		
		# Pulo na parede se estiver perto de uma e movendo na mesma direção
		if is_near_wall and can_wall_jump and is_on_floor():
			var move_direction = sign(velocity.x)
			if move_direction != 0 and move_direction == wall_direction:
				super.perform_wall_jump(move_direction, enemy_stats.move_speed * 2)
		
		# Lógica de ataque
		if distance_to_player <= min_attack_distance:
			velocity.x = 0 # Mantém apenas o movimento vertical
			
			if can_attack and attack_timer.time_left <= 0:
				start_attack()
	else:
		state = STATES.IDLE

func handle_attacking_state(_delta: float) -> void:
	if is_in_knockback or not is_attacking:
		state = STATES.CHASE
		return
	#super.disable_enemy_hitbox(false)
	
	var move_direction = super.get_direction_to(target_player.global_position, global_position)
	velocity = Vector2.ZERO
	update_enemy_hitbox_shape()
	update_sprite_direction(move_direction == Vector2.RIGHT)
	update_enemy_hitbox_position(move_direction == Vector2.RIGHT)
func handle_wander_state(delta: float) -> void:
	# Atualiza o caminho de navegação
	update_navigation_path()
	
	# Verifica se chegou ao destino ou se esta perto dele
	var is_close_or_arrived = navigation_agent.is_navigation_finished() or navigation_agent.distance_to_target() < 40
	if is_close_or_arrived:
		set_random_state()
		return
	# Aplica movimento
	apply_navigation_movement()
	
	# Verifica colisão com paredes
	var wall_direction = 0
	is_near_wall = false
	for raycast in wall_raycasts:
		raycast.force_raycast_update()
		if super.is_colliding_with_wall(raycast):
			is_near_wall = true
			wall_direction = sign(raycast.target_position.x) # 1 para direita, -1 para esquerda
			break
	
	# Se houver parede, inverte a direção
	if is_near_wall and can_wall_jump and is_on_floor():
		var move_direction = sign(velocity.x)
		if move_direction != 0 and move_direction == wall_direction:
			super.perform_wall_jump(move_direction, enemy_stats.move_speed * 2)

	# Atualiza direção do sprite
	var next_pos = navigation_agent.get_next_path_position()
	#update_sprite_direction(next_pos.x > global_position.x)

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
	#super.disable_enemy_hitbox(false)
func finish_attack():
	is_attacking = false
	can_attack = true
	state = STATES.CHASE
	is_first_attack_after_chase = false
	#super.disable_enemy_hitbox()

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
		enemy_control_ui.hide()

func _on_enemy_hurtbox_player_hitbox_entered() -> void:
	if target_player and not is_in_knockback and not is_dead:
		var data = PlayerStats.calculate_attack_damage()
		super.take_knockback(target_player.knockback_force, target_player.global_position)
		enemy_stats.on_take_damage(data.damage)
		float_Damage_control.set_damage(data)

func _on_skeleton_death():
	animated_sprite_2d.play("dead")
	super._on_dead()

func _on_enemy_hitbox_area_entered(area: Area2D) -> void:
	if target_player:
		target_in_attack_range = true
		can_attack = true
		print("Player in Range")
		
func _on_enemy_hitbox_area_exited(area: Area2D) -> void:
	if target_player:
		target_in_attack_range = false
		can_attack = false
		print("Player out of Range")
