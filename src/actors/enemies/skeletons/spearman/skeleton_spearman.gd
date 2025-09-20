class_name SkeletonSpearman
extends TerrestrialEnemy

@onready var hit_flash_animation: AnimationPlayer = $HitFlashAnimation
@onready var animation_player: AnimationPlayer = $AnimationPlayer

enum STATES {IDLE, WANDER, CHASE, ATTACKING}
var state: STATES = STATES.IDLE

var is_first_attack_after_chase := false

func _ready() -> void:
	super._ready()
	pick_random_state([STATES.IDLE, STATES.WANDER])
	attack_names = ["Attack_1", "Attack_2"]

	if enemy_stats and not enemy_stats.died.is_connected(_on_enemy_stats_died):
		enemy_stats.died.connect(_on_enemy_stats_died)
	if enemy_hurtbox and not enemy_hurtbox.area_entered.is_connected(_on_enemy_hurtbox_area_entered):
		enemy_hurtbox.area_entered.connect(_on_enemy_hurtbox_area_entered)
	if hit_flash_animation and not hit_flash_animation.animation_finished.is_connected(_on_hit_flash_animation_animation_finished):
		hit_flash_animation.animation_finished.connect(_on_hit_flash_animation_animation_finished)


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
			handle_idle_state(delta)
		STATES.WANDER:
			handle_wander_state(delta)
		STATES.CHASE:
			handle_chase_state(delta)
		STATES.ATTACKING:
			handle_attacking_state(delta)

	if state == STATES.ATTACKING:
		enemy_hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	else:
		enemy_hitbox.get_node("CollisionShape2D").set_deferred("disabled", false)


	super.apply_gravity(delta)
	play_animations()
	move_and_slide()


func update_navigation_path() -> void:
	if navigation_timer <= 0:
		var target_pos = target_player.global_position if state == STATES.CHASE else wander_controller.target_position
		navigation_agent.target_position = target_pos
		navigation_timer = navigation_update_interval
	navigation_timer -= get_physics_process_delta_time()


func apply_navigation_movement(speed_multiplier: float = 1.0) -> void:
	if navigation_agent.is_navigation_finished():
		velocity.x = 0
		return

	var next_path_pos = navigation_agent.get_next_path_position()
	var direction = Vector2(sign(next_path_pos.x - global_position.x), 0)
	velocity.x = direction.x * enemy_stats.move_speed * speed_multiplier


func play_animations() -> void:
	if is_in_knockback or is_hurting:
		animation_player.play("Hurt_" + direction_str)
		return
	match state:
		STATES.IDLE:
			animation_player.play("Idle_" + direction_str)
		STATES.WANDER:
			animation_player.play("Walk_" + direction_str)
		STATES.CHASE:
			if distance_to_player <= min_attack_distance:
				animation_player.play("Idle_" + direction_str)
			else:
				animation_player.play("Run_" + direction_str)
		STATES.ATTACKING:
			animation_player.play(current_attack_animation + "_" + direction_str)


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
	face_direction = sign(wander_controller.target_position.x - global_position.x)


func handle_idle_state(_delta: float) -> void:
	velocity = Vector2.ZERO
	position.y += sin(wander_controller.timer.time_left * 2) * 0.1


func handle_chase_state(_delta: float) -> void:
	if is_in_knockback:
		return

	if target_player and is_instance_valid(target_player):
		distance_to_player = global_position.distance_to(target_player.global_position)
		var target_direction = super.get_direction_to(target_player.global_position, global_position)

		# Atualiza o caminho de navegação
		update_navigation_path()
		apply_navigation_movement(3.0)

		# Atualiza direção do sprite
		face_direction = sign(target_direction.x)

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

	var move_direction = super.get_direction_to(target_player.global_position, global_position)
	velocity = Vector2.ZERO
	face_direction = sign(move_direction.x)


func handle_wander_state(_delta: float) -> void:
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


func start_attack():
	if is_in_knockback and not can_attack:
		return
	is_attacking = true
	state = STATES.ATTACKING
	can_attack = false
	if is_first_attack_after_chase:
		current_attack_animation = "Run_And_Attack"
		is_first_attack_after_chase = false
	else:
		current_attack_animation = AnimationUtils.pick_random_animation(attack_names)


func finish_attack():
	is_attacking = false
	can_attack = true
	state = STATES.CHASE
	is_first_attack_after_chase = false


func _on_enemy_hurtbox_area_entered(area2D: Area2D) -> void:
	if target_player and area2D.collision_layer == 512:
		hit_flash_animation.play("hit_flash")
		var is_knockback = take_hit()
		if is_knockback:
			take_knockback(target_player.knockback_force, target_player.global_position)

func _on_hit_flash_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name == "hit_flash":
		is_hurting = false
		is_invulnerable = false

func _on_enemy_stats_died(exp_amount: float) -> void:
	animation_player.play("Dead_" + direction_str)
	super._on_enemy_stats_died(exp_amount)


func _on_detection_zone_player_entered(player: Player) -> void:
	target_player = player
	state = STATES.CHASE
	can_attack = true
	wander_controller.pause_timer()
	is_first_attack_after_chase = true


func _on_detection_zone_player_exited(player: Player) -> void:
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


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name.contains("Attack"):
		finish_attack()
		if target_in_attack_range:
			super.hit_player()
		else:
			can_attack = false
	if anim_name.contains("Hurt"):
		is_hurting = false
		is_invulnerable = false
	if anim_name.contains("Dead"):
		enemy_control_ui.hide()
