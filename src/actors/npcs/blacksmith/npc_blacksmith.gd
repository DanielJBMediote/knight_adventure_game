class_name NPCBlacksmith
extends NPC

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@onready var socket_gem_system_ui_scene: PackedScene = preload("res://src/gameplay/mechanics/equipment_socket_gem_system_ui.tscn")
#@onready var shop_ui_scene: PackedScene = preload("res://src/gameplay/mechanics/shop_ui.tscn")

var socket_system_ui: EquipmentSocketGemSystemUI
#var shop_ui: ShopUI


func _ready() -> void:
	super._ready()
	var npc_data := LocalizationManager.get_npc_data("blacksmith")
	dialog_ballon.dialog_started.connect(_on_dialog_stated)
	dialog_ballon.dialog_finished.connect(_on_dialog_finished)
	if not npc_data.is_empty():
		self.npc_name = npc_data.get("name", "Unknown")
		self.npc_type = TYPE.BLACKSMITH
		var dialogs = npc_data.get("dialogs", {})

		npc_dialogs = NPCDialogData.new()
		npc_dialogs.assign_data(dialogs)

	if npc_texture_portrait:
		var new_tx = Texture2D.new()
		new_tx = npc_texture_portrait
		npc_interface.set_npc_texture_portrait(new_tx, { "flip_h": true })

	add_blacksmith_options()


func _on_dialog_stated() -> void:
	animated_sprite_2d.play("speaking")


func _on_dialog_finished() -> void:
	animated_sprite_2d.stop()
	animated_sprite_2d.frame = 0


func add_blacksmith_options() -> void:
	var buy_sell_label = str(LocalizationManager.get_ui_text("buy_sell"), " ", LocalizationManager.get_ui_text("equipments"))
	var equipment_socket_label = LocalizationManager.get_ui_text("equipment_gem_socket_ui")
	npc_interface.add_option(buy_sell_label, _on_buy_sell_selected)
	npc_interface.add_option(equipment_socket_label, _on_socket_management_selected)


func _on_buy_sell_selected() -> void:
	if npc_dialogs and npc_dialogs.buying_selling.size() > 0:
		var dialog = npc_dialogs.get_random_dialog_buying_selling()
		dialog_ballon.show_dialog(dialog)

	#if not shop_ui:
	#shop_ui = shop_ui_scene.instantiate()
	#shop_ui.shop_closed.connect(_on_shop_closed)
	#active_ui = shop_ui
	#
	#npc_interface.show_subsystem(shop_ui)


func _on_socket_management_selected() -> void:
	if not socket_system_ui:
		socket_system_ui = socket_gem_system_ui_scene.instantiate()
		npc_interface.main_container.add_child(socket_system_ui)
		socket_system_ui.system_closed.connect(_on_socket_system_closed)

	active_ui = socket_system_ui
	if npc_dialogs and npc_dialogs.buying_selling.size() > 0:
		var dialog = npc_dialogs.get_random_dialog_buying_selling()
		npc_interface.show_dialog(dialog)

	npc_interface.show_subsystem(socket_system_ui)


func _on_shop_closed() -> void:
	active_ui = null
	#npc_interface.hide_subsystem()


func _on_socket_system_closed() -> void:
	npc_interface.main_container.remove_child(active_ui)
	active_ui = null
	npc_interface.hide_subsystem()
