extends ParallaxBackground

@onready var houses: ParallaxLayer = $Houses
@onready var gravewards: ParallaxLayer = $Gravewards
var player: Player

const MAX_OFFSET := 300.0

# Fatores de movimento para cada layer (ajuste conforme necessário)
@export var house_move_factor := 0.1  # Move 30% da distância do jogador
@export var grass_move_factor := 0.2  # Move 50% da distância do jogador
@export var smooth_speed := 5.0

# Posição Y de referência do jogador
var player_base_y := 0.0

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	player_base_y = player.position.y  # Armazena a posição inicial do jogador

func _process(delta: float) -> void:
	return
	# Calcula o deslocamento Y do jogador em relação à posição inicial
	var y_offset := player.position.y - player_base_y
	# Dentro do _process, após calcular y_offset
	y_offset = clamp(y_offset, -MAX_OFFSET, MAX_OFFSET)  # Defina max_offset conforme necessário
	
	# Substitua as linhas de motion_offset por:
	houses.motion_offset.y = lerp(houses.motion_offset.y, y_offset * house_move_factor, delta * smooth_speed)
	gravewards.motion_offset.y = lerp(gravewards.motion_offset.y, y_offset * grass_move_factor, delta * smooth_speed)
	# Onde smooth_speed controla a suavização (ex: 2.0)
