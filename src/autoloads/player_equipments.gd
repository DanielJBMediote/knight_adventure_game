extends Node

signal player_equipment_updated(slot_type: EquipmentItem.TYPE, equipment: EquipmentItem)

var equipped_items: Dictionary = {} # Dicionário por tipo de equipamento
var equipment_slots: Array[EquipmentItem.TYPE] = [
	EquipmentItem.TYPE.HELMET,
	EquipmentItem.TYPE.ARMOR,
	EquipmentItem.TYPE.BOOTS,
	EquipmentItem.TYPE.GLOVES,
	EquipmentItem.TYPE.RING,
	EquipmentItem.TYPE.AMULET,
	EquipmentItem.TYPE.WEAPON
]

var active_attributes: Array[ItemAttribute]


func _ready() -> void:
	PlayerEvents.update_equipment.connect(_update_equipment)
	# Inicializa slots vazios
	for slot in equipment_slots:
		equipped_items[slot] = null


func _update_equipment(equipment: EquipmentItem) -> void:
	if equipment:
		var equipped_slot = get_equipped_item_type(equipment.equipment_type)
		if equipped_slot == null:
			equip(equipment)
		elif equipped_slot.equipment_type == equipment.equipment_type:
			if equipped_slot == equipment:
				unequip(equipment)
			else:
				swap_equipment(equipment)

func can_equip(equipment: EquipmentItem) -> bool:
	if not equipment:
		return false
	# var player_level = PlayerStats.level
	var item_level = equipment.item_level
	# Verifica nível requerido
	if not ItemManager.compare_player_level(item_level):
		var part_1 = LocalizationManager.get_ui_text("insufficient_level")
		var part_2 = LocalizationManager.get_ui_text("level_required")
		var message = str(part_1, "! ", part_2, ": ", equipment.item_level, ".")
		GameEvents.show_instant_message(message, InstantMessage.TYPE.DANGER)
		return false

	# Verifica se o slot está disponível
	if equipment.equipment_type not in equipment_slots:
		# print("Tipo de equipamento inválido: ", equipment.equipment_type)
		return false

	return true


func swap_equipment(new_equipment: EquipmentItem) -> bool:
	var slot_type = new_equipment.equipment_type

	# Verifica se pode equipar
	if not can_equip(new_equipment):
		return false

	# Guarda o item atual para possível restauração
	var current_equipped = equipped_items[slot_type]

	# Tenta adicionar o item atual de volta ao inventário se existir
	if current_equipped:
		var slot_index = new_equipment.slot_index_ref
		# Rremover o itme do inventário
		InventoryManager.remove_item(new_equipment)
		# Tentar adicionar o item equipado para o inventário
		if not InventoryManager.add_item(current_equipped, slot_index):
			# Não tem espaço no inventário - cancela a operação
			printerr("No space in inventory to unequip item or swap equipments.")
			return false
		remove_equipment_stats(current_equipped)

	# Equipa o novo item
	equipped_items[slot_type] = new_equipment
	apply_equipment_stats(new_equipment)

	# Remove o novo item do inventário
	InventoryManager.remove_item(new_equipment)
	InventoryManager.inventory_updated.emit()
	player_equipment_updated.emit(slot_type, new_equipment)
	return true


func equip(new_equipment: EquipmentItem) -> bool:
	var slot_type = new_equipment.equipment_type

	# Verifica se pode equipar
	if not can_equip(new_equipment):
		return false

	# Se já tem item equipado, tenta desequipar primeiro
	if equipped_items[slot_type] != null:
		var current_equipped = equipped_items[slot_type]
		if not unequip(current_equipped, new_equipment.slot_index_ref):
			# Não foi possível desequipar (inventário cheio)
			return false

	# Equipa novo item
	equipped_items[slot_type] = new_equipment
	apply_equipment_stats(new_equipment)

	# Remove do inventário
	InventoryManager.remove_item(new_equipment)
	InventoryManager.inventory_updated.emit()
	player_equipment_updated.emit(slot_type, new_equipment)
	# print("Equipped: ", new_equipment.item_name)
	return true

# Retornar bool para sucesso
func unequip(equipment: EquipmentItem, slot_index: int = -1) -> bool:
	var slot_type = equipment.equipment_type
	var equipped = equipped_items[slot_type]
	if equipped == equipment:
		# Verifica se tem espaço no inventário primeiro
		var is_added = InventoryManager.add_item(equipment, slot_index)
		if is_added:
			remove_equipment_stats(equipment)
			equipped_items[slot_type] = null
			player_equipment_updated.emit(slot_type, null)
			InventoryManager.inventory_updated.emit()
			return true
		else:
			return false
	return false


func apply_equipment_stats(equipment: EquipmentItem) -> void:
	if not equipment:
		return

	# 1. Primeiro remove TODOS os bônus de set atuais
	remove_all_set_bonuses()

	# 2. Aplica os atributos base do equipamento
	#apply_base_equipment_stats(equipment, 1.0)

	# 3. Aplica os atributos adicionais do equipamento
	var all_attributes = equipment.get_all_attributes()
	apply_attributes_to_stats(all_attributes, 1.0)

	# 4. Recalcula e aplica os bônus de set (agora incluindo o novo equipamento)
	apply_all_set_bonuses()

	PlayerStats.emit_attributes_changed()


func remove_equipment_stats(equipment: EquipmentItem) -> void:
	if not equipment:
		return

	# 1. Primeiro remove TODOS os bônus de set atuais
	remove_all_set_bonuses()

	# 2. Remove os atributos base do equipamento
	#apply_base_equipment_stats(equipment, -1.0)

	# 3. Remove os atributos adicionais do equipamento
	var all_attributes = equipment.get_all_attributes()
	apply_attributes_to_stats(all_attributes, -1.0)

	# 4. Recalcula e aplica os bônus de set (agora sem o equipamento removido)
	apply_all_set_bonuses()

	PlayerStats.emit_attributes_changed()


func apply_base_equipment_stats(equipment: EquipmentItem, multiplier: float) -> void:
	if equipment.equipment_type == EquipmentItem.TYPE.WEAPON:
		PlayerStats.update_min_damage(equipment.damage.min_value * multiplier)
		PlayerStats.update_max_damage(equipment.damage.max_value * multiplier)
	else:
		PlayerStats.update_defense_points(equipment.defense.value * multiplier)


func apply_all_set_bonuses() -> void:
	var bonus_attributes = get_set_bonus_attributes()
	apply_attributes_to_stats(bonus_attributes, 1.0)


func remove_all_set_bonuses() -> void:
	var bonus_attributes = get_set_bonus_attributes()
	apply_attributes_to_stats(bonus_attributes, -1.0)


# Método genérico para aplicar/remover atributos
func apply_attributes_to_stats(attributes: Array[ItemAttribute], multiplier: float) -> void:
	for attribute in attributes:
		var value = attribute.value * multiplier
		apply_single_attribute(attribute.type, value)


# Método para aplicar um único atributo
func apply_single_attribute(attribute_type: ItemAttribute.TYPE, value: float) -> void:
	match attribute_type:
		ItemAttribute.TYPE.HEALTH:
			PlayerStats.update_max_health(value)
		ItemAttribute.TYPE.MANA:
			PlayerStats.update_max_mana(value)
		ItemAttribute.TYPE.DAMAGE:
			PlayerStats.update_min_damage(value)
			PlayerStats.update_max_damage(value)
		ItemAttribute.TYPE.DEFENSE:
			PlayerStats.update_defense_points(value)
		ItemAttribute.TYPE.CRITICAL_RATE:
			PlayerStats.update_critical_rate(value)
		ItemAttribute.TYPE.CRITICAL_DAMAGE:
			PlayerStats.update_critical_damage(value)
		ItemAttribute.TYPE.ATTACK_SPEED:
			PlayerStats.update_attack_speed(value)
		ItemAttribute.TYPE.MOVE_SPEED:
			PlayerStats.update_move_speed(value)
		ItemAttribute.TYPE.ENERGY:
			PlayerStats.update_max_energy(value)
		ItemAttribute.TYPE.ENERGY_REGEN:
			PlayerStats.update_energy_regen(value)
		ItemAttribute.TYPE.HEALTH_REGEN:
			PlayerStats.update_health_regen(value)
		ItemAttribute.TYPE.MANA_REGEN:
			PlayerStats.update_mana_regen(value)
		ItemAttribute.TYPE.POISON_HIT_RATE:
			PlayerStats.update_poison_rate(value)
		ItemAttribute.TYPE.BLEED_HIT_RATE:
			PlayerStats.update_bleed_rate(value)
		ItemAttribute.TYPE.EXP_BUFF:
			PlayerStats.update_exp_buff(value)
		# ItemAttribute.TYPE.GOLD_FIND:
		# 	PlayerStats.update_gold_find(value)
		# ItemAttribute.TYPE.ITEM_FIND:
		# 	PlayerStats.update_item_find(value)
		# ItemAttribute.TYPE.DAMAGE_REDUCTION:
		# 	PlayerStats.update_damage_reduction(value)
		# ItemAttribute.TYPE.SLOW_EFFECT:
		# 	PlayerStats.update_slow_effect(value)
		# ItemAttribute.TYPE.SPELL_POWER:
		# 	PlayerStats.update_spell_power(value)
		# ItemAttribute.TYPE.ALL_STATS:
		# 	PlayerStats.update_all_stats(value)


func get_set_bonus_attributes() -> Array[ItemAttribute]:
	var set_counts: Dictionary = {}
	var all_bonuses: Array[ItemAttribute] = []

	# Conta peças de cada set
	for slot in equipped_items:
		var item = equipped_items[slot]
		if item is EquipmentItem and item.equipment_set in EquipmentConsts.UNIQUES_SETS:
			set_counts[item.equipment_set] = set_counts.get(item.equipment_set, 0) + 1

	# Calcula bônus ativos
	for set_type in set_counts:
		var equipped_count = set_counts[set_type]
		var bonuses = SetBonus.get_active_set_bonuses(set_type, equipped_count)
		all_bonuses.append_array(bonuses)

	return all_bonuses


func get_equipped_set_items(set_type: EquipmentItem.SETS) -> Array[EquipmentItem]:
	var equipped_set_items: Array[EquipmentItem] = []

	for slot in equipped_items:
		var item = equipped_items[slot]
		if item is EquipmentItem and item.equipment_set == set_type:
			equipped_set_items.append(item)

	return equipped_set_items


func get_equipped_item_type(slot_type: EquipmentItem.TYPE) -> EquipmentItem:
	return equipped_items.get(slot_type, null)


func is_equipped(item: EquipmentItem) -> bool:
	var equipped = equipped_items.get(item.equipment_type, null)
	return item == equipped


func is_slot_occupied(slot_type: EquipmentItem.TYPE) -> bool:
	return equipped_items.get(slot_type, null) != null


func get_all_equipped_items() -> Array[EquipmentItem]:
	var items: Array[EquipmentItem] = []
	for slot in equipment_slots:
		if equipped_items[slot]:
			items.append(equipped_items[slot])
	return items


func get_all_unique_sets_equipped_items() -> Dictionary:
	var unique_sets: Dictionary = {}

	for item in get_all_equipped_items():
		if item.equipment_set in EquipmentConsts.UNIQUES_SETS:
			if not unique_sets.has(item.equipment_set):
				unique_sets[item.equipment_set] = []
			unique_sets[item.equipment_set].append(item)

	return unique_sets


func get_total_equipment_bonuses() -> Array[ItemAttribute]:
	return active_attributes
