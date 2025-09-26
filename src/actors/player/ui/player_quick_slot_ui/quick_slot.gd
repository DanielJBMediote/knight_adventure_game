class_name QuickSlot
extends Panel

@onready var rarity_texture: TextureRect = $RarityTexture
@onready var button_ui: TextureRect = $MarginContainer/ButtonUI
@onready var item_texture: TextureRect = $MarginContainer/ItemTexture
@onready var stacks: DefaultLabel = $MarginContainer/Stacks
@onready var unique_border: Panel = $UniqueBorder
@onready var timer_progress_bar: TextureProgressBar = $TimerProgressBar
@onready var cooldown_timer: Timer = $CooldownTimer

@export var slot_key := 1

const KEYBOARD_KEY_REGION_X = {1: 0, 2: 16, 3: 32}
const JOYPAD_KEY_REGION_X = {1: 160, 2: 144, 3: 112}

var item: Item
var progress_tween: Tween

func _ready() -> void:
	add_to_group("quick_slots")
	_setup()
	_setup_slot_key_button()
	GameManager.joy_connection_changed.connect(_setup_slot_key_button)
	PlayerEvents.potion_cooldown_started.connect(_on_potion_cooldown_started)

func _setup() -> void:
	if item:
		stacks.text = str(item.current_stack) if item.stackable else ""
		item_texture.texture = item.item_texture
		stacks.visible = item.stackable
		rarity_texture.texture = ItemManager.get_background_theme_by_rarity(item.item_rarity)
		unique_border.visible = item.is_unique
	else:
		stacks.text = ""
		item_texture.texture = null
		stacks.visible = false
		rarity_texture.texture = null
		unique_border.hide()

func _on_potion_cooldown_started(potion_id: String, cooldown_time: float) -> void:
	if not item:
		return

	if potion_id == item.item_id:
		timer_progress_bar.max_value = cooldown_time
		timer_progress_bar.value = cooldown_time
	
	if not cooldown_timer:
		cooldown_timer = Timer.new()
		cooldown_timer.one_shot = true
		add_child(cooldown_timer)

	if progress_tween:
		progress_tween.kill()
	
	progress_tween = create_tween()
	progress_tween.tween_property(timer_progress_bar, "value", 0, cooldown_time)

	cooldown_timer.timeout.connect(_on_potion_cooldown_finished.bind(cooldown_timer, potion_id))
	cooldown_timer.start(cooldown_time)

func _on_potion_cooldown_finished(timer: Timer, potion_id: String) -> void:
	if not item:
		return

	if potion_id == item.item_id:
		timer.queue_free()

func _setup_slot_key_button() -> void:
	if slot_key:
		if GameManager.current_joypad:
			var x = JOYPAD_KEY_REGION_X.get(slot_key, 160)
			button_ui.texture.region = Rect2(x, 16, 16, 16)
		else:
			var x = KEYBOARD_KEY_REGION_X.get(slot_key, 0)
			button_ui.texture.region = Rect2(x, 128, 16, 16)

func _input(event: InputEvent) -> void:
	if item:
		var input_key = str("quick_slot_", slot_key)
		if event.is_action(input_key) and event.is_action_pressed(input_key):
			if item is PotionItem and item.current_stack > 0:
				if PlayerEvents.use_potion(item):
					_setup()
