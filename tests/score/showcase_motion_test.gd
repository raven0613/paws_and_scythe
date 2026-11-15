extends SceneTree

const Motion = preload("res://src/service/score/showcase_motion.gd")
const Config = preload("res://src/configs/score/showcase_config.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
var failures := 0

func _init() -> void:
	_test_fan()
	_test_single_group()
	_test_handoff()
	_test_layers()
	_check(is_equal_approx(Motion.stage_end([2, 5]), Config.ROW_INTERVAL + Motion.group_release(5)), "Stage ends when the last group starts returning")
	print("Showcase motion: %d failures" % failures)
	quit(1 if failures else 0)

func _test_fan() -> void:
	_check(Motion.fan_angle(0, 1) == 0.0, "Single card stays upright")
	for count in range(2, Rules.BOARD_LIMIT + 1):
		var first := Motion.fan_angle(0, count)
		var last := Motion.fan_angle(count - 1, count)
		_check(first < 0.0 and last > 0.0, "Fan opens from negative to positive angles along the path")
		_check(is_equal_approx(first, -last), "Fan is centered on the group")
		_check(last - first <= Config.FAN_MAX_SPREAD + 0.0001, "Fan spread stays within the configured maximum")
		for index in range(1, count):
			_check(Motion.fan_angle(index, count) > Motion.fan_angle(index - 1, count), "Each card turns further along the path")

func _test_single_group() -> void:
	var count := 5
	for noise in [-1.0, 0.0, 1.0]:
		var entries: Array = [Motion.entry(0, count - 1, count, noise)]
		var item: Dictionary = entries[0]
		_check(is_equal_approx(item.start, (count - 1) * Config.CARD_INTERVAL), "Cards rise one after another along the path")
		_check(Motion.pose(entries, item.start - 0.01) == Motion.REST, "Card rests before its turn")
		var peak := Motion.pose(entries, item.start + Config.RISE_DURATION)
		_check(is_equal_approx(peak.rotation, Motion.fan_angle(count - 1, count)), "Card reaches its fan angle")
		var along := Vector2.UP.rotated(peak.rotation)
		_check(is_equal_approx(peak.offset.length(), item.lift) and peak.offset.normalized().is_equal_approx(along), "Card lifts along its rotated up axis")
		_check(item.lift >= Config.LIFT * (1.0 - Config.LIFT_JITTER) - 0.0001 and item.lift <= Config.LIFT * (1.0 + Config.LIFT_JITTER) + 0.0001, "Irregular lift stays within the jitter range")
		_check(Motion.pose(entries, item.release - 0.01).offset.is_equal_approx(peak.offset), "Card holds its fan pose until release")
		var rest := Motion.pose(entries, Motion.duration(entries))
		_check(rest.offset.is_zero_approx() and is_zero_approx(rest.rotation), "Card tweens back to its exact rest pose")
	var low := Motion.entry(0, 0, count, -1.0)
	var high := Motion.entry(0, 0, count, 1.0)
	_check(high.lift > low.lift, "Noise changes lift along the rotated axis")
	_check(is_equal_approx(low.release, Motion.group_release(count)), "Whole group releases together")

func _test_handoff() -> void:
	var first := Motion.entry(0, 4, 5, 0.3)
	var second := Motion.entry(1, 0, 3, -0.4)
	var entries: Array = [first, second]
	var before := Motion.pose(entries, second.start - 0.0001)
	var at := Motion.pose(entries, second.start)
	_check(absf(before.rotation - at.rotation) < 0.01 and before.offset.distance_to(at.offset) < 0.1, "Shared card continues from its current pose")
	var peak := Motion.pose(entries, second.start + Config.RISE_DURATION)
	_check(is_equal_approx(peak.rotation, second.rotation), "Shared card turns to the new group's angle")
	var rest := Motion.pose(entries, Motion.duration(entries))
	_check(rest.offset.is_zero_approx() and is_zero_approx(rest.rotation), "Shared card returns home after the last group")
	_check(is_equal_approx(second.start, Config.ROW_INTERVAL), "Groups start one row interval apart")

# 越晚亮相的組位於越上層；交叉牌被後一組接手時升到後一組的層級，收回原位後還原。
func _test_layers() -> void:
	var first := Motion.entry(0, 1, 2, 0.0)
	var second := Motion.entry(1, 0, 2, 0.0)
	_check(Motion.layer_order([first], first.start - 0.01) == -1, "Card keeps its own layer before rising")
	_check(Motion.layer_order([first], first.start) == 0, "Rising card takes its group's layer")
	_check(Motion.layer_order([first], first.release + Config.RETURN_DURATION - 0.01) == 0, "Returning card stays above the board")
	_check(Motion.layer_order([first], first.release + Config.RETURN_DURATION) == -1, "Rested card restores its own layer")
	_check(Motion.layer_order([second], second.start) > Motion.layer_order([first], second.start), "Later group covers an earlier returning group")
	_check(Motion.layer_order([first, second], second.start) == 1, "Shared card rises to the later group's layer")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
