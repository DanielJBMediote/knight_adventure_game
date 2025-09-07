class_name NPCDialogData
extends Resource

var questing: Array[String] = []
var greetings: Array[String] = []
var exiting: Array[String] = []
var buying_selling: Array[String] = []
var after_buying: Array[String] = []
var after_selling: Array[String] = []
var no_golds: Array[String] = []

func assign_data(data: Dictionary) -> void:
	for key in data:
		var has_key = get(key) != null and get(key).is_empty()
		if has_key:
			var target_array = get(key)
			var source_array = data[key]
			if source_array is Array:
				target_array.clear()
				for item in source_array:
					target_array.append(item)

func get_random_dialog_greetings() -> String:
	return greetings.pick_random() if greetings.size() > 0 else "..."

func get_random_dialog_exiting() -> String:
	return exiting.pick_random() if exiting.size() > 0 else "..."

func get_random_dialog_buying_selling() -> String:
	return buying_selling.pick_random() if buying_selling.size() > 0 else "..."

func get_random_dialog_after_buying() -> String:
	return after_buying.pick_random() if after_buying.size() > 0 else "..."

func get_random_dialog_after_selling() -> String:
	return after_selling.pick_random() if after_selling.size() > 0 else "..."
