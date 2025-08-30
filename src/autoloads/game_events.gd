# autoloads/game_events.gd
extends Node

signal game_paused(paused: bool)

enum DIFFICULTY { NORMAL, PAINFUL, FATAL, INFERNAL }  # 100% dos stats  # 120% dos stats dos inimigos  # 150% dos stats dos inimigos  # 200% dos stats dos inimigos

const DROP_DIFFICULT_MODIFICATOR = {
	DIFFICULTY.NORMAL: 0.8,  # 80% da chance base
	DIFFICULTY.PAINFUL: 1.0,  # 100% da chance base
	DIFFICULTY.FATAL: 1.2,  # 120% da chance base
	DIFFICULTY.INFERNAL: 1.5,  # 150% da chance base
}
const STATS_DIFFICULT_MODIFICATOR = {
	DIFFICULTY.NORMAL: 1.0,  # 100% da chance base
	DIFFICULTY.PAINFUL: 1.5,  # 150% da chance base
	DIFFICULTY.FATAL: 2.0,  # 200% da chance base
	DIFFICULTY.INFERNAL: 2.5,  # 250% da chance base
}
const ENEMY_LEVEL_INCREMENT = {
	DIFFICULTY.NORMAL: 0,  # +0 Levels
	DIFFICULTY.PAINFUL: 5,  # +5 Levels
	DIFFICULTY.FATAL: 10,  # +10 Levels
	DIFFICULTY.INFERNAL: 15,  # +15 Levels
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


func pause_game() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	game_paused.emit()


func change_to_scene_with_transition(new_scene: PackedScene, fade_suration: float = 0.5):
	TransitionManager.transition_to_scene(new_scene, fade_suration)


func set_current_map(map_data: MapData) -> void:
	current_map = map_data


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


func get_game_difficult() -> DIFFICULTY:
	if current_map:
		return current_map.difficulty
	return DIFFICULTY.NORMAL

## Returns the modificator factor of drop rate by difficulty.
## More difficulty, more factor
static func get_drop_modificator_by_difficult(_difficult: DIFFICULTY) -> float:
	return DROP_DIFFICULT_MODIFICATOR.get(_difficult, 0.8)


static func get_stats_modificator_by_difficult(_difficult: DIFFICULTY) -> float:
	return STATS_DIFFICULT_MODIFICATOR.get(_difficult, 1.0)


static func get_additional_levels_modificator_by_difficult(_difficult: DIFFICULTY) -> float:
	return ENEMY_LEVEL_INCREMENT.get(_difficult, 0)
