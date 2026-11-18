extends SceneTree

const Pop = preload("res://src/service/score/high_card_pop.gd")
const Schedule = preload("res://src/service/score/award_schedule.gd")
const Config = preload("res://src/configs/score/high_card_config.gd")
const Feedback = preload("res://src/configs/score/score_feedback_config.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const SAMPLES = 60
var failures := 0

func _init() -> void:
	_test_grow()
	_test_spring()
	_test_shrink()
	_test_schedule()
	print("High card pop: %d failures" % failures)
	quit(1 if failures else 0)

func _test_grow() -> void:
	_check(Pop.pose(0.0).scale == Vector2.ZERO, "+N starts from nothing")
	_check(Pop.pose(-1.0).scale == Vector2.ZERO, "+N stays hidden before its turn")
	_check(Pop.pose(Config.GROW_DURATION).scale.is_equal_approx(Vector2.ONE), "+N reaches its full size when growing ends")
	var previous := 0.0
	for step in range(1, 11):
		var size: float = Pop.pose(Config.GROW_DURATION * step / 10.0).scale.x
		_check(size > previous, "+N grows steadily")
		previous = size
	_check(Pop.pose(Config.GROW_DURATION / 4.0).scale.x > 0.5, "Growing starts fast and eases out")
	_check(Pop.pose(Config.GROW_DURATION / 2.0).offset == Vector2.ZERO, "+N grows at its target position")

func _test_spring() -> void:
	var crossings := 0
	var previous := 0.0
	var first_peak := 0.0
	var last_peak := 0.0
	for step in range(1, SAMPLES):
		var pose: Dictionary = Pop.pose(Config.GROW_DURATION + Config.SPRING_DURATION * step / SAMPLES)
		var y: float = pose.offset.y
		if step == 1:
			_check(y < 0.0, "Spring first bounces upward")
		if previous < 0.0 and y >= 0.0:
			crossings += 1
		if absf(y) > 0.01:
			_check(pose.scale.y > 1.0 if y < 0.0 else pose.scale.y < 1.0, "Rising stretches and falling squashes")
			_check(is_equal_approx(pose.scale.x + pose.scale.y, 2.0), "Stretch trades width for height")
		_check(absf(y) <= Config.SPRING_AMPLITUDE, "Spring stays within its amplitude")
		if step < SAMPLES / Config.SPRING_CYCLES:
			first_peak = maxf(first_peak, absf(y))
		else:
			last_peak = maxf(last_peak, absf(y))
		previous = y
	_check(crossings == int(Config.SPRING_CYCLES), "Spring bounces the configured number of times")
	_check(last_peak < first_peak, "Spring decays")
	var rest: Dictionary = Pop.pose(Pop.lead())
	_check(rest.offset.is_zero_approx() and rest.scale.is_equal_approx(Vector2.ONE), "Spring settles at its target pose")
	_check(Pop.pose(Pop.lead() + 1.0).scale.is_equal_approx(Vector2.ONE), "+N holds still after the spring")

func _test_shrink() -> void:
	_check(is_equal_approx(Pop.shrink(0.0), 1.0), "Shrink starts at full size")
	_check(is_zero_approx(Pop.shrink(1.0)), "Shrink ends invisible")
	_check(Pop.shrink(0.15) > 1.0, "Shrink swells slightly before vanishing")

# +N 依跳出間隔出現，彈完時中央開始加上該張點數，各段首尾相接，最後一張使用完整跑分時間。
func _test_schedule() -> void:
	for count in range(1, Rules.MAX_PLAYS + 1):
		var schedule := Schedule.build(count, Config.POP_INTERVAL, Pop.lead())
		for index in count:
			var entry: Dictionary = schedule[index]
			_check(is_equal_approx(entry.launch, index * Config.POP_INTERVAL), "High cards pop at the configured interval")
			_check(is_equal_approx(entry.landing - entry.launch, Pop.lead()), "Central counts after the spring settles")
		_check(is_equal_approx(schedule[-1].seconds, Feedback.COUNT_DURATION), "Last high card uses the full count duration")
		var added := Schedule.duration(schedule) - Feedback.COUNT_DURATION
		_check(is_equal_approx(added, Pop.lead() + (count - 1) * Config.POP_INTERVAL), "Popping adds the lead plus one interval per extra card")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
