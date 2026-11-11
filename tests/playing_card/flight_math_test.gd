extends SceneTree

const Math = preload("res://src/service/playing_card/flight_math.gd")
const Config = preload("res://src/configs/playing_card/flight_animation_config.gd")
const Frame = preload("res://src/configs/gameplay/gameplay_frame_config.gd")
var failures := 0

func _init() -> void:
	_check(is_zero_approx(Math.spring(0.0)), "Spring starts at origin")
	_check(is_equal_approx(Math.spring(1.0), 1.0), "Spring ends exactly at destination")
	var previous := 0.0
	for index in range(101):
		var value: float = Math.spring(index / 100.0)
		_check(value >= previous and value <= 1.0, "Travel remains monotonic and bounded")
		previous = value
	var distance := Config.FULL_STRETCH_DISTANCE
	_check(is_zero_approx(Math.stretch_ratio(0.0)), "Stationary cards keep their shape")
	_check(is_equal_approx(Math.stretch_ratio(distance / 2.0), Config.MAX_STRETCH_RATIO / 2.0), "Distance controls stretch")
	_check(is_equal_approx(Math.stretch_ratio(distance * 2.0), Config.MAX_STRETCH_RATIO), "Long flights cap their stretch")
	var delta := Vector2(distance, distance)
	_check(Math.reference_delta(delta * 2.0, Frame.REFERENCE_SIZE * 2.0).is_equal_approx(delta), "Window scaling preserves reference distance")
	_check(Math.reference_delta(delta / 2.0, Frame.REFERENCE_SIZE).is_equal_approx(delta / 2.0), "Camera zoom affects visible distance")
	_check(Math.front_corner(Vector2.RIGHT) == Vector2(1, 0), "Horizontal tie consistently chooses top corner")
	_check(Math.front_corner(Vector2(-1, 1)) == Vector2(0, 1), "Direction selects nearest corner")
	var transform := Transform2D(PI / 2.0, Vector2(2, 3), 0.0, delta)
	_check(Math.local_direction(transform.basis_xform(Vector2.ONE), transform).is_equal_approx(Vector2.ONE.normalized()), "Direction compensates for rotation and nonuniform scale")
	_check(is_zero_approx(Math.stretch_envelope(0.0)), "Stretch begins smoothly")
	_check(is_equal_approx(Math.stretch_envelope(1.0), Config.ARRIVAL_STRETCH), "Landing continues from arrival shape")
	print("Flight math tests: %d failures" % failures)
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
