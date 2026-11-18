extends SceneTree

const Math = preload("res://src/service/playing_card/flight_math.gd")
const Config = preload("res://src/configs/playing_card/flight_animation_config.gd")
const Actions = preload("res://src/configs/playing_card/action_animation_config.gd")
const Frame = preload("res://src/configs/gameplay/gameplay_frame_config.gd")
const SAMPLE = 0.01
const PIVOT = Vector2(36.5, 46.0)
var failures := 0

func _init() -> void:
	_test_spring()
	_test_speed()
	_test_deform()
	_test_lift(Actions.PLACE_APEX)
	_test_landing(Config.PLACE_LANDING)
	_test_landing(Config.LIGHT_LANDING)
	_check(Config.PLACE_LANDING.press > Config.LIGHT_LANDING.press, "Placing slams harder than other arrivals")
	print("Flight math tests: %d failures" % failures)
	quit(1 if failures else 0)

func _test_spring() -> void:
	_check(is_zero_approx(Math.spring(0.0)), "Spring starts at origin")
	_check(is_equal_approx(Math.spring(1.0), 1.0), "Spring ends exactly at destination")
	var previous := 0.0
	for index in range(101):
		var value: float = Math.spring(index / 100.0)
		_check(value >= previous and value <= 1.0, "Travel remains monotonic and bounded")
		previous = value

func _test_speed() -> void:
	var speed := Config.FULL_SPEED
	_check(is_zero_approx(Math.intensity(0.0)), "Resting cards keep their shape")
	_check(is_equal_approx(Math.intensity(speed / 2.0), 0.5), "Speed controls the deformation")
	_check(is_equal_approx(Math.intensity(speed * 2.0), 1.0), "Fast flights cap their deformation")
	var delta := Vector2(speed, speed)
	_check(Math.reference_delta(delta * 2.0, Frame.REFERENCE_SIZE * 2.0).is_equal_approx(delta), "Window scaling preserves reference speed")
	_check(Math.reference_delta(delta / 2.0, Frame.REFERENCE_SIZE).is_equal_approx(delta / 2.0), "Camera zoom affects visible speed")
	var transform := Transform2D(PI / 2.0, Vector2(2, 3), 0.0, delta)
	_check(Math.local_direction(transform.basis_xform(Vector2.ONE), transform).is_equal_approx(Vector2.ONE.normalized()), "Direction compensates for rotation and nonuniform scale")

func _test_deform() -> void:
	var direction := Vector2(1, 2).normalized()
	var stretch := Config.MAX_STRETCH
	var scale := 1.0 + Config.LIFT_SCALE
	var shape := Math.deform(direction, stretch, scale, PIVOT)
	_check((shape * PIVOT).is_equal_approx(PIVOT), "Deformation stays centered on the card")
	_check(is_equal_approx(shape.determinant(), scale * scale), "Stretching preserves the card area")
	var along := shape.basis_xform(direction)
	_check(along.normalized().is_equal_approx(direction) and is_equal_approx(along.length(), (1.0 + stretch) * scale), "Card elongates along its motion")
	_check(is_equal_approx(shape.basis_xform(direction.orthogonal()).length(), scale / (1.0 + stretch)), "Card narrows across its motion")
	_check(Math.deform(direction, 0.0, 1.0, PIVOT).is_equal_approx(Transform2D.IDENTITY), "Resting cards keep their original shape")
	_check(Math.deform(direction, -stretch, 1.0, PIVOT).basis_xform(direction).length() < 1.0, "Negative stretch squashes along the motion")

func _test_lift(apex: float) -> void:
	_check(is_zero_approx(Math.lift(0.0, apex)) and is_zero_approx(Math.lift(1.0, apex)), "Cards leave and return to the table")
	_check(is_equal_approx(Math.lift(apex, apex), 1.0), "Cards peak at the apex")
	var launch := Math.lift(SAMPLE, apex)
	var crest := 1.0 - Math.lift(apex - SAMPLE, apex)
	_check(launch > crest, "Cards launch quickly and slow toward the apex")
	var impact := Math.lift(1.0 - SAMPLE, apex)
	var drop := 1.0 - Math.lift(apex + SAMPLE, apex)
	_check(impact > drop, "Cards accelerate into the landing")
	var bounded := true
	for index in range(101):
		var height := Math.lift(index / 100.0, apex)
		bounded = bounded and height >= 0.0 and height <= 1.0
	_check(bounded, "Lift stays between the table and the apex")

func _test_landing(profile: Dictionary) -> void:
	var touch := Math.landing(0.0, profile)
	_check(is_equal_approx(touch.scale, 1.0) and is_equal_approx(touch.carry, 1.0), "Landing continues from the arrival shape")
	_check(Math.landing(SAMPLE, profile).scale < 1.0, "Landing presses the card first")
	var lowest := 1.0
	var highest := 1.0
	var swing := 1.0
	for index in range(101):
		var pose := Math.landing(index / 100.0, profile)
		lowest = minf(lowest, pose.scale)
		highest = maxf(highest, pose.scale)
		swing = minf(swing, pose.carry)
	_check(lowest < 1.0 and highest > 1.0, "Landing bounces back past the original size")
	_check(swing < 0.0, "Arrival stretch swings into a squash")
	var settled := Math.landing(1.0, profile)
	_check(is_equal_approx(settled.scale, 1.0) and is_zero_approx(settled.carry), "Landing settles at the original shape")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
