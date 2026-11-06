@tool
extends Control

signal order_changed(ids: Array)

const Config = preload("res://src/configs/cat_card_area/cat_card_area_config.gd")
const Feedback = preload("res://src/configs/cat_cards/cat_feedback_config.gd")
const Layout = preload("res://src/service/cat_card_area/cat_card_layout.gd")

@export_range(Config.MIN_CARD_COUNT, Config.MAX_CARD_COUNT, 1)
var card_count: int = Config.DEFAULT_CARD_COUNT:
	set(value):
		card_count = clampi(value, Config.MIN_CARD_COUNT, Config.MAX_CARD_COUNT)
		if is_node_ready():
			_update_layout()

var _ids: Array = []
var _reorder_tween: Tween
@onready var _cards: Control = $cards

func _ready() -> void:
	if not Engine.is_editor_hint():
		for card in _cards.get_children():
			card.reorder_requested.connect(_reorder)
		card_count = 0
	_update_layout()

func show_loadout(ids: Array, state: Dictionary) -> void:
	if _reorder_tween:
		_reorder_tween.kill()
	_ids = ids.duplicate()
	card_count = ids.size()
	for index in ids.size():
		_cards.get_child(index).configure(ids[index], state)
	HoverInfo.refresh()

func set_interaction_enabled(enabled: bool) -> void:
	for card in _cards.get_children():
		card.interaction_enabled = enabled

func get_card(id: String) -> Control:
	return _cards.get_child(_ids.find(id))

func reset_feedback() -> void:
	for i in _ids.size():
		_cards.get_child(i).reset_feedback()

func _positions() -> Array:
	var positions: Array = Array(Layout.get_positions(card_count, Feedback.CARD_SIZE))
	if not Engine.is_editor_hint():
		positions.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and a.x < b.x))
	return positions

func _update_layout() -> void:
	var positions := _positions()
	for index in _cards.get_child_count():
		var card := _cards.get_child(index) as Control
		card.visible = index < card_count
		if card.visible:
			card.position = positions[index]

func _reorder(source: String, destination: String) -> void:
	var previous := _ids.duplicate()
	var next := _ids.duplicate()
	var destination_index := next.find(destination)
	next.erase(source)
	next.insert(destination_index, source)
	var positions := _positions()
	order_changed.emit(next)
	# 資料更新後，同一貓牌由原槽平滑移向新槽。
	_reorder_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for index in _ids.size():
		var card: Control = _cards.get_child(index)
		card.position = positions[previous.find(_ids[index])]
		_reorder_tween.tween_property(card, "position", positions[index], Feedback.REORDER_DURATION)
