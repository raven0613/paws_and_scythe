extends SceneTree

const Surge = preload("res://src/service/score/galaxy_surge.gd")
const Vignette = preload("res://src/service/score/vignette_motion.gd")
const Slam = preload("res://src/service/score/slam_math.gd")
const Config = preload("res://src/configs/score/galaxy_transition_config.gd")
const Feel = preload("res://src/configs/score/celebration_config.gd")
const TOLERANCE = 0.001
const SAMPLE = 0.005
var failures := 0

func _init() -> void:
	_test_charge()
	_test_impact()
	_test_vignette()
	print("Galaxy transition: %d failures" % failures)
	quit(1 if failures else 0)

func _test_charge() -> void:
	var start := Surge.charge(0.0)
	_check(is_equal_approx(start.flow, 1.0) and is_zero_approx(start.brightness) and start.scale.is_equal_approx(Vector2.ONE), "Charge starts from the current rainbow")
	var charged := Surge.charge(Config.CHARGE_DURATION)
	_check(is_equal_approx(charged.flow, Config.CHARGE_FLOW) and is_equal_approx(charged.brightness, Config.CHARGE_BRIGHTNESS), "Rainbow speeds up and brightens while charging")
	_check(charged.scale.is_equal_approx(Config.CHARGE_SQUASH), "Number squashes before launching")

func _test_impact() -> void:
	var hit := Surge.pose(0.0)
	_check(is_equal_approx(hit.impact, 1.0) and not hit.galaxy, "Ceiling hit opens with the impact frame")
	_check(Config.IMPACT_DURATION <= Feel.CEILING_HOLD, "Impact frame finishes while the number holds on the ceiling")
	var galaxy := Surge.pose(Config.IMPACT_DURATION)
	_check(galaxy.galaxy and is_zero_approx(galaxy.impact), "Galaxy follows the impact frame directly")
	_check(is_zero_approx(galaxy.fire), "Flame starts blending once the galaxy appears")
	var halfway := Surge.pose(Config.IMPACT_DURATION + Config.FIRE_BLEND_DURATION / 2)
	_check(halfway.fire > 0.0 and halfway.fire < 1.0, "Flame colors blend gradually")
	_check(is_equal_approx(Surge.pose(Config.IMPACT_DURATION + Config.FIRE_BLEND_DURATION).fire, 1.0), "Flame finishes on the galaxy set")

func _test_vignette() -> void:
	var hit := Vignette.pose(0.0)
	_check(is_equal_approx(hit.radius, Config.VIGNETTE_RADIUS) and is_equal_approx(hit.intensity, Config.VIGNETTE_INTENSITY), "Vignette appears tight on the ceiling hit")
	var opened := Vignette.pose(Config.VIGNETTE_BURST_DURATION)
	_check(opened.radius > hit.radius, "Vignette bursts outward")
	var flickered := false
	for step in int(Config.VIGNETTE_FLICKER_DURATION / SAMPLE):
		var time := step * SAMPLE
		flickered = flickered or absf(Vignette.pose(time).intensity - _steady(time)) > TOLERANCE
	_check(flickered, "Vignette flickers after bursting")
	var after := Vignette.pose(maxf(Config.VIGNETTE_FADE_DURATION, Config.VIGNETTE_FLICKER_DURATION))
	if Config.VIGNETTE_AFTERGLOW == Config.Afterglow.LINGER:
		_check(is_equal_approx(after.intensity, Config.VIGNETTE_LINGER_INTENSITY) and is_equal_approx(after.radius, Config.VIGNETTE_LINGER_RADIUS), "Lingering vignette stays faint")
	else:
		_check(is_zero_approx(after.intensity), "Fading vignette disappears after bursting")

func _steady(since: float) -> float:
	var settle := smoothstep(0.0, 1.0, since / Config.VIGNETTE_FADE_DURATION)
	if Config.VIGNETTE_AFTERGLOW == Config.Afterglow.LINGER:
		return lerpf(Config.VIGNETTE_INTENSITY, Config.VIGNETTE_LINGER_INTENSITY, settle)
	return Config.VIGNETTE_INTENSITY * (1.0 - settle)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
