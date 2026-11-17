extends Node

const Config = preload("res://src/configs/hand_area/hand_area_config.gd")
const HoverTilt = preload("res://src/service/motion/hover_tilt.gd")
const Breath = preload("res://src/service/motion/breath_pulse.gd")
var _cards: Control
var _enabled := false
var _hovered: Control
var _states: Dictionary = {}

# 位移、縮放與透視傾斜作用於卡牌 visual 子節點，根節點固定在槽位負責輸入，浮起時 Hover 範圍維持不變。
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
		if state.selected != _hovered.selected:
			_follow_selection(_hovered)
		var target := HoverTilt.target(_hovered.get_local_mouse_position(), _hovered.size, Config.HOVER_TILT)
		state.tilt = HoverTilt.follow(state.tilt, target, delta, Config.HOVER_TILT_FOLLOW)
	for item in _states.keys():
		_step(item, delta)

func _hovered_card() -> Control:
	var control := get_viewport().gui_get_hovered_control()
	if control == null:
		return null
	for card in _cards.get_children():
		if card.visible and (control == card or card.is_ancestor_of(control)):
			return card
	return null

# 未選取的牌上浮，選取中的牌已因選取上移，改為原地呼吸一次；兩者都拉到最上層並依滑鼠透視傾斜。
func _enter(card: Control) -> void:
	var state: Dictionary = _states.get(card, {"lift": 0.0, "tilt": Vector2.ZERO, "scale": 1.0, "pulse": {},
		"layer": card.z_index, "tween": null})
	_states[card] = state
	state.released = false
	card.z_index = Config.HOVER_LAYER
	_follow_selection(card)

# 停在牌上點擊選取時，浮起隨牌往上跳的同時收回並呼吸一次；取消選取時浮起升回。
func _follow_selection(card: Control) -> void:
	var state: Dictionary = _states[card]
	state.selected = card.selected
	if card.selected:
		state.pulse = {"time": 0.0, "from": state.scale}
		_tween_lift(state, 0.0, Config.HOVER_RELEASE_DURATION, Tween.TRANS_QUAD)
	else:
		_tween_lift(state, Config.HOVER_LIFT, Config.HOVER_DURATION, Tween.TRANS_BACK)

func _tween_lift(state: Dictionary, target: float, duration: float, transition: Tween.TransitionType) -> void:
	if state.tween:
		state.tween.kill()
	state.tween = create_tween().set_trans(transition).set_ease(Tween.EASE_OUT)
	state.tween.tween_method(func(value: float): state.lift = value, state.lift, target, duration)

# 離開時以 Quad Out 歸位並回正，呼吸播完後回到原圖層。
func _release(card: Control) -> void:
	var state: Dictionary = _states[card]
	state.tween.kill()
	card.z_index = Config.HOVER_RELEASE_LAYER
	state.tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	state.tween.tween_method(func(value: float): state.lift = value, state.lift, 0.0, Config.HOVER_RELEASE_DURATION)
	state.tween.tween_method(func(value: Vector2): state.tilt = value, state.tilt, Vector2.ZERO, Config.HOVER_RELEASE_DURATION)
	state.tween.chain().tween_callback(func(): state.released = true)

func _step(card: Control, delta: float) -> void:
	var state: Dictionary = _states[card]
	if not state.pulse.is_empty():
		state.pulse.time += delta
		state.scale = Breath.scale(state.pulse.time, state.pulse.from)
		if Breath.finished(state.pulse.time):
			state.pulse = {}
	if state.released and state.pulse.is_empty():
		_settle(card)
		return
	var visual: Node2D = card.group_visual()
	visual.scale = Vector2.ONE * state.scale
	visual.position = Vector2.UP * state.lift + Breath.offset(state.scale, card.pivot_offset)
	card.set_tilt(state.tilt, Config.HOVER_PERSPECTIVE)

func _settle(card: Control) -> void:
	var visual: Node2D = card.group_visual()
	visual.scale = Vector2.ONE
	visual.position = Vector2.ZERO
	card.set_tilt(Vector2.ZERO, Config.HOVER_PERSPECTIVE)
	card.z_index = _states[card].layer
	_states.erase(card)

func _reset() -> void:
	for card in _states.keys():
		_states[card].tween.kill()
		_settle(card)
	_hovered = null
