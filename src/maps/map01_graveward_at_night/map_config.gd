extends Node2D

@onready var parallax_background: ParallaxBackground = $ParallaxBackground
@onready var houses: ParallaxLayer = $ParallaxBackground/Houses
@onready var grass: ParallaxLayer = $ParallaxBackground/Grass
@onready var player: Player = $Entities/Player

const MAX_OFFSET := 300.0

# Fatores de movimento para cada layer (ajuste conforme necessário)
var house_move_factor := 0.1  # Move 30% da distância do jogador
var grass_move_factor := 0.2  # Move 50% da distância do jogador
var smooth_speed := 5.0

# Posição Y de referência do jogador
var player_base_y := 0.0

func _ready() -> void:
	player_base_y = player.position.y  # Armazena a posição inicial do jogador

func _process(delta: float) -> void:
	# Calcula o deslocamento Y do jogador em relação à posição inicial
	var y_offset := player.position.y - player_base_y
	
	# Dentro do _process, após calcular y_offset
	y_offset = clamp(y_offset, -MAX_OFFSET, MAX_OFFSET)  # Defina max_offset conforme necessário
	
	# Substitua as linhas de motion_offset por:
	houses.motion_offset.y = lerp(houses.motion_offset.y, y_offset * house_move_factor, delta * smooth_speed)
	grass.motion_offset.y = lerp(grass.motion_offset.y, y_offset * grass_move_factor, delta * smooth_speed)
	# Onde smooth_speed controla a suavização (ex: 2.0)
