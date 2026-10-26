@tool
extends Control

signal card_selected(card: Control)

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
var _selected_card: Control


func _ready() -> void:
	if not Engine.is_editor_hint():
		for card in _cards.get_children():
			card.selection_requested.connect(_select_card)
	_update_layout()


func get_selected_card() -> Control:
	return _selected_card


func clear_selection() -> void:
	if is_instance_valid(_selected_card):
		_selected_card.selected = false
	_selected_card = null
	card_selected.emit(null)


func set_selection_enabled(enabled: bool) -> void:
	_selection_enabled = enabled
	if not enabled:
		clear_selection()
	_update_layout()


func take_selected_card() -> Control:
	var card := _selected_card
	if card == null:
		return null
	clear_selection()
	_cards.remove_child(card)
	card_count -= 1
	return card


func restore_card(card: Control, index: int, original_y: float) -> void:
	_cards.add_child(card)
	_cards.move_child(card, index)
	card.position.y = original_y
	card_count += 1


func _select_card(card: Control) -> void:
	if not _selection_enabled or not card.visible:
		return
	if _selected_card == card:
		clear_selection()
		return
	clear_selection()
	_selected_card = card
	card.selected = true
	card_selected.emit(card)


func _update_layout() -> void:
	var card_width := float(CardTexture.get_width())
	for index in range(_cards.get_child_count()):
		var card := _cards.get_child(index) as Control
		card.visible = index < card_count
		card.position.x = Config.CARD_START_X + (card_width + Config.CARD_GAP) * index
		if not Engine.is_editor_hint():
			card.selection_enabled = _selection_enabled and card.visible

	var gap_count := maxi(card_count - 1, 0)
	var hand_width := (
		Config.CARD_START_X
		+ card_width * card_count
		+ Config.CARD_GAP * gap_count
		+ Config.RIGHT_PADDING
	)
	_background.patch_margin_left = Config.BACKGROUND_EDGE_WIDTH
	_background.patch_margin_right = Config.BACKGROUND_EDGE_WIDTH
	custom_minimum_size.x = hand_width
	size.x = hand_width
