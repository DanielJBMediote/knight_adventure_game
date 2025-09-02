class_name InventoryItemSlot
extends Panel

const ITEM_SLOT_STYLEBOX_HOVER = preload("res://src/ui/themes/item_slot_stylebox_hover.tres")
const ITEM_SLOT_STYLEBOX_NORMAL = preload("res://src/ui/themes/item_slot_stylebox_normal.tres")

@onready var rarity_texture: TextureRect = $MarginContainer/RarityTexture
@onready var item_texture: TextureRect = $MarginContainer/ItemTexture
@onready var stacks: Label = $MarginContainer/Stacks
@onready var unique_border: Panel = $UniqueBorder
@onready var locked_panel: Panel = $LockedPanel

var item: Item
var target_mouse_entered := false
var is_locked := false
var slot_index: int = -1

func _ready() -> void:
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)
	self.focus_entered.connect(_on_focus_entered)
	self.focus_exited.connect(_on_focus_exited)
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_NORMAL)
	update_lock_status()

func setup_item(new_item: Item):
	if new_item != null:
		item = new_item
		stacks.text = str(new_item.current_stack) if new_item.stackable else ""
		item_texture.texture = new_item.item_texture
		stacks.visible = new_item.stackable
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

func update_lock_status():
	if slot_index != -1:
		is_locked = !InventoryManager.is_slot_unlocked(slot_index)
		locked_panel.visible = is_locked
		
		if is_locked:
			#self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_LOCKED)
			self.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_NORMAL)
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

func _input(event: InputEvent) -> void:
	# Não permite interação com slots bloqueados
	if target_mouse_entered and item and not is_locked:
		if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			ItemManager.update_selected_item(item)

func _on_mouse_entered() -> void:
	target_mouse_entered = true
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_HOVER)

func _on_mouse_exited() -> void:
	target_mouse_entered = false
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_NORMAL)

func _on_focus_entered() -> void:
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_HOVER)

func _on_focus_exited() -> void:
	self.add_theme_stylebox_override("panel", ITEM_SLOT_STYLEBOX_NORMAL)
