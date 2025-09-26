class_name ItemAction
extends Resource

enum TYPE {INSTANTLY, BUFF}

## Define a ação que um item pode realizar, como curar, aumentar atributos, etc.
@export var action_type: TYPE = TYPE.INSTANTLY
## O atributo que será afetado pela ação do item
@export var attribute: ItemAttribute
@export var duration: float = 0.0


func save_data() -> Dictionary:
	return Utils.serialize_object(self)

func load_data(data: Dictionary) -> ItemAction:
	return Utils.deserialize_object(data) as ItemAction

# func save_data() -> Dictionary:
# 	return {
# 		"__resource_type": "ItemAction",
#			"__script_path": self.get_script().resource_path,
# 		"action_type": action_type,
# 		"duration": duration,
# 		"attribute": attribute.save_data() if attribute else {}
# 	}

# func load_data(data: Dictionary) -> void:
# 	if data.is_empty():
# 		return
	
# 	action_type = data.get("action_type", TYPE.INSTANTLY)
# 	duration = data.get("duration", 0.0)
	
# 	if data.has("attribute") and data["attribute"] is Dictionary:
# 		if attribute == null:
# 			attribute = ItemAttribute.new()
# 		attribute.load_data(data["attribute"])
