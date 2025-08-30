class_name UniqueItemBonus
extends Resource

class BonusSetup:
	
	var set_name: EquipmentItem.SETS
	var triggers_interval: Array[int]
	
	func _init(_set_name: EquipmentItem.SETS, _triggers_interval: Array[int]):
		self.set_name = _set_name
		self.triggers_interval = _triggers_interval



@export var atributes: Array[ItemAttribute] = []
@export var equips_trigger_num: int
