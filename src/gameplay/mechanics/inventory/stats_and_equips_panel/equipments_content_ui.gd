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
	PlayerEquipments.player_equipment_updated.connect(_on_update_player_equipment)
	_initialize_slot_map()
	_initialize_equipments()

func _initialize_equipments() -> void:
	for equipment in PlayerEquipments.get_all_equipped_items():
		var target_slot = slot_map[equipment.equipment_type]
		if equipment and target_slot != null:
			target_slot.setup_equipment(equipment)
			

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

func _on_update_player_equipment(slot_type: EquipmentItem.TYPE, equipment: EquipmentItem) -> void:
	if slot_type in slot_map:
		var target_slot: EquipmentItemSlotUI = slot_map[slot_type]
		target_slot.setup_equipment(equipment)

# Método alternativo se você quiser limpar todos os slots
func clear_all_equipment() -> void:
	for slot in slot_map.values():
		slot.setup_equipment(null)

# Método para obter um slot específico pelo tipo
func get_slot_by_type(equipment_type: int) -> EquipmentItemSlotUI:
	return slot_map.get(equipment_type, null)
