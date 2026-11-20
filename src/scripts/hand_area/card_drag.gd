extends Node

# 拖曳放牌：由共用的 card_carry 拿起手牌，浮起後跟隨游標並擺動；游標靠近合法待放格時鎖定該格、牌面下壓並往格子靠攏。
# 放開時送出鎖定的落點與當下的高度及擺動角度，由落牌演出接續。
signal released(card: Control, cell: Variant, lift: float, tilt: float)

const Config = preload("res://src/configs/hand_area/card_drag_config.gd")
const Carry = preload("res://src/scripts/motion/card_carry.gd")

var card: Control:
	get:
		return _carry.card
var _board: Control
var _carry := Carry.new()
var _target: Variant = null

func setup(board: Control) -> void:
	_board = board
	add_child(_carry)
	_carry.released.connect(_finish)

func begin(dragged: Control, pointer: Vector2) -> void:
	_target = null
	_carry.begin(dragged, pointer, Config)

func _process(delta: float) -> void:
	if card == null:
		return
	_retarget(_board.drop_cell(_carry.pointer, Config.SNAP_RANGE))
	var goal := _carry.goal()
	if _target != null:
		goal = goal.lerp(_carry.to_parent(_board.placement_center(_target)) - card.pivot_offset, Config.MAGNET)
	_carry.follow(delta, goal)

func _retarget(cell: Variant) -> void:
	if cell == _target:
		return
	_target = cell
	_board.set_drop_target(cell)
	_carry.lift_to(1.0 if cell == null else Config.TARGET_LIFT)

func _finish() -> void:
	_board.set_drop_target(null)
	var lift := _carry.lift
	var tilt := _carry.sway
	released.emit(_carry.drop(), _target, lift, tilt)
