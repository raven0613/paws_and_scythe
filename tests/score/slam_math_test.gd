extends SceneTree

const Slam = preload("res://src/service/score/slam_math.gd")
const Config = preload("res://src/configs/score/celebration_config.gd")
const Feedback = preload("res://src/configs/score/score_feedback_config.gd")
const TOLERANCE = 0.01
const EPSILON = 0.000001
const CORNERS = [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(-0.5, 0.5), Vector2(0.5, 0.5)]
var size := Vector2(2, 1) * Feedback.NUMBER_FONT_SIZE
var failures := 0

func _init() -> void:
	_check_travel()
	_check_contacts()
	_check_ceiling()
	_check_landings()
	_check_emitters()
	_check_effects()
	var rest := Slam.pose(1.0, size)
	_check(rest.position.is_zero_approx() and rest.scale.is_equal_approx(Vector2.ONE) and is_zero_approx(rest.rotation),
		"Slam restores exact rest pose")
	_check(is_zero_approx(rest.flash) and is_zero_approx(rest.flare) and rest.quake.is_zero_approx(),
		"Flash, flame flare and screen quake settle at the end")
	print("Slam math: %d failures" % failures)
	quit(1 if failures else 0)

func _check_travel() -> void:
	for speed in [Config.LAUNCH_SPEED, Config.REBOUND_SPEED]:
		_check(is_zero_approx(Slam.travel(0.0, speed)) and is_equal_approx(Slam.travel(1.0, speed), 1.0),
			"Travel covers the full distance")
	_check(Slam.travel(0.5, Config.LAUNCH_SPEED) > 0.5, "Launch leaves the floor faster than average")
	_check(Slam.travel(0.5, Config.REBOUND_SPEED) < 0.5, "Rebound accelerates toward the floor")

func _check_contacts() -> void:
	var ceiling := _at(Slam.contact_time(0))
	var floor_contact := _at(Slam.contact_time(1))
	_check(Slam.contacts(ceiling - TOLERANCE) == 0, "No contact before the ceiling")
	_check(Slam.contacts(ceiling) == 1 and Slam.contacts(floor_contact - TOLERANCE) == 1, "Ceiling is the first contact")
	_check(Slam.contacts(floor_contact) == 2 and Slam.contacts(1.0) == Slam.CONTACT_COUNT, "Floor is the second contact")

func _check_ceiling() -> void:
	var arrival := Slam.pose((Slam.contact_time(0) - EPSILON) / Slam.duration(), size)
	var hit := Slam.pose(_at(Slam.contact_time(0)), size)
	_check(absf(arrival.position.y + Config.CEILING_HEIGHT) < TOLERANCE, "Launch lifts the center by the configured height")
	_check(hit.scale.is_equal_approx(Config.LAUNCH_SCALE * Config.CEILING_SQUASH), "Ceiling hit keeps the launch enlargement")
	_check(absf(_edges(hit).x - _edges(arrival).x) < TOLERANCE, "Squash keeps the highest corner on the ceiling")
	var ceiling := Slam.impact(0)
	var ground := Slam.impact(1)
	_check(ceiling.shake.length() > ground.shake.length() and ceiling.quake.length() > ground.quake.length(),
		"Ceiling shakes harder than the floor")
	_check(ceiling.flare > ground.flare and Config.CEILING_DEBRIS_COUNT > Config.FLOOR_DEBRIS_COUNT,
		"Ceiling sprays the strongest flare and debris")

func _check_landings() -> void:
	var first := Slam.pose(_at(Slam.landing_time(0)), size)
	_check(first.scale.is_equal_approx(Config.FLOOR_SQUASH) and is_equal_approx(first.rotation, Config.FLOOR_TILT),
		"First landing touches down tilted and squashed")
	for index in Config.BOUNCE_COUNT + 1:
		var pose := Slam.pose(_at(Slam.landing_time(index)), size)
		_check(absf(_edges(pose).y - size.y / 2) < TOLERANCE, "Every landing puts the lowest corner on the floor")
		_check(absf(pose.rotation - Slam.landing_tilt(index)) < TOLERANCE, "Landing uses its rocking tilt")
	for index in range(1, Config.BOUNCE_COUNT):
		var before := Slam.landing_tilt(index - 1)
		var after := Slam.landing_tilt(index)
		_check(signf(before) != signf(after) and absf(after) < absf(before), "Each bounce lands on the opposite corner with less tilt")
	_check(is_zero_approx(Slam.landing_tilt(Config.BOUNCE_COUNT)), "Final landing rests on both feet")
	var start := Slam.landing_time(0)
	var steps := 50
	var lowest := -INF
	for step in steps + 1:
		var time := lerpf(start, Slam.landing_time(Config.BOUNCE_COUNT), float(step) / steps)
		lowest = maxf(lowest, _edges(Slam.pose(time / Slam.duration(), size)).y)
	_check(lowest < size.y / 2 + Config.FLOOR_SHAKE.y + TOLERANCE, "Rocking stays on top of the floor")

func _check_emitters() -> void:
	var ceiling := Slam.emitters(0, size)
	_check(ceiling.size() == 2 and ceiling.all(func(emitter: Dictionary) -> bool: return emitter.front and emitter.direction.y > 0.0),
		"Ceiling debris sprays in front of the number and drifts downward")
	_check(ceiling[0].point.x < 0.0 and ceiling[0].direction.x < 0.0 and ceiling[1].point.x > 0.0 and ceiling[1].direction.x > 0.0,
		"Ceiling debris sprays outward from both ends")
	var ground := Slam.emitters(1, size)
	_check(ground.size() == 1 and not ground[0].front and ground[0].direction.y < 0.0, "Floor debris sprays upward behind the number")
	_check(absf(ground[0].point.y - size.y / 2) < TOLERANCE and signf(ground[0].point.x) == signf(Config.FLOOR_TILT),
		"Floor debris starts at the landing corner")

func _check_effects() -> void:
	var ceiling := _at(Slam.contact_time(0))
	var floor_contact := _at(Slam.contact_time(1))
	_check(is_zero_approx(Slam.pose(ceiling - TOLERANCE, size).flash), "Number stays unflashed before the first contact")
	_check(Slam.pose(ceiling, size).flash > minf(Config.CEILING_FLASH, 1.0) - TOLERANCE, "Ceiling contact flashes")
	_check(Slam.pose(floor_contact, size).flash > minf(Config.FLOOR_FLASH, 1.0) - TOLERANCE, "Floor contact flashes")
	_check(is_zero_approx(Slam.fade(Config.FLASH_DURATION, Config.FLASH_DURATION)), "Pulse ends after its duration")

func _edges(pose: Dictionary) -> Vector2:
	var top := INF
	var bottom := -INF
	for corner in CORNERS:
		var y: float = pose.position.y + (corner * size * pose.scale).rotated(pose.rotation).y
		top = minf(top, y)
		bottom = maxf(bottom, y)
	return Vector2(top, bottom)

func _at(time: float) -> float:
	return (time + EPSILON) / Slam.duration()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
