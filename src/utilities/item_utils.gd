class_name ItemUtils

static func duplicate_item(item: Item) -> Item:
	var copy = item.duplicate()
	
	# Copia arrays tipados
	if item.item_attributes:
		copy.item_attributes = []
		for attr in item.item_attributes:
			var attr_copy = attr.duplicate()
			copy.item_attributes.append(attr_copy)
	
	# Copia ação do item
	if item.item_action:
		copy.item_action = item.item_action.duplicate()
	
	# Copia propriedades específicas baseadas no tipo
	if item is EquipmentItem:
		copy.set_bonus_attributes = []
		for attr in item.set_bonus_attributes:
			var attr_copy = attr.duplicate()
			copy.set_bonus_attributes.append(attr_copy)
		
		copy.equipment_type = item.equipment_type
		copy.set_group = item.set_group
		copy.equipment_set = item.equipment_set
	
	elif item is GemItem:
		copy.gem_quality = item.gem_quality
		copy.gem_type = item.gem_type
	
	elif item is PotionItem:
		copy.potion_type = item.potion_type
	
	return copy
