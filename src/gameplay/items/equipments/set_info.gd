# set_ui_info.gd
class_name SetUIInfo

# Classe para informações de peça do set
class SetPieceInfo:
	var piece_name: String
	var piece_equipped: bool
	var piece_type: EquipmentItem.TYPE
	
	func _init(_name: String, _is_equipped: bool, _type: EquipmentItem.TYPE) -> void:
		piece_name = _name
		piece_equipped = _is_equipped
		piece_type = _type
	
	func get_name() -> String:
		return piece_name
	
	func is_equipped() -> bool:
		return piece_equipped
	
	func get_type() -> EquipmentItem.TYPE:
		return piece_type

# Classe para informações de bônus do set
class SetBonusInfo:
	var bonus_description: String
	var bonus_active: bool
	var bonus_required_pieces: int
	
	func _init(_description: String, _is_active: bool, _required_pieces: int) -> void:
		bonus_description = _description
		bonus_active = _is_active
		bonus_required_pieces = _required_pieces
	
	func get_description() -> String:
		return bonus_description
	
	func is_active() -> bool:
		return bonus_active
	
	func get_required_pieces() -> int:
		return bonus_required_pieces

# Classe principal com todas as informações do set
var equipped_pieces: Array[SetPieceInfo]
var active_bonuses: Array[SetBonusInfo]
var total_equipped: int
var total_pieces: int

func _init() -> void:
	equipped_pieces = []
	active_bonuses = []
	total_equipped = 0
	total_pieces = 0

func get_equipped_pieces() -> Array[SetPieceInfo]:
	return equipped_pieces

func get_active_bonuses() -> Array[SetBonusInfo]:
	return active_bonuses

func get_total_equipped() -> int:
	return total_equipped

func get_total_pieces() -> int:
	return total_pieces

func add_piece_info(piece_info: SetPieceInfo) -> void:
	equipped_pieces.append(piece_info)

func add_bonus_info(bonus_info: SetBonusInfo) -> void:
	active_bonuses.append(bonus_info)
