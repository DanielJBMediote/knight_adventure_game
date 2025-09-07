## NPC Class
class_name NPC
extends Node2D

enum TYPE {BLACKSMITH, JEWELER}

signal interact

@export var npc_name: String
@export var interact_area: Area2D
@export var player_detection_area: Area2D
@export var interact_label: InteractLabel
@export var dialog_ballon: DialogBallon
@export var npc_type: TYPE
@export var npc_interface: NPCInterface
@export var npc_texture_portrait: Texture2D

var can_interact := false
var npc_dialogs: NPCDialogData
var target_player: Player
var player_ui: CanvasLayer

var active_ui: Control = null

func _ready() -> void:
	interact_label.hide()
	npc_interface.hide()
	npc_interface.back_button_pressed.connect(_on_back_button_action)  # Conectar ao novo sinal
	player_detection_area.body_entered.connect(_on_player_detection_area_body_entered)
	player_detection_area.body_exited.connect(_on_player_detection_area_body_exited)
	interact_area.body_entered.connect(_on_player_interact_area_entered)
	interact_area.body_exited.connect(_on_player_interact_area_exited)
	
	# Encontrar a UI do jogador
	player_ui = get_tree().get_first_node_in_group("player_ui")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and target_player and can_interact:
		start_interaction()

func start_interaction() -> void:
	if player_ui:
		player_ui.hide()
	
	npc_interface.show()
	npc_interface.npc_name_label.text = npc_name

func end_interaction() -> void:
	if npc_dialogs and npc_dialogs.exiting.size() > 0:
		var exit_text = npc_dialogs.get_random_dialog_exiting()
		dialog_ballon.show_dialog(exit_text)
	
	npc_interface.hide()
	if player_ui:
		player_ui.show()
	
	# Resetar estado
	active_ui = null

func _on_back_button_action(action: String) -> void:
	match action:
		"back_to_menu":
			# Apenas volta para o menu (já tratado pelo NPCInterface)
			pass
		"exit_interaction":
			# Sai da interação completa
			end_interaction()

func _on_buy_sell_selected() -> void:
	# Implementar lógica de compra/venda
	pass

func _on_socket_management_selected() -> void:
	# Implementar lógica de sockets
	pass

func _on_buy_gems_selected() -> void:
	# Implementar para joalheiro
	pass

func _on_upgrade_gems_selected() -> void:
	# Implementar para joalheiro
	pass

func close_active_ui() -> void:
	if active_ui:
		# Chama método específico para fechar a UI ativa
		if active_ui.has_method("close_ui"):
			active_ui.close_ui()
		else:
			# Fallback: apenas esconde a UI
			active_ui.hide()
			active_ui = null
			npc_interface.hide_subsystem()

func _on_player_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target_player = body
		
		if npc_dialogs and npc_dialogs.greetings.size() > 0:
			var greeting = npc_dialogs.get_random_dialog_greetings()
			dialog_ballon.show_dialog(greeting)

func _on_player_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		target_player = null
		
		if npc_dialogs and npc_dialogs.exiting.size() > 0:
			var exiting = npc_dialogs.get_random_dialog_greetings()
			dialog_ballon.show_dialog(exiting)

func _on_player_interact_area_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		interact_label.show()
		can_interact = true

func _on_player_interact_area_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		interact_label.hide()
		can_interact = false
