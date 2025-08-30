extends Node

var equipped_items: Dictionary = {}  # Dicionário por tipo de equipamento
var equipment_slots: Array[EquipmentItem.TYPE] = [
	EquipmentItem.TYPE.HELMET,
	EquipmentItem.TYPE.AMULET,
	EquipmentItem.TYPE.RING,
	EquipmentItem.TYPE.GLOVES,
	EquipmentItem.TYPE.ARMOR,
	EquipmentItem.TYPE.WEAPON,
	EquipmentItem.TYPE.BOOTS
]


func _ready() -> void:
	PlayerEvents.update_equipment.connect(_update_equipment)
	# Inicializa slots vazios
	for slot in equipment_slots:
		equipped_items[slot] = null


func _update_equipment(equipment: EquipmentItem, is_equipped: bool = false) -> void:
	if equipment:
		if is_equipped:
			unequip(equipment)
		elif can_equip(equipment):
			equip(equipment)


func can_equip(equipment: EquipmentItem) -> bool:
	if not equipment:
		return false
	var player_level = PlayerStats.level
	var item_level = equipment.item_level
	# Verifica nível requerido
	if not ItemManager.compare_player_level(item_level):
		print("Nível insuficiente para equipar: ", equipment.item_name)
		return false

	# Verifica se o slot está disponível
	if equipment.equipment_type not in equipment_slots:
		print("Tipo de equipamento inválido: ", equipment.equipment_type)
		return false

	return true


func equip(new_equipment: EquipmentItem) -> void:
	#if not can_equip(new_equipment):
		#return

	var slot_type = new_equipment.equipment_type

	# Desequipa item atual se houver
	if equipped_items[slot_type] != null:
		var current_equipped = equipped_items[slot_type]
		unequip(current_equipped)

	# Equipa novo item
	equipped_items[slot_type] = new_equipment
	apply_equipment_stats(new_equipment)
	InventoryManager.remove_item(new_equipment)

	#print("Equipado: ", new_equipment.item_name, " no slot: ", slot_type)


func unequip(equipment: EquipmentItem) -> bool:  # Retornar bool para sucesso
	var slot_type = equipment.equipment_type
	if equipped_items[slot_type] == equipment:
		# Verifica se tem espaço no inventário primeiro
		if InventoryManager.add_item(equipment):
			remove_equipment_stats(equipment)
			equipped_items[slot_type] = null
			#InventoryManager.add_item(equipment)
			return true
		else:
			print("Inventário cheio! Não foi possível desequipar.")
			return false
	return false


func apply_equipment_stats(equipment: EquipmentItem) -> void:
	if not equipment:
		return
		
	if equipment.equipment_type == EquipmentItem.TYPE.WEAPON:
		PlayerStats.update_min_damage(equipment.damage.value)
		PlayerStats.update_max_damage(equipment.damage.value)
	else:
		PlayerStats.update_defense(equipment.defense.value)
	
	# Processa todos os atributos de uma vez
	for attribute in equipment.get_all_attributes():
		match attribute.type:
			ItemAttribute.TYPE.HEALTH:
				PlayerStats.update_max_health(attribute.value)
			ItemAttribute.TYPE.MANA:
				PlayerStats.update_max_mana(attribute.value)
			ItemAttribute.TYPE.DAMAGE:
				PlayerStats.update_min_damage(attribute.min_value)
				PlayerStats.update_max_damage(attribute.max_value)
			ItemAttribute.TYPE.DEFENSE:
				PlayerStats.update_defense(attribute.value)
			ItemAttribute.TYPE.CRITICAL_RATE:
				PlayerStats.update_critical_rate(attribute.value)
			ItemAttribute.TYPE.CRITICAL_DAMAGE:
				PlayerStats.update_critical_damage(attribute.value)
			ItemAttribute.TYPE.ATTACK_SPEED:
				PlayerStats.update_attack_speed(attribute.value)
			ItemAttribute.TYPE.MOVE_SPEED:
				PlayerStats.update_move_speed(attribute.value)
	
	# Atualiza a UI com um único evento
	PlayerStats.emit_attributes_changed()

func remove_equipment_stats(equipment: EquipmentItem) -> void:
	if not equipment:
		return
	
	if equipment.equipment_type == EquipmentItem.TYPE.WEAPON:
		PlayerStats.update_min_damage(-equipment.damage.min_value)
		PlayerStats.update_max_damage(-equipment.damage.max_value)
	else:
		PlayerStats.update_defense(-equipment.defense.value)
	
	# Processa todos os atributos de uma vez (subtraindo)
	for attribute in equipment.get_all_attributes():
		match attribute.type:
			ItemAttribute.TYPE.HEALTH:
				PlayerStats.update_max_health(-attribute.value)
			ItemAttribute.TYPE.MANA:
				PlayerStats.update_max_mana(-attribute.value)
			ItemAttribute.TYPE.DAMAGE:
				PlayerStats.update_min_damage(-attribute.value)
				PlayerStats.update_max_damage(-attribute.value)
			ItemAttribute.TYPE.DEFENSE:
				PlayerStats.update_defense(-attribute.value)
			ItemAttribute.TYPE.CRITICAL_RATE:
				PlayerStats.update_critical_rate(-attribute.value)
			ItemAttribute.TYPE.CRITICAL_DAMAGE:
				PlayerStats.update_critical_damage(-attribute.value)
			ItemAttribute.TYPE.ATTACK_SPEED:
				PlayerStats.update_attack_speed(-attribute.value)
			ItemAttribute.TYPE.MOVE_SPEED:
				PlayerStats.update_move_speed(-attribute.value)
	
	PlayerStats.emit_attributes_changed()


func get_equipped_item_type(slot_type: EquipmentItem.TYPE) -> EquipmentItem:
	return equipped_items.get(slot_type, null)


func is_equipped(item: EquipmentItem) -> bool:
	var equipped = equipped_items.get(item.equipment_type, null)
	return equipped == item


func is_slot_occupied(slot_type: EquipmentItem.TYPE) -> bool:
	return equipped_items.get(slot_type, null) != null


func get_all_equipped_items() -> Array[EquipmentItem]:
	var items: Array[EquipmentItem] = []
	for slot in equipment_slots:
		if equipped_items[slot]:
			items.append(equipped_items[slot])
	return items


func get_total_equipment_bonuses() -> Dictionary:
	var bonuses = {
		"health": 0.0,
		"mana": 0.0,
		"energy": 0.0,
		"min_damage": 0.0,
		"max_damage": 0.0,
		"defense": 0.0,
		"critical_rate": 0.0,
		"critical_damage": 0.0,
		"attack_speed": 0.0,
		"move_speed": 0.0
	}

	#for item in get_all_equipped_items():
	#bonuses.health += item.health_bonus
	#bonuses.mana += item.mana_bonus
	#bonuses.energy += item.energy_bonus
	#bonuses.min_damage += item.min_damage_bonus
	#bonuses.max_damage += item.max_damage_bonus
	#bonuses.defense += item.defense_bonus
	#bonuses.critical_rate += item.critical_rate_bonus
	#bonuses.critical_damage += item.critical_damage_bonus
	#bonuses.attack_speed += item.attack_speed_bonus
	#bonuses.move_speed += item.move_speed_bonus

	return bonuses
