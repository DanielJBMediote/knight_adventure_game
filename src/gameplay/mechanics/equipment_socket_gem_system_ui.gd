class_name EquipmentSocketGemSystemUI
extends Control

signal system_closed

@onready var title: Label = $HBoxContainer/Panel/MarginContainer/Container/Title
@onready var equipment_slot_ui: EquipmentSlotUI = $HBoxContainer/Panel/MarginContainer/Container/EquipmentSlotUI


func _ready() -> void:
	title.text = LocalizationManager.get_ui_text("equipment_gem_socket_ui")
	
func close_ui() -> void:
	# Lógica para fechar a UI adequadamente
	hide()
	system_closed.emit() # Emitir o sinal se necessário
