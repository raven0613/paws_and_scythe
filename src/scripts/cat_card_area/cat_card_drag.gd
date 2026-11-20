extends Node

# 貓牌拖曳排序：由共用的 card_carry 拿起貓牌，浮起後跟隨游標並擺動。牌面最接近的槽位為插入位置，
# 插入位置改變時送出 order_previewed 讓其他貓牌讓位；放開時送出當下的排序與放開時的高度及擺動角度，由 settle() 吸進槽位。
signal order_previewed(order: Array)
signal released(card: Control, order: Array, lift: float, tilt: float)

const Config = preload("res://src/configs/cat_card_area/cat_drag_config.gd")
const ActionConfig = preload("res://src/configs/playing_card/action_animation_config.gd")
const FlightConfig = preload("res://src/configs/playing_card/flight_animation_config.gd")
const Flight = preload("res://src/scripts/playing_card/flight/card_flight.gd")
const Math = preload("res://src/service/playing_card/flight_math.gd")
const Carry = preload("res://src/scripts/motion/card_carry.gd")
const Order = preload("res://src/service/cat_card_area/cat_order.gd")

var card: Control:
	get:
		return _carry.card
var _carry := Carry.new()
var _ids: Array = []
var _slots: Array = []
var _order: Array = []

func _ready() -> void:
	add_child(_carry)
	_carry.released.connect(_finish)

# ids 為拿起前的排序，slots 為各排序位置的卡片左上角，與卡片同一父節點座標。
func begin(dragged: Control, pointer: Vector2, ids: Array, slots: Array) -> void:
	_ids = ids
	_slots = slots
	_order = ids
	dragged.set_carried(true)
	_carry.begin(dragged, pointer, Config)

func _process(delta: float) -> void:
	if card == null:
		return
	var goal := _carry.goal()
	var order := Order.moved(_ids, card.cat_id, Order.nearest_slot(_slots, goal))
	if order != _order:
		_order = order
		order_previewed.emit(order)
	_carry.follow(delta, goal)

func _finish() -> void:
	var lift := _carry.lift
	var tilt := _carry.sway
	released.emit(_carry.drop(), _order, lift, tilt)

# 從放開時的高度 lift 與擺動角度 tilt 接續，在 SETTLE_DURATION 內吸進 slot，抵達時播放落地回彈；第一幀在呼叫當下套用，與拖曳最後的姿態無縫銜接。
func settle(settling: Control, slot: Vector2, lift: float, tilt: float) -> void:
	var layer := settling.z_index
	settling.z_index = ActionConfig.FLIGHT_LAYER
	settling.move_to(slot, Config.SETTLE_DURATION)
	var flight := Flight.new(settling, Config.SETTLE_DURATION, FlightConfig.DROP_ENABLED, Config.SETTLE_LANDING)
	var land := _settle_progress.bind(settling, lift, tilt, flight)
	land.call(0.0)
	var timeline := settling.create_tween().set_parallel()
	timeline.tween_method(land, 0.0, 1.0, Config.SETTLE_DURATION)
	flight.land(timeline, Config.SETTLE_DURATION)
	await timeline.finished
	flight.finish()
	settling.z_index = layer
	settling.set_carried(false)

# 角度隨位置的彈簧進度回正，高度由 lift 以二次曲線加速降到桌面，抵達時以最快速度觸地。
func _settle_progress(progress: float, settling: Control, lift: float, tilt: float, flight: RefCounted) -> void:
	settling.rotation = lerp_angle(tilt, 0.0, Math.spring(progress))
	flight.update(progress, lift * (1.0 - progress * progress))
