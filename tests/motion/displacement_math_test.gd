extends SceneTree

const Config = preload("res://src/configs/combo/combo_animation_config.gd")
const Math = preload("res://src/service/motion/displacement_math.gd")
const Profile = Config.DISTURB_PROFILE
var failures := 0

func _init() -> void:
	for reach in [0, 1, Config.INSERT_DISTURB_COUNT, Config.HOVER_DISTURB_COUNT]:
		var center: int = reach + 1
		var indices: Array[int] = []
		indices.assign(range(center * 2 + 1))
		var cues := Math.plan(indices, center, reach, Profile)
		var order := 0
		for distance in range(1, center + 1):
			for index in [center - distance, center + distance]:
				var cue: Dictionary = cues[index]
				if distance <= reach:
					_check(is_equal_approx(cue.strength, pow(Config.DISTURB_FALLOFF, distance - 1)), "Each side attenuates by row distance")
					_check(is_equal_approx(cue.delay, order * Config.DISTURB_INTERVAL), "Nearby rows lead; equal distances use list order")
					order += 1
				else:
					_check(cue.strength == 0.0 and Math.duration(cue, Profile) == Config.INSERT_PUSH_DURATION, "Rows beyond reach only push")
				_check(Math.sample(0.0, cue, Profile).is_zero_approx(), "Interrupted motion starts from captured pose")
				_check(Math.sample(Math.duration(cue, Profile), cue, Profile).is_equal_approx(Vector2(1, 0)), "Every row finishes at its exact target")
				var early: float = Config.INSERT_PUSH_DURATION / 2.0
				_check(is_equal_approx(Math.sample(early, cue, Profile).x, Math.sample(early, cues[center], Profile).x), "All rows push immediately with identical progress")
				if cue.delay > 0.0:
					var before := Math.sample(minf(early, cue.delay / 2.0), cue, Profile)
					_check(before.x > 0.0 and is_zero_approx(before.y), "Push proceeds before delayed disturbance")
		_check(cues[center].strength == 0.0, "Center has its own feedback")
		var longer := indices.duplicate()
		longer.append(indices.size())
		longer.append(indices.size() + 1)
		var extended := Math.plan(longer, center, reach, Profile)
		for index in indices:
			_check(extended[index] == cues[index], "Extra distant rows preserve existing timing and strength")
		_check(Math.duration(extended[longer.back()], Profile) == Config.INSERT_PUSH_DURATION, "Long lists add no disturbance tail")
		var reversed := indices.duplicate()
		reversed.reverse()
		_check(Math.plan(reversed, center, reach, Profile) == cues, "Scheduling is independent of input order")
	_test_edge()
	print("Combo displacement tests: %d failures" % failures)
	quit(1 if failures else 0)

func _test_edge() -> void:
	var reach: int = maxi(Config.INSERT_DISTURB_COUNT, Config.HOVER_DISTURB_COUNT)
	var indices: Array[int] = []
	indices.assign(range(1, reach + 2))
	var cues := Math.plan(indices, 0, reach, Profile)
	for index in range(1, reach + 1):
		_check(is_equal_approx(cues[index].delay, (index - 1) * Config.DISTURB_INTERVAL), "One-sided lists keep consecutive delays")
	_check(cues[reach + 1].strength == 0.0, "End insertion respects the per-side limit")
	_check(Math.plan([], 0, reach, Profile).is_empty(), "Single-row lists have no neighbors")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
