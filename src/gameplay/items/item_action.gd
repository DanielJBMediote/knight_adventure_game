class_name ItemAction
extends Resource

enum ActionType { INSTANTLY, BUFF, DEBUFF }

@export var action_type: ActionType = ActionType.INSTANTLY
@export var attribute_key: String = ""  # Ex: "health", "damage", "speed"
@export var amount: float = 0.0         # Valor fixo ou percentual
@export var duration: float = 0.0       # Duração em segundos (para buffs)
@export var is_percentage: bool = false # Se true, amount é percentual
