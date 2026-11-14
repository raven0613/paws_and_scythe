extends SceneTree

const Math = preload("res://src/service/score/odometer_math.gd")
const Config = preload("res://src/configs/score/odometer_config.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Feedback = preload("res://src/configs/score/score_feedback_config.gd")
const Motion = preload("res://src/service/score/number_motion.gd")
var failures := 0

func _init() -> void:
	_check(Math.decimals(1, 1 + Rules.COMBO_STEP, true) == Config.MULTIPLIER_MIN_DECIMALS, "Simple multipliers keep one decimal throughout")
	var fraction := 1.0 / pow(Config.RADIX, Config.MULTIPLIER_MAX_DECIMALS)
	_check(Math.decimals(1 + fraction, 2, true) == Config.MULTIPLIER_MAX_DECIMALS, "Precision includes the starting endpoint")
	_check(Math.decimals(1, 2 + fraction, true) == Config.MULTIPLIER_MAX_DECIMALS, "Precision includes the target endpoint")
	_check(Math.decimals(1 + fraction, 2 + fraction, false) == 0, "Scores and combo counts stay integer")
	for precision in range(Config.MULTIPLIER_MAX_DECIMALS + 1):
		var value: int = pow(Config.RADIX, precision)
		_check(is_equal_approx(float(Math.format_units(value, precision)), 1.0), "Fixed precision formats exactly")
		_check(Math.units(-1, precision) == -value, "Negative values preserve sign")
	var boundary: float = pow(Config.RADIX, 2)
	var before := boundary - 1 + (1.0 + Config.ROLL_START) / 2.0
	_check(Math.wheel(before, 0).x == Config.RADIX - 1, "Units roll out of nine")
	_check(Math.wheel(before, 1).y > 0 and Math.wheel(before, 2).y > 0, "Carry propagates through consecutive nines")
	_check(Math.wheel(boundary - 2, 1).y == 0, "Higher places stay still until carry")
	_check(Math.wheel(boundary, 0) == Vector2.ZERO and Math.wheel(boundary, 2) == Vector2(1, 0), "Carry settles exactly at next power")
	_check(Math.visible_places(0, 0) == 1, "Scores start with a single zero")
	_check(Math.visible_places(before, 0) == str(int(boundary)).length(), "New leading wheel appears during carry")
	_check(Math.visible_places(0, Config.MULTIPLIER_MAX_DECIMALS) == Config.MULTIPLIER_MAX_DECIMALS + 1, "Fractional formatting preserves all decimal slots")
	_check(Math.wheel(before, 0).y < Math.wheel(before + fraction, 0).y, "Forward and reverse travel share continuous wheel positions")
	_check(Math.detent(0).is_equal_approx(Vector2.ONE) and Math.detent(Config.DETENT_PORTION).is_equal_approx(Vector2.ONE), "Detent returns to rest")
	_check(Math.detent(Config.DETENT_PORTION / 2).is_equal_approx(Vector2.ONE + Config.DETENT_SCALE), "Detent uses configured compression")
	var tick := Config.DETENT_PORTION / 2
	_check(Math.wheel_detent(boundary + tick, 2, false).is_equal_approx(Vector2.ONE + Config.DETENT_SCALE), "Higher wheels click just after carrying")
	_check(Math.wheel_detent(boundary + Config.RADIX + tick, 2, false).is_equal_approx(Vector2.ONE), "Stationary higher wheels stay still during lower-digit clicks")
	_check(Math.wheel_detent(boundary - tick, 2, true).is_equal_approx(Vector2.ONE + Config.DETENT_SCALE), "Reverse carry has its own arrival click")
	_check_reel()
	print("Odometer math: %d failures" % failures)
	quit(1 if failures else 0)

func _check_reel() -> void:
	var seconds := Feedback.COUNT_DURATION
	var slow := Config.READABLE_RATE * seconds / 2
	for place in 2:
		_check(Math.handoff(0, slow, seconds, place) == 0.0, "Readable counts follow the real wheel")
	_check(Math.reel(0, slow, 0.5, seconds, 0) == Math.wheel(Motion.value(0, slow, 0.5), 0), "Readable counts show the exact wheel")
	var fast := pow(Config.RADIX, 6)
	for place in 4:
		var handover := Math.handoff(0, fast, seconds, place)
		_check(handover > 0.0, "Fast lower places spin")
		var step := 0.01
		var before := _position(Math.reel(0, fast, handover - step, seconds, place))
		var earlier := _position(Math.reel(0, fast, handover - step * 2, seconds, place))
		var spin := Config.SPIN_RATE * seconds * step
		_check(is_equal_approx(fposmod(before - earlier, Config.RADIX), fposmod(spin, Config.RADIX)), "Spin rolls forward at the configured rate")
		var joined := _position(Math.reel(0, fast, handover, seconds, place))
		_check(is_equal_approx(fposmod(joined - before, Config.RADIX), fposmod(spin, Config.RADIX)), "Spin joins the real wheel exactly at handover")
		var reverse := _position(Math.reel(fast, 0, handover - step, seconds, place)) - _position(Math.reel(fast, 0, handover - step * 2, seconds, place))
		_check(is_equal_approx(fposmod(reverse, Config.RADIX), fposmod(-spin, Config.RADIX)), "Decreasing counts spin backward")
	_check(Math.reel(0, fast, 1.0, seconds, 0) == Math.wheel(fast, 0), "Every reel lands on the exact target")

func _position(wheel: Vector2) -> float:
	return wheel.x + wheel.y

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
