class_name Enemy
extends CharacterBody2D

const FRICTION := 1000.0

enum ENEMY_TYPES {FLYING, TERRESTRIAL}

@export var float_damage_control: FloatDamageControl
@export var enemy_hitbox: Area2D
@export var enemy_hurtbox: Area2D
@export var target_zone: Area2D
@export var navigation_agent: NavigationAgent2D
@export var wander_controller: WanderController
@export var enemy_control_ui: EnemyControlUI
@export var enemy_stats: EnemyStats

@export var enemy_type: ENEMY_TYPES

## Distância para detectar plataformas acima
@export var wall_detection_height := 0.0
## Distância para detectar paredes
@export var wall_detection_distance := 32.0
## Distância para detectar a plataforma
@export var min_floor_distance := 10.0
## Distância para iniciar o ataque
@export var min_attack_distance := 100.0
## Tempo entre ataques
@export var attack_cooldown := 1.5
## Nomes das animações de ataque
@export var attack_names: Array[String] = []
@export var knockback_force: float = 300.0
@export var knockback_resistance: float = 1.0
## Velocidade de subida
@export var climb_speed := 80.0
## Tempo de estado "Morto" antes de ser removido da Àrvore
@export var time_dead_before_free := 1.0
@export var knockback_air_force := -1.0

@export var min_time_state: float = 5.0
@export var max_time_state: float = 10.0
@export var navigation_update_interval := 0.2

@export var loot_categories: Array[Item.CATEGORY] = []

var floor_raycast: RayCast2D
var wall_raycasts: Array[RayCast2D] = []
var is_near_wall := false

var target_player: Player
var distance_to_floor := 0.0

var navigation_timer := 0.0

var attack_timer: Timer
var can_attack := true
var is_hitbox_on_target := false
var target_in_attack_range := false
var distance_to_player := 0.0
var current_attack_animation := ""

var knockback_timer: Timer
var is_in_knockback := false
var is_invulnerable := false

var is_attacking := false
var is_dead := false
var is_hurting := false

var face_direction := 1
var direction_str: String:
	get: return "Right" if face_direction == 1 else "Left"

func _ready() -> void:
	setup_attack_timer()
	setup_raycasts()

	if wander_controller:
		wander_controller.start_position = global_position

	if not navigation_agent:
		navigation_agent = NavigationAgent2D.new()
		add_child(navigation_agent)

	# Configuração do NavigationAgent
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 10.0
	navigation_agent.avoidance_enabled = true

	if float_damage_control and not float_damage_control.hitted.is_connected(_on_hitted):
		float_damage_control.hitted.connect(_on_hitted)
	
	if enemy_hitbox and not enemy_hitbox.area_entered.is_connected(_on_enemy_hitbox_area_entered):
		enemy_hitbox.area_entered.connect(_on_enemy_hitbox_area_entered)
	if enemy_hitbox and not enemy_hitbox.area_exited.is_connected(_on_enemy_hitbox_area_exited):
		enemy_hitbox.area_exited.connect(_on_enemy_hitbox_area_exited)

	if target_zone and not target_zone.area_entered.is_connected(_on_target_zone_area_entered):
		target_zone.area_entered.connect(_on_target_zone_area_entered)
	if target_zone and not target_zone.area_exited.is_connected(_on_target_zone_area_exited):
		target_zone.area_exited.connect(_on_target_zone_area_exited)


func setup_attack_timer() -> void:
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_finished)
	add_child(attack_timer)


func setup_raycasts() -> void:
	# Cria raycasts para detecção de paredes à esquerda e direita
	for i in 2:
		var raycast = RayCast2D.new()
		raycast.enabled = true
		raycast.collision_mask = 2
		raycast.collide_with_areas = true
		raycast.collide_with_bodies = true

		var direction = -1 if i == 0 else 1
		raycast.target_position = Vector2(wall_detection_distance * direction, 0)
		raycast.position = Vector2(0, wall_detection_height)

		add_child(raycast)
		wall_raycasts.append(raycast)

	floor_raycast = RayCast2D.new()
	floor_raycast.enabled = true
	floor_raycast.collision_mask = 2
	floor_raycast.collide_with_areas = true
	floor_raycast.collide_with_bodies = true
	floor_raycast.target_position = Vector2(0, 128)
	floor_raycast.position = Vector2.ZERO
	add_child(floor_raycast)


func get_distance_to_floor() -> float:
	floor_raycast.force_raycast_update()

	if floor_raycast.is_colliding():
		var distance = floor_raycast.global_position.distance_to(floor_raycast.get_collision_point())
		return distance
	return 9999.0


func get_distance_to_player() -> float:
	if target_player:
		return global_position.distance_to(target_player.global_position)
	else:
		return 0.0


func disable_enemy_hitbox(disabled: bool = false) -> void:
	var collision: CollisionShape2D = enemy_hitbox.get_node("CollisionShape2D")
	collision.set_deferred("disabled", disabled)


func pick_random_state(states_list: Array):
	return states_list[randi() % states_list.size()]


func get_direction_to(positionA: Vector2, positionB: Vector2):
	var direction = (positionA - positionB).normalized()
	return Vector2.RIGHT if direction.x > 0 else Vector2.LEFT


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

	disable_enemy_hitbox()

	# Calcula direção do knockback
	var knockback_direction = (global_position - attacker_position).normalized()
	if enemy_type == ENEMY_TYPES.FLYING:
		knockback_direction.y = knockback_air_force # Mais para cima para um efeito melhor

	# Aplica o knockback
	velocity = knockback_direction * knock_force * knockback_resistance

	# Configura timer para recuperação
	if knockback_timer:
		knockback_timer.stop()
	else:
		knockback_timer = Timer.new()
		add_child(knockback_timer)
		knockback_timer.timeout.connect(_on_knockback_finished)

	knockback_timer.start(0.3) # Duração do knockback


func hit_player():
	var is_player_in_close_range = target_player and distance_to_player < 30.0 # Aqui considera o player ocupando o mesmo lugar do Mob
	var can_hit_player = can_attack and (target_in_attack_range or is_player_in_close_range)

	if can_hit_player and not (target_player.is_rolling or target_player.is_dashing):
		var damage_data = enemy_stats.calculate_base_attack_damage()

		target_player.apply_damage_on_player(damage_data, enemy_stats)
		target_player.take_knockback(knockback_force, global_position)

		attack_timer.start(attack_cooldown)
		can_attack = false


func take_hit() -> bool:
	if is_dead:
		return false

	if not float_damage_control or not enemy_stats:
		return false

	if target_player and not is_in_knockback and not is_invulnerable:
		is_hurting = true
		var damage_data = PlayerStats.calculate_attack_damage()
		enemy_stats.calculate_damage_taken(damage_data)
		float_damage_control.update_damage(damage_data)
		return damage_data.is_knockback_hit

	return false


func _on_hitted(damage: float) -> void:
	enemy_stats.update_health(-damage)


func _on_knockback_finished():
	is_in_knockback = false
	is_hurting = false
	is_invulnerable = false
	can_attack = true


func _on_enemy_hitbox_area_entered(area: Area2D) -> void:
	if target_player and area.collision_layer == 1024:
		is_hitbox_on_target = true


func _on_enemy_hitbox_area_exited(area: Area2D) -> void:
	if target_player and area.collision_layer == 1024:
		is_hitbox_on_target = false


func _on_target_zone_area_entered(area: Area2D) -> void:
	if target_player and area.collision_layer == 1024:
		can_attack = true
		target_in_attack_range = true


func _on_target_zone_area_exited(area: Area2D) -> void:
	if target_player and area.collision_layer == 1024:
		can_attack = false
		target_in_attack_range = false
		# is_attacking = false

func _on_attack_cooldown_finished():
	can_attack = true
	if target_player:
		target_in_attack_range = global_position.distance_to(target_player.global_position) <= min_attack_distance


func _on_dead_timer_timeout() -> void:
	queue_free()


func _on_enemy_stats_died(exp_amount: float) -> void:
	is_dead = true
	drop_loots()
	PlayerStats.add_experience(exp_amount)
	if time_dead_before_free >= 1.0:
		_setup_dead_timer()


func _setup_dead_timer() -> void:
	var dead_timer = Timer.new()
	dead_timer.wait_time = time_dead_before_free
	dead_timer.one_shot = true
	dead_timer.timeout.connect(_on_dead_timer_timeout)
	add_child(dead_timer)
	dead_timer.start()


func drop_loots() -> void:
	if loot_categories.is_empty():
		return

	# Gera os itens de loot
	var loot_items = LootManager.generate_loot_for_enemy(enemy_stats, loot_categories)
	var map = GameManager.current_map
	
	# Dropa os itens
	var spread_distance = 10.0
	var random_offset = Vector2(randf_range(-spread_distance, spread_distance), randf_range(-spread_distance, spread_distance))
	for i in range(enemy_stats.num_drops):
		if i < loot_items.size():
			var item_resource: Item = loot_items[i]
			var item_scene = preload("res://src/gameplay/items/item_body.tscn")
			var item_instance: ItemBody = item_scene.instantiate()
			item_instance.item_resource = item_resource

			if item_instance.can_spawn():
				item_instance.position = global_position + random_offset
				map.add_child(item_instance)

	for i in range(enemy_stats.amount_coins):
		var coin_scene = preload("res://src/gameplay/items/coin/coin_body.tscn")
		var coin_instance: CoinBody = coin_scene.instantiate()
		coin_instance.position = global_position + random_offset
		coin_instance.coin = Coin.new()
		map.add_child(coin_instance)
