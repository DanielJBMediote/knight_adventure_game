class_name CoinBody
extends RigidBody2D

@onready var coin_texture: Sprite2D = $CoinTexture
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collect_zone: Area2D = $CollectZone

@export var bounce_factor: float = 0.3
@export var friction: float = 0.1

@export var min_spawn_force: float = 50.0
@export var max_spawn_force: float = 200.0
@export var min_spawn_torque: float = 1.0
@export var max_spawn_torque: float = 10.0

@export var coin: Coin
@export var lifespan: float = 60.0  # Tempo até desaparecer
@export var bounce_duration: float = 0.5  # Duração de cada bounce

var interact_text = LocalizationManager.get_ui_text("collect")

var player: Player = null
var float_tween: Tween
var is_on_floor: bool = false
var floor_check_timer: Timer


func _ready():
	setup_coin_texture()
	# Configura a animação baseada no tamanho da moeda
	setup_animation()
	# Configura a física do item
	setup_physics()
	# Aplica força inicial aleatória
	apply_random_force()
	# Conecta os sinais das áreas
	collect_zone.body_entered.connect(_on_collect_zone_body_entered)
	collect_zone.body_exited.connect(_on_collect_zone_body_exited)

	# Cria timer para verificar quando a moeda parou no chão
	floor_check_timer = Timer.new()
	add_child(floor_check_timer)
	floor_check_timer.wait_time = 0.5
	floor_check_timer.timeout.connect(_check_if_on_floor)
	floor_check_timer.start()

	# Some após um tempo se não for coletada
	await get_tree().create_timer(lifespan).timeout
	if float_tween:
		float_tween.kill()
	queue_free()


func set_coin(new_coin: Coin) -> void:
	self.coin = new_coin

func _check_if_on_floor() -> void:
	if is_on_floor:
		return

	# Verifica se a moeda está praticamente parada
	if linear_velocity.length() < 5.0 and abs(angular_velocity) < 0.1:
		is_on_floor = true
		if floor_check_timer:
			floor_check_timer.stop()
			floor_check_timer.queue_free()

		# Inicia a animação de flutuação agora que está no chão
		start_float_animation()


func _input(event: InputEvent) -> void:
	if not player:
		return
	if event.is_action_pressed("interact"):
		collect()


func setup_physics() -> void:
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = bounce_factor
	physics_material_override.rough = friction
	physics_material_override.absorbent = false


func setup_animation() -> void:
	if coin and animation_player:
		match coin.coin_size:
			Coin.SIZE.SMALL:
				animation_player.play("coin_small")
			Coin.SIZE.NORMAL:
				animation_player.play("coin")
			Coin.SIZE.BIG:
				animation_player.play("coin_huge")
			_:
				animation_player.play("coin")


func start_float_animation() -> void:
	# Para a física para a moeda não se mover mais
	freeze = true

	# Cria um tween para fazer a moeda flutuar suavemente
	float_tween = create_tween()
	float_tween.set_loops()

	# Move para cima
	float_tween.tween_property(self, "position:y", position.y - 16.0, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(
		Tween.TRANS_SINE
	)

	# Move para baixo (volta à posição original)
	float_tween.tween_property(self, "position:y", position.y, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(
		Tween.TRANS_SINE
	)


func apply_random_force() -> void:
	# Aplica força linear aleatória
	var force_direction = Vector2(randf_range(-1, 1), randf_range(-0.5, -1.5)).normalized()
	var force_magnitude = randf_range(min_spawn_force, max_spawn_force)
	apply_central_impulse(force_direction * force_magnitude)

	# Aplica torque (rotação) aleatório
	var torque = randf_range(min_spawn_torque, max_spawn_torque)
	if randf() > 0.5:
		torque *= -1  # 50% de chance para cada direção
	apply_torque_impulse(torque)


func setup_coin_texture() -> void:
	if coin:
		coin_texture.texture = coin.coin_texture


func collect():
	if coin:
		CurrencyManager.add_coins(coin.coin_value)

		# Efeitos visuais (opcional)
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
		tween.tween_callback(queue_free)


func _on_collect_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		PlayerEvents.show_interaction(interact_text)


func _on_collect_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and player:
		player = null
		PlayerEvents.hide_interaction()
