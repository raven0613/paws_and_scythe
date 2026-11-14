extends SceneTree

const Config = preload("res://src/configs/cat_cards/cat_activation_config.gd")
const Feedback = preload("res://src/configs/cat_cards/cat_feedback_config.gd")
const Timing = preload("res://src/service/cat_cards/activation/activation_timing.gd")
const Card = preload("res://src/service/cat_cards/activation/card_motion.gd")
const Badge = preload("res://src/service/cat_cards/activation/badge_motion.gd")
const Tail = preload("res://src/service/cat_cards/activation/badge_tail.gd")
const TOLERANCE = 0.01
const SAMPLE = 0.005
const HALF_PIXEL = 0.5
var failures := 0

func _init() -> void:
	_test_timing()
	_test_card()
	_test_badge()
	_test_tail()
	print("Cat activation: %d failures" % failures)
	quit(1 if failures else 0)

func _test_timing() -> void:
	var arrival := Config.BADGE_FLIGHT_DURATION + Config.BADGE_REBOUND_DURATION + Config.BADGE_SETTLE_DURATION
	_check(is_equal_approx(Timing.arrival(), arrival), "Target counting starts when the badge lands")
	_check(is_equal_approx(Timing.release(), arrival + Config.COUNT_DURATION + Config.RELEASE_HOLD), "Card holds after the target finishes counting")
	_check(Timing.finish() > Timing.release(), "Card and badge return after the hold")

func _test_card() -> void:
	var start := Card.pose(0.0)
	_check(is_equal_approx(start.scale, 1.0) and start.tilt.is_zero_approx(), "Card starts from its resting pose")
	var popped := Card.pose(Config.CARD_POP_DURATION)
	_check(is_equal_approx(popped.scale, Config.CARD_SCALE), "Card reaches its activation scale within the pop duration")
	_check(popped.tilt.is_equal_approx(Config.CARD_TILT), "Card tilts in perspective together with the pop")
	_check(start.offset.is_zero_approx(), "Card starts at its slot")
	var shaking := false
	for step in int(Config.CARD_SHAKE_DURATION / SAMPLE):
		var pose := Card.pose(step * SAMPLE)
		var strength: float = (pose.scale - 1.0) / (Config.CARD_SCALE - 1.0)
		var jitter: Vector2 = pose.offset - Config.CARD_OFFSET * strength
		shaking = shaking or jitter.length() > TOLERANCE and absf(pose.rotation - Config.CARD_ROTATION * strength) > TOLERANCE
	_check(shaking, "Card shakes in position and angle")
	var held := Card.pose(Timing.release())
	_check(held.offset.is_equal_approx(Config.CARD_OFFSET) and is_equal_approx(held.rotation, Config.CARD_ROTATION), "Card holds at its offset once the shake settles")
	_check(held.anchor.is_equal_approx(Config.CARD_OFFSET + Card.active_corner()), "Badge anchor follows the moved, scaled and rotated corner without shake")
	var halfway := Card.pose(Timing.release() + Config.CARD_RETURN_DURATION / 2)
	_check(halfway.scale > 1.0 and halfway.scale < Config.CARD_SCALE, "Card tweens back to its resting size")
	_check(halfway.offset.length() > 0.0 and halfway.offset.length() < Config.CARD_OFFSET.length(), "Card tweens back toward its slot")
	var rest := Card.pose(Timing.release() + Config.CARD_RETURN_DURATION)
	_check(is_equal_approx(rest.scale, 1.0) and is_zero_approx(rest.rotation) and rest.tilt.is_zero_approx(), "Card returns to its resting pose")
	_check(rest.offset.is_zero_approx(), "Card returns to its slot")
	var slot_shadow := Vector2(2, 2)
	_check(Card.shadow(slot_shadow, 0.0).is_equal_approx(slot_shadow), "Shadow starts at its resting side")
	_check(Card.shadow(slot_shadow, Timing.release()).is_equal_approx(Config.CARD_SHADOW_OFFSET), "Shadow moves to its activation side with the pop")
	_check(Card.shadow(slot_shadow, Timing.release() + Config.CARD_RETURN_DURATION).is_equal_approx(slot_shadow), "Shadow returns with the card")
	var corner := Card.corner(1.0, 0.0)
	_check(corner.is_equal_approx(Vector2(Feedback.CARD_SIZE.x, -Feedback.CARD_SIZE.y) / 2), "Corner is the top right of the card")

func _test_badge() -> void:
	_check(Badge.path(0.0).is_equal_approx(Badge.origin()) and is_zero_approx(Badge.scale(0.0)), "Badge emerges from nothing at the card center")
	_check(Badge.origin().is_equal_approx(-Card.active_corner()), "Badge launches from the card center")
	var middle := Badge.path(Config.BADGE_FLIGHT_DURATION / 2)
	_check(middle.y < Badge.origin().lerp(Config.BADGE_WALL, 0.5).y, "Badge flies along an arc above the straight line")
	_check(Badge.path(Config.BADGE_FLIGHT_DURATION).is_equal_approx(Config.BADGE_WALL), "Badge hits the wall at the end of its flight")
	_check(is_equal_approx(Badge.scale(Config.BADGE_FLIGHT_DURATION), 1.0), "Badge reaches its full size at the wall")
	var bounce := Config.BADGE_FLIGHT_DURATION + Config.BADGE_REBOUND_DURATION
	_check(Badge.path(bounce).is_equal_approx(Config.BADGE_REBOUND), "Badge rebounds to the lower left")
	_check(Config.BADGE_REBOUND.x < Config.BADGE_WALL.x and Config.BADGE_REBOUND.y > Config.BADGE_WALL.y, "Rebound heads lower left")
	_check(Config.BADGE_REST.x < Config.BADGE_REBOUND.x and Config.BADGE_REST.y < Config.BADGE_REBOUND.y, "Settle heads upper left")
	_check(Badge.path(Timing.arrival()).is_equal_approx(Config.BADGE_REST), "Badge lands at its rest point")
	var peak := 0.0
	var spun := false
	for step in int(Config.BADGE_LANDING_DURATION / SAMPLE):
		var body := Badge.body(Timing.arrival() + step * SAMPLE)
		peak = maxf(peak, body.scale)
		spun = spun or absf(body.spin) > TOLERANCE
	_check(peak > 1.0 and absf(peak - Config.BADGE_LANDING_SCALE) < 0.05, "Badge pops beyond its size on landing")
	_check(spun, "Badge rotates and shakes on landing")
	var settled := Badge.body(Timing.arrival() + Config.BADGE_LANDING_DURATION)
	_check(is_equal_approx(settled.scale, 1.0) and settled.position.is_equal_approx(Config.BADGE_REST), "Badge settles at its size and rest point")
	_check(is_zero_approx(settled.spin), "Badge text stays upright at rest")
	_check(is_zero_approx(Badge.scale(Timing.release() + Config.BADGE_EXIT_DURATION)), "Badge shrinks away when the card returns")

func _test_tail() -> void:
	var rest := Tail.rest()
	var flight := Tail.offsets(Config.BADGE_FLIGHT_DURATION / 2)
	_check(flight[0].length() > rest[0].length(), "Tails stretch apart while the badge moves fast")
	var landing := Tail.offsets(Timing.arrival())
	_check(landing[0].x > 0.0 and landing[0].y > 0.0, "Tails trail to the lower right after the upper left bounce")
	var start := _relative(landing[0])
	var swung := false
	var compressed := false
	for step in int(Config.BADGE_LANDING_DURATION * 2 / SAMPLE):
		var offsets := Tail.offsets(Timing.arrival() + step * SAMPLE)
		swung = swung or signf(_relative(offsets[0])) != signf(start)
		compressed = compressed or offsets[0].length() < rest[0].length()
	_check(swung, "Tails swing past their rest direction before settling")
	_check(compressed, "Tails squeeze together as the badge stops")
	var turning := Tail.offsets(Timing.arrival())
	_check(absf(_relative(turning[1] - turning[0]) - _relative(turning[0])) > TOLERANCE, "Second tail lags behind the first while turning")
	var final := Tail.offsets(Timing.finish())
	for index in rest.size():
		_check(final[index].distance_to(rest[index]) < HALF_PIXEL, "Tails come to rest behind the badge")
		_check(rest[index].x < 0.0 and rest[index].y > 0.0, "Tails rest to the lower left")

func _relative(offset: Vector2) -> float:
	return wrapf(offset.angle() - Config.TAIL_REST_ANGLE, -PI, PI)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
