class_name ItemObject
extends RigidBody2D

@onready var animation: AnimationPlayer = $ItemAnimation
@onready var item_texture_sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var area_2d: Area2D = $Area2D
@onready var dropped_item_effect: Node2D = $DroppedItemEffect
@onready var item_interaction: Control = $ItemInteraction

# Configurações de física
@export var item_gravity_scale: float = 1.0
@export var bounce_factor: float = 0.3
@export var friction: float = 0.1
@export var item_linear_damp: float = 0.2
@export var item_angular_damp: float = 0.5

# Força aleatória ao spawnar
@export var min_spawn_force: float = 50.0
@export var max_spawn_force: float = 200.0
@export var min_spawn_torque: float = 1.0
@export var max_spawn_torque: float = 10.0

const ItemRarity = Item.ItemRarity
const ItemSubCategory = Item.ItemSubCategory

var player: Player
var item_resource: Item

const COLORS_EFFECT := {
	ItemRarity.COMMON: Color.DIM_GRAY,
	ItemRarity.UNCOMMON: Color.GREEN,
	ItemRarity.RARE: Color.BLUE,
	ItemRarity.EPIC: Color.PURPLE,
	ItemRarity.LEGENDARY: Color.ORANGE,
	ItemRarity.MYTHICAL: Color.RED,
}

#func _init(_item_res: Item) -> void:
	#if _item_res:
		#item_resource = _item_res
		#return
	#queue_free()

func _ready() -> void:
	if !item_resource:
		printerr("ItemResource não definido!")
		queue_free()
		return
	
	# Configura a física do item
	setup_physics()
	# Aplica força inicial aleatória
	apply_random_force()
	setup_rarity_bright()
	setup_pulse_animation()
	item_interaction.hide()
	
	area_2d.body_entered.connect(_on_player_body_entered)
	area_2d.body_exited.connect(_on_player_body_exited)

func _input(event: InputEvent) -> void:
	if item_resource == null:
		return

	if event.is_action_pressed("interact"):
		collect()
		pass

func setup_physics() -> void:
	# Configura propriedades físicas
	gravity_scale = item_gravity_scale
	mass = 0.5  # Peso médio para itens
	linear_damp = item_linear_damp
	angular_damp = item_angular_damp
	
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = bounce_factor
	physics_material_override.rough = friction
	physics_material_override.absorbent = false
	
	# Configura a camada/máscara de colisão
	collision_layer = 0b0001  # Camada 1 - Itens
	collision_mask = 0b0111   # Colide com chão, paredes e jogador

func setup_pulse_animation():
	if item_resource == null:
		return
	var item_subcategory = item_resource.item_subcategory
	
	match item_subcategory:
		ItemSubCategory.POTION:
			animation.play("pulse_potions")
		ItemSubCategory.GEM:
			animation.play("pulse_gems")

func setup_rarity_bright() -> void:
	if item_resource.item_texture:
		item_texture_sprite.texture = item_resource.item_texture
		
	dropped_item_effect.modulate = COLORS_EFFECT[item_resource.item_rarity]

func apply_random_force() -> void:
	# Aplica força linear aleatória
	var force_direction = Vector2(
		randf_range(-1, 1),
		randf_range(-0.5, -1)  # Mais para cima que para os lados
	).normalized()
	
	var force_magnitude = randf_range(min_spawn_force, max_spawn_force)
	apply_central_impulse(force_direction * force_magnitude)
	
	# Aplica torque (rotação) aleatório
	var torque = randf_range(min_spawn_torque, max_spawn_torque)
	if randf() > 0.5:
		torque *= -1  # 50% de chance para cada direção
	#apply_torque_impulse(torque)

func collect() -> bool:
	if player and item_resource:
		# Tenta adicionar o item ao inventário
		if InventoryManager.add_item(item_resource):
			# Se foi adicionado com sucesso, remove o item do mundo
			queue_free()
			return true
		# Efeito visual de coleta (opcional)
		#spawn_collect_effect()
	return false

func can_spawn() -> bool:
	var can_spawn := false
	if item_resource:
		var factor = randf() * 1.0
		can_spawn = factor <= item_resource.spawn_chance
	return can_spawn

func spawn_collect_effect() -> void:
	# Cria um efeito visual quando o item é coletado
	#var effect = preload("res://effects/item_collect_effect.tscn").instantiate()
	#effect.global_position = global_position
	#get_parent().add_child(effect)
	pass

func _on_player_body_entered(body: Node) -> void:
	if body is Player:
		player = body
		item_interaction.show()
			
func _on_player_body_exited(body: Node) -> void:
	if body is Player:
		player = null
		item_interaction.hide()
