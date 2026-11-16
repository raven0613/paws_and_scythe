extends SceneTree

const Slosh = preload("res://src/service/action_buttons/water_slosh.gd")
const Config = preload("res://src/configs/action_buttons/action_button_motion_config.gd")
var failures := 0

func _init() -> void:
	_check(Slosh.is_calm(Slosh.REST), "Rest water is calm")
	var kicked := Slosh.kick(Slosh.REST, 1.0)
	_check(not Slosh.is_calm(kicked) and kicked.chop > 0.0, "A kick disturbs the water")
	var quarter := Slosh.step(kicked, 0.25 / Config.SLOSH_FREQUENCY)
	_check(quarter.tilt > 0.0, "A rightward kick piles water on the left first")
	_check(quarter.tilt <= Config.SLOSH_TILT and quarter.tilt > Config.SLOSH_TILT * 0.5, "Peak tilt follows the configured strength")
	_check(Slosh.step(Slosh.kick(Slosh.REST, -1.0), 0.25 / Config.SLOSH_FREQUENCY).tilt < 0.0, "A leftward kick tilts the other way")
	var half := Slosh.step(kicked, 0.75 / Config.SLOSH_FREQUENCY)
	_check(half.tilt < 0.0, "Water sloshes back past level")
	var state := kicked
	var calm_at := -1.0
	for frame in 60 * 10:
		state = Slosh.step(state, 1.0 / 60.0)
		if calm_at < 0.0 and Slosh.is_calm(state):
			calm_at = frame / 60.0
	_check(calm_at > 1.0 and calm_at < 10.0, "Water calms down gradually")
	_check(Slosh.step(kicked, 0.5).chop < kicked.chop, "Choppy waves fade")
	var stacked := kicked
	for count in 10:
		stacked = Slosh.kick(stacked, 1.0)
	_check(is_equal_approx(stacked.chop, Config.SLOSH_CHOP_MAX), "Choppy energy is capped")
	var coarse := Slosh.step(kicked, 0.3)
	var fine := kicked
	for frame in 36:
		fine = Slosh.step(fine, 0.3 / 36.0)
	_check(absf(coarse.tilt - fine.tilt) < 0.01 and absf(coarse.chop - fine.chop) < 0.0001, "Sloshing is stable across frame rates")
	print("Water slosh: %d failures" % failures)
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
