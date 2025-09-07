extends StaticBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D

@export var texture: Texture2D

func _ready() -> void:
	if texture:
		sprite_2d.texture = texture
