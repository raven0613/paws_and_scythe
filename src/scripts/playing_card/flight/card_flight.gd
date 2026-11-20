extends RefCounted

const Config = preload("res://src/configs/playing_card/flight_animation_config.gd")
const Math = preload("res://src/service/playing_card/flight_math.gd")

# 單張卡牌的飛行形變，作用於卡牌 group_visual() 提供的整體節點，牌面、文字、花紋、陰影與附加圖層一起變形；
# 離開桌面的陰影偏移作用於 group_shadow()，透視傾身經由卡牌的 set_tilt()。
# 飛行中依牌中心的可見速度沿移動方向伸縮並透視傾身，可疊加離開桌面的高度；到站後播放落地回彈，結束時還原。
var _card: Control
var _visual: Node2D
var _shadow: Node2D
var _shadow_rest: Vector2
var _enabled: bool
var _duration: float
var _landing: Dictionary
var _previous := Vector2.ZERO
var _progress := -1.0
var _direction := Vector2.RIGHT
var _intensity := 0.0

# duration 為飛行秒數，用來由進度差換算速度；landing 為到站後的回彈參數。
func _init(card: Control, duration: float, enabled: bool, landing: Dictionary = {}) -> void:
	_card = card
	_duration = duration
	_enabled = enabled
	_landing = landing
	_visual = card.group_visual()
	_shadow = card.group_shadow()
	_shadow_rest = _shadow.position

# 卡牌位置更新後呼叫；lift 為離開桌面的高度，0 為桌面、1 為最高點。
func update(progress: float, lift := 0.0) -> void:
	if not _enabled:
		return
	var view := _card.get_global_transform_with_canvas()
	var center := view * _card.pivot_offset
	var elapsed := (progress - _progress) * _duration
	if _progress >= 0.0 and elapsed > 0.0:
		var delta := center - _previous
		_intensity = Math.intensity(Math.reference_delta(delta, _card.get_viewport_rect().size).length() / elapsed)
		if not delta.is_zero_approx():
			_direction = Math.local_direction(delta, view)
	_previous = center
	_progress = progress
	_apply(_intensity, 1.0 + lift * Config.LIFT_SCALE, lift)

# 在動作時間線上接續落地回彈，delay 為抵達的時間點。
func land(timeline: Tween, delay: float) -> void:
	if not _enabled:
		return
	timeline.tween_method(_settle, 0.0, 1.0, _landing.duration).set_delay(delay)

func finish() -> void:
	if not _enabled:
		return
	_visual.transform = Transform2D.IDENTITY
	_shadow.position = _shadow_rest
	_card.set_tilt(Vector2.ZERO, Config.LEAN_PERSPECTIVE)

func _settle(progress: float) -> void:
	var pose := Math.landing(progress, _landing)
	_apply(_intensity * pose.carry, pose.scale, 0.0)

func _apply(intensity: float, scale: float, lift: float) -> void:
	_visual.transform = Math.deform(_direction, intensity * Config.MAX_STRETCH, scale, _card.pivot_offset)
	_shadow.position = _shadow_rest + Config.LIFT_SHADOW * lift
	_card.set_tilt(_direction * intensity * Config.MAX_LEAN, Config.LEAN_PERSPECTIVE)
