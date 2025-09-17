# set_bonus.gd
class_name SetBonus

var required_pieces: int
var attribute: ItemAttribute

func _init(_required_pieces: int, _attribute: ItemAttribute) -> void:
	required_pieces = _required_pieces
	attribute = _attribute

static var UNIQUE_SETS_BONUSES: Dictionary = {
	
	EquipmentItem.SETS.SAMURAI: [
		SetBonus.new(1, ItemAttribute.new(ItemAttribute.TYPE.DAMAGE, 250.0))
	],
	EquipmentItem.SETS.WINDCUTTER: [
		SetBonus.new(2, ItemAttribute.new(ItemAttribute.TYPE.DAMAGE, 300.0)),
		SetBonus.new(3, ItemAttribute.new(ItemAttribute.TYPE.ATTACK_SPEED, 0.10))
	],
	EquipmentItem.SETS.SERPENT_EMBRACE: [
		SetBonus.new(2, ItemAttribute.new(ItemAttribute.TYPE.CRITICAL_DAMAGE, 0.15)),
		SetBonus.new(3, ItemAttribute.new(ItemAttribute.TYPE.POISON_HIT_RATE, 0.15)),
		SetBonus.new(5, ItemAttribute.new(ItemAttribute.TYPE.POISON_HIT_RATE, 0.15)),
	],
	EquipmentItem.SETS.SILVER_MOON: [
		SetBonus.new(2, ItemAttribute.new(ItemAttribute.TYPE.CRITICAL_RATE, 350)),
		SetBonus.new(3, ItemAttribute.new(ItemAttribute.TYPE.ATTACK_SPEED, 0.25))
	],
	EquipmentItem.SETS.SACRED_CRUSADER: [
		SetBonus.new(2, ItemAttribute.new(ItemAttribute.TYPE.HEALTH, 2000.0)),
		SetBonus.new(3, ItemAttribute.new(ItemAttribute.TYPE.DEFENSE, 800.0)),
	],
	EquipmentItem.SETS.FROSTBEAR_WRATH: [
		SetBonus.new(2, ItemAttribute.new(ItemAttribute.TYPE.HEALTH, 4000.0)),
		SetBonus.new(3, ItemAttribute.new(ItemAttribute.TYPE.DEFENSE, 1000.0)),
		SetBonus.new(5, ItemAttribute.new(ItemAttribute.TYPE.HEALTH_REGEN, 15.0)),
	],
	EquipmentItem.SETS.LOST_KING: [
		SetBonus.new(2, ItemAttribute.new(ItemAttribute.TYPE.HEALTH, 3000.0)),
		SetBonus.new(3, ItemAttribute.new(ItemAttribute.TYPE.DEFENSE, 1000.0)),
		SetBonus.new(5, ItemAttribute.new(ItemAttribute.TYPE.CRITICAL_RATE, 500.0)),
		SetBonus.new(6, ItemAttribute.new(ItemAttribute.TYPE.CRITICAL_DAMAGE, 0.15)),
		SetBonus.new(7, ItemAttribute.new(ItemAttribute.TYPE.DAMAGE, 750.0)),
	],
	EquipmentItem.SETS.DEMONS_BANE: [
		SetBonus.new(2, ItemAttribute.new(ItemAttribute.TYPE.CRITICAL_DAMAGE, 0.20)),
		SetBonus.new(3, ItemAttribute.new(ItemAttribute.TYPE.DAMAGE, 1000.0)),
		SetBonus.new(4, ItemAttribute.new(ItemAttribute.TYPE.ATTACK_SPEED, 0.20)),
		SetBonus.new(5, ItemAttribute.new(ItemAttribute.TYPE.DEFENSE, 1200.0)),
	],
	EquipmentItem.SETS.SOLARIS: [
		SetBonus.new(2, ItemAttribute.new(ItemAttribute.TYPE.HEALTH, 5000.0)),
		SetBonus.new(3, ItemAttribute.new(ItemAttribute.TYPE.DAMAGE, 1500.0)),
		SetBonus.new(4, ItemAttribute.new(ItemAttribute.TYPE.DEFENSE, 1500.0)),
		SetBonus.new(5, ItemAttribute.new(ItemAttribute.TYPE.ATTACK_SPEED, 0.10)),
		SetBonus.new(6, ItemAttribute.new(ItemAttribute.TYPE.MOVE_SPEED, 0.25)),
	],
	EquipmentItem.SETS.DEATH_REAPER: [
		SetBonus.new(2, ItemAttribute.new(ItemAttribute.TYPE.DAMAGE, 1000.0)),
		SetBonus.new(3, ItemAttribute.new(ItemAttribute.TYPE.DAMAGE, 1500.0)),
		SetBonus.new(4, ItemAttribute.new(ItemAttribute.TYPE.CRITICAL_RATE, 1000)),
		SetBonus.new(5, ItemAttribute.new(ItemAttribute.TYPE.CRITICAL_DAMAGE, 0.45)),
		SetBonus.new(6, ItemAttribute.new(ItemAttribute.TYPE.ATTACK_SPEED, 0.25)),

	],
	EquipmentItem.SETS.JUGGERNOUT: [
		SetBonus.new(1, ItemAttribute.new(ItemAttribute.TYPE.CRITICAL_DAMAGE, 1.0)),
	],
	EquipmentItem.SETS.ELEMENTALS_POWERFULL: [
		SetBonus.new(2, ItemAttribute.new(ItemAttribute.TYPE.HEALTH, 10000.0)),
		SetBonus.new(2, ItemAttribute.new(ItemAttribute.TYPE.MANA, 250.0)),
		SetBonus.new(2, ItemAttribute.new(ItemAttribute.TYPE.ENERGY, 100.0)),
	],
	
	# Defina os demais sets seguindo o mesmo padrão...
}

func get_bonus_description() -> String:
	var attr_name = ItemAttribute.get_attribute_type_name(attribute.type)
	var value_str = ItemAttribute.format_value(attribute.type, attribute.value)
	var desc = "+ %s %s" % [value_str, attr_name]
	return desc

# Função auxiliar para obter os bônus ativos baseado no número de peças equipadas
static func get_active_set_bonuses(_set_type: EquipmentItem.SETS, equipped_pieces: int) -> Array[ItemAttribute]:
	var active_bonuses: Array[ItemAttribute] = []
	
	if not UNIQUE_SETS_BONUSES.has(_set_type):
		return active_bonuses
	
	var bonuses = UNIQUE_SETS_BONUSES[_set_type]
	
	# Ordena por required_pieces em ordem decrescente para pegar o maior bônus disponível
	bonuses.sort_custom(func(a, b): return a.required_pieces > b.required_pieces)
	
	for bonus in bonuses:
		if equipped_pieces >= bonus.required_pieces:
			active_bonuses.append(bonus.attribute)
	
	return active_bonuses

# Nova função: Retorna informações para a UI sobre peças equipadas e bônus ativos
static func get_set_ui_info(_set_type: EquipmentItem.SETS) -> SetUIInfo:
	var ui_info = SetUIInfo.new()
	
	# Verifica se o set existe
	if not UNIQUE_SETS_BONUSES.has(_set_type):
		return ui_info
	
	# Obtém todas as peças possíveis do set
	var available_parts = EquipmentConsts.SETS_AVAILABLE_PARTS.get(_set_type, [])
	ui_info.total_pieces = available_parts.size()
	
	# Obtém as peças equipadas do player para este set
	var equipped_items := PlayerEquipments.get_equipped_set_items(_set_type)
	ui_info.total_equipped = equipped_items.size()
	
	# Preenche informações das peças
	for part_type in available_parts:
		var part_name = LocalizationManager.get_equipment_unique_item(_set_type, part_type)
		var is_equipped = false
		
		# Verifica se esta peça está equipada
		for equipped_item in equipped_items:
			if equipped_item.equipment_type == part_type:
				is_equipped = true
				break
		
		var piece_info = SetUIInfo.SetPieceInfo.new(part_name, is_equipped, part_type)
		ui_info.add_piece_info(piece_info)
	
	# Preenche informações dos bônus
	var bonuses = UNIQUE_SETS_BONUSES[_set_type]
	
	# Ordena por required_pieces em ordem crescente
	bonuses.sort_custom(func(a, b): return a.required_pieces < b.required_pieces)
	
	for bonus in bonuses:
		var is_active = ui_info.total_equipped >= bonus.required_pieces
		# var pieces_text = LocalizationManager.get_ui_text("pieces")
		var description = "(%d): %s" % [bonus.required_pieces, bonus.get_bonus_description()]
		
		var bonus_info = SetUIInfo.SetBonusInfo.new(description, is_active, bonus.required_pieces)
		ui_info.add_bonus_info(bonus_info)
	
	return ui_info

# Função para obter a descrição completa dos bônus do set
static func get_set_bonus_descriptions(_set_type: EquipmentItem.SETS) -> Array[String]:
	if not UNIQUE_SETS_BONUSES.has(_set_type):
		return []
	
	var description: Array[String] = []
	var bonuses = UNIQUE_SETS_BONUSES[_set_type]
	
	# Ordena por required_pieces em ordem crescente
	bonuses.sort_custom(func(a, b): return a.required_pieces < b.required_pieces)

	# var pieces = LocalizationManager.get_ui_text("pieces")
	for bonus in bonuses:
		description.append("(%d): %s" % [bonus.required_pieces, bonus.get_bonus_description()])
	
	return description
