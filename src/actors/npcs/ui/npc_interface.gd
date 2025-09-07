class_name NPCInterface
extends CanvasLayer

# Sinal para quando o botão voltar é pressionado
signal back_button_pressed(action: String)

@onready var option_button_scene: PackedScene = preload("res://src/actors/npcs/ui/npc_ui_option_botton.tscn")
@onready var npc_portrait: TextureRect = $Control/MarginContainer/MainContainer/DialogContainer/NPCPortrait

@onready var dialog_container: HBoxContainer = $Control/MarginContainer/MainContainer/DialogContainer
@onready var dialog_text: Label = $Control/MarginContainer/MainContainer/DialogContainer/DialogPanel/MarginContainer/DialogText

@onready var options_list: VBoxContainer = $Control/MarginContainer/MainContainer/OptionsList
@onready var main_container: VBoxContainer = $Control/MarginContainer/MainContainer
@onready var npc_name_label: Label = $Control/MarginContainer/MainContainer/Header/NPCNameLabel
@onready var back_button: Button = $Control/MarginContainer/MainContainer/Header/BackButton

var current_options: Array = []
var current_subsystem: Control = null
var is_showing_subsystem: bool = false

func _ready() -> void:
	dialog_container.hide()
	back_button.pressed.connect(_on_back_button_pressed)

func set_npc_texture_portrait(texture: Texture2D, options: Dictionary = {}) -> void:
	if not is_instance_valid(npc_portrait):
		push_error("npc_portrait node is not valid")
		return
	
	# Define a textura principal
	npc_portrait.texture = texture
	
	# Aplica as opções se forem fornecidas
	if not options.is_empty():
		apply_texture_options(options)

func apply_texture_options(options: Dictionary) -> void:
	for property in options:
		if npc_portrait.has_method("set_" + property):
			# Se for um método setter
			npc_portrait.call("set_" + property, options[property])
		elif npc_portrait.has_property(property):
			# Se for uma propriedade direta
			npc_portrait.set(property, options[property])
		else:
			push_warning("Property '%s' not found on npc_portrait node" % property)

func add_option(option_text: String, callback: Callable = Callable()) -> void:
	var option: NPCInterfaceUIOptionButton = option_button_scene.instantiate()
	option.text = option_text
	
	if callback.is_valid():
		option.pressed.connect(callback)
	
	options_list.add_child(option)
	current_options.append(option)

func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("back"):
		#_on_back_button_pressed()
	pass

func clear_options() -> void:
	for option in current_options:
		option.queue_free()
	current_options.clear()

func show_dialog(text: String) -> void:
	dialog_container.show()
	dialog_text.text = text
	dialog_text.visible_ratio = 0
	
	var tween = create_tween()
	var duration = text.length() / 20
	tween.tween_property(dialog_text, "visible_ratio", 1.0, duration)
	tween.finished.connect( func(): tween.kill() )

func show_subsystem(subsystem: Control) -> void:
	# Esconder opções e mostrar subsistema
	options_list.hide()
	subsystem.reparent(main_container)
	subsystem.show()
	current_subsystem = subsystem
	is_showing_subsystem = true

func hide_subsystem() -> void:
	if current_subsystem:
		# Mostrar opções novamente e esconder subsistema
		current_subsystem.hide()
		dialog_text.text = ""
		dialog_container.hide()
		current_subsystem.queue_free()
		current_subsystem.reparent(get_tree().current_scene)
		current_subsystem = null
		is_showing_subsystem = false
		options_list.show()

func _on_back_button_pressed() -> void:
	if is_showing_subsystem:
		# Se está mostrando subsistema, volta para o menu
		hide_subsystem()
		back_button_pressed.emit("back_to_menu")
		back_button.release_focus()
	else:
		# Se já está no menu, sai da interação
		back_button_pressed.emit("exit_interaction")
