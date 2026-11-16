extends Node

const Config = preload("res://src/configs/hand_area/hand_area_config.gd")
const HoverTilt = preload("res://src/service/motion/hover_tilt.gd")
var _cards: Control
var _enabled := false
var _hovered: Control
var _states: Dictionary = {}

# 位移與透視傾斜作用於卡牌 visual 子節點，根節點固定在槽位負責輸入，浮起時 Hover 範圍維持不變。
func setup(cards: Control) -> void:
	_cards = cards

# 手牌可操作時才回應 Hover；停用時立即歸位，交給發牌、出牌與棄牌等動作接手卡牌。
func set_enabled(enabled: bool) -> void:
	if _enabled == enabled:
		return
	_enabled = enabled
	if not enabled:
		_reset()

func _process(delta: float) -> void:
	if not _enabled:
		return
	var card := _hovered_card()
	if card != _hovered:
		if _hovered != null:
			_release(_hovered)
		_hovered = card
		if card != null:
			_enter(card)
	if _hovered != null:
		var state: Dictionary = _states[_hovered]
		var target := HoverTilt.target(_hovered.get_local_mouse_position(), _hovered.size, Config.HOVER_TILT)
		state.tilt = HoverTilt.follow(state.tilt, target, delta, Config.HOVER_TILT_FOLLOW)
	for item in _states:
		_apply(item)

func _hovered_card() -> Control:
	var control := get_viewport().gui_get_hovered_control()
	if control == null:
		return null
	for card in _cards.get_children():
		if card.visible and (control == card or card.is_ancestor_of(control)):
			return card
	return null

func _enter(card: Control) -> void:
	var state: Dictionary = _states.get(card, {"lift": 0.0, "tilt": Vector2.ZERO, "layer": card.z_index, "tween": null})
	_states[card] = state
	if state.tween:
		state.tween.kill()
	card.z_index = Config.HOVER_LAYER
	state.tween = create_tween()
	state.tween.tween_method(func(value: float): state.lift = value, state.lift, Config.HOVER_LIFT, Config.HOVER_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _release(card: Control) -> void:
	var state: Dictionary = _states[card]
	state.tween.kill()
	card.z_index = Config.HOVER_RELEASE_LAYER
	state.tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	state.tween.tween_method(func(value: float): state.lift = value, state.lift, 0.0, Config.HOVER_RELEASE_DURATION)
	state.tween.tween_method(func(value: Vector2): state.tilt = value, state.tilt, Vector2.ZERO, Config.HOVER_RELEASE_DURATION)
	state.tween.chain().tween_callback(_settle.bind(card))

func _apply(card: Control) -> void:
	var state: Dictionary = _states[card]
	card.group_visual().position = Vector2.UP * state.lift
	card.set_tilt(state.tilt, Config.HOVER_PERSPECTIVE)

func _settle(card: Control) -> void:
	card.group_visual().position = Vector2.ZERO
	card.set_tilt(Vector2.ZERO, Config.HOVER_PERSPECTIVE)
	card.z_index = _states[card].layer
	_states.erase(card)

func _reset() -> void:
	for card in _states.keys():
		_states[card].tween.kill()
		_settle(card)
	_hovered = null
