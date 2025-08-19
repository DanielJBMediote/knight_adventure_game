class_name ItemObject
extends RigidBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var area_2d: Area2D = $Area2D
@onready var dropped_item_effect: Node2D = $DroppedItemEffect

@export var item_resource: Item

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

const COLORS_EFFECT := {
	ItemRarity.COMMON: Color.DIM_GRAY,
	ItemRarity.UNCOMMON: Color.GREEN,
	ItemRarity.RARE: Color.BLUE,
	ItemRarity.EPIC: Color.PURPLE,
	ItemRarity.LEGENDARY: Color.ORANGE,
	ItemRarity.MYTHICAL: Color.RED,
}

func _ready() -> void:
	if !item_resource:
		printerr("ItemResource não definido!")
		queue_free()
		return
	
	# Configura a física do item
	setup_physics()
	# Aplica força inicial aleatória
	apply_random_force()
	setup_appearance()
	
	area_2d.body_entered.connect(_on_area_2d_body_entered)

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

func setup_appearance() -> void:
	if item_resource.item_texture:
		sprite_2d.texture = item_resource.item_texture
		#sprite_2d.scale = Vector2(1, 1)
		if item_resource.item_subcategory == Item.ItemSubCategory.POTION:
			dropped_item_effect.scale = Vector2(0.55, 1)
			dropped_item_effect.position = Vector2(0.0, -5.0)
		
		dropped_item_effect.get_node("Sprite2D").modulate = COLORS_EFFECT[item_resource.item_rarity]

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

func _on_area_2d_body_entered(body: Node) -> void:
	if body is Player:
		# Tenta adicionar o item ao inventário
		if InventoryManager.add_item(item_resource):
			# Se foi adicionado com sucesso, remove o item do mundo
			queue_free()
			
			# Efeito visual de coleta (opcional)
			spawn_collect_effect()
		else:
			# Inventário cheio - faz o item quicar
			var bounce_direction = (global_position - body.global_position).normalized()
			apply_central_impulse(bounce_direction * 100)

func can_spawn() -> bool:
	return randf() * 1.0 <= item_resource.spawn_chance

func spawn_collect_effect() -> void:
	# Cria um efeito visual quando o item é coletado
	#var effect = preload("res://effects/item_collect_effect.tscn").instantiate()
	#effect.global_position = global_position
	#get_parent().add_child(effect)
	pass
