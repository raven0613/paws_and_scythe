extends RefCounted

const Config = preload("res://src/configs/score/showcase_config.gd")
const REST = {"rotation": 0.0, "offset": Vector2.ZERO}

# 扇形角度：牌組中央為零度，依路徑順序由負角展開至正角。
static func fan_angle(index: int, count: int) -> float:
	if count <= 1:
		return 0.0
	var step := minf(Config.FAN_STEP, Config.FAN_MAX_SPREAD / (count - 1))
	return (index - (count - 1) / 2.0) * step

# 牌組自開始到收回的時間：最後一張浮起到位並停留。
static func group_release(count: int) -> float:
	return (count - 1) * Config.CARD_INTERVAL + Config.RISE_DURATION + Config.HOLD_DURATION

# 亮相段在最後一組開始收回時結束，後續演出與收回同時進行。
static func stage_end(counts: Array) -> float:
	return (counts.size() - 1) * Config.ROW_INTERVAL + group_release(counts[-1])

# 單張牌在第 order 組中的動作；各組相隔 ROW_INTERVAL 開始，noise 介於 -1 與 1，決定沿旋轉後上方的位移增減。
static func entry(order: int, index: int, count: int, noise: float) -> Dictionary:
	var group_start := order * Config.ROW_INTERVAL
	return {
		"order": order,
		"start": group_start + index * Config.CARD_INTERVAL,
		"release": group_start + group_release(count),
		"rotation": fan_angle(index, count),
		"lift": Config.LIFT * (1.0 + Config.LIFT_JITTER * noise),
	}

# 牌目前所屬的亮相組；尚未浮起或已收回原位時為 -1。越晚亮相的組位於越上層。
static func layer_order(entries: Array, time: float) -> int:
	var active := _active(entries, time)
	if active < 0 or time >= entries[active].release + Config.RETURN_DURATION:
		return -1
	return entries[active].order

static func duration(entries: Array) -> float:
	var result := 0.0
	for item in entries:
		result = maxf(result, item.release + Config.RETURN_DURATION)
	return result

# entries 依開始時間排列；後一組開始時從當下姿態接手，維持動作連續。
static func pose(entries: Array, time: float) -> Dictionary:
	var active := _active(entries, time)
	if active < 0:
		return REST
	var current: Dictionary = entries[active]
	var from := pose(entries.slice(0, active), current.start)
	var target := {"rotation": current.rotation, "offset": Vector2.UP.rotated(current.rotation) * current.lift}
	if time < current.start + Config.RISE_DURATION:
		var rise: float = Tween.interpolate_value(0.0, 1.0, time - current.start, Config.RISE_DURATION, Tween.TRANS_BACK, Tween.EASE_OUT)
		return _blend(from, target, rise)
	if time < current.release:
		return target
	var back: float = Tween.interpolate_value(0.0, 1.0, minf(time - current.release, Config.RETURN_DURATION), Config.RETURN_DURATION, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	return _blend(target, REST, back)

static func _active(entries: Array, time: float) -> int:
	var active := -1
	for index in entries.size():
		if time >= entries[index].start:
			active = index
	return active

static func _blend(from: Dictionary, to: Dictionary, weight: float) -> Dictionary:
	var offset: Vector2 = from.offset
	return {"rotation": lerpf(from.rotation, to.rotation, weight), "offset": offset.lerp(to.offset, weight)}
