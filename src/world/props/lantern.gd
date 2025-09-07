class_name Lantern
extends StaticBody2D

@onready var lanter_pilar: Sprite2D = $LanterPilar
@onready var lanter_holder: Sprite2D = $LanterHolder
@onready var lanter_strings: Sprite2D = $LanterStrings
@onready var point_light_2d: PointLight2D = $PointLight2D

@onready var lantern_off: Sprite2D = $LanternOff
@onready var lantern_on: Sprite2D = $LanternOn

@export var light_interval: float = 3.0
@export var is_on: bool = true
@export var flip_h: bool = false
@export var flicker_chance: float = 0.1

var tween: Tween

func _ready() -> void:
	flip_lantern()
	tuning_on()


func tuning_on() -> void:
	lantern_off.visible = !is_on
	lantern_on.visible = is_on
	
	if !is_on:
		point_light_2d.energy = 0
		point_light_2d.scale = Vector2(0.5, 0.5)
		if tween:
			tween.kill()
		return
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_loops()
	
	# Efeito de falha aleatória
	var base_energy := 1.0
	var base_scale := Vector2(1.5, 1.5)
	
	# Loop principal com possíveis falhas
	tween.tween_callback(_flicker_effect.bind(base_energy, base_scale, flicker_chance))
	tween.tween_interval(randf_range(light_interval * 0.8, light_interval * 1.2))

func _flicker_effect(base_energy: float, base_scale: Vector2, flicker_chance: float) -> void:
	if randf() < flicker_chance:
		# Efeito de falha - luz apaga completamente
		var flicker_tween = create_tween()
		flicker_tween.set_parallel(true)
		

		# Apaga a luz rapidamente
		flicker_tween.tween_property(point_light_2d, "energy", 0, 0.1)
		flicker_tween.tween_property(point_light_2d, "scale", Vector2(0.5, 0.5), 0.1)
		flicker_tween.tween_callback(_toggle_lantern_sprites.bind(false)).set_delay(randf_range(0.1, 0.5))
		
		# Mantém apagado por um tempo aleatório
		flicker_tween.tween_interval(randf_range(0.1, 0.5))
		
		# Reacende a luz
		flicker_tween.tween_property(point_light_2d, "energy", base_energy, 0.2)
		flicker_tween.tween_property(point_light_2d, "scale", base_scale, 0.2)
		flicker_tween.tween_callback(_toggle_lantern_sprites.bind(true)).set_delay(randf_range(0.1, 0.5))
		
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

func _toggle_lantern_sprites(is_light_on: bool) -> void:
	lantern_off.visible = !is_light_on
	lantern_on.visible = is_light_on
	point_light_2d.visible = is_light_on

func flip_lantern() -> void:
	lanter_holder.flip_h = flip_h
	if flip_h:
		lanter_holder.position.x *= -1 
		lantern_off.position.x *= -1 
		lantern_on.position.x *= -1 
		lanter_strings.position.x *= -1
		point_light_2d.position.x *= -1
