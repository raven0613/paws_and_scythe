extends SceneTree

const Schedule = preload("res://src/service/score/award_schedule.gd")
const Config = preload("res://src/configs/score/score_feedback_config.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
var failures := 0

func _init() -> void:
	for count in range(1, Rules.BOARD_LIMIT + 1):
		var schedule := Schedule.build(count, Config.AWARD_INTERVAL, Config.AWARD_FLIGHT_DURATION)
		_check(schedule.size() == count, "Every scoring group receives one launch")
		for index in count:
			var entry: Dictionary = schedule[index]
			_check(is_equal_approx(entry.launch, index * Config.AWARD_INTERVAL), "Groups launch at the configured interval")
			_check(is_equal_approx(entry.landing - entry.launch, Config.AWARD_FLIGHT_DURATION), "Each wave flies for the configured duration")
			_check(Schedule.combo_seconds(entry) <= entry.seconds, "Combo pop finishes within its central segment")
			if index < count - 1:
				var next: Dictionary = schedule[index + 1]
				_check(is_equal_approx(entry.landing + entry.seconds, next.landing), "Central segments chain without overlap")
			else:
				_check(is_equal_approx(entry.seconds, Config.COUNT_DURATION), "Last segment uses the full count duration")
		_check(is_equal_approx(Schedule.duration(schedule), schedule[-1].landing + Config.COUNT_DURATION), "Stage ends when the last count completes")
		_check(Schedule.landed(schedule, 0.0) == -1, "Central waits for the first wave")
		_check(Schedule.landed(schedule, Schedule.duration(schedule)) == count - 1, "Every wave lands before the stage ends")
		for index in count:
			_check(Schedule.landed(schedule, schedule[index].landing) == index, "Arrival starts its own segment")
	var entry: Dictionary = Schedule.build(1, Config.AWARD_INTERVAL, Config.AWARD_FLIGHT_DURATION)[0]
	_check(Schedule.progress(entry, entry.landing - 1.0, entry.seconds) == 0.0, "Progress waits for arrival")
	_check(Schedule.progress(entry, entry.landing + entry.seconds * 2, entry.seconds) == 1.0, "Progress stays at the exact target")
	print("Award schedule: %d failures" % failures)
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
