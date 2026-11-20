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
const DragConfig = preload("res://src/configs/cat_card_area/cat_drag_config.gd")
const CatDrag = preload("res://src/scripts/cat_card_area/cat_card_drag.gd")

@export_range(Config.MIN_CARD_COUNT, Config.MAX_CARD_COUNT, 1)
var card_count: int = Config.DEFAULT_CARD_COUNT:
	set(value):
		card_count = clampi(value, Config.MIN_CARD_COUNT, Config.MAX_CARD_COUNT)
		if is_node_ready():
			_update_layout()

var _ids: Array = []
var _sell_button: Button
var _sell_target := ""
var _drag: Node
@onready var _cards: Control = $cards

func _ready() -> void:
	if not Engine.is_editor_hint():
		for card in _cards.get_children():
			card.drag_requested.connect(_begin_drag)
			card.clicked.connect(_toggle_sell)
		card_count = 0
		_sell_button = Button.new()
		BoxStyle.apply_button(_sell_button, Trade.SELL_FONT_SIZE)
		_sell_button.hide()
		_sell_button.pressed.connect(_on_sell_pressed)
		add_child(_sell_button)
		_drag = CatDrag.new()
		_drag.order_previewed.connect(_make_way)
		_drag.released.connect(_drop)
		add_child(_drag)
	_update_layout()

# 持有清單、排序或張數改變時重新設定卡面，Hover 立即反映新排別的效益標示。
func show_loadout(ids: Array, state: Dictionary) -> void:
	_hide_sell()
	_follow_ids(ids)
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

# 每隻貓牌沿用原本顯示牠的卡片節點，拖曳、吸入與滑動的都是同一張牌；新取得的貓牌接手未使用的節點。
func _follow_ids(ids: Array) -> void:
	var children := _cards.get_children()
	var spare := children.slice(_ids.size())
	var nodes := ids.map(func(id): return children[_ids.find(id)] if _ids.has(id) else spare.pop_front())
	for index in nodes.size():
		_cards.move_child(nodes[index], index)

# 持有清單更新後，每張貓牌由 previous 中的原槽平滑移向新槽，消失的卡片節點恢復原姿態。
func slide_from(previous: Array) -> void:
	for card in _cards.get_children():
		card.reset_feedback()
	var before := _positions(previous.size())
	var from := {}
	for id in _ids:
		from[id] = before[previous.find(id)]
	_slide(from, Trade.SLIDE_DURATION)

# 每張貓牌從 from 記錄的位置滑向目前排序的槽位；settling 為自行吸入槽位的貓牌。
func _slide(from: Dictionary, duration: float, settling: Control = null) -> void:
	var slots := _positions(card_count)
	for index in _ids.size():
		var card: Control = _cards.get_child(index)
		card.position = from[_ids[index]]
		if card != settling:
			card.move_to(slots[index], duration)

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
			card.place(positions[index])

# 拿起貓牌時收起賣出按鈕，由拖曳控制器接手。
func _begin_drag(card: Control, pointer: Vector2) -> void:
	_hide_sell()
	_drag.begin(card, pointer, _ids.duplicate(), _positions(card_count))

# 插入位置改變時，其餘貓牌滑到預覽排序中的槽位讓位。
func _make_way(order: Array) -> void:
	var slots := _positions(card_count)
	for index in order.size():
		var card := get_card(order[index])
		if card != _drag.card:
			card.move_to(slots[index], DragConfig.MAKE_WAY_DURATION)

# 放開後提交排序：被拖曳的貓牌吸進自己的槽位，其餘貓牌從目前位置滑向各自的槽位。
func _drop(card: Control, order: Array, lift: float, tilt: float) -> void:
	var from := {}
	for id in _ids:
		from[id] = get_card(id).position
	if order != _ids:
		order_changed.emit(order)
	_slide(from, DragConfig.MAKE_WAY_DURATION, card)
	_drag.settle(card, _positions(card_count)[_ids.find(card.cat_id)], lift, tilt)

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
