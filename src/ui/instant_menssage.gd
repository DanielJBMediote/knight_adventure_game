class_name InstantMessage
extends Control

@onready var message: Label = $Label
@onready var timer: Timer = $Timer

enum TYPE {SUCCESS, DANGER, WARNING}

const COLORS = {
	TYPE.SUCCESS: Color.WEB_GREEN,
	TYPE.WARNING: Color.YELLOW,
	TYPE.DANGER: Color.RED
}

# Sinal para notificar quando a mensagem é escondida
signal message_hidden

func _ready() -> void:
	# Configurações iniciais
	hide()
	timer.timeout.connect(_on_timer_timeout)

# Função para mostrar a mensagem
func show_message(text: String, type: TYPE = TYPE.SUCCESS, duration: float = 3.0) -> void:
	message.text = text
	
	# Define a cor baseada no tipo
	if COLORS.has(type):
		message.add_theme_color_override("font_color", COLORS[type])
	else:
		message.add_theme_color_override("font_color", COLORS[TYPE.SUCCESS]) # Default
	
	# Mostra a mensagem
	show()
	
	# Inicia o timer para esconder após o tempo especificado
	timer.wait_time = duration
	timer.start()

# Função para esconder a mensagem
func hide_message() -> void:
	timer.stop()
	message_hidden.emit()
	queue_free()

# Chamado quando o timer termina
func _on_timer_timeout() -> void:
	hide_message()

# Função estática para facilitar o uso de qualquer lugar
static func show_instant_message(parent: Node, text: String, type: TYPE = TYPE.SUCCESS, duration: float = 3.0) -> InstantMessage:
	var message_scene = preload("res://src/ui/instant_menssage.tscn")
	var message_instance = message_scene.instantiate() as InstantMessage
	
	parent.add_child(message_instance)
	message_instance.show_message(text, type, duration)
	
	return message_instance
