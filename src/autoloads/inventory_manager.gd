extends Node

signal page_changed

signal inventory_updated
signal inventory_saved
signal inventory_loaded

signal update_inventory_visible(is_open: bool)

signal update_item_information(item: Item)

static var items: Array[Item] = []
static var slots: Array[Item] = []
static var current_page: int = 0
static var unlocked_slots: int = 18

const MAX_SLOTS := 54
const SLOTS_PER_PAGE := 18

var is_open: bool = false
var current_select_item: Item


func _ready():
	# Inicializa slots vazios
	for i in range(MAX_SLOTS):  # Número de slots
		slots.append(null)
	
	#create_ramdon_items()


func create_ramdon_items() -> void:
	var enemy_stats = EnemyStats.new()
	var total_itens = 0
	for i in 100:
		enemy_stats.level = randi_range(1, 45)
		var gem = GemItem.new()
		gem.setup(enemy_stats)
		var is_addded = add_item(gem)
		if is_addded:
			total_itens += 1
		#print("Gem Added: ", is_addded)
		#if randf() * 1.0 <= gem.spawn_chance:
		#var item = Item.new()
		#item.item_texture = Coin.GOLD_COIN
		#add_item(item)
		#var potion = PotionItem.new()
		#potion.setup(enemy_stats)
		#add_item(potion)
		#var equip = EquipmentItem.new()
		#equip.setup(enemy_stats)
		#var is_addded = add_item(equip)
		#if is_addded:
			#total_itens += 1
	print("Total itens added: ", total_itens)


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
		var slot = slots[i]
		if slots[i] == null and is_slot_unlocked(i):
			var item_copy = item.clone()
			item_copy.current_stack = 1  # Garante que itens únicos tenham stack 1
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


func remove_item(item: Item):
	var slot_index = slots.find(item)
	if slot_index != -1:
		var item_index = items.find(item)
		if item_index != -1:
			items.remove_at(item_index)
		slots[slot_index] = null
		inventory_updated.emit()


func sort_inventory(mode: String = "ASC"):
	var unlocked_items: Array[Item] = []
	var unlocked_indices: Array[int] = []
	
	for i in range(slots.size()):
		if is_slot_unlocked(i) and slots[i] != null:
			unlocked_items.append(slots[i])
			unlocked_indices.append(i)
		elif is_slot_unlocked(i):
			unlocked_indices.append(i)  # Mantém registro dos slots vazios desbloqueados
	
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
	
	## Filtra apenas slots com itens (remove nulls)
	#var non_null_slots: Array[Item] = []
	#var null_count = 0
#
	#for slot in slots:
		#if slot != null:
			#non_null_slots.append(slot)
		#else:
			#null_count += 1
#
	## Ordena os itens não nulos
	#non_null_slots.sort_custom(_sort_items.bind(mode))
#
	## Reconstrói o array de slots com itens ordenados + slots vazios no final
	#slots.clear()
	#slots.append_array(non_null_slots)
#
	## Adiciona os slots vazios no final
	#for i in range(null_count):
		#slots.append(null)
#
	## Atualiza o array items para refletir a ordenação (cria novas referências)
	#items.clear()
	#for slot in non_null_slots:
		#items.append(slot)
#
	## Emite sinal de atualização
	#inventory_updated.emit()


# Função de comparação personalizada para ordenação
func _sort_items(a: Item, b: Item, mode: String) -> bool:
	# 1. Ordena por Category
	if a.item_category != b.item_category:
		if mode == "ASC":
			return a.item_category < b.item_category
		else:
			return a.item_category > b.item_category

	if a.item_category == b.item_category:
		var a_sort_value = a.get_sort_value()
		var b_sort_value = b.get_sort_value()

		if a_sort_value != b_sort_value:
			if mode == "ASC":
				return a_sort_value < b_sort_value
			else:
				return a_sort_value > b_sort_value

	# 2. Se Category igual, ordena por SubCategory
	if a.item_subcategory != b.item_subcategory:
		if mode == "ASC":
			return a.item_subcategory < b.item_subcategory
		else:
			return a.item_subcategory > b.item_subcategory

	# 3. Se SubCategory igual, ordena por Rarity
	if a.item_rarity != b.item_rarity:
		if mode == "ASC":
			return a.item_rarity < b.item_rarity
		else:
			return a.item_rarity > b.item_rarity

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


# Função auxiliar para conectar os botões corretamente
func connect_sort_buttons(asc_button: Button, desc_button: Button) -> void:
	asc_button.pressed.connect(sort_inventory.bind("ASC"))
	desc_button.pressed.connect(sort_inventory.bind("DESC"))


func change_page(direction: int) -> void:
	current_page = wrapi(current_page + direction, 0, MAX_SLOTS / SLOTS_PER_PAGE)
	inventory_updated.emit()
	page_changed.emit()


func get_current_page_items() -> Array[Item]:
	var start_index = current_page * SLOTS_PER_PAGE
	var end_index = start_index + SLOTS_PER_PAGE
	return slots.slice(start_index, end_index)


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
