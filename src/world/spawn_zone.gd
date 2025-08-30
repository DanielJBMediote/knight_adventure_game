class_name SpawnZone
extends Node2D

@onready var trigger_player_zone: Area2D = $TriggerPlayerZone
@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_cooldown_timer: Timer = $WaveCooldownTimer
@onready var smoke_effects: AnimatedSprite2D = $SmokeEffects


@export var min_enemy_numbers: int = 1
@export var max_enemy_numbers: int = 3
@export var enemy_scenes: Array[PackedScene]
@export var spawn_interval: float = 1.0
@export var initial_spawn_delay: float = 0.5
@export var random_interval_variation: float = 0.3

# Configurações da wave
@export var wave_cooldown_time: float = 10.0
@export var infinite_waves: bool = false
@export var max_waves: int = 0

# Configurações da fumaça
@export var smoke_animation_name: String = "spawn_1"
@export var smoke_duration: float = 0.5  # Duração da animação de fumaça

# Array para os Marker2D de spawn points
var spawn_points: Array[Marker2D] = []

var player: Player = null
var enemies: Array[Enemy] = []
var has_spawned: bool = false
var enemies_to_spawn: int = 0
var current_spawn_count: int = 0
var current_wave: int = 0
var is_in_cooldown: bool = false
var player_was_in_zone: bool = false

# Fila para inimigos aguardando spawn com fumaça
var pending_spawns: Array[Dictionary] = []

func _ready() -> void:
	trigger_player_zone.body_entered.connect(_on_body_entered)
	trigger_player_zone.body_exited.connect(_on_body_exited)
	
	# Conecta o sinal da animação de fumaça
	if smoke_effects:
		smoke_effects.visible = false
		smoke_effects.animation_finished.connect(_on_smoke_effects_animation_finished)
	else:
		push_warning("SmokeEffects node not found!")
	
	# Coleta todos os Marker2D filhos como spawn points
	collect_spawn_points()
	
	# Initialize timers
	initialize_timers()

func initialize_timers() -> void:
	# Spawn Timer
	if not spawn_timer:
		spawn_timer = Timer.new()
		add_child(spawn_timer)
		spawn_timer.name = "SpawnTimer"
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.one_shot = true
	
	# Wave Cooldown Timer
	if not wave_cooldown_timer:
		wave_cooldown_timer = Timer.new()
		add_child(wave_cooldown_timer)
		wave_cooldown_timer.name = "WaveCooldownTimer"
	wave_cooldown_timer.timeout.connect(_on_wave_cooldown_timeout)
	wave_cooldown_timer.one_shot = true

func collect_spawn_points() -> void:
	spawn_points.clear()
	
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
			print("Found spawn point at: ", child.global_position)
	
	if spawn_points.is_empty():
		push_warning("No spawn points (Marker2D) found in SpawnZone!")
		var default_marker = Marker2D.new()
		default_marker.global_position = global_position
		add_child(default_marker)
		spawn_points.append(default_marker)

func get_random_spawn_point() -> Marker2D:
	if spawn_points.is_empty():
		return null
	return spawn_points[randi() % spawn_points.size()]

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body is Player:
		player = body
		player_was_in_zone = true
		
		if not is_in_cooldown and not has_spawned:
			start_wave()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body == player:
		player = null
		player_was_in_zone = false

func start_wave() -> void:
	if enemy_scenes.is_empty() or spawn_points.is_empty():
		return
	
	if max_waves > 0 and current_wave >= max_waves:
		print("Maximum waves (", max_waves, ") reached")
		return
	
	current_wave += 1
	has_spawned = true
	is_in_cooldown = false
	enemies_to_spawn = randi_range(min_enemy_numbers, max_enemy_numbers)
	current_spawn_count = 0
	
	print("Starting wave ", current_wave, " with ", enemies_to_spawn, " enemies")
	start_spawn_timer(initial_spawn_delay)

func start_spawn_timer(delay: float) -> void:
	var actual_delay = delay
	if random_interval_variation > 0:
		actual_delay += randf_range(-random_interval_variation, random_interval_variation)
		actual_delay = max(0.1, actual_delay)
	
	spawn_timer.start(actual_delay)

func _on_spawn_timer_timeout() -> void:
	if current_spawn_count < enemies_to_spawn:
		# Prepara o spawn com fumaça
		prepare_spawn_with_smoke()
		
		if current_spawn_count < enemies_to_spawn:
			start_spawn_timer(spawn_interval)
	else:
		spawn_timer.stop()
		print("Finished spawning wave ", current_wave)

func prepare_spawn_with_smoke() -> void:
	if enemy_scenes.is_empty() or spawn_points.is_empty() or not player:
		return
	
	var enemy_scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy_instance: Enemy = enemy_scene.instantiate()
	
	if not enemy_instance or not enemy_instance is Enemy:
		push_error("Failed to instantiate enemy scene")
		return
	
	var spawn_point = get_random_spawn_point()
	if not spawn_point:
		push_error("No spawn points available")
		enemy_instance.queue_free()
		return
	
	# Configura a instância do inimigo (mas ainda não adiciona à cena)
	enemy_instance.global_position = spawn_point.global_position
	enemy_instance.visible = false  # Inimigo invisível inicialmente
	#enemy_instance.target_player = player
	
	if enemy_instance.has_signal("tree_exiting"):
		enemy_instance.tree_exiting.connect(_on_enemy_died.bind(enemy_instance))
	
	# Adiciona à fila de spawns pendentes
	var spawn_data = {
		"enemy": enemy_instance,
		"spawn_point": spawn_point,
		"wave": current_wave
	}
	pending_spawns.append(spawn_data)
	
	# Inicia a animação de fumaça
	start_smoke_effect(spawn_point.global_position)
	
	print("Preparing to spawn enemy ", current_spawn_count + 1, " of ", enemies_to_spawn, " in wave ", current_wave)

func start_smoke_effect(smoke_position: Vector2) -> void:
	if smoke_effects:
		smoke_effects.global_position = smoke_position
		smoke_effects.visible = true
		smoke_effects.play(smoke_animation_name)
	else:
		# Se não há efeito de fumaça, spawna o inimigo imediatamente
		_on_smoke_effects_animation_finished()

func _on_smoke_effects_animation_finished() -> void:
	if pending_spawns.is_empty():
		return
	
	# Pega o próximo spawn da fila
	var spawn_data = pending_spawns.pop_front()
	var enemy_instance: Enemy = spawn_data["enemy"]
	var spawn_point: Marker2D = spawn_data["spawn_point"]
	
	# Adiciona o inimigo à cena
	var entities_zone = get_tree().get_first_node_in_group("entities_zone")
	if entities_zone:
		entities_zone.add_child(enemy_instance)
		enemy_instance.visible = true  # Torna o inimigo visível
		enemies.append(enemy_instance)
		
		current_spawn_count += 1
		print("Spawned enemy ", current_spawn_count, " of ", enemies_to_spawn, " in wave ", current_wave)
	else:
		push_error("Entities zone not found!")
		enemy_instance.queue_free()

func complete_spawn_immediately() -> void:
	# Completa todos os spawns pendentes imediatamente (útil se o efeito de fumaça falhar)
	while not pending_spawns.is_empty():
		_on_smoke_effects_animation_finished()

func _on_enemy_died(enemy: Enemy) -> void:
	if enemy in enemies:
		enemies.erase(enemy)
		print("Enemy died, remaining: ", enemies.size(), " in wave ", current_wave)
	
	if enemies.is_empty() and current_spawn_count >= enemies_to_spawn:
		on_wave_completed()

func on_wave_completed() -> void:
	print("Wave ", current_wave, " completed!")
	has_spawned = false
	
	# Limpa qualquer spawn pendente
	pending_spawns.clear()
	
	if infinite_waves or (max_waves == 0 or current_wave < max_waves):
		start_wave_cooldown()
	else:
		print("All waves completed! Total waves: ", current_wave)

func start_wave_cooldown() -> void:
	is_in_cooldown = true
	wave_cooldown_timer.start(wave_cooldown_time)
	print("Wave cooldown started: ", wave_cooldown_time, " seconds until next wave")

func _on_wave_cooldown_timeout() -> void:
	is_in_cooldown = false
	print("Wave cooldown finished")
	
	if player_was_in_zone and player:
		start_wave()
	else:
		print("Player not in zone, waiting for player to return")

func reset_spawn_zone() -> void:
	has_spawned = false
	is_in_cooldown = false
	current_spawn_count = 0
	enemies_to_spawn = 0
	current_wave = 0
	enemies.clear()
	pending_spawns.clear()
	spawn_timer.stop()
	wave_cooldown_timer.stop()
	player_was_in_zone = false
	
	# Para a animação de fumaça
	if smoke_effects:
		smoke_effects.stop()
		smoke_effects.visible = false
	
	print("Spawn zone completely reset")

func stop_spawning() -> void:
	spawn_timer.stop()
	wave_cooldown_timer.stop()
	is_in_cooldown = true
	current_spawn_count = 0
	enemies_to_spawn = 0
	pending_spawns.clear()
	
	if smoke_effects:
		smoke_effects.stop()
		smoke_effects.visible = false
	
	print("Spawning stopped and cooldown paused")

func resume_spawning() -> void:
	if is_in_cooldown and wave_cooldown_timer.time_left > 0:
		print("Resuming cooldown: ", wave_cooldown_timer.time_left, " seconds remaining")
		wave_cooldown_timer.start(wave_cooldown_timer.time_left)
	elif not has_spawned and player_was_in_zone:
		print("Resuming spawning - starting new wave")
		start_wave()

func get_spawn_progress() -> Dictionary:
	return {
		"wave": current_wave,
		"total_waves": max_waves if max_waves > 0 else (999 if infinite_waves else current_wave),
		"enemies_total": enemies_to_spawn,
		"enemies_spawned": current_spawn_count,
		"enemies_remaining": enemies_to_spawn - current_spawn_count,
		"enemies_active": enemies.size(),
		"pending_spawns": pending_spawns.size(),
		"in_cooldown": is_in_cooldown,
		"cooldown_remaining": wave_cooldown_timer.time_left if is_in_cooldown else 0.0
	}

func add_spawn_point(position: Vector2) -> void:
	var new_marker = Marker2D.new()
	new_marker.global_position = position
	add_child(new_marker)
	spawn_points.append(new_marker)

func clear_spawn_points() -> void:
	for marker in spawn_points:
		if is_instance_valid(marker):
			marker.queue_free()
	spawn_points.clear()

func _draw() -> void:
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, 10, Color.RED)
		
		for marker in spawn_points:
			if is_instance_valid(marker):
				var local_pos = marker.position
				draw_circle(local_pos, 5, Color.GREEN)
				draw_line(Vector2.ZERO, local_pos, Color.YELLOW, 1)
