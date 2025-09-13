class_name BaseSlotUI
extends Panel

# Constantes comuns
const ITEM_SLOT_STYLEBOX_HOVER = preload("res://src/ui/themes/item_slot_stylebox_hover.tres")
const ITEM_SLOT_STYLEBOX_NORMAL = preload("res://src/ui/themes/item_slot_stylebox_normal.tres")

@export var rarity_texture: TextureRect
@export var item_texture: TextureRect
@export var unique_border: Panel
@export var info: Label
@export var preview_gems_attached: VBoxContainer

# Variáveis comuns
var current_item: Item
var slot_index: int = -1
var target_mouse_entered := false
var is_locked := false

# Variáveis de drag and drop
var click_timer: Timer
var is_click: bool = false
var is_dragging: bool = false
var is_drag_started: bool = false
var can_drag: bool = false
var can_drop: bool = false
var drag_offset: Vector2
var original_position: Vector2
var original_slot_index: int


func _ready() -> void:
	# Configuração comum
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)
	self.gui_input.connect(_on_gui_input)
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_NORMAL)

	# Timer para diferenciar clique de drag
	click_timer = Timer.new()
	click_timer.wait_time = 0.3
	click_timer.one_shot = true
	add_child(click_timer)

	# Configuração específica da classe filha
	_setup_specifics()


# Método virtual para configuração específica das classes filhas
func _setup_specifics() -> void:
	pass


# Método virtual para setup do current_item
func setup_item(new_item: Item) -> void:
	current_item = new_item
	_update_lock_status()
	_update_item_rarity_texture()
	_update_border_style()
	_update_item_info()
	_update_gems_attached()

func get_item() -> Item:
	return current_item

func _update_lock_status() -> void:
	# Implementação específica nas classes filhas
	pass

func _update_item_info() -> void:
	if not current_item:
		info.hide()
	else:
		info.show()
		if current_item.stackable:
			info.text = str(current_item.current_stack)
			return
		info.hide()

func _update_gems_attached() -> void:
	if not preview_gems_attached:
		return

	for child in preview_gems_attached.get_children():
		child.queue_free()

	if not current_item:
		preview_gems_attached.hide()
		return
	if current_item.item_category != Item.CATEGORY.EQUIPMENTS:
		preview_gems_attached.hide()
		return
	
	preview_gems_attached.show()
	var equipment = current_item as EquipmentItem
	var attached_gems = equipment.attached_gems
	for slot_key in attached_gems:
		var gem = attached_gems.get(slot_key)
		if gem:
			var tx_rect =  TextureRect.new()
			tx_rect.texture = gem.item_texture
			tx_rect.custom_minimum_size = Vector2(12, 12)
			tx_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tx_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			preview_gems_attached.add_child(tx_rect)
	

# DRAG AND DROP - FUNÇÕES COMUNS
func _on_gui_input(event: InputEvent) -> void:
	if is_locked or current_item == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and can_drag:
			# Inicia o processo de clique/drag
			is_click = true
			click_timer.start()

			# Espera para ver se vira um drag
			await click_timer.timeout
			if is_click and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_drag:
				# Virou drag - inicia arrasto
				is_click = false
				is_drag_started = true
				start_drag()
		elif not event.pressed and is_click and not is_drag_started:
			# Clique concluído - mostra informações
			is_click = false
			ItemManager.update_selected_item(current_item)
		elif not event.pressed and is_dragging:
			# Soltou o botão durante drag - finaliza
			end_drag()


func _input(event: InputEvent) -> void:
	# Detecta movimento do mouse para iniciar drag mais cedo
	if event is InputEventMouseMotion and is_click:
		if event.relative.length() > 3:  # Sensibilidade do movimento
			is_click = false
			if can_drag and not is_drag_started:
				is_drag_started = true
				start_drag()


func start_drag() -> void:
	if current_item == null or is_locked or is_dragging:
		return

	is_dragging = true
	original_position = global_position
	original_slot_index = slot_index
	drag_offset = get_global_mouse_position() - global_position

	# Configuração visual do drag
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hide_item_visuals()  # Esconde o current_item visualmente

	# Emite sinal para o manager
	InventoryManager.start_item_drag(current_item, slot_index)


func end_drag() -> void:
	if not is_dragging:
		return

	is_dragging = false
	is_drag_started = false
	mouse_filter = Control.MOUSE_FILTER_PASS

	# Restaura visual do current_item
	_show_item_visuals()

	# Verifica se está sobre outro slot
	var target_slot = get_drop_target_slot()

	if target_slot != null and target_slot != self:
		# Tenta mover o current_item
		_try_move_item(target_slot)
	else:
		# Retorna à posição original
		global_position = original_position
		InventoryManager.cancel_item_drag()


func get_drop_target_slot() -> BaseSlotUI:
	var mouse_pos = get_global_mouse_position()
	
	# Lista de grupos para verificar (na ordem de prioridade)
	var slot_groups = [InventoryItemSlotUI.GROUP_NAME, EquipmentItemSlotUI.GROUP_NAME, ESGSEquipmentItemSlotUI.GROUP_NAME]
	for group in slot_groups:
		for slot in get_tree().get_nodes_in_group(group):
			if slot is BaseSlotUI and slot != self and not slot.is_locked:
				var rect = Rect2(slot.global_position, slot.size)
				if rect.has_point(mouse_pos):
					return slot
	
	return null


func _try_move_item(_target_slot: BaseSlotUI) -> void:
	# Implementação específica nas classes filhas
	pass


func _hide_item_visuals() -> void:
	if not current_item:
		return
	rarity_texture.hide()
	item_texture.hide()
	unique_border.hide()
	preview_gems_attached.hide()


func _show_item_visuals() -> void:
	if not current_item:
		return
	
	rarity_texture.show()
	item_texture.show()
	unique_border.visible = current_item.is_unique

	if current_item.item_category == Item.CATEGORY.EQUIPMENTS:
		preview_gems_attached.show()
		


# FUNÇÕES DE MOUSE COMUNS
func _on_mouse_entered() -> void:
	target_mouse_entered = true
	if current_item:
		can_drag = true
		can_drop = !is_locked
	if not is_locked:
		self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_HOVER)


func _on_mouse_exited() -> void:
	if current_item:
		can_drag = false
		can_drop = !is_locked
	target_mouse_entered = false
	if not is_locked:
		self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_NORMAL)


func _update_item_rarity_texture() -> void:
	if not current_item or not rarity_texture:
		rarity_texture.texture = null
		return
	match current_item.item_rarity:
		Item.RARITY.COMMON:
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_COMMOM
		Item.RARITY.UNCOMMON:
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_UNCOMMON
		Item.RARITY.RARE:
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_RARE
		Item.RARITY.EPIC:
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_EPIC
		Item.RARITY.LEGENDARY:
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_LEGENDARY
		Item.RARITY.MYTHICAL:
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_MITICAL
		_:
			rarity_texture.texture = null

func _update_border_style():
	if current_item:
		unique_border.visible = current_item.is_unique
	else:
		unique_border.hide()
