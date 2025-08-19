# autoloads/game_events.gd
extends Node

signal game_paused(paused: bool)

enum Difficulty {
	NORMAL,    # 100% dos stats
	PAINFUL,   # 120% dos stats dos inimigos
	FATAL,     # 150% dos stats dos inimigos
	INFERNAL   # 200% dos stats dos inimigos
}

var current_map: MapData
var is_paused := false
var current_joypad = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Verificar joypads conectados ao iniciar
	check_initial_joypads()
	
	# Conectar sinal para mudanças futuras
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		pause_game()
	if event.is_action_pressed("inventory"):
		InventoryManager.handle_inventory_visibility()

func pause_game()-> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	game_paused.emit()

func change_to_scene_with_transition(new_scene: PackedScene, fade_suration: float = 0.5):
	TransitionManager.transition_to_scene(new_scene, fade_suration)

func set_current_map(map_data: MapData)-> void:
	current_map = map_data

func get_map_enemy_levels() -> Dictionary:
	return {
		"mobs": [current_map.level_mob_min, current_map.level_mob_max],
		"boss": current_map.boss_level
	}

func check_initial_joypads():
	var joypads = Input.get_connected_joypads()
	if joypads.size() > 0:
		print("Joypads conectados: ", joypads)
	else:
		print("Nenhum joypad conectado")

func _on_joy_connection_changed(device_id, connected):
	var device_name = Input.get_joy_name(device_id)
	if connected:
		print("Joypad conectado: ID ", device_id, " - ", device_name)
	else:
		print("Joypad desconectado: ID ", device_id)
