@tool
extends Control

signal selection_changed

const Config = preload("res://src/configs/hand_area/hand_area_config.gd")
const CardTexture = preload("res://src/assets/card/card_bg.png")

@export_range(Config.MIN_CARD_COUNT, Config.MAX_CARD_COUNT, 1)
var card_count: int = Config.DEFAULT_CARD_COUNT:
	set(value):
		card_count = clampi(value, Config.MIN_CARD_COUNT, Config.MAX_CARD_COUNT)
		if is_node_ready():
			_update_layout()

@onready var _background: NinePatchRect = $background
@onready var _cards: Control = $cards
var _selection_enabled := true
var _selected: Array = []
var _slot_y: Array[float] = []

func _ready() -> void:
	for card in _cards.get_children():
		_slot_y.append(card.position.y)
	_update_layout()

func clear_preview() -> void:
	for card in _cards.get_children():
		_cards.remove_child(card)
		card.queue_free()

func show_cards(cards: Array) -> void:
	for index in cards.size():
		var card: Control = cards[index]
		if card.get_parent() != _cards:
			card.reparent(_cards, false)
		_cards.move_child(card, index)
		card.visible = true
		card.set_marks([])
	card_count = cards.size()
	_update_layout()

func get_selected_ids() -> Array:
	return _selected.duplicate()

func clear_selection() -> void:
	_selected.clear()
	_update_layout()
	selection_changed.emit()

func set_selection_enabled(enabled: bool) -> void:
	_selection_enabled = enabled
	_update_layout()

func select_card(card: Control) -> void:
	if not _selection_enabled or card.get_parent() != _cards:
		return
	if _selected.has(card.card_id):
		_selected.erase(card.card_id)
	else:
		_selected.append(card.card_id)
	_update_layout()
	selection_changed.emit()

func _update_layout() -> void:
	var card_width := float(CardTexture.get_width())
	for index in range(_cards.get_child_count()):
		var card := _cards.get_child(index) as Control
		card.visible = index < card_count
		card.position.x = Config.CARD_START_X + (card_width + Config.CARD_GAP) * index
		if not Engine.is_editor_hint():
			card.selected = _selected.has(card.card_id)
			card.position.y = _slot_y[index] - (Config.SELECTED_OFFSET if card.selected else 0.0)
			card.selection_enabled = _selection_enabled and card.visible
	var gap_count := maxi(card_count - 1, 0)
	var hand_width := Config.CARD_START_X + card_width * card_count + Config.CARD_GAP * gap_count + Config.RIGHT_PADDING
	_background.patch_margin_left = Config.BACKGROUND_EDGE_WIDTH
	_background.patch_margin_right = Config.BACKGROUND_EDGE_WIDTH
	custom_minimum_size.x = hand_width
	size.x = hand_width
