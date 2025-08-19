class_name MapDroppedItemNode
extends Node2D

func _ready() -> void:
	add_to_group("items_dropped_zone")
	# Debug para verificar se o nó está no grupo
	print("Zona de drop registrada:", name)

func add_item_in_map(item_obj: ItemObject) -> void:
	if item_obj:
		add_child(item_obj)
		print("Item adicionado:", item_obj.name)
	else:
		printerr("Tentativa de adicionar item inválido")
