extends SceneTree

const Breath = preload("res://src/service/motion/breath_pulse.gd")
const Config = preload("res://src/configs/playing_card/card_hover_config.gd")
var failures := 0

func _init() -> void:
	_check(is_equal_approx(Breath.scale(0.0, 1.0), 1.0), "Breath starts from the resting size")
	_check(is_equal_approx(Breath.scale(Config.BREATH_UP, 1.0), Config.BREATH_SCALE), "Breath peaks at the configured scale")
	var end := Config.BREATH_UP + Config.BREATH_DOWN
	_check(is_equal_approx(Breath.scale(end, 1.0), 1.0) and Breath.finished(end), "Breath settles back to the resting size")
	_check(not Breath.finished(end - 0.001), "Breath lasts its full duration")
	var previous := 1.0
	for step in range(1, 11):
		var value := Breath.scale(Config.BREATH_UP * step / 10.0, 1.0)
		_check(value > previous - 0.0001, "Scale grows while breathing in")
		previous = value
	_check(Breath.scale(Config.BREATH_UP / 4.0, 1.0) - 1.0 > (Config.BREATH_SCALE - 1.0) / 2.0, "Breathing in starts fast and eases out")
	for step in range(1, 11):
		var value := Breath.scale(Config.BREATH_UP + Config.BREATH_DOWN * step / 10.0, 1.0)
		_check(value < previous + 0.0001, "Scale shrinks while breathing out")
		previous = value
	var middle := Breath.scale(Config.BREATH_UP + Config.BREATH_DOWN / 2.0, 1.0)
	_check(is_equal_approx(Breath.scale(0.0, middle), middle), "Re-entering mid-breath continues from the current size")
	var pivot := Vector2(36.5, 46)
	for value in [1.0, Config.BREATH_SCALE]:
		_check((Breath.offset(value, pivot) + pivot * value).is_equal_approx(pivot), "Card scales about its center")
	print("Breath pulse: %d failures" % failures)
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
