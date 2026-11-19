extends Node

# 拖曳放牌：接手被拖起的手牌，浮起後跟隨游標並依橫向速度擺動，游標靠近合法待放格時鎖定該格、牌面下壓並往格子靠攏；
# 拖曳期間暫停資訊 Hover。
# 放開時還原卡牌圖層與根節點角度，送出鎖定的落點與當下的高度及擺動角度，由落牌演出接續。
signal released(card: Control, cell: Variant, lift: float, tilt: float)

const Config = preload("res://src/configs/hand_area/card_drag_config.gd")
const ActionConfig = preload("res://src/configs/playing_card/action_animation_config.gd")
const FlightConfig = preload("res://src/configs/playing_card/flight_animation_config.gd")
const Flight = preload("res://src/scripts/playing_card/flight/card_flight.gd")

var card: Control
var lift := 0.0
var _board: Control
var _layer := 0
var _grab := Vector2.ZERO
var _pointer := Vector2.ZERO
var _sway := 0.0
var _time := 0.0
var _target: Variant = null
var _flight: RefCounted
var _lift_tween: Tween

func setup(board: Control) -> void:
	_board = board
	get_viewport().get_window().focus_exited.connect(_on_focus_lost)

# pointer 為開始拖曳時游標在畫面上的位置，牌面與游標的相對位置在拖曳期間維持不變。
func begin(dragged: Control, pointer: Vector2) -> void:
	card = dragged
	_pointer = pointer
	_grab = _parent_point(_pointer) - card.position
	_layer = card.z_index
	card.z_index = ActionConfig.FLIGHT_LAYER
	_sway = 0.0
	_time = 0.0
	_target = null
	# 形變以秒為進度，持續時間 1 使進度差即為經過秒數。
	_flight = Flight.new(card, 1.0, FlightConfig.DRAG_ENABLED)
	_lift_to(1.0)
	HoverInfo.set_paused(true)

func _input(event: InputEvent) -> void:
	if card == null:
		return
	if event is InputEventMouseMotion:
		_pointer = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish(_target)

func _process(delta: float) -> void:
	if card == null:
		return
	_time += delta
	_retarget(_board.drop_cell(_pointer, Config.SNAP_RANGE))
	var goal := _parent_point(_pointer) - _grab
	if _target != null:
		goal = goal.lerp(_parent_point(_board.placement_center(_target)) - card.pivot_offset, Config.MAGNET)
	var previous := card.position
	card.position = previous.lerp(goal, 1.0 - exp(-Config.FOLLOW_SPEED * delta))
	var sway := clampf((card.position.x - previous.x) / delta * Config.SWAY_PER_SPEED, -Config.MAX_SWAY, Config.MAX_SWAY)
	_sway = lerpf(_sway, sway, 1.0 - exp(-Config.SWAY_FOLLOW * delta))
	card.rotation = _sway
	_flight.update(_time, lift)

func _retarget(cell: Variant) -> void:
	if cell == _target:
		return
	_target = cell
	_board.set_drop_target(cell)
	_lift_to(1.0 if cell == null else Config.TARGET_LIFT)

func _lift_to(value: float) -> void:
	if _lift_tween:
		_lift_tween.kill()
	_lift_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_lift_tween.tween_property(self, "lift", value, Config.LIFT_DURATION)

func _finish(cell: Variant) -> void:
	var dropped := card
	card = null
	_lift_tween.kill()
	_board.set_drop_target(null)
	_flight.finish()
	dropped.z_index = _layer
	dropped.rotation = 0.0
	HoverInfo.set_paused(false)
	released.emit(dropped, cell, lift, _sway)

# 視窗失去焦點時收不到放開事件，直接放回手牌。
func _on_focus_lost() -> void:
	if card != null:
		_finish(null)

func _parent_point(point: Vector2) -> Vector2:
	return card.get_parent().get_global_transform_with_canvas().affine_inverse() * point
