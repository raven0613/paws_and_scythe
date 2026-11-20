@tool
extends Control

signal order_changed(ids: Array)
signal sell_requested(id: String)

const Config = preload("res://src/configs/cat_card_area/cat_card_area_config.gd")
const Feedback = preload("res://src/configs/cat_cards/cat_feedback_config.gd")
const Trade = preload("res://src/configs/cat_cards/cat_trade_config.gd")
const Layout = preload("res://src/service/cat_card_area/cat_card_layout.gd")
const Modifiers = preload("res://src/service/cat_cards/rule_modifiers.gd")
const Market = preload("res://src/service/shop/cat_market.gd")
const BoxStyle = preload("res://src/scripts/ui/box_style.gd")
const PopBurst = preload("res://src/scripts/motion/pop_burst.gd")

@export_range(Config.MIN_CARD_COUNT, Config.MAX_CARD_COUNT, 1)
var card_count: int = Config.DEFAULT_CARD_COUNT:
	set(value):
		card_count = clampi(value, Config.MIN_CARD_COUNT, Config.MAX_CARD_COUNT)
		if is_node_ready():
			_update_layout()

var _ids: Array = []
var _reorder_tween: Tween
var _sell_button: Button
var _sell_target := ""
@onready var _cards: Control = $cards

func _ready() -> void:
	if not Engine.is_editor_hint():
		for card in _cards.get_children():
			card.reorder_requested.connect(_reorder)
			card.clicked.connect(_toggle_sell)
		card_count = 0
		_sell_button = Button.new()
		BoxStyle.apply_button(_sell_button, Trade.SELL_FONT_SIZE)
		_sell_button.hide()
		_sell_button.pressed.connect(_on_sell_pressed)
		add_child(_sell_button)
	_update_layout()

# 持有清單、排序或張數改變時重新設定卡面，Hover 立即反映新排別的效益標示。
func show_loadout(ids: Array, state: Dictionary) -> void:
	if _reorder_tween:
		_reorder_tween.kill()
	_hide_sell()
	_ids = ids.duplicate()
	card_count = ids.size()
	var potency := Modifiers.potency(ids)
	for index in ids.size():
		_cards.get_child(index).configure(ids[index], state, potency[ids[index]])
	HoverInfo.refresh()

func set_interaction_enabled(enabled: bool) -> void:
	for card in _cards.get_children():
		card.interaction_enabled = enabled
	if not enabled:
		_hide_sell()

func get_card(id: String) -> Control:
	return _cards.get_child(_ids.find(id))

func reset_feedback() -> void:
	for i in _ids.size():
		_cards.get_child(i).reset_feedback()

func set_playback_speed(speed: float) -> void:
	for card in _cards.get_children():
		card.set_playback_speed(speed)

func play_vanish(id: String) -> void:
	await get_card(id).play_vanish().finished

# 持有清單更新後，每張貓牌由 previous 中的原槽平滑移向新槽，消失的卡片節點恢復原姿態。
func slide_from(previous: Array) -> void:
	for card in _cards.get_children():
		card.reset_feedback()
	if _ids.is_empty():
		return
	var before := _positions(previous.size())
	var after := _positions(card_count)
	_reorder_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for index in _ids.size():
		var card: Control = _cards.get_child(index)
		card.position = before[previous.find(_ids[index])]
		_reorder_tween.tween_property(card, "position", after[index], Trade.SLIDE_DURATION)

func _positions(count: int) -> Array:
	var positions: Array = Array(Layout.get_positions(count, Feedback.CARD_SIZE))
	if not Engine.is_editor_hint():
		positions.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and a.x < b.x))
	return positions

func _update_layout() -> void:
	var positions := _positions(card_count)
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
	var positions := _positions(card_count)
	order_changed.emit(next)
	# 資料更新後，同一貓牌由原槽平滑移向新槽。
	_reorder_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for index in _ids.size():
		var card: Control = _cards.get_child(index)
		card.position = positions[previous.find(_ids[index])]
		_reorder_tween.tween_property(card, "position", positions[index], Feedback.REORDER_DURATION)

# 點擊貓牌在卡片下緣彈出賣出按鈕，再點同一張收起。
func _toggle_sell(id: String) -> void:
	if _sell_target == id:
		_hide_sell()
		return
	_sell_target = id
	var card := get_card(id)
	_sell_button.text = Trade.SELL_TEXT % Market.sell_price(id)
	_sell_button.size = Trade.SELL_BUTTON_SIZE
	_sell_button.position = _cards.position + card.position + Vector2((Feedback.CARD_SIZE.x - Trade.SELL_BUTTON_SIZE.x) / 2, Feedback.CARD_SIZE.y - Trade.BUTTON_OVERLAP)
	_sell_button.scale = Vector2.ZERO
	_sell_button.show()
	PopBurst.play(self, _sell_button, Trade.BUTTON_POP_SCALE, Trade.POP)

func _hide_sell() -> void:
	_sell_button.hide()
	_sell_target = ""

func _on_sell_pressed() -> void:
	var id := _sell_target
	_hide_sell()
	sell_requested.emit(id)

# 在賣出按鈕與目標卡片以外按下滑鼠時收起按鈕，事件繼續傳給其他元件。
func _input(event: InputEvent) -> void:
	if _sell_target.is_empty() or not (event is InputEventMouseButton and event.pressed):
		return
	var point := get_global_mouse_position()
	if not _sell_button.get_global_rect().has_point(point) and not get_card(_sell_target).get_global_rect().has_point(point):
		_hide_sell()
