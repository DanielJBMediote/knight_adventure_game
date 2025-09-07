class_name InventoryItemSlotUI
extends Panel

const ITEM_SLOT_STYLEBOX_HOVER = preload("res://src/ui/themes/item_slot_stylebox_hover.tres")
const ITEM_SLOT_STYLEBOX_NORMAL = preload("res://src/ui/themes/item_slot_stylebox_normal.tres")

@onready var equip_comparator: TextureRect = $EquipComparator
@onready var rarity_texture: TextureRect = $MarginContainer/RarityTexture
@onready var item_texture: TextureRect = $MarginContainer/ItemTexture
@onready var stacks: Label = $MarginContainer/Stacks
@onready var unique_border: Panel = $UniqueBorder
@onready var locked_panel: Panel = $LockedPanel

const ICON_UP = Rect2(282, 20, 13, 12)
const ICON_DOWN = Rect2(282, 32, 13, 12)

var item: Item
var slot_index: int = -1
var target_mouse_entered := false
var is_locked := false

var click_timer: Timer
var is_click: bool = false

var is_dragging := false
var drag_started := false
var can_drag := false
var can_drop := false
var drag_offset: Vector2
var original_position: Vector2
var original_slot_index: int

func _ready() -> void:
	add_to_group("inventory_slots")
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)
	self.focus_entered.connect(_on_focus_entered)
	self.focus_exited.connect(_on_focus_exited)
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_NORMAL)
	update_lock_status()

	click_timer = Timer.new()
	click_timer.wait_time = 0.1
	click_timer.one_shot = true
	add_child(click_timer)


func setup_item(new_item: Item):
	equip_comparator.hide()
	if new_item != null:
		item = new_item
		stacks.text = str(new_item.current_stack) if new_item.stackable else ""
		item_texture.texture = new_item.item_texture
		stacks.visible = new_item.stackable
		if new_item.item_category == Item.CATEGORY.EQUIPMENTS:
			updade_equipment_styles(new_item as EquipmentItem)
		set_item_rarity_texture(new_item.item_rarity)
		update_border_style(new_item.is_unique)
	else:
		item = null
		stacks.text = ""
		item_texture.texture = null
		stacks.visible = false
		rarity_texture.texture = null
		update_border_style()
	update_lock_status()


func updade_equipment_styles(new_item: EquipmentItem) -> void:
	var equipped = PlayerEquipments.get_equipped_item_type(new_item.equipment_type)
	if not equipped:
		equip_comparator.hide()
		return
	
	# Cria uma nova AtlasTexture para garantir que a região seja aplicada corretamente
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = preload("res://assets/ui/buttons.png") # Ajuste o caminho
	
	if equipped.equipment_power > new_item.equipment_power:
		atlas_texture.region = ICON_DOWN
		equip_comparator.modulate = Color.RED
	else:
		atlas_texture.region = ICON_UP
		equip_comparator.modulate = Color.GREEN
	
	equip_comparator.texture = atlas_texture
	equip_comparator.show()


func update_lock_status():
	if slot_index != -1:
		is_locked = !InventoryManager.is_slot_unlocked(slot_index)
		locked_panel.visible = is_locked
		
		if is_locked:
			#self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_LOCKED)
			self.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_NORMAL)
			# self.theme = ITEM_SLOT_STYLEBOX_NORMAL
			self.mouse_filter = Control.MOUSE_FILTER_PASS


func set_item_rarity_texture(rarity: Item.RARITY) -> void:
	match rarity:
		Item.RARITY.COMMON:
			# Azul para itens Normais
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_COMMOM
		
		Item.RARITY.UNCOMMON:
			# Azul para itens Bons
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_UNCOMMON
		
		Item.RARITY.RARE:
			# Azul para itens Mágicos
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_RARE
		
		Item.RARITY.EPIC:
			# Roxo para itens Épicos
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_EPIC
		
		Item.RARITY.LEGENDARY:
			# Laranja para itens lendários
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_LEGENDARY
		
		Item.RARITY.MYTHICAL:
			# Dourado para itens Míticos
			rarity_texture.texture = ItemManager.BG_GRADIENT_ITEM_MITICAL
		
		_:
			rarity_texture.texture = null


func update_border_style(is_unique: bool = false):
	unique_border.visible = is_unique

func _gui_input(event: InputEvent) -> void:
	if is_locked or item == null:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and can_drag:
			# Inicia o processo de clique/drag
			is_click = true
			click_timer.start()
			
			# Espera para ver se vira um dragi
			await click_timer.timeout
			if is_click and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_drag:
				# Virou drag - inicia arrasto
				is_click = false
				drag_started = true
				start_drag()
		elif not event.pressed and is_click and not drag_started:
			# Clique concluído - mostra informações
			is_click = false
			ItemManager.update_selected_item(item)
		elif not event.pressed and is_dragging:
			# Soltou o botão durante drag - finaliza
			end_drag()

func _input(event: InputEvent) -> void:
	# Detecta movimento do mouse para iniciar drag mais cedo
	if event is InputEventMouseMotion and is_click:
		if event.relative.length() > 3: # Sensibilidade do movimento
			is_click = false
			if can_drag and not drag_started:
				drag_started = true
				start_drag()

func start_drag() -> void:
	if item == null or is_locked:
		return
	
	is_dragging = true
	original_position = global_position
	original_slot_index = slot_index
	drag_offset = get_global_mouse_position() - global_position
	
	# Torna este slot temporariamente o topo para visualização do drag
	# z_index = 100
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	equip_comparator.hide()
	rarity_texture.hide()
	item_texture.hide()
	stacks.hide()
	unique_border.hide()
	
	# Emite sinal para o inventory manager saber que começou um drag
	InventoryManager.start_item_drag(item, slot_index)

func end_drag() -> void:
	if not is_dragging:
		return
	
	is_dragging = false
	drag_started = false
	# z_index = 0
	mouse_filter = Control.MOUSE_FILTER_PASS

	# Verifica se está sobre outro slot
	var target_slot = get_drop_target_slot()
	
	# unique_border.show()
	rarity_texture.show()
	item_texture.show()
	stacks.show()
	
	if target_slot != null and target_slot != self:
		# Tenta mover o item para outro slot
		InventoryManager.move_item(original_slot_index, target_slot.slot_index)
	else:
		# Retorna à posição original se não houve drop válido
		global_position = original_position
		InventoryManager.cancel_item_drag()

func get_drop_target_slot() -> InventoryItemSlotUI:
	# Verifica todos os slots para ver se o mouse está sobre algum
	var mouse_pos = get_global_mouse_position()
	# var viewport = get_viewport()
	
	for child in get_tree().get_nodes_in_group("inventory_slots"):
		if child is InventoryItemSlotUI and child != self:
			var rect = Rect2(child.global_position, child.size)
			if rect.has_point(mouse_pos) and not child.is_locked:
				return child
	
	return null

func can_drop_data(_position: Vector2, data: Variant) -> bool:
	# Verifica se este slot pode receber o item
	if is_locked:
		return false
	
	if data is Item:
		# Aqui você pode adicionar lógicas adicionais de validação
		# Por exemplo, verificar se o tipo de item é compatível com este slot
		return true
	
	return false

func drop_data(_position: Vector2, data: Variant) -> void:
	if data is Item and can_drop_data(_position, data):
		InventoryManager.move_item_to_slot(data, slot_index)

func _on_mouse_entered() -> void:
	target_mouse_entered = true
	if item:
		can_drag = true
		can_drop = !is_locked
	if not is_locked:
		self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_HOVER)

func _on_mouse_exited() -> void:
	if item:
		can_drag = false
	target_mouse_entered = false
	if not is_locked:
		self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_NORMAL)

func _on_focus_entered() -> void:
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_HOVER)

func _on_focus_exited() -> void:
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_NORMAL)
