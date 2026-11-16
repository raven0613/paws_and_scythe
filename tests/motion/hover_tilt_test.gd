extends SceneTree

const HoverTilt = preload("res://src/service/motion/hover_tilt.gd")
const HandConfig = preload("res://src/configs/hand_area/hand_area_config.gd")
const CatConfig = preload("res://src/configs/cat_cards/cat_feedback_config.gd")
const SIZE = Vector2(73, 92)
var failures := 0

func _init() -> void:
	for limit in [HandConfig.HOVER_TILT, CatConfig.HOVER_TILT]:
		_check(HoverTilt.target(SIZE / 2, SIZE, limit).is_zero_approx(), "Centered mouse keeps the card flat")
		var right := HoverTilt.target(Vector2(SIZE.x, SIZE.y / 2), SIZE, limit)
		_check(is_equal_approx(right.x, limit.x) and is_zero_approx(right.y), "Mouse on the right presses the right side back, bringing the left side closer")
		var top := HoverTilt.target(Vector2(SIZE.x / 2, 0.0), SIZE, limit)
		_check(is_equal_approx(top.y, -limit.y) and is_zero_approx(top.x), "Mouse at the top presses the top edge back")
		var corner := HoverTilt.target(Vector2.ZERO, SIZE, limit)
		_check(corner.is_equal_approx(-limit), "Corners tilt along both axes")
		_check(HoverTilt.target(SIZE * 3, SIZE, limit).is_equal_approx(limit), "Tilt stays within the limit")
		var inner := HoverTilt.target(SIZE * 0.75, SIZE, limit)
		_check(inner.x > 0.0 and inner.x < limit.x and inner.y > 0.0 and inner.y < limit.y, "Tilt grows toward the edges")
	var target: Vector2 = HandConfig.HOVER_TILT
	var rate: float = HandConfig.HOVER_TILT_FOLLOW
	var slow := Vector2.ZERO
	for frame in 30:
		slow = HoverTilt.follow(slow, target, 1.0 / 30.0, rate)
	var fast := Vector2.ZERO
	for frame in 144:
		fast = HoverTilt.follow(fast, target, 1.0 / 144.0, rate)
	_check(slow.distance_to(fast) < 0.0001, "Following is independent of frame rate")
	var step := HoverTilt.follow(Vector2.ZERO, target, 1.0 / 60.0, rate)
	_check(step.x > 0.0 and step.x < target.x, "Tilt eases toward its target")
	print("Hover tilt: %d failures" % failures)
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
