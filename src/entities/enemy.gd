class_name Enemy
extends CharacterBody2D

@onready var float_label: PackedScene = preload("res://src/gui/float_label.tscn")

const FRICTION := 1000.0

enum ENEMY_TYPES { FLYING, TERRESTRIAL }
@export var enemy_type: ENEMY_TYPES

@export var floor_raycast_offset := Vector2(0, 0) # Offset do raycast da plataforma
@export var wall_raycast_offset := Vector2(0, 0)  # Offset do raycast de parede
@export var wall_detection_distance := 100.0  # Distância para detectar paredes
@export var min_floor_distance := 10.0 # Distância para detectar a plataforma
@export var min_attack_distance := 100.0  # Distância para iniciar o ataque
@export var attack_cooldown := 1.5  # Tempo entre ataques
@export var attack_names: Array[String]= [] # Nomes das animações de ataque
@export var knockback_force: float = 300.0
@export var knockback_resistance: float = 1.0
@export var climb_speed := 80.0  # Velocidade de subida

var floor_raycast: RayCast2D
var wall_raycasts: Array[RayCast2D] = []
var is_near_wall := false

var target_player: Player
var distance_to_floor := 0.0

var attack_timer: Timer
var can_attack := true
var target_in_attack_range := false
var distance_to_player := 0.0
var current_attack_animation := ""

var knockback_timer: Timer
var is_in_knockback := false
var is_invulnerable := false

var is_attacking := false
var is_dead := false
var is_hurting := false

func _ready() -> void:
	setup_attack_timer()
	setup_raycasts()

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
		raycast.target_position = Vector2(wall_detection_distance * (-1 if i == 0 else 1), 15)
		raycast.position = wall_raycast_offset * (-1 if i == 0 else 1)
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

func _disable_enemy_hitbox(current: Enemy)-> void:
	if current == self:
		var hitbox = current.get_node("EnemyHitbox") as Area2D
		if hitbox:
			hitbox.get_node("CollisionShape2D").disabled = not is_attacking

func pick_random_state(states_list: Array):
	return states_list[randi() % states_list.size()]

func get_direction_to(positionA: Vector2, positionB: Vector2):
	var direction = (positionA - positionB).normalized()
	return Vector2.RIGHT if direction.x > 0 else Vector2.LEFT

func hit_player(enemy_stats: EntityStats):
	var is_player_in_close_range = target_player and global_position.distance_to(target_player.global_position) < 30.0
	var can_hit_player = can_attack and (target_in_attack_range or is_player_in_close_range)
	
	if can_hit_player:
		var data: DamageData = enemy_stats.calculate_damage()
		
		target_player.apply_damage(data)
		target_player.take_knockback(knockback_force, global_position)
		
		attack_timer.start(attack_cooldown)
		can_attack = false

func _on_attack_cooldown_finished():
	can_attack = true
	if target_player:
		target_in_attack_range = global_position.distance_to(target_player.global_position) <= min_attack_distance

func _on_dead(amount: float) -> void:
	is_dead = true
	PlayerEvents.add_experience(amount)
	
	var float_exp: FloatLabel = float_label.instantiate()
	float_exp.modulate = Color.ORANGE
	float_exp.position = Vector2(position.x, position.y - 250)
	float_exp.text = str("+", roundi(amount), " Exp")
	add_child(float_exp)
	
