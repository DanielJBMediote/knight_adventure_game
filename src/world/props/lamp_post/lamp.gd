# lamp.gd
class_name Lamp
extends RigidBody2D

signal lamp_breaked()

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var point_light_2d: PointLight2D = $PointLight2D

const LAMP_ON_RECT := Rect2(969, 6, 13, 18)
const LAMP_OFF_RECT := Rect2(1002, 6, 13, 18)

@export var break_force: float = 100.0  # Força necessária para quebrar

var is_broken: bool = false
var collision_count: int = 0
var tween: Tween
var is_light_on: bool = true
var flicker_timer: Timer

func _ready() -> void:
	point_light_2d.enabled = is_light_on

func _turn_on(is_on: bool = true) -> void:
	is_light_on = is_on
	sprite_2d.region_rect = LAMP_ON_RECT if is_on else LAMP_OFF_RECT
	point_light_2d.visible = is_on
	
	if !is_on:
		stop_light_effect()
		point_light_2d.energy = 0
		point_light_2d.scale = Vector2(0.5, 0.5)

func start_light_effect(light_interval: float, flicker_chance: float) -> void:
	_turn_on(true)
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_loops()
	
	# Efeito de falha aleatória
	var base_energy := 1.0
	var base_scale := Vector2(1.5, 1.5)
	
	# Loop principal com possíveis falhas
	tween.tween_callback(_flicker_effect.bind(base_energy, base_scale, flicker_chance, light_interval))
	tween.tween_interval(randf_range(light_interval * 0.8, light_interval * 1.2))

func stop_light_effect() -> void:
	if tween:
		tween.kill()
		tween = null
	if flicker_timer:
		flicker_timer.stop()
		flicker_timer.queue_free()
		flicker_timer = null

func _flicker_effect(base_energy: float, base_scale: Vector2, flicker_chance: float, light_interval: float) -> void:
	if is_broken:
		return  # Não faz efeitos se estiver quebrada

	if randf() < flicker_chance:
		# Efeito de falha - luz apaga completamente
		var flicker_tween = create_tween()
		
		# Apaga a luz rapidamente
		flicker_tween.tween_property(point_light_2d, "energy", 0, 0.1)
		flicker_tween.tween_property(point_light_2d, "scale", Vector2(0.5, 0.5), 0.1)
		flicker_tween.tween_callback(_turn_on.bind(false))
		
		# Mantém apagado por um tempo aleatório
		flicker_tween.tween_interval(randf_range(0.1, 0.5))
		
		# Reacende a luz
		flicker_tween.tween_callback(_turn_on.bind(true))
		flicker_tween.tween_property(point_light_2d, "energy", base_energy, 0.2)
		flicker_tween.tween_property(point_light_2d, "scale", base_scale, 0.2)
		
	else:
		# Comportamento normal com pequenas variações
		var normal_tween = create_tween()
		normal_tween.set_parallel(true)
		
		normal_tween.tween_property(point_light_2d, "energy", 
			base_energy * randf_range(0.9, 1.1), 
			randf_range(light_interval * 0.2, light_interval * 0.4))
		
		normal_tween.tween_property(point_light_2d, "scale", 
			base_scale * randf_range(0.95, 1.05), 
			randf_range(light_interval * 0.2, light_interval * 0.4))

func _on_body_entered(body: Node) -> void:
	if is_broken:
		return
	
	if body is Player:
		collision_count += 1
		
		# Quebra após algumas colisões ou se a força for suficiente
		if collision_count >= 2 or linear_velocity.length() > break_force:
			break_lamp()

func break_lamp() -> void:
	if is_broken:
		return
		
	is_broken = true
	lamp_breaked.emit()
	
	# Para o efeito normal e inicia o efeito de quebra
	stop_light_effect()
	
	# Efeito de luz falhando antes de apagar completamente
	flicker_timer = Timer.new()
	add_child(flicker_timer)
	flicker_timer.wait_time = 2.0
	flicker_timer.one_shot = true
	flicker_timer.timeout.connect(_on_flicker_timeout)
	flicker_timer.start()
	
	# Inicia efeito de falha intenso
	_start_break_flicker()

func _start_break_flicker() -> void:
	if !is_broken:
		return
	
	var break_tween = create_tween()
	break_tween.set_loops()
	
	# Efeito de falha intenso e rápido
	break_tween.tween_property(point_light_2d, "energy", 1.5, 0.1)
	break_tween.tween_property(point_light_2d, "scale", Vector2(0.5, 0.5), 0.1)
	break_tween.tween_property(point_light_2d, "energy", 0.1, 0.1)
	break_tween.tween_property(point_light_2d, "scale", Vector2(0.6, 0.6), 0.1)
	break_tween.tween_interval(0.1)

func _on_flicker_timeout() -> void:
	# Apaga a luz completamente após o tempo
	stop_light_effect()
	_turn_on(false)
	
	# Muda para colidir apenas com o chão (Layer 2)
	collision_layer = 2  # Agora é parte do chão
	collision_mask = 2   # Só colide com chão
	
	if flicker_timer:
		flicker_timer.queue_free()
		flicker_timer = null
