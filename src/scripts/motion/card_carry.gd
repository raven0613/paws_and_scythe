extends Node

# 手牌與貓牌共用的拖起動作：卡牌浮起後追上持有者指定的位置，依橫向速度擺動並套用飛行形變；拖曳期間暫停資訊 Hover。
# 放開左鍵或視窗失去焦點時送出 released，由持有者決定落點，呼叫 drop() 交回卡牌後接續落下演出。
signal released

const ActionConfig = preload("res://src/configs/playing_card/action_animation_config.gd")
const FlightConfig = preload("res://src/configs/playing_card/flight_animation_config.gd")
const Flight = preload("res://src/scripts/playing_card/flight/card_flight.gd")

var card: Control
var pointer := Vector2.ZERO
var lift := 0.0
var sway := 0.0
var _config: Script
var _grab := Vector2.ZERO
var _layer := 0
var _time := 0.0
var _flight: RefCounted
var _lift_tween: Tween

func _ready() -> void:
	get_viewport().get_window().focus_exited.connect(_on_focus_lost)

# at 為開始拖曳時游標在畫面上的位置，牌面與游標的相對位置在拖曳期間維持不變。
# config 提供 LIFT_DURATION、FOLLOW_SPEED、SWAY_PER_SPEED、MAX_SWAY 與 SWAY_FOLLOW。
func begin(dragged: Control, at: Vector2, config: Script) -> void:
	card = dragged
	pointer = at
	_config = config
	_grab = to_parent(pointer) - card.position
	_layer = card.z_index
	card.z_index = ActionConfig.FLIGHT_LAYER
	sway = 0.0
	_time = 0.0
	# 形變以秒為進度，持續時間 1 使進度差即為經過秒數。
	_flight = Flight.new(card, 1.0, FlightConfig.DRAG_ENABLED)
	lift_to(1.0)
	HoverInfo.set_paused(true)

# 維持抓取相對位置時，牌左上角在父節點座標中應在的位置。
func goal() -> Vector2:
	return to_parent(pointer) - _grab

# 持有者每幀決定 target 後呼叫：牌以指數速率追上 target，依橫向速度擺動並更新形變。
func follow(delta: float, target: Vector2) -> void:
	_time += delta
	var previous := card.position
	card.position = previous.lerp(target, 1.0 - exp(-_config.FOLLOW_SPEED * delta))
	var swing := clampf((card.position.x - previous.x) / delta * _config.SWAY_PER_SPEED, -_config.MAX_SWAY, _config.MAX_SWAY)
	sway = lerpf(sway, swing, 1.0 - exp(-_config.SWAY_FOLLOW * delta))
	card.rotation = sway
	_flight.update(_time, lift)

# 以 Back Out 在 LIFT_DURATION 內補間到離開桌面的高度 value。
func lift_to(value: float) -> void:
	if _lift_tween:
		_lift_tween.kill()
	_lift_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_lift_tween.tween_property(self, "lift", value, _config.LIFT_DURATION)

# 還原卡牌圖層、角度與形變並恢復資訊 Hover，交回卡牌；lift 與 sway 保留放開當下的值供落下演出接續。
func drop() -> Control:
	var dropped := card
	card = null
	_lift_tween.kill()
	_flight.finish()
	dropped.z_index = _layer
	dropped.rotation = 0.0
	HoverInfo.set_paused(false)
	return dropped

func to_parent(point: Vector2) -> Vector2:
	return card.get_parent().get_global_transform_with_canvas().affine_inverse() * point

func _input(event: InputEvent) -> void:
	if card == null:
		return
	if event is InputEventMouseMotion:
		pointer = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		released.emit()

# 視窗失去焦點時收不到放開事件，直接放下。
func _on_focus_lost() -> void:
	if card != null:
		released.emit()
