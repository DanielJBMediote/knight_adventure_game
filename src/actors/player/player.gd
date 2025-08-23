# player.gd
class_name Player
extends CharacterBody2D

@onready var float_damage_control: FloatDamageControl = $FloatDamageControl
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CharacterCollisionShape
@onready var floor_down_raycast: RayCast2D = $FloorDownRayCast
@onready var floor_up_raycast: RayCast2D = $FloorUpRayCast
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var hit_flash_animation_player: AnimationPlayer = $HitFlashAnimationPlayer

@onready var player_area_hitbox: Area2D = $PlayerHitbox
@onready var player_area_hitbox_shape: CollisionShape2D = $PlayerHitbox/CollisionShape2D

@onready var player_area_hurtbox: Area2D = $PlayerHurtbox
@onready var player_area_hurtbox_shape: CollisionShape2D = $PlayerHurtbox/CollisionShape2D

const MAX_SPEED = 300.0 # Velocidade máxima do jogador
const ACCELERATION = 1400.0 # Aceleração do jogador
const FRICTION = 4000.0 # Atrito do jogador com relação ao solo
const GRAVITY = 2800.0 # Força da gravidade
const JUMP_FORCE = 1000.0 # Força do pulo
const CROUCH_TRANSITION_DURATION := 0.3 # Delay da transição igual ao tempo de animação
const MIN_SLIDE_ANGLE := 10.0  # Ângulo mínimo para considerar deslize em rampa
const ROTATION_SPEED: float = 10.0
const MAX_ATTACK_COUNT: int = 2
const MIN_DISTANCE_TO_FLOOR_UP_TO_CROUCH: float = 65.0

# Váriaveis responsável pela direções
var input_direction := 0.0
var face_direction: int = 1 # Direção do jogador

# Váriaveis responsável pelo pulo do personagem
var has_started_jump := false # valor para manipular as transições entre o Jump e o Fall
var has_played_peak_animation := false # Valor true quando o pulo atinge o a alturamaxima


# Distância entre o jogador e a plataforma
var distance_to_floor_down: float = 0.0 
var distance_to_floor_up: float = 0.0

# Váriaveis responsável por calcular o terreno/angula e rampas
var floor_angle: float = 0.0 # Angulo com relação ao chão
var slope_angle: float = 0.0 # Angulo da rampa
var slope_direction: float = 1.0 # 1 para Direita e -1 para Esquerda
var is_downhill: bool = false # Referência a rampa com relação a direção do personagem
var current_rotation: float = 0.0

const DASH_SPEED := 800.0
const DASH_DURATION := 0.2
const DASH_COOLDOWN := 0.5

@export var dash_node: PackedScene
var dash_timer: Timer
var can_dash := true
var air_dash_count := 1  # Quantidade de dash no ar permitido

# Váriaveis responsável pela transição do crouch
var is_crouch_transition_complete = false # Valor que manipula a transição de Crouch
 
@export var knockback_resistance: float = 1.0:
	set(value):
		knockback_resistance = value
		if PlayerStats:
			PlayerStats.set_knockback_resistance(value)

@export var knockback_force: float = 300.0:
	set(value):
		knockback_force = value
		if PlayerStats:
			PlayerStats.set_knockback_force(value)

var is_invulnerable: bool = false

# Váriaveis responsável pelos ataques/combos
var attack_count: int = 0 

var is_idle := false
var is_moving := false
var is_jumping := false
var is_attacking := false
var is_crouching := false
var is_rolling := false
var is_dashing := false
var is_sliding := false
var is_hurting := false
var is_falling := false

func _ready() -> void:
	add_to_group("player")
	
	if PlayerStats:
		PlayerStats.set_knockback_resistance(knockback_resistance)
		PlayerStats.set_knockback_force(knockback_force)
	
	floor_down_raycast.enabled = true
	floor_up_raycast.enabled = true
	
	dash_timer = Timer.new()
	dash_timer.wait_time = 0.10
	dash_timer.autostart = true
	dash_timer.timeout.connect(_on_dash_timeout)
	dash_timer.stop()
	add_child(dash_timer)
	
	float_damage_control.trigged_hit.connect(_on_take_damage)
	PlayerEvents.level_up.connect(_show_level_up_label)
	PlayerEvents.show_exp.connect(_show_experience)

func apply_damage_on_player(damage_data: DamageData, enemy_stats: EnemyStats):
	damage_data = PlayerStats.calculate_damage_taken(damage_data, enemy_stats.entity_level)
	float_damage_control.set_damage(damage_data)
	
	# Processa cada status effect
	for effect in damage_data.status_effects:
		if effect.active:
			PlayerEvents.add_status_effect.emit(effect)

func _on_dash_timeout():
	create_dash_effect()

func _physics_process(delta) -> void:
	if not is_sliding:
		current_rotation = lerp(current_rotation, 0.0, ROTATION_SPEED * delta)
		sprite_2d.rotation_degrees = current_rotation
	
	if is_hurting:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta * 0.5)
	
	# Se estiver dando dash, não aplica gravidade ou outras forças
	if not is_dashing:
		calculate_distance_to_floors()
		update_slopes_values()
		apply_gravity(delta)
		handle_actions()
		apply_movement(delta)
	else:
		# Durante o dash, apenas move e verifica colisões
		move_and_slide()
		# Verifica se colidiu com algo durante o dash
		if get_slide_collision_count() > 0:
			is_dashing = false
			is_invulnerable = false
			velocity = Vector2.ZERO
	
	update_animation()
	
	# Aplica o movimento normalmente se não estiver dando dash
	if not is_dashing:
		move_and_slide()

func update_slopes_values() -> void:
	floor_angle = 0.0
	slope_angle = 0.0
	if is_on_floor() and get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		var normal = collision.get_normal()
		floor_angle = rad_to_deg(normal.angle_to(Vector2.UP))
		slope_angle = rad_to_deg(acos(normal.dot(Vector2.UP)))
		#print("Floor Angle: ", floor_angle, " Slope Angle: ", slope_angle)
		slope_direction = sign(normal.x)

func calculate_distance_to_floors() -> void:
	floor_down_raycast.force_raycast_update()  # Atualiza o raycast manualmente
	
	if floor_down_raycast.is_colliding():
		distance_to_floor_down = floor_down_raycast.global_position.distance_to(floor_down_raycast.get_collision_point())
	else:
		distance_to_floor_down = 9999.0
	
	floor_up_raycast.force_raycast_update()
	if floor_up_raycast.is_colliding():
		distance_to_floor_up = floor_up_raycast.global_position.distance_to(floor_up_raycast.get_collision_point())
	else:
		distance_to_floor_up = 9999.0

func handle_actions() -> void:
	if Input.is_action_just_pressed("Test"):
		PlayerEvents.handle_event_add_experience(100)
	if is_on_floor():
		handle_actions_when_on_floor()
	else:
		handle_actions_when_on_air()
func handle_actions_when_on_floor() -> void:
	is_jumping = false
	is_dashing = false
	has_started_jump = false
	has_played_peak_animation = false
	air_dash_count = 1
	
	if not is_dashing:
		sprite_2d.modulate.a = 100
	
	# Evitar de se mover ao estar realizando o rolamento
	if not is_rolling and not is_attacking and not is_hurting:
		input_direction = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		# Atualiza face_direction apenas quando há input significativo
		if abs(input_direction) > 0.1:
			face_direction = sign(input_direction)
	
	is_moving = abs(input_direction) > 0.1
	is_idle = input_direction == 0 and not is_rolling and not is_crouching
	
	var not_roll_and_attack = not is_rolling and not is_attacking and not is_hurting
	
	var distance_to_up_available = distance_to_floor_up > MIN_DISTANCE_TO_FLOOR_UP_TO_CROUCH
	var can_jump = !is_jumping and !is_rolling and distance_to_up_available
	var can_crouch = not_roll_and_attack and !is_jumping and distance_to_up_available
	# Se remover o is_attacking do can_crouch da pra fazer faz um combo infinito kk
	var can_roll = not_roll_and_attack and !is_crouching and !is_jumping
	var can_attack = not_roll_and_attack
	var can_slide = not_roll_and_attack and is_on_floor()
	
	# Controle do slide baseado em input e inclinação
	if can_slide and Input.is_action_pressed("ui_down"):
		# Se estiver em rampa
		if abs(floor_angle) > MIN_SLIDE_ANGLE: 
			# Verifica se é rampa descendente (inclinação na mesma direção que o jogador está olhando)
			is_downhill = (face_direction > 0 and floor_angle < 0) or (face_direction < 0 and floor_angle > 0)
			is_sliding = is_downhill
		else:  # Se estiver no chão plano
			is_sliding = is_moving  # Só desliza se estiver em movimento
	else:
		is_sliding = false
	
	if can_dash and Input.is_action_just_pressed("dash"):
		is_dashing = true
		dash()
	
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = -JUMP_FORCE
		is_jumping = true
		has_started_jump = true
	
	if can_crouch and Input.is_action_just_pressed("crouch"):
		is_crouching = false if is_crouching else true
		if is_jumping:
			is_crouching = false
			
	if Input.is_action_just_pressed("roll"):
		if can_roll and PlayerStats.has_energy_to_roll():
			is_rolling = true
			PlayerEvents.handle_event_spent_energy(PlayerStats.energy_cost_to_roll)
		else:
			if not PlayerStats.has_energy_to_roll():
				PlayerEvents.energy_warning.emit()
	if can_attack:
		is_attacking = Input.get_action_strength("attack")
		handle_attack_combo_count()

func handle_actions_when_on_air() -> void:
	if not is_dashing and not is_attacking:
		input_direction = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		
	var can_attack = not is_attacking and not is_dashing
	
	if can_dash and Input.is_action_just_pressed("dash") and air_dash_count > 0:
		is_dashing = true
		air_dash_count -= 1
		dash()
	
	if can_attack:
		is_attacking = Input.get_action_strength("attack")
		handle_attack_combo_count()
	
	if is_crouching:
		is_crouching = false
func handle_attack_combo_count() -> void:
	attack_count += 1
	if attack_count > MAX_ATTACK_COUNT:
		attack_count = 1

func create_dash_effect() -> void:
	var dash_effect = dash_node.instantiate()
	dash_effect.set_property(position, sprite_2d.scale, sprite_2d.flip_h)
	get_tree().current_scene.add_child(dash_effect)
	
	var dash_effect_tween = create_tween()
	sprite_2d.modulate = Color(1, 1, 1, 0.7)
	dash_effect_tween.tween_property(sprite_2d, "modulate:a", 1.0, DASH_DURATION)
func dash():
	if not can_dash:
		return
	
	can_dash = false
	is_dashing = true
	
	# Ativa a invulnerabilidade durante o dash
	is_invulnerable = true
	
	# Configura a velocidade do dash
	velocity = Vector2(DASH_SPEED * face_direction, 0)
	
	# Cria efeitos de dash
	create_dash_effect()
	dash_timer.start()
	
	# Temporizador para duração do dash
	await get_tree().create_timer(DASH_DURATION).timeout
	
	# Finaliza o dash
	is_dashing = false
	is_invulnerable = false
	
	# Reduz a velocidade gradualmente após o dash
	var tween = create_tween()
	tween.tween_property(self, "velocity:x", 0, 0.2)
	
	# Cooldown do dash
	await get_tree().create_timer(DASH_COOLDOWN).timeout
	can_dash = true
	dash_timer.stop()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		is_falling = false
		velocity.y = min(velocity.y, 0)
func apply_movement(delta):
	# Atualiza face_direction apenas quando há input significativo
	if abs(input_direction) > 0.1:  # Threshold para joystick
		face_direction = sign(input_direction)
		
	if is_dashing:
		velocity.x = move_toward(velocity.x, ((MAX_SPEED * face_direction) * 1.5), ACCELERATION * delta)
		return
		
	# Verifica se deve deslizar apenas em rampas descendentes
	if is_sliding and not is_crouching:
		if is_downhill:  # Deslize em rampa
			var slide_power = MAX_SPEED * 1.5  # Mais rápido em rampas
			var slide_direction = slope_direction
			if not is_moving:
				slide_power = 0
			velocity.x = move_toward(velocity.x, slide_direction * slide_power, ACCELERATION * delta)
		else:  # Deslize no chão plano
			var slide_friction = FRICTION / 8
			velocity.x = move_toward(velocity.x, 0, slide_friction * delta)
		return
	
	# Se estiver atacando, para o player para executar o Ataque
	if is_attacking:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		return
	
	# Se estiver em Movimento e Agachado
	if is_moving and is_crouching:
		#face_direction = input_direction
		velocity.x = move_toward(velocity.x, face_direction * (MAX_SPEED/4), ACCELERATION * delta)
		return

	# Se estiver apenas Agachado
	if is_crouching:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		return
	
	# Se estiver parado e executar o Rolling
	if not is_moving and is_rolling:
		velocity.x = move_toward(velocity.x, MAX_SPEED * face_direction, ACCELERATION * delta)
		return
		
	# Se estiver apenas em Movimento
	if is_moving:
		# Caso atingir a velocidade maxima, vou fazer alguma coisa aqui
		if velocity.x == MAX_SPEED * face_direction:
			pass
		
		velocity.x = move_toward(velocity.x, face_direction * MAX_SPEED, ACCELERATION * delta)
		return
	
	velocity.x = move_toward(velocity.x, input_direction * (MAX_SPEED), FRICTION * delta)

func take_knockback(knock_force: float, attacker_position: Vector2):
	
	# Pequena pausa dramática (0.1 segundos)
	Engine.time_scale = 0.1
	await get_tree().create_timer(0.02, true).timeout  # Timer real, não afetado pelo time_scale
	Engine.time_scale = 1.0
	
	if is_invulnerable:
		return
	
	is_hurting = true
	is_invulnerable = true
	
	# 1. Calcula a direção do knockback (afastando do inimigo)
	var knockback_direction = (global_position - attacker_position).normalized()
	knockback_direction.y = -0.5  # Adiciona um pouco para cima
	
	# 2. Atualiza a face_direction para olhar para o inimigo
	face_direction = -1 if attacker_position.x < global_position.x else 1
	
	# 3. Aplica o knockback
	velocity = knockback_direction * knock_force * knockback_resistance

func update_animation():
	# Define a direção da animação uma única vez
	var anim_direction = "Right" if face_direction == 1 else "Left"
	
	# 1. Animações prioritárias (que interrompem outras)
	if is_hurting:
		hit_flash_animation_player.play("hit_flash")
		return
	
	if is_dashing:
		animation_player.play("Dash" + anim_direction)
		return
	
	if is_attacking:
		handle_attack_animation(anim_direction)
		return
	
	if is_rolling:
		animation_player.play("Rolling" + anim_direction)
		return
	
	# 2. Animações de movimento aéreo
	if not is_on_floor():
		handle_air_animations(anim_direction)
		return
	
	# 3. Animações de movimento no chão
	handle_ground_animations(anim_direction)

# Funções auxiliares para organizar a lógica
func handle_attack_animation(anim_direction: String):
	if is_crouching:
		animation_player.play("CrouchAttack" + anim_direction)
	else:
		animation_player.play("Attack" + anim_direction + "_" + str(attack_count))

func handle_air_animations(anim_direction: String):
	if velocity.y < 0 and has_started_jump:
		if animation_player.current_animation != "JumpStart" + anim_direction:
			animation_player.play("JumpStart" + anim_direction)
	elif velocity.y >= 0 and not has_played_peak_animation:
		animation_player.play("JumpTransition" + anim_direction)
		has_played_peak_animation = true
	elif velocity.y > 100:
		animation_player.play("Falling" + anim_direction)

func handle_ground_animations(anim_direction: String):
	# Reseta rotação quando no chão
	current_rotation = lerp(current_rotation, 0.0, ROTATION_SPEED * get_physics_process_delta_time())
	sprite_2d.rotation_degrees = current_rotation
	
	if is_sliding and velocity.x != 0 and not is_crouching:
		handle_sliding_animation(anim_direction)
		return
	
	if is_crouching:
		handle_crouch_animations(anim_direction)
		return
	
	# Movimento básico no chão
	if is_moving and abs(velocity.x) > 0:
		animation_player.play("Runing" + anim_direction)
	elif is_idle:
		if not animation_player.current_animation.begins_with("Crouch"):
			animation_player.play("Idle" + anim_direction)

func handle_sliding_animation(anim_direction: String):
	animation_player.play("Sliding" + anim_direction)
	if is_downhill:
		var target_rotation = -floor_angle * 0.5
		current_rotation = lerp(current_rotation, target_rotation, ROTATION_SPEED * get_physics_process_delta_time())
		sprite_2d.rotation_degrees = current_rotation + (15 * slope_direction)
		collision_shape.rotation_degrees = current_rotation + (20 * slope_direction)

func handle_crouch_animations(anim_direction: String):
	if not is_crouch_transition_complete:
		animation_player.play("CrouchingTransition" + anim_direction)
		await get_tree().create_timer(CROUCH_TRANSITION_DURATION).timeout
		is_crouch_transition_complete = true
		return
	
	if is_moving:
		animation_player.play("CrouchWalking" + anim_direction)
	else:
		animation_player.play("Crouching" + anim_direction)

func update_colision_shape_when_crouch() -> void:
	if is_crouching:
		collision_shape.shape.size = Vector2(64, 100)
		collision_shape.position.y = -22
	else:
		collision_shape.shape.size = Vector2(64, 145)
		collision_shape.position.y = -42
	pass

func _on_animation_player_animatioan_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("Attack") or anim_name.begins_with("CrouchAttack"):
		is_attacking = false
	if anim_name.begins_with("Rolling"):
		is_rolling = false
	if anim_name.begins_with("CrouchingTransition"):
		is_crouch_transition_complete = true
	if anim_name.begins_with("Dash"):
		is_dashing = false
	if anim_name.begins_with("Stun"):
		is_hurting = false
		is_invulnerable = false

func _on_hit_flash_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "hit_flash":
		is_hurting = false
		is_invulnerable = false
		is_rolling = false

func _on_take_damage(damage: float)-> void:
	PlayerEvents.handle_event_spent_health(damage)

func _show_level_up_label(level: int):
	var float_label: FloatLabel = preload("res://src/ui/float_label.tscn").instantiate()
	float_label.text = "Level Up!"
	
	#float_label.add_theme_font_size_override("font_size", 32)
	float_label.modulate = Color.LIME_GREEN
	add_child(float_label)
	float_label.position.y = float_damage_control.position.y

func _show_experience(amount: float):
	#PlayerEvents.handle_event_add_experience(amount)
	var float_label_scene = load("res://src/ui/float_label.tscn")
	var float_label: FloatLabel = float_label_scene.instantiate()
	float_label.modulate = Color.ORANGE
	float_label.add_theme_font_size_override("font_size", 20)
	float_label.text = str("+", roundi(amount), " EXP")
	add_child(float_label)
	float_label.position.y = float_damage_control.position.y
