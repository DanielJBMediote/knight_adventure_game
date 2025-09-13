# equipment_socket_manager.gd
class_name EquipmentSocketManager
extends Node

static func add_gem_to_socket(equipment: EquipmentItem, gem: GemItem, socket_index: int = -1) -> bool:

	if socket_index == -1:
		for slot_key in equipment.attached_gems.keys():
			if equipment.attached_gems[slot_key] == null:
				socket_index = slot_key
				break

	if not equipment:
		return false
	
	if socket_index >= equipment.available_sockets:
		return false
	
	# Verificar se o socket já tem uma gema
	if equipment.attached_gems.has(socket_index) and equipment.attached_gems[socket_index] != null:
		return false
	
	var new_gem = gem.clone()
	new_gem.current_stack = 1
	# Adicionar a gema ao socket
	equipment.attached_gems[socket_index] = new_gem
	InventoryManager.remove_item(gem)
	equipment.recalculate_power()
	
	return true

static func remove_gem_from_socket(equipment: EquipmentItem, socket_index: int) -> bool:
	if not equipment:
		return false
	
	if not equipment.attached_gems.has(socket_index):
		return false
	
	var gem = equipment.attached_gems[socket_index]
	if gem:
		InventoryManager.add_item(gem)
		equipment.attached_gems[socket_index] = null
		equipment.recalculate_power()
		return true
	
	return false
