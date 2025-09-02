class_name SetBonus

var set_type: EquipmentItem.SETS
var required_pieces: int
var attributes: Array[ItemAttribute]

func _init(_set_type: EquipmentItem.SETS, _required_pieces: int, _attributes: Array[ItemAttribute]) -> void:
	set_type = _set_type
	required_pieces = _required_pieces
	attributes = _attributes


static var UNIQUE_SETS_BONUSES: Dictionary[EquipmentItem.SETS, Array] = {
	
	EquipmentItem.SETS.SERPENT_EMBRACE: [
		# 2 peças: +15% Poison Hit Rate, +10% Critical Damage
		SetBonus.new(EquipmentItem.SETS.SERPENT_EMBRACE, 2, [
			ItemAttribute.new(ItemAttribute.TYPE.POISON_HIT_RATE, 15.0),
			ItemAttribute.new(ItemAttribute.TYPE.CRITICAL_DAMAGE, 10.0)
		]),
		# 4 peças: +25% Poison Hit Rate, +15% Critical Damage, +5% Health Regen
		SetBonus.new(EquipmentItem.SETS.SERPENT_EMBRACE, 4, [
			ItemAttribute.new(ItemAttribute.TYPE.POISON_HIT_RATE, 25.0),
			ItemAttribute.new(ItemAttribute.TYPE.CRITICAL_DAMAGE, 15.0),
			ItemAttribute.new(ItemAttribute.TYPE.HEALTH_REGEN, 5.0)
		]),
		# Completo (5 peças): +35% Poison Hit Rate, +20% Critical Damage, +10% Health Regen, +15% Damage
		SetBonus.new(EquipmentItem.SETS.SERPENT_EMBRACE, 5, [
			ItemAttribute.new(ItemAttribute.TYPE.POISON_HIT_RATE, 35.0),
			ItemAttribute.new(ItemAttribute.TYPE.CRITICAL_DAMAGE, 20.0),
			ItemAttribute.new(ItemAttribute.TYPE.HEALTH_REGEN, 10.0),
			ItemAttribute.new(ItemAttribute.TYPE.DAMAGE, 15.0)
		])
	],
	
	# EquipmentItem.SETS.SACRED_CRUSADER: [
	# 	# 2 peças: +20% Defense, +10% Health
	# 	SetBonus.new(EquipmentItem.SETS.SACRED_CRUSADER, 2, [
	# 		ItemAttribute.new(ItemAttribute.TYPE.DEFENSE, 20.0),
	# 		ItemAttribute.new(ItemAttribute.TYPE.HEALTH, 10.0)
	# 	]),
	# 	# Completo (3 peças): +35% Defense, +20% Health, +15% Damage Reduction
	# 	SetBonus.new(EquipmentItem.SETS.SACRED_CRUSADER, 3, [
	# 		ItemAttribute.new(ItemAttribute.TYPE.DEFENSE, 35.0),
	# 		ItemAttribute.new(ItemAttribute.TYPE.HEALTH, 20.0),
	# 		ItemAttribute.new(ItemAttribute.TYPE.DAMAGE_REDUCTION, 15.0)
	# 	])
	# ],
	
	# EquipmentItem.SETS.FROSTBEAR_WRATH: [
	# 	# 2 peças: +15% Slow Effect, +10% Mana
	# 	SetBonus.new(EquipmentItem.SETS.FROSTBEAR_WRATH, 2, [
	# 		ItemAttribute.new(ItemAttribute.TYPE.SLOW_EFFECT, 15.0),
	# 		ItemAttribute.new(ItemAttribute.TYPE.MANA, 10.0)
	# 	]),
	# 	# 4 peças: +25% Slow Effect, +15% Mana, +5% Mana Regen
	# 	SetBonus.new(EquipmentItem.SETS.FROSTBEAR_WRATH, 4, [
	# 		ItemAttribute.new(ItemAttribute.TYPE.SLOW_EFFECT, 25.0),
	# 		ItemAttribute.new(ItemAttribute.TYPE.MANA, 15.0),
	# 		ItemAttribute.new(ItemAttribute.TYPE.MANA_REGEN, 5.0)
	# 	]),
	# 	# Completo (5 peças): +35% Slow Effect, +20% Mana, +10% Mana Regen, +15% Spell Power
	# 	SetBonus.new(EquipmentItem.SETS.FROSTBEAR_WRATH, 5, [
	# 		ItemAttribute.new(ItemAttribute.TYPE.SLOW_EFFECT, 35.0),
	# 		ItemAttribute.new(ItemAttribute.TYPE.MANA, 20.0),
	# 		ItemAttribute.new(ItemAttribute.TYPE.MANA_REGEN, 10.0),
	# 		ItemAttribute.new(ItemAttribute.TYPE.SPELL_POWER, 15.0)
	# 	])
	# ],
	
	# # Continue definindo para todos os sets únicos...
	# EquipmentItem.SETS.LOST_KING: [
	# 	SetBonus.new(EquipmentItem.SETS.LOST_KING, 3, [
	# 		ItemAttribute.new(ItemAttribute.TYPE.GOLD_FIND, 25.0),
	# 		ItemAttribute.new(ItemAttribute.TYPE.EXP_BUFF, 15.0)
	# 	]),
	# 	SetBonus.new(EquipmentItem.SETS.LOST_KING, 5, [
	# 		ItemAttribute.new(ItemAttribute.TYPE.GOLD_FIND, 40.0),
	# 		ItemAttribute.new(ItemAttribute.TYPE.EXP_BUFF, 25.0),
	# 		ItemAttribute.new(ItemAttribute.TYPE.ITEM_FIND, 15.0)
	# 	]),
	# 	SetBonus.new(EquipmentItem.SETS.LOST_KING, 7, [
	# 		ItemAttribute.new(ItemAttribute.TYPE.GOLD_FIND, 60.0),
	# 		ItemAttribute.new(ItemAttribute.TYPE.EXP_BUFF, 40.0),
	# 		ItemAttribute.new(ItemAttribute.TYPE.ITEM_FIND, 25.0),
	# 		ItemAttribute.new(ItemAttribute.TYPE.ALL_STATS, 10.0)
	# 	])
	# ],
	
	# Defina os demais sets seguindo o mesmo padrão...
}


func get_bonus_description() -> String:
	var desc = ""
	for attr in attributes:
		var attr_name = LocalizationManager.get_attribute_name(ItemAttribute.ATTRIBUTE_KEYS[attr.type])
		var value_str = ItemAttribute.format_value(attr.type, attr.value)
		desc += "+%s %s\n" % [value_str, attr_name]
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
			active_bonuses.append_array(bonus.attributes)
			break
	
	return active_bonuses

# Função para obter a descrição completa dos bônus do set
static func get_set_bonus_descriptions(_set_type: EquipmentItem.SETS) -> Array[String]:
	if not UNIQUE_SETS_BONUSES.has(_set_type):
		return []
	
	var description := []
	var bonuses = UNIQUE_SETS_BONUSES[_set_type]
	
	# Ordena por required_pieces em ordem crescente
	bonuses.sort_custom(func(a, b): return a.required_pieces < b.required_pieces)
	var pieces = LocalizationManager.get_ui_text("pieces")
	for bonus in bonuses:
		description.append("%d %s:\n%s\n" % [bonuses.required_pieces, pieces, bonus.get_bonus_description()])
	
	return description
