extends SceneTree

const Shake = preload("res://src/service/motion/shake_motion.gd")
const Config = preload("res://src/configs/combo/combo_animation_config.gd")
var failures := 0

func _init() -> void:
	var start := _pose(0.0)
	_check(start.position.is_zero_approx() and is_zero_approx(start.rotation) and is_equal_approx(start.decay, 1.0), "Shake starts from the resting pose at full strength")
	var end := _pose(1.0)
	_check(end.position.is_zero_approx() and is_zero_approx(end.rotation) and is_zero_approx(end.decay), "Shake settles exactly at rest")
	var moved := false
	var previous_decay := 1.0
	for step in range(1, 20):
		var pose := _pose(step / 20.0)
		moved = moved or not pose.position.is_zero_approx()
		_check(absf(pose.position.x) <= Config.HOVER_SHAKE.x and absf(pose.position.y) <= Config.HOVER_SHAKE.y, "Shake stays within its amplitude")
		_check(absf(pose.rotation) <= Config.HOVER_TILT, "Tilt stays within its amplitude")
		_check(pose.decay < previous_decay, "Shake strength decays over time")
		previous_decay = pose.decay
	_check(moved, "Shake moves between start and end")
	print("Shake motion: %d failures" % failures)
	quit(1 if failures else 0)

func _pose(progress: float) -> Dictionary:
	return Shake.pose(progress, Config.HOVER_SHAKE, Config.HOVER_TILT, Config.HOVER_CYCLES, Config.HOVER_VERTICAL_CYCLES, Config.HOVER_DECAY_POWER)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
