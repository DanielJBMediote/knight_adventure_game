class_name EquipmentContentUI
extends GridContainer

@onready var amulet_slot: EquipmentItemSlotUI = $Left/AmuletSlot
@onready var gloves_slot: EquipmentItemSlotUI = $Left/GlovesSlot
@onready var helmet_slot: EquipmentItemSlotUI = $Center/HelmetSlot
@onready var armor_slot: EquipmentItemSlotUI = $Center/ArmorSlot
@onready var boots_slot: EquipmentItemSlotUI = $Center/BootsSlot
@onready var ring_slot: EquipmentItemSlotUI = $Right/RingSlot
@onready var weapon_slot: EquipmentItemSlotUI = $Right/WeaponSlot

# Dicionário para mapear tipos de equipamento para slots
var slot_map: Dictionary

func _ready() -> void:
	PlayerEvents.update_equipment.connect(_update_equipment)
	_initialize_slot_map()

func _initialize_slot_map() -> void:
	slot_map = {
		EquipmentItem.TYPE.HELMET: helmet_slot,
		EquipmentItem.TYPE.AMULET: amulet_slot,
		EquipmentItem.TYPE.RING: ring_slot,
		EquipmentItem.TYPE.GLOVES: gloves_slot,
		EquipmentItem.TYPE.ARMOR: armor_slot,
		EquipmentItem.TYPE.WEAPON: weapon_slot,
		EquipmentItem.TYPE.BOOTS: boots_slot
	}

func _update_equipment(equipment: EquipmentItem, is_uneqquip: bool = false) -> void:
	if equipment and equipment.equipment_type in slot_map:
		var target_slot = slot_map[equipment.equipment_type]
		if is_uneqquip:
			target_slot.setup_equipment(null)
		else:
			target_slot.setup_equipment(equipment)

# Método alternativo se você quiser limpar todos os slots
func clear_all_equipment() -> void:
	for slot in slot_map.values():
		slot.setup_equipment(null)

# Método para obter um slot específico pelo tipo
func get_slot_by_type(equipment_type: int) -> EquipmentItemSlotUI:
	return slot_map.get(equipment_type, null)
