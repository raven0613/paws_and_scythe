extends SceneTree

const Motion = preload("res://src/service/playing_card/dig_motion.gd")
const Config = preload("res://src/configs/playing_card/action_animation_config.gd")
const CardTexture = preload("res://src/assets/card/card_bg.png")
var failures := 0

func _init() -> void:
	var size: Vector2 = CardTexture.get_size()
	var drop: float = size.y * Config.DIG_RISE_HEIGHT
	var duration: float = Motion.time_to_drop(drop, size.y)
	for side in [-1.0, 1.0]:
		_check(Motion.offset(0.0, size, side, duration).is_zero_approx(), "Reversed trajectory ends at exact cell")
		var apex: Vector2 = Motion.offset(Config.DIG_APEX_TIME / duration, size, side, duration)
		_check(is_equal_approx(apex.y, -drop), "Apex matches configured rise")
		var end: Vector2 = Motion.offset(1.0, size, side, duration)
		_check(is_equal_approx(end.y, drop), "Exit solver reaches requested depth")
		_check(is_equal_approx(end.x, side * size.x * Config.DIG_SIDE_WIDTH), "Exit preserves chosen direction and width")
		var extended := Motion.offset(2.0, size, side, duration)
		_check(extended.y > end.y and is_equal_approx(extended.x, end.x * 2.0), "Camera changes extend the same parabola")
	print("Dig motion tests: %d failures" % failures)
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
