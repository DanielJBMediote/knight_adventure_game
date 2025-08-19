extends Node

signal inventory_updated
signal inventory_saved()
signal inventory_loaded()
signal close_open_inventory(is_open: bool)

var is_open: bool = false

static var items: Array[Item] = []
static var slots: Array[Item] = []
static var current_page: int = 0

const MAX_SLOTS := 54
const SLOTS_PER_PAGE := 18

func _ready():
	# Inicializa slots vazios
	for i in range(MAX_SLOTS):  # Número de slots
		slots.append(null)
	
	#create_ramdon_items()

func create_ramdon_items() -> void:
	for i in 200:
		var item = PotionItem.new()
		add_item(item)

func handle_inventory_visibility() -> void:
	is_open = !is_open
	close_open_inventory.emit(is_open)

func add_item(item: Item) -> bool:
	# Se o item não for stackable, trata como item único
	item.use_item.connect(PlayerEvents._on_item_used)
		
	if not item.stackable:
		return add_single_item(item)
	
	# Tenta adicionar a stacks existentes primeiro
	var remaining_stack = item.current_stack
	remaining_stack = try_add_to_existing_stacks(item, remaining_stack)
	
	# Se ainda sobrar itens, adiciona em slots vazios
	if remaining_stack > 0:
		remaining_stack = add_to_empty_slots(item, remaining_stack)
	
	# Retorna true se pelo menos parte do stack foi adicionada
	inventory_updated.emit()
	return remaining_stack < item.current_stack

func add_single_item(item: Item) -> bool:
	# Procura por um slot vazio para item único
	for i in range(slots.size()):
		if slots[i] == null:
			slots[i] = item.duplicate()  # Usa duplicate para não compartilhar referência
			slots[i].current_stack = 1  # Garante que itens únicos tenham stack 1
			items.append(slots[i])
			return true
	return false

func try_add_to_existing_stacks(item: Item, remaining_stack: int) -> int:
	for i in range(slots.size()):
		if slots[i] == null:
			continue
			
		# Verifica se pode adicionar a este stack
		if (slots[i].item_id == item.item_id and 
			slots[i].item_rarity == item.item_rarity and
			slots[i].current_stack < slots[i].max_stack):
			
			var available_space = slots[i].max_stack - slots[i].current_stack
			var amount_to_add = min(available_space, remaining_stack)
			
			slots[i].current_stack += amount_to_add
			remaining_stack -= amount_to_add
			
			# Atualiza o item correspondente no array items
			for j in range(items.size()):
				if items[j] == slots[i]:
					items[j].current_stack = slots[i].current_stack
					break
			
			if remaining_stack <= 0:
				return 0
	
	return remaining_stack

func add_to_empty_slots(item: Item, remaining_stack: int) -> int:
	for i in range(slots.size()):
		if slots[i] == null:
			var new_item = item.duplicate()
			var stack_size = min(remaining_stack, new_item.max_stack)
			
			new_item.current_stack = stack_size
			slots[i] = new_item
			items.append(new_item)
			
			remaining_stack -= stack_size
			
			if remaining_stack <= 0:
				return 0
	
	return remaining_stack

func remove_item(item: Item):
	var slot_index = slots.find(item)
	if slot_index != -1:
		var item_index = items.find(item)
		if item_index != -1:
			items.erase(item)
		slots[slot_index] = null
		inventory_updated.emit()

func change_page(direction: int) -> void:
	current_page = wrapi(current_page + direction, 0, MAX_SLOTS / SLOTS_PER_PAGE)
	inventory_updated.emit()

func get_current_page_items() -> Array[Item]:
	var start_index = current_page * SLOTS_PER_PAGE
	var end_index = start_index + SLOTS_PER_PAGE
	return slots.slice(start_index, end_index)

func save_inventory():
	var save_data = []
	for item in items:
		if item != null:
			save_data.append({
				"id": item.id,
				"current_stack": item.current_stack
			})
		else:
			save_data.append(null)
	
	# Salva no arquivo (usando Godot's File API)
	var file = FileAccess.open("user://inventory.save", FileAccess.WRITE)
	file.store_var(save_data)

func load_inventory():
	if FileAccess.file_exists("user://inventory.save"):
		var file = FileAccess.open("user://inventory.save", FileAccess.READ)
		var save_data = file.get_var()
		
		for i in range(min(save_data.size(), items.size())):
			if save_data[i] != null:
				var item_data = save_data[i]
				var item = load("res://items/%s.tres" % item_data["id"])
				if item:
					item.current_stack = item_data["current_stack"]
					items[i] = item
		
		inventory_updated.emit()
