@tool
extends Control

signal selection_changed

const Config = preload("res://src/configs/hand_area/hand_area_config.gd")
const CardTexture = preload("res://src/assets/card/card_bg.png")
const HoverAnimator = preload("res://src/scripts/hand_area/hand_hover_animator.gd")
const Shift = preload("res://src/service/hand_area/hand_shift.gd")

@export_range(Config.MIN_CARD_COUNT, Config.MAX_CARD_COUNT, 1)
var card_count: int = Config.DEFAULT_CARD_COUNT:
	set(value):
		card_count = clampi(value, Config.MIN_CARD_COUNT, Config.MAX_CARD_COUNT)
		_layout_count = card_count
		if is_node_ready():
			_update_layout()

@onready var _background: NinePatchRect = $background
@onready var _cards: Control = $cards
var _selection_enabled := true
var _selected: Array = []
var _slot_y: Array[float] = []
var _hover: Node
# 手牌區寬度依 _layout_count 計算；補位開始時即採用更新後的張數。
var _layout_count := Config.DEFAULT_CARD_COUNT
var _slides: Dictionary = {}
var _held: Control
var _background_tween: Tween
var _background_target := 0.0

func _ready() -> void:
	for card in _cards.get_children():
		_slot_y.append(card.position.y)
	if not Engine.is_editor_hint():
		_hover = HoverAnimator.new()
		_hover.setup(_cards)
		add_child(_hover)
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

func card_destination(index: int) -> Transform2D:
	return _cards.get_global_transform_with_canvas() * Transform2D(0.0, _slot_position(index))

# 出牌或棄牌的牌離手時呼叫，order 為更新後的手牌 ID；留下的牌由最靠近空位的一張開始依序補位。
func close_gaps(order: Array) -> void:
	_shift(order, Config.SHIFT_INTERVAL, Config.SHIFT_DURATION)

# 撤銷出牌的牌飛回時呼叫，order 為還原後的手牌 ID；讓位的牌同時移動，在 duration 內讓出槽位。
func make_room(order: Array, duration: float) -> void:
	_shift(order, 0.0, duration)

# 補間只作用於橫向位置，選取位移與 Hover 照常運作；移動中的牌再次補位時從當下位置接續。
func _shift(order: Array, interval: float, duration: float) -> void:
	var current: Array = []
	for card in _cards.get_children():
		if card.visible:
			current.append(card.card_id)
			if not order.has(card.card_id):
				_stop_slide(card)
	var moves := Shift.plan(current, order, interval)
	for move in moves:
		var card: Control = _cards.get_child(move.from)
		_stop_slide(card)
		var slide := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		slide.tween_property(card, "position:x", _slot_position(move.to).x, duration).set_delay(move.delay)
		slide.tween_callback(func(): _slides.erase(card))
		_slides[card] = slide
	_layout_count = order.size()
	_resize_background(_hand_width(), Shift.edge_delay(moves), duration)

func _slot_position(index: int) -> Vector2:
	return Vector2(Config.CARD_START_X + (CardTexture.get_width() + Config.CARD_GAP) * index, _slot_y[index])

func clear_selection() -> void:
	_selected.clear()
	_update_layout()
	selection_changed.emit()

func set_selection_enabled(enabled: bool) -> void:
	_selection_enabled = enabled
	_hover.set_enabled(enabled)
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

# 拖曳中的牌由拖曳與落牌演出接手位置，排版略過這張牌並保留空出的槽位；card 為 null 時交回排版。
func hold(card: Control) -> void:
	if card != null:
		_stop_slide(card)
	_held = card

# 離手的牌停在當下位置，交給出牌與棄牌動作接手。
func _stop_slide(card: Control) -> void:
	if _slides.has(card):
		_slides[card].kill()
		_slides.erase(card)

func _update_layout() -> void:
	for index in range(_cards.get_child_count()):
		var card := _cards.get_child(index) as Control
		if card == _held:
			continue
		card.visible = index < card_count
		if not _slides.has(card):
			card.position.x = _slot_position(index).x
		if not Engine.is_editor_hint():
			card.selected = _selected.has(card.card_id)
			card.position.y = _slot_y[index] - (Config.SELECTED_OFFSET if card.selected else 0.0)
			card.selection_enabled = _selection_enabled and card.visible
	var hand_width := _hand_width()
	_background.patch_margin_left = Config.BACKGROUND_EDGE_WIDTH
	_background.patch_margin_right = Config.BACKGROUND_EDGE_WIDTH
	custom_minimum_size.x = hand_width
	size.x = hand_width
	if not (_background_tween and _background_tween.is_running() and is_equal_approx(_background_target, hand_width)):
		_resize_background(hand_width, 0.0, 0.0)

func _hand_width() -> float:
	var gap_count := maxi(_layout_count - 1, 0)
	return Config.CARD_START_X + CardTexture.get_width() * _layout_count + Config.CARD_GAP * gap_count + Config.RIGHT_PADDING

# 底板左緣固定，右緣以與卡牌相同的曲線移動；duration 為零時直接到位。
func _resize_background(width: float, delay: float, duration: float) -> void:
	if _background_tween:
		_background_tween.kill()
	_background_target = width
	if duration <= 0.0 or is_equal_approx(_background.offset_right, width):
		_background.offset_right = width
		return
	_background_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_background_tween.tween_property(_background, "offset_right", width, duration).set_delay(delay)
