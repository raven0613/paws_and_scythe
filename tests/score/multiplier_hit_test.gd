extends SceneTree

const Hit = preload("res://src/service/score/multiplier_hit.gd")
const Config = preload("res://src/configs/score/score_feedback_config.gd")
var failures := 0

func _init() -> void:
	var duration := Config.COUNT_DURATION
	var start := Hit.pose(0.0, duration)
	_check(is_equal_approx(start.scale, 1.0) and start.position.is_zero_approx() and is_zero_approx(start.rotation), "Multiplier starts from its resting pose")
	var grown := Hit.pose(Config.MULTIPLIER_HIT_GROW, duration)
	_check(is_equal_approx(grown.scale, Config.MULTIPLIER_HIT_SCALE), "Multiplier grows to the hit scale")
	var overshoot := false
	for step in range(1, 10):
		overshoot = overshoot or Hit.pose(Config.MULTIPLIER_HIT_GROW * step / 10.0, duration).scale > Config.MULTIPLIER_HIT_SCALE
	_check(overshoot, "Growth overshoots before settling")
	var shaking := Hit.pose(Config.MULTIPLIER_HIT_SHAKE_DURATION / 3.0, duration)
	_check(not shaking.position.is_zero_approx() or not is_zero_approx(shaking.rotation), "Multiplier shakes while growing")
	var hold := Hit.pose(duration - Config.MULTIPLIER_HIT_RELEASE, duration)
	_check(is_equal_approx(hold.scale, Config.MULTIPLIER_HIT_SCALE) and hold.position.is_zero_approx() and is_zero_approx(hold.rotation), "Multiplier holds the hit scale once the shake settles")
	var returning := Hit.pose(duration - Config.MULTIPLIER_HIT_RELEASE / 2.0, duration)
	_check(returning.scale > 1.0 and returning.scale < Config.MULTIPLIER_HIT_SCALE, "Multiplier tweens back before the count lands")
	var rest := Hit.pose(duration, duration)
	_check(is_equal_approx(rest.scale, 1.0) and rest.position.is_zero_approx() and is_zero_approx(rest.rotation), "Multiplier rests when the count lands")
	print("Multiplier hit: %d failures" % failures)
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
