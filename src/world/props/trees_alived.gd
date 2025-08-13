extends StaticBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D

enum STYLES {A,B,C,D,E,F,G,H,I,J,K,L,M,N,O}
@export var style: STYLES

# Mapeamento de estilo para frame
const STYLE_FRAMES = {
	STYLES.A: 0,
	STYLES.B: 1,
	STYLES.C: 2,
	STYLES.D: 3,
	STYLES.E: 4,
	STYLES.F: 5,
	STYLES.G: 6,
	STYLES.H: 7,
	STYLES.I: 8,
	STYLES.J: 9,
	STYLES.K: 10,
	STYLES.L: 11,
	STYLES.M: 12,
	STYLES.N: 13,
	STYLES.O: 14,
}

func _ready() -> void:
	sprite_2d.frame = STYLE_FRAMES.get(style, 0)  # 0 é o valor padrão se não encontrado
