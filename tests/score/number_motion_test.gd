extends SceneTree

const Motion = preload("res://src/service/score/number_motion.gd")
const Config = preload("res://src/configs/score/score_feedback_config.gd")
const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
var failures := 0

func _init() -> void:
	var motion = Motion.new()
	var base: float = Catalog.CARDS.growth.value
	var bonus: float = Catalog.CARDS.peace.value
	motion.reset(0.0)
	motion.begin(base)
	motion.advance(Config.COUNT_MAIN_RATIO / 2)
	_check(motion.current > 0 and motion.current < base, "First segment is still counting")
	motion.begin(base + bonus)
	_check(motion.current == base, "New segment first lands on the previous exact result")
	motion.advance(0.0)
	_check(motion.current == base, "Second segment starts from the completed result")
	motion.advance(1.0)
	_check(motion.current == base + bonus and not motion.active, "Completion preserves the exact target")
	motion.begin(base)
	motion.advance(Config.COUNT_MAIN_RATIO)
	_check(motion.current >= base and motion.current <= base + bonus, "Decreasing values stay in range")
	motion.finish()
	_check(motion.current == base, "Interrupted decrease can finish exactly")
	var multiplier: float = Catalog.CARDS.variety.value
	motion.reset(multiplier)
	motion.begin(multiplier + Catalog.CARDS.combo.value)
	motion.advance(Config.COUNT_MAIN_RATIO / 2)
	_check(motion.current > multiplier, "Small multiplier changes begin moving during the main count")
	motion.advance(1.0)
	_check(motion.current == multiplier + Catalog.CARDS.combo.value, "Fractional multipliers retain full precision")
	motion.begin(motion.current)
	_check(not motion.active, "An unchanged target is already complete")
	motion.begin(base)
	motion.reset(0.0)
	motion.begin(bonus)
	_check(motion.current == 0.0, "Reset clears the previous pending result")
	motion.advance(1.0)
	motion.advance(Config.COUNT_MAIN_RATIO)
	_check(motion.current == bonus, "A completed segment stays on its result")
	var main_travel := Motion.value(0.0, base, Config.COUNT_MAIN_RATIO) - Motion.value(0.0, base, 0.0)
	_check(is_equal_approx(Motion.rate(0.0, base, 0.0) * Config.COUNT_MAIN_RATIO, main_travel), "Main rate matches the main segment")
	var tail_travel := base - Motion.value(0.0, base, Config.COUNT_MAIN_RATIO)
	_check(is_equal_approx(Motion.rate(0.0, base, 1.0) * (1.0 - Config.COUNT_MAIN_RATIO), tail_travel), "Tail rate matches the tail segment")
	print("Number motion: %d failures" % failures)
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
