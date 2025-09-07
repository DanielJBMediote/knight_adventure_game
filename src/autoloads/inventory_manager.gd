extends Node

signal page_changed

signal inventory_updated
# signal inventory_saved
# signal inventory_loaded
signal item_drag_started(item: Item, slot_index: int)
signal item_drag_ended(success: bool)
signal items_swapped(slot_index_a: int, slot_index_b: int)

signal update_inventory_visible(is_open: bool)

var items: Array[Item] = []
var slots: Array[Item] = []
var current_page: int = 0
var unlocked_slots: int = 54

const MAX_SLOTS: int = 54
const SLOTS_PER_PAGE: int = 18

var is_open: bool = false
var current_select_item: Item

var drag_item: Item = null
var drag_slot_index: int = -1

func _ready():
	# Inicializa slots vazios
	for i in range(MAX_SLOTS): # Número de slots
		slots.append(null)
	
	create_ramdon_items()


func create_ramdon_items() -> void:
	var enemy_stats = EnemyStats.new()
	var player_level = PlayerStats.level
	# var total_itens = 0
	for i in 10:
		# enemy_stats.level = randi_range(player_level, player_level)
		enemy_stats.level = player_level
		# var rune = RuneItem.new()
		# rune.setup(enemy_stats)
		# add_item(rune)
		# var gem = GemItem.new()
		# gem.setup(enemy_stats)
		# add_item(gem)
		# var potion = PotionItem.new()
		# potion.setup(enemy_stats)
		# add_item(potion)

		# if is_addded:
		# 	total_itens += 1
		var equip = EquipmentItem.new()
		equip.setup(enemy_stats)
		add_item(equip)
	# print("Total itens added: ", total_itens)


func handle_inventory_visibility() -> void:
	is_open = !is_open
	update_inventory_visible.emit(is_open)

func is_slot_unlocked(slot_index: int) -> bool:
	return slot_index < unlocked_slots

func unlock_slots(amount: int) -> void:
	unlocked_slots = min(unlocked_slots + amount, MAX_SLOTS)
	inventory_updated.emit()

func add_item(item: Item) -> bool:
	# Cria uma cópia do item para trabalhar
	var item_copy = item.clone()

	# Se o item não for stackable, trata como item único
	if not item_copy.stackable:
		return add_single_item(item_copy)

	# Tenta adicionar a stacks existentes primeiro
	var remaining_stack = item_copy.current_stack
	remaining_stack = try_add_to_existing_stacks(item_copy, remaining_stack)

	# Se ainda sobrar itens, adiciona em slots vazios
	if remaining_stack > 0:
		remaining_stack = add_to_empty_slots(item_copy, remaining_stack)

	# Retorna true se pelo menos parte do stack foi adicionada
	inventory_updated.emit()
	return remaining_stack < item_copy.current_stack


func add_single_item(item: Item) -> bool:
	# Procura por um slot vazio para item único
	for i in range(slots.size()):
		if slots[i] == null and is_slot_unlocked(i):
			var item_copy = item.clone()
			item_copy.current_stack = 1 # Garante que itens únicos tenham stack 1
			slots[i] = item_copy
			items.append(item_copy)
			inventory_updated.emit()
			return true
	return false


func try_add_to_existing_stacks(item: Item, remaining_stack: int) -> int:
	for i in range(slots.size()):
		if is_slot_unlocked(i) == false:
			continue
		if slots[i] == null:
			continue

		# Verifica se pode adicionar a este stack
		if (
			slots[i].item_id == item.item_id
			and slots[i].item_rarity == item.item_rarity
			and slots[i].current_stack < slots[i].max_stack
		):
			var available_space = slots[i].max_stack - slots[i].current_stack
			var amount_to_add = min(available_space, remaining_stack)

			slots[i].current_stack += amount_to_add
			remaining_stack -= amount_to_add

			if remaining_stack <= 0:
				return 0

	return remaining_stack


func add_to_empty_slots(item: Item, remaining_stack: int) -> int:
	for i in range(slots.size()):
		if slots[i] == null and is_slot_unlocked(i):
			var item_copy = item.clone()
			var stack_size = min(remaining_stack, item_copy.max_stack)

			item_copy.current_stack = stack_size
			slots[i] = item_copy
			items.append(item_copy)

			remaining_stack -= stack_size

			if remaining_stack <= 0:
				return 0

	return remaining_stack


func remove_item(item: Item, amount: int = 1) -> bool:
	# If we need to remove more than what's available in this stack, return false
	if item.current_stack < amount:
		return false
	
	# Remove from this stack
	item.current_stack -= amount
	
	# If the stack is depleted, remove the item completely
	if item.current_stack <= 0:
		var slot_index = slots.find(item)
		if slot_index != -1:
			slots[slot_index] = null
			var item_index = items.find(item)
			if item_index != -1:
				items.remove_at(item_index)
	
	inventory_updated.emit()
	return true


func remove_items(items_to_remove: Array[Item], total_amount: int) -> bool:
	var remaining_amount = total_amount
	
	# First, try to remove from the provided items array
	for item in items_to_remove:
		if remaining_amount <= 0:
			break
		
		if item != null and item.current_stack > 0:
			var amount_to_remove = min(remaining_amount, item.current_stack)
			if remove_item(item, amount_to_remove):
				remaining_amount -= amount_to_remove
	
	# If we still need more items, search the entire inventory
	if remaining_amount > 0:
		var all_items_of_type = find_many_items_by_id(items_to_remove[0].item_id if items_to_remove.size() > 0 else "")
		for item in all_items_of_type:
			if remaining_amount <= 0:
				break
			
			# Skip items that were already processed in the first loop
			if not items_to_remove.has(item) and item.current_stack > 0:
				var amount_to_remove = min(remaining_amount, item.current_stack)
				if remove_item(item, amount_to_remove):
					remaining_amount -= amount_to_remove
	
	return remaining_amount <= 0

func sort_inventory(mode: String = "ASC"):
	var unlocked_items: Array[Item] = []
	var unlocked_indices: Array[int] = []
	
	for i in range(slots.size()):
		if is_slot_unlocked(i) and slots[i] != null:
			unlocked_items.append(slots[i])
			unlocked_indices.append(i)
		elif is_slot_unlocked(i):
			unlocked_indices.append(i) # Mantém registro dos slots vazios desbloqueados
	
	# Ordena os itens
	unlocked_items.sort_custom(_sort_items.bind(mode))
	
	# Reorganiza os itens nos slots desbloqueados
	var item_index = 0
	for i in unlocked_indices:
		if item_index < unlocked_items.size():
			slots[i] = unlocked_items[item_index]
			item_index += 1
		else:
			slots[i] = null
	
	# Atualiza o array items
	items.clear()
	for item in unlocked_items:
		items.append(item)
	
	inventory_updated.emit()
	

# Função de comparação personalizada para ordenação
func _sort_items(a: Item, b: Item, mode: String) -> bool:
	# 3. Se SubCategory igual, ordena por Rarity
	if a.item_rarity != b.item_rarity:
		if mode == "ASC":
			return a.item_rarity < b.item_rarity
		else:
			return a.item_rarity > b.item_rarity

	# 1. Ordena por Category
	if a.item_category != b.item_category:
		if mode == "ASC":
			return a.item_category < b.item_category
		else:
			return a.item_category > b.item_category
	
	
	if a.item_subcategory != b.item_subcategory:
		if mode == "ASC":
			return a.item_subcategory < b.item_subcategory
		else:
			return a.item_subcategory > b.item_subcategory
	
	
	if a.item_category == b.item_category:
		var a_sort_value = a.get_sort_value()
		var b_sort_value = b.get_sort_value()

		if a_sort_value != b_sort_value:
			if mode == "ASC":
				return a_sort_value < b_sort_value
			else:
				return a_sort_value > b_sort_value
	
	if a.is_unique != b.is_unique:
		if mode == "ASC":
			return a.is_unique < b.is_unique
		else:
			return a.is_unique > b.is_unique


	# if a.item_subcategory == b.item_subcategory:
	# 	var a_sort_value = a.get_sort_value()
	# 	var b_sort_value = b.get_sort_value()

	# 	if a_sort_value != b_sort_value:
	# 		if mode == "ASC":
	# 			return a_sort_value < b_sort_value
	# 		else:
	# 			return a_sort_value > b_sort_value

	# 4. Se o nível é igual, ordena por Nível
	if a.item_level != b.item_level:
		if mode == "ASC":
			return a.item_level < b.item_level
		else:
			return a.item_level > b.item_level

	if a.current_stack != b.current_stack:
		if mode == "ASC":
			return a.current_stack < b.current_stack
		else:
			return a.current_stack > b.current_stack

	# Fallback. Se tudo igual, mantém ordem original (estável)
	return false


func find_item_by_id(item_id: String) -> Item:
	for item in items:
		if item != null and item.item_id == item_id:
			return item
	return null

func find_many_items_by_id(_item_id: String) -> Array[Item]:
	var found_items: Array[Item] = []
	for item in items:
		if item != null and item.item_id == _item_id:
			found_items.append(item)
	return found_items

func find_many_stackable_items_by_id(_item_id: String) -> Item:
	var _item: Item = null
	for item in items:
		if item != null and item.item_id == _item_id and item.stackable:
			if _item == null:
				_item = item
			elif item.current_stack > _item.current_stack:
				_item.current_stack += item.current_stack

	return _item

# Função auxiliar para conectar os botões corretamente
func connect_sort_buttons(asc_button: Button, desc_button: Button) -> void:
	asc_button.pressed.connect(sort_inventory.bind("ASC"))
	desc_button.pressed.connect(sort_inventory.bind("DESC"))


func change_page(direction: int) -> void:
	var max_page := ceili(float(MAX_SLOTS) / SLOTS_PER_PAGE)
	current_page = wrapi(current_page + direction, 0, max_page)
	inventory_updated.emit()
	page_changed.emit()


func get_current_page_items() -> Array[Item]:
	var start_index = current_page * SLOTS_PER_PAGE
	var end_index = start_index + SLOTS_PER_PAGE
	return slots.slice(start_index, end_index)


func start_item_drag(item: Item, slot_index: int) -> void:
	drag_item = item
	drag_slot_index = slot_index
	item_drag_started.emit(item, slot_index)

func cancel_item_drag() -> void:
	# Não precisa adicionar de volta pois o item nunca foi removido
	drag_item = null
	drag_slot_index = -1
	item_drag_ended.emit(false)

func move_item(from_slot: int, to_slot: int) -> void:
	if from_slot == to_slot:
		cancel_item_drag()
		return
	
	if not is_valid_slot_index(from_slot) or not is_valid_slot_index(to_slot):
		cancel_item_drag()
		return
	
	# Verifica se o slot de destino está desbloqueado
	if not is_slot_unlocked(to_slot):
		cancel_item_drag()
		return
	
	var from_item = slots[from_slot]
	var to_item = slots[to_slot]
	
	# Caso 1: Slot destino vazio - move o item
	if to_item == null:
		slots[to_slot] = from_item
		slots[from_slot] = null
	
	# Caso 2: Mesmo item e stackable - tenta juntar stacks
	elif (from_item.item_id == to_item.item_id and
		  from_item.item_rarity == to_item.item_rarity and
		  from_item.stackable and to_item.stackable):
		var total_stack = from_item.current_stack + to_item.current_stack
		var max_stack = from_item.max_stack
		
		if total_stack <= max_stack:
			# Cabe tudo no slot de destino
			to_item.current_stack = total_stack
			slots[from_slot] = null
			# Remove do array de items
			var item_index = items.find(from_item)
			if item_index != -1:
				items.remove_at(item_index)
		else:
			# Só cabe parte, deixa o resto no slot original
			to_item.current_stack = max_stack
			from_item.current_stack = total_stack - max_stack
	
	# Caso 3: Itens diferentes - troca de posição
	else:
		slots[from_slot] = to_item
		slots[to_slot] = from_item
	
	# Limpa o estado de drag
	drag_item = null
	drag_slot_index = -1
	inventory_updated.emit()
	item_drag_ended.emit(true)
	items_swapped.emit(from_slot, to_slot)

func move_item_to_slot(item: Item, target_slot: int) -> void:
	if drag_item != null and drag_slot_index != -1:
		move_item(drag_slot_index, target_slot)

func is_valid_slot_index(index: int) -> bool:
	return index >= 0 and index < slots.size()


func save_inventory():
	var save_data = []
	for item in items:
		if item != null:
			save_data.append({"id": item.id, "current_stack": item.current_stack})
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
