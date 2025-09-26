class_name CheckpointData
extends Resource

var player_position := Vector2.ZERO
var scene_path: String


func _init() -> void:
	pass


func get_scene_path() -> String:
	return scene_path


func save_data() -> Dictionary:
	var saved_data := {
		"scene_path": scene_path,
		"player_position":
		{
			"pos_x": player_position.x,
			"pos_y": player_position.y
		}
	}
	return saved_data


func load_data(loaded_data: Dictionary) -> void:
	if loaded_data == null or loaded_data.is_empty():
		printerr("No data found to load CheckpointData.")
		return

	scene_path = loaded_data.get("scene_path")

	if not scene_path:
		printerr("Scene not found")
		return

	var _position = loaded_data.get("player_position")
	if _position:
		player_position = Vector2(_position["pos_x"], _position["pos_y"])
