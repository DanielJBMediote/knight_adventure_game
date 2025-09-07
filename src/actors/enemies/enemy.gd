class_name Enemy
extends CharacterBody2D

const FRICTION := 1000.0

enum ENEMY_TYPES { FLYING, TERRESTRIAL }

@export var enemy_type: ENEMY_TYPES
@export var enemy_stats: EnemyStats

@export var wall_detection_height := 0.0
@export var wall_detection_distance := 32.0  # Distância para detectar paredes
@export var min_floor_distance := 10.0  # Distância para detectar a plataforma
@export var min_attack_distance := 100.0  # Distância para iniciar o ataque
@export var attack_cooldown := 1.5  # Tempo entre ataques
@export var attack_names: Array[String] = []  # Nomes das animações de ataque
@export var knockback_force: float = 300.0
@export var knockback_resistance: float = 1.0
@export var climb_speed := 80.0  # Velocidade de subida
@export var time_dead_before_free := 1.0
@export var knockback_air_force := -1.0

@export var loot_categories: Array[Item.CATEGORY] = []

var floor_raycast: RayCast2D
var wall_raycasts: Array[RayCast2D] = []
var is_near_wall := false

var target_player: Player
var distance_to_floor := 0.0

var attack_timer: Timer
var can_attack := true
var target_in_attack_range := false  # É manipulado pelo EnemyHitbox
var distance_to_player := 0.0
var current_attack_animation := ""

var knockback_timer: Timer
var is_in_knockback := false
var is_invulnerable := false

var is_attacking := false
var is_dead := false
var is_hurting := false

var dead_timer: Timer

func _init() -> void:
	pass

func _ready() -> void:
	setup_attack_timer()
	setup_dead_timer()
	setup_raycasts()


func setup_dead_timer() -> void:
	dead_timer = Timer.new()
	dead_timer.wait_time = time_dead_before_free
	dead_timer.one_shot = true
	dead_timer.timeout.connect(_on_dead_timer_timeout)

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
	var collision: CollisionShape2D = get_node("EnemyHitbox").get_node("CollisionShape2D")
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


func hit_player():
	var is_player_in_close_range = target_player and distance_to_player < 30.0  # Aqui considera o player ocupando o mesmo lugar do Mob
	var can_hit_player = can_attack and (target_in_attack_range or is_player_in_close_range)

	if can_hit_player and not (target_player.is_rolling or target_player.is_dashing):
		var damage_data: DamageData = enemy_stats.calculate_base_attack_damage()

		target_player.apply_damage_on_player(damage_data, enemy_stats)
		target_player.take_knockback(knockback_force, global_position)

		attack_timer.start(attack_cooldown)
		can_attack = false


func take_hit_with_knockback() -> bool:
	if is_dead:
		return false

	var float_damage_control: FloatDamageControl = get_node_or_null("FloatDamageControl")

	if enemy_stats == null or float_damage_control == null:
		printerr("EnemyStats or FloatDamageControl is nulls, check tree.")
		return false

	if target_player and not is_in_knockback and not is_invulnerable:
		var damage_data = PlayerStats.calculate_attack_damage()
		is_hurting = true
		enemy_stats.on_take_damage(damage_data.damage)
		float_damage_control.set_damage(damage_data)
		return damage_data.is_knockback_hit

	return false


func _on_attack_cooldown_finished():
	can_attack = true
	if target_player:
		target_in_attack_range = global_position.distance_to(target_player.global_position) <= min_attack_distance


func _on_dead_timer_timeout() -> void:
	queue_free()


func _on_dead(exp: float) -> void:
	is_dead = true
	drop_loots()
	PlayerStats.add_experience(exp)
	if time_dead_before_free >= 1.0:
		add_child(dead_timer)
		dead_timer.start()


func drop_loots() -> void:
	if loot_categories.is_empty():
		return

	var drop_zone = get_tree().get_first_node_in_group("items_dropped_zone")
	if !drop_zone:
		printerr("Nenhuma zona de drop encontrada!")
		return

	# Gera os itens de loot
	var loot_items = LootManager.generate_loot_for_enemy(enemy_stats, loot_categories)

	# Dropa os itens
	var spread_distance = 10.0
	var random_offset = Vector2(randf_range(-spread_distance, spread_distance), randf_range(-spread_distance, spread_distance)		)
	for i in range(enemy_stats.num_drops):
		if i < loot_items.size():
			
			var item_resource: Item = loot_items[i]
			var item_scene = preload("res://src/gameplay/items/item_body.tscn")
			var item_instance: ItemBody = item_scene.instantiate()
			item_instance.item_resource = item_resource

			if item_instance.can_spawn():
				# Posiciona o item com algum espalhamento
				item_instance.position = global_position + random_offset
				drop_zone.add_child(item_instance)
	
	for i in range(enemy_stats.amount_coins):
		var coin_scene = preload("res://src/gameplay/items/coin/coin_body.tscn")
		var coin_instance: CoinBody = coin_scene.instantiate()
		coin_instance.position = global_position + random_offset
		coin_instance.coin = Coin.new()
		drop_zone.add_child(coin_instance)
