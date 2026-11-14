extends SceneTree

const Config = preload("res://src/configs/cat_cards/cat_activation_config.gd")
const Feedback = preload("res://src/configs/cat_cards/cat_feedback_config.gd")
const Timing = preload("res://src/service/cat_cards/activation/activation_timing.gd")
const Card = preload("res://src/service/cat_cards/activation/card_motion.gd")
const Badge = preload("res://src/service/cat_cards/activation/badge_motion.gd")
const Tail = preload("res://src/service/cat_cards/activation/badge_tail.gd")
const Palette = preload("res://src/service/cat_cards/activation/badge_palette.gd")
const TOLERANCE = 0.01
const SAMPLE = 0.005
const HALF_PIXEL = 0.5
var failures := 0

func _init() -> void:
	_test_timing()
	_test_card()
	_test_badge()
	_test_tail()
	_test_palette()
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
	_check(flight[0].length() > rest[0].length(), "Tails stretch apart while the badge flies away from them")
	var rebound := Tail.offsets(Config.BADGE_FLIGHT_DURATION + Config.BADGE_REBOUND_DURATION)
	_check(rebound[0].length() < rest[0].length(), "Tails squeeze together while the badge rebounds toward them")
	var sided := true
	for step in int(Timing.finish() / SAMPLE):
		var offsets := Tail.offsets(step * SAMPLE)
		for index in offsets.size():
			sided = sided and absf(_relative(_segment(offsets, index))) < PI / 2
	_check(sided, "Tails stay on the lower left side of the badge")
	var above := [false, false]
	var below := [false, false]
	var crossings := [INF, INF]
	var previous := [0.0, 0.0]
	for step in int(Config.BADGE_LANDING_DURATION * 2 / SAMPLE):
		var time := Timing.arrival() + step * SAMPLE
		var offsets := Tail.offsets(time)
		for index in offsets.size():
			var angle := _relative(_segment(offsets, index))
			above[index] = above[index] or angle > TOLERANCE
			below[index] = below[index] or angle < -TOLERANCE
			if step > 0 and previous[index] < 0.0 and angle >= 0.0:
				crossings[index] = minf(crossings[index], time)
			previous[index] = angle
	for index in rest.size():
		_check(above[index] and below[index], "Tails wave to both sides of the diagonal on landing")
	_check(crossings[0] < crossings[1], "Second tail lags behind the first, forming a wave")
	var final: PackedVector2Array = Tail.simulate().back()
	for index in rest.size():
		_check(final[index].distance_to(rest[index]) < HALF_PIXEL, "Tails come to rest behind the badge")
		_check(rest[index].x < 0.0 and rest[index].y > 0.0, "Tails rest to the lower left")

func _test_palette() -> void:
	var rainbow := Palette.fills({"target": Config.BADGE_RAINBOW_TARGET})
	_check(rainbow.size() == Config.TAIL_SIZES.size() + 1, "Rainbow fills the body and every tail")
	_check(rainbow[0] == PackedColorArray(Config.BADGE_RAINBOW_COLORS), "Rainbow body uses the full rainbow colors")
	var lighter := true
	for index in range(1, rainbow.size()):
		_check(rainbow[index].size() == Config.BADGE_RAINBOW_COLORS.size(), "Each tail carries the whole rainbow")
		for stop in rainbow[index].size():
			lighter = lighter and rainbow[index][stop].get_luminance() > rainbow[index - 1][stop].get_luminance()
	_check(lighter, "Rainbow tails get lighter toward the end")
	for target in Feedback.TARGET_NAMES:
		if target == Config.BADGE_RAINBOW_TARGET:
			continue
		var plain := Palette.fills({"target": target})
		_check(plain[0] == PackedColorArray([Config.BADGE_COLOR]), "Other effects keep the original body color")
		for index in Config.TAIL_COLORS.size():
			_check(plain[index + 1] == PackedColorArray([Config.TAIL_COLORS[index]]), "Other effects keep the original tail colors")

func _segment(offsets: PackedVector2Array, index: int) -> Vector2:
	return offsets[index] - (offsets[index - 1] if index > 0 else Vector2.ZERO)

func _relative(offset: Vector2) -> float:
	return wrapf(offset.angle() - Config.TAIL_REST_ANGLE, -PI, PI)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
