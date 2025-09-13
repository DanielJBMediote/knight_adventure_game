## NPC Class
class_name NPC
extends CharacterBody2D

enum TYPE {BLACKSMITH, JEWELER}

@onready var npc_interaction_ui_scene: PackedScene = load("res://src/actors/npcs/ui/npc_interaction_ui.tscn")

@export var npc_name: String
@export var interact_area: Area2D
@export var player_detection_area: Area2D
@export var dialog_ballon: DialogBallon
@export var npc_type: TYPE
@export var npc_texture_portrait: Texture2D

var interact_text = ""

var can_interact := false
var npc_dialogs: NPCDialogData
var npc_interaction_ui: NPCInteractionUI
var target_player: Player
var player_ui: PlayerUI

var active_ui: Control = null

func _ready() -> void:
	player_detection_area.body_entered.connect(_on_player_detection_area_body_entered)
	player_detection_area.body_exited.connect(_on_player_detection_area_body_exited)
	interact_area.body_entered.connect(_on_player_interact_area_entered)
	interact_area.body_exited.connect(_on_player_interact_area_exited)
	
	# Encontrar a UI do jogador
	player_ui = GameEvents.get_player_ui()
	interact_text = LocalizationManager.get_ui_text("interact")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and target_player and can_interact:
		_start_interaction()

func _start_interaction() -> void:
	if player_ui:
		npc_interaction_ui = npc_interaction_ui_scene.instantiate()
		player_ui.start_interaction(npc_interaction_ui)
		npc_interaction_ui.npc_name_label.text = npc_name
		npc_interaction_ui.back_button_pressed.connect(_on_back_button_action)

func _add_options() -> void:
	pass

func _end_interaction() -> void:
	if npc_dialogs and npc_dialogs.exiting.size() > 0:
		var exit_text = npc_dialogs.get_random_dialog_exiting()
		dialog_ballon.show_dialog(exit_text)
	
	if player_ui:
		player_ui.end_interaction()
	
	# Resetar estado
	active_ui = null

func _on_back_button_action(action: String) -> void:
	match action:
		"back_to_menu":
			_close_active_ui()
		"exit_interaction":
			_end_interaction()

func _close_active_ui() -> void:
	if active_ui:
		# Chama método específico para fechar a UI ativa
		if active_ui.has_method("close_ui"):
			active_ui.close_ui()
		else:
			# Fallback: apenas esconde a UI
			active_ui.hide()
			active_ui = null
			npc_interaction_ui.hide_subsystem()

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
		PlayerEvents.show_interaction(interact_text)
		can_interact = true

func _on_player_interact_area_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		PlayerEvents.hide_interaction()
		can_interact = false
