class_name ItemBody
extends RigidBody2D

@onready var animation: AnimationPlayer = $ItemAnimation
@onready var item_texture_sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var area_2d: Area2D = $Area2D
@onready var dropped_item_effect: Node2D = $DroppedItemEffect

# Configurações de física
@export var bounce_factor: float = 0.3
@export var friction: float = 0.1

# Força aleatória ao spawnar
@export var min_spawn_force: float = 50.0
@export var max_spawn_force: float = 200.0
@export var min_spawn_torque: float = 1.0
@export var max_spawn_torque: float = 10.0

var player: Player
@export var item_resource: Item

const COLORS_EFFECT := {
	Item.RARITY.COMMON: Color.DIM_GRAY,
	Item.RARITY.UNCOMMON: Color.SEA_GREEN,
	Item.RARITY.RARE: Color.DODGER_BLUE,
	Item.RARITY.EPIC: Color.REBECCA_PURPLE,
	Item.RARITY.LEGENDARY: Color.DARK_ORANGE,
	Item.RARITY.MYTHICAL: Color.ORANGE_RED,
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
	#apply_explosion_force()
	setup_rarity_bright()
	setup_sprite()

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
	#mass = 0.5  # Peso médio para itens
	#gravity_scale = item_gravity_scale
	#linear_damp = item_linear_damp
	#angular_damp = item_angular_damp

	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = bounce_factor
	physics_material_override.rough = friction
	physics_material_override.absorbent = false


func setup_sprite():
	var category = item_resource.item_category
	var subcategory = item_resource.item_subcategory

	if category == Item.CATEGORY.EQUIPMENTS:
		animation.play("bounce_equips")
		return

	match subcategory:
		Item.SUBCATEGORY.POTION:
			animation.play("bounce_potions")
		Item.SUBCATEGORY.GEM:
			#item_texture_sprite.scale = Vector2(0.75, 0.75)
			animation.play("bounce_gems")


func setup_rarity_bright() -> void:
	var subcategory = item_resource.item_subcategory
	var rarity = item_resource.item_rarity
	if item_resource.item_texture:
		item_texture_sprite.texture = item_resource.item_texture

	dropped_item_effect.scale += Vector2(rarity * 0.15, rarity * 0.15)
	dropped_item_effect.modulate = COLORS_EFFECT[rarity]


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
	var is_spawned := false
	if item_resource:
		var factor = randf() * 1.0
		is_spawned = factor <= item_resource.spawn_chance
	return is_spawned


func spawn_collect_effect() -> void:
	# Cria um efeito visual quando o item é coletado
	#var effect = preload("res://effects/item_collect_effect.tscn").instantiate()
	#effect.global_position = global_position
	#get_parent().add_child(effect)
	pass


func _on_player_body_entered(body: Node) -> void:
	if body is Player:
		player = body


func _on_player_body_exited(body: Node) -> void:
	if body is Player:
		player = null
