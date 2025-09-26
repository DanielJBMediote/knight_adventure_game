# autoloads/game_manager.gd
extends Node

signal game_paused(paused: bool)
signal game_saved(save_success: bool)
signal game_loaded(load_success: bool)
signal difficulty_changed(new_difficulty: DIFFICULTY)
signal player_died()
# signal player_level_up(new_level: int)
signal game_time_updated(elapsed_time: float)
signal joy_connection_changed()

enum DIFFICULTY {NORMAL, PAINFUL, FATAL, INFERNAL}

const DIFFICULT_NAMES = {
	DIFFICULTY.NORMAL: "normal",
	DIFFICULTY.PAINFUL: "painful",
	DIFFICULTY.FATAL: "fatal",
	DIFFICULTY.INFERNAL: "infernal",
}

const DROP_DIFFICULT_MODIFIER = {
	DIFFICULTY.NORMAL: 0.8,
	DIFFICULTY.PAINFUL: 1.0,
	DIFFICULTY.FATAL: 1.2,
	DIFFICULTY.INFERNAL: 1.5,
}
const STATS_DIFFICULT_MODIFIER = {
	DIFFICULTY.NORMAL: 1.0,
	DIFFICULTY.PAINFUL: 1.5,
	DIFFICULTY.FATAL: 2.0,
	DIFFICULTY.INFERNAL: 2.5,
}
const ENEMY_LEVEL_INCREMENT = {
	DIFFICULTY.NORMAL: 0,
	DIFFICULTY.PAINFUL: 5,
	DIFFICULTY.FATAL: 10,
	DIFFICULTY.INFERNAL: 15,
}

var current_map: MapData
var difficulty := DIFFICULTY.NORMAL
var is_paused := false
var current_joypad = null

var game_start_time: float = 0.0
var elapsed_game_time: float = 0.0
var player_score: int = 0
var player_deaths: int = 0
var enemies_killed: int = 0
var current_checkpoint: Dictionary = {}
var game_settings: Dictionary = {}
var quest_progress: Dictionary = {}
var unlocked_achievements: Array = []

# Sistema de save/load
const SAVE_FILE_PATH: String = "user://save_game.dat"
const SETTINGS_FILE_PATH: String = "user://settings.cfg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game_start_time = Time.get_unix_time_from_system()

	_check_initial_joypads()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	load_game_settings()
	
	_start_game_timer()

func _start_game_timer():
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_game_time)
	add_child(timer)
	timer.start()

func _update_game_time():
	elapsed_game_time = Time.get_unix_time_from_system() - game_start_time
	game_time_updated.emit(elapsed_game_time)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		toggle_pause_game()
	
	#if event.is_action_pressed("screenshot"):
		#take_screenshot()

func toggle_pause_game():
	if not is_paused:
		pause_game()
	else:
		resume_game()

func pause_game() -> void:
	var player_ui = get_player_ui()
	if player_ui:
		is_paused = true
		var scene = preload("res://src/ui/pause_game_menu.tscn")
		var instance = scene.instantiate()
		player_ui.add_child(instance)
		get_tree().paused = true
		game_paused.emit(true)

func resume_game() -> void:
	var game_paused_ui = get_tree().get_first_node_in_group("game_paused_menu")
	if game_paused_ui:
		game_paused_ui.queue_free()
	is_paused = false
	get_tree().paused = false
	game_paused.emit(false)

func change_to_scene_with_transition(new_scene: PackedScene, fade_duration: float = 0.5):
	TransitionManager.transition_to_scene(new_scene, fade_duration)

func back_to_main_menu() -> void:
	var main_menu = preload("res://src/scenes/main_menu.tscn")
	change_to_scene_with_transition(main_menu, 0)

func exit_game() -> void:
	save_game_settings()
	get_tree().quit()


# SISTEMA DE SCORE
func add_score(points: int) -> void:
	player_score += points

func get_score() -> int:
	return player_score

func increment_deaths() -> void:
	player_deaths += 1
	player_died.emit()

func increment_enemies_killed() -> void:
	enemies_killed += 1

# func increment_items_collected() -> void:
# 	items_collected += 1

func save_game() -> bool:
	var save_data = {
		"player_coins": CurrencyManager.save_data(),
		"player_score": player_score,
		"player_deaths": player_deaths,
		"enemies_killed": enemies_killed,
		"player_inventory": InventoryManager.save_data(),
		"elapsed_time": elapsed_game_time,
		"checkpoint": current_checkpoint,
		"player_stats": PlayerStats.save_data(),
		"quest_progress": quest_progress,
		"unlocked_achievements": unlocked_achievements,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		game_saved.emit(true)
		print("Game saved successfully")
		return true
	
	game_saved.emit(false)
	return false

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		game_loaded.emit(false)
		return false
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		
		player_score = save_data.get("player_score", 0)
		player_deaths = save_data.get("player_deaths", 0)
		enemies_killed = save_data.get("enemies_killed", 0)
		elapsed_game_time = save_data.get("elapsed_time", 0.0)
		current_checkpoint = save_data.get("checkpoint", {})
		quest_progress = save_data.get("quest_progress", {})
		unlocked_achievements = save_data.get("unlocked_achievements", [])
		
		CurrencyManager.load_data(save_data.get(("player_coins")))
		PlayerStats.load_stats(save_data.get("player_stats"))
		InventoryManager.load_data(save_data.get("player_inventory"))
		
		game_loaded.emit(true)
		print("Game loaded successfully")
		return true
	
	game_loaded.emit(false)
	return false

func delete_save_file() -> bool:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		reset_game_data()
		return true
	return false

func reset_game_data() -> void:
	# player_coins = 0
	player_score = 0
	player_deaths = 0
	enemies_killed = 0
	# items_collected = 0
	elapsed_game_time = 0.0
	current_checkpoint = {}
	quest_progress = {}
	unlocked_achievements = []
	game_start_time = Time.get_unix_time_from_system()

# SISTEMA DE CONFIGURAÇÕES
func save_game_settings() -> void:
	var config = ConfigFile.new()
	
	# Configurações de áudio
	config.set_value("audio", "master_volume", game_settings.get("master_volume", 1.0))
	config.set_value("audio", "music_volume", game_settings.get("music_volume", 1.0))
	config.set_value("audio", "sfx_volume", game_settings.get("sfx_volume", 1.0))
	
	# Configurações de vídeo
	config.set_value("video", "fullscreen", game_settings.get("fullscreen", true))
	config.set_value("video", "resolution", game_settings.get("resolution", Vector2i(1920, 1080)))
	
	# Configurações de controle
	config.set_value("controls", "invert_y", game_settings.get("invert_y", false))
	config.set_value("controls", "mouse_sensitivity", game_settings.get("mouse_sensitivity", 1.0))
	
	config.save(SETTINGS_FILE_PATH)

func load_game_settings() -> void:
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_FILE_PATH)
	if error != OK:
		# Configurações padrão
		game_settings = {
			"master_volume": 1.0,
			"music_volume": 1.0,
			"sfx_volume": 1.0,
			"fullscreen": false,
			"resolution": Vector2i(1920, 1080),
			"invert_y": false,
			"mouse_sensitivity": 1.0
		}
		return
	
	game_settings = {
		"master_volume": config.get_value("audio", "master_volume", 1.0),
		"music_volume": config.get_value("audio", "music_volume", 1.0),
		"sfx_volume": config.get_value("audio", "sfx_volume", 1.0),
		"fullscreen": config.get_value("video", "fullscreen", true),
		"resolution": config.get_value("video", "resolution", Vector2i(1920, 1080)),
		"invert_y": config.get_value("controls", "invert_y", false),
		"mouse_sensitivity": config.get_value("controls", "mouse_sensitivity", 1.0)
	}
	
	apply_game_settings()

func apply_game_settings() -> void:
	# Volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(game_settings.master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(game_settings.music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(game_settings.sfx_volume))
	
	# Resolutions
	if game_settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	DisplayServer.window_set_size(game_settings.resolution)

func get_player_ui() -> PlayerUI:
	return get_tree().get_first_node_in_group("player_ui")

func _check_initial_joypads():
	var joypads = Input.get_connected_joypads()
	if joypads.size() > 0:
		print("Connected Joypads: ", joypads)
	else:
		print("NO Joypads connected.")

func _on_joy_connection_changed(device_id, connected):
	var device_name = Input.get_joy_name(device_id)
	if connected:
		current_joypad = device_name
		joy_connection_changed.emit()
		print("Joypad connected: ID ", device_id, " - ", device_name)
	else:
		print("Joypad disconnected: ID ", device_id)

func update_difficulty(new_difficulty: DIFFICULTY) -> void:
	difficulty = new_difficulty
	difficulty_changed.emit(difficulty)

func get_difficulty() -> DIFFICULTY:
	return difficulty

func get_difficulty_name() -> String:
	var name_key = DIFFICULT_NAMES.get(difficulty)
	return LocalizationManager.get_ui_text(name_key)

func show_instant_message(message: String, type: InstantMessage.TYPE = InstantMessage.TYPE.SUCCESS, duration: float = 3.0) -> void:
	var player_ui = get_tree().get_first_node_in_group("player_ui")
	if player_ui:
		InstantMessage.show_instant_message(player_ui, message, type, duration)

func update_checkpoint() -> void:
	current_checkpoint["scene_path"] = get_tree().current_scene.scene_file_path
	var position = PlayerStats.player_ref.global_position
	if position:
		current_checkpoint["player_position"] = Utils.serialize_value(position)
	print("Checkpoint set: ", current_checkpoint)

func get_checkpoint() -> Dictionary:
	return current_checkpoint

func unlock_achievement(achievement_id: String) -> void:
	if achievement_id in unlocked_achievements:
		return
	
	unlocked_achievements.append(achievement_id)
	print("Achievement unlocked: ", achievement_id)
	show_instant_message("Achievement Unlocked: " + achievement_id, InstantMessage.TYPE.INFO)

func has_achievement(achievement_id: String) -> bool:
	return achievement_id in unlocked_achievements

func take_screenshot() -> void:
	var image = get_viewport().get_texture().get_image()
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var path = "user://screenshots/screenshot_%s.png" % timestamp
	
	# Criar diretório se não existir
	var dir = DirAccess.open("user://")
	dir.make_dir("screenshots")
	
	image.save_png(path)
	print("Screenshot saved: ", path)

func get_game_time_formatted() -> String:
	return StringUtils.format_to_timer(elapsed_game_time)

func update_quest_progress(quest_id: String, progress: int) -> void:
	quest_progress[quest_id] = progress

func get_quest_progress(quest_id: String) -> int:
	return quest_progress.get(quest_id, 0)

func complete_quest(quest_id: String) -> void:
	quest_progress[quest_id] = 100
	show_instant_message("Quest completed: " + quest_id, InstantMessage.TYPE.SUCCESS)
