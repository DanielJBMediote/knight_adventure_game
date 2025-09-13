# lamp_post.gd
class_name LampPost
extends StaticBody2D

@onready var lamp_group: Node2D = $LampGroup
@onready var lanter_holder: StaticBody2D = $LanterHolder
@onready var lamp: Lamp = $LampGroup/Lamp

@onready var pin_join_2d_1: PinJoint2D = $LampGroup/PinJoin2D_1
@onready var pin_join_2d_2: PinJoint2D = $LampGroup/PinJoin2D_2
@onready var pin_joint_2d_3: PinJoint2D = $LampGroup/PinJoint2D_3

@onready var chain_segment: LampChainSegment = $LampGroup/ChainSegment
@onready var chain_segment_2: LampChainSegment = $LampGroup/ChainSegment2

@export var light_interval: float = 3.0
@export var is_on: bool = true
@export var flicker_chance: float = 0.1

var tween: Tween
var is_chain_broken: bool = false

func _ready() -> void:
	tuning_on()
	if lamp:
		lamp.lamp_breaked.connect(_on_break_chains)
	
	chain_segment.player_hitbox_entered.connect(_on_break_chains)
	chain_segment_2.player_hitbox_entered.connect(_on_break_chains)

func tuning_on() -> void:
	if !is_on:
		lamp._turn_on(false)
		if tween:
			tween.kill()
		return

	# A luz agora é controlada pela própria lâmpada
	lamp.start_light_effect(light_interval, flicker_chance)


func _toggle_lantern_sprites(is_light_on: bool) -> void:
	lamp._turn_on(is_light_on)

func _on_break_chains() -> void:
	if is_chain_broken:
		return
	break_chains()

func break_chains() -> void:
	if is_chain_broken:
		return
	
	is_chain_broken = true
	
	# Desativa todos os pin joints para liberar a lâmpada
	if pin_join_2d_1:
		pin_join_2d_1.node_a = ""  # Desconecta o joint
	if pin_join_2d_2:
		pin_join_2d_2.node_a = ""
	if pin_joint_2d_3:
		pin_joint_2d_3.node_a = ""
	
	# Configura a lâmpada para cair no chão
	if lamp:
		lamp.gravity_scale = 1.0  # Ativa gravidade normal
		lamp.break_lamp()
	
	# Para efeitos visuais, você pode adicionar partículas ou som aqui
	print("Corrente quebrada! Lâmpada caindo...")
