class_name SmartCameraController
extends Node2D

@onready var start_marker: Marker2D = $StartMarker
@onready var end_marker: Marker2D = $EndMarker

@export var left_marker_position := Vector2.ZERO
@export var right_marker_position := Vector2.ZERO
@export var default_margins: Vector2 = Vector2(200, 100)
@export var limit_bottom: float = 1000.0

func _ready():
	start_marker.global_position = left_marker_position
	end_marker.global_position = right_marker_position
	_set_limits_from_markers()

func _set_limits_from_markers():
	var camera = get_viewport().get_camera_2d()
	if camera:
		camera.limit_left = start_marker.global_position.x
		camera.limit_right = end_marker.global_position.x
		camera.limit_bottom = limit_bottom
