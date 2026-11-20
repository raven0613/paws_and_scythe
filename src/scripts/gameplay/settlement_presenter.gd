extends Node

signal completed

const Config = preload("res://src/configs/score/score_feedback_config.gd")
const ComboConfig = preload("res://src/configs/combo/combo_config.gd")
const CatActivation = preload("res://src/configs/cat_cards/cat_activation_config.gd")
const ActivationTiming = preload("res://src/service/cat_cards/activation/activation_timing.gd")
const BadgePalette = preload("res://src/service/cat_cards/activation/badge_palette.gd")
const AwardSchedule = preload("res://src/service/score/award_schedule.gd")
const CatText = preload("res://src/scripts/cat_cards/cat_score_text.gd")
const Celebration = preload("res://src/service/score/celebration_math.gd")
const Feel = preload("res://src/configs/score/celebration_config.gd")
const OdometerConfig = preload("res://src/configs/score/odometer_config.gd")
const Particles = preload("res://src/scripts/score/score_particles.gd")
const HighConfig = preload("res://src/configs/score/high_card_config.gd")
const HighPop = preload("res://src/service/score/high_card_pop.gd")
const HighPops = preload("res://src/scripts/score/high_card_pops.gd")
const ShowcaseConfig = preload("res://src/configs/score/showcase_config.gd")
const ShowcaseMotion = preload("res://src/service/score/showcase_motion.gd")
const ShowcaseCards = preload("res://src/scripts/playing_card/showcase_card_animator.gd")
const TOTAL_WAVE = -1
var _score: Control
var _combo: Control
var _level: Control
var _cats: Control
var _board: Control
var _particles: Control
var _pops: Node2D
var _showcase := ShowcaseCards.new()
var _timeline: Tween
var _result: Dictionary
var _level_target := 0.0
var _running := false
var _speed := 1.0
var _last_central := -1
var _relay_landed := -1
var _pops_shown := false

func setup(score: Control, combo: Control, level: Control, cats: Control, board: Control, canvas: Control) -> void:
	_score = score
	_combo = combo
	_level = level
	_cats = cats
	_board = board
	add_child(_showcase)
	_particles = Particles.new()
	canvas.add_child(_particles)
	_pops = HighPops.new()
	canvas.add_child(_pops)
	_score.get_node("controls/skip").pressed.connect(finish)
	_score.get_node("controls/fast").toggled.connect(_set_fast)

func play(result: Dictionary, current_score: float) -> void:
	_result = result
	_level_target = current_score + result.total
	_running = true
	_score.show()
	_score.get_node("number").show()
	_score.get_node("number").prepare(result.total, _level.target_score)
	_score.get_node("combo_counter").reset()
	for index in result.groups.size():
		var row: Control = _combo.get_row(index)
		row.prepare_settlement()
		row.modulate = Color.WHITE
		row.score = result.groups[index].original_score
	_timeline = create_tween()
	_apply_speed()
	_last_central = Celebration.last_central_event(result.events)
	var start := 0
	while start < result.events.size():
		var end := _segment_end(result.events, start)
		_append_segment(result.events, start, end)
		start = end
	_append_central_feedback(true)
	_timeline.tween_callback(_fly_total)
	_timeline.tween_method(_particles.progress.bind(TOTAL_WAVE), 0.0, 1.0, Config.FINAL_FLIGHT_DURATION)
	_append_level_count()
	_timeline.tween_callback(finish)

# 同一次發動的逐組效果合成一段同時演出，連續的入帳事件合成依序入帳段，其餘事件各自一段。
static func _segment_end(events: Array, start: int) -> int:
	var first: Dictionary = events[start]
	var end := start + 1
	while end < events.size() and _same_segment(first, events[end]):
		end += 1
	return end

static func _same_segment(first: Dictionary, event: Dictionary) -> bool:
	if first.kind == "group_award":
		return event.kind == "group_award"
	return _is_group_effect(first) and _is_group_effect(event) and event.activation == first.activation

static func _is_group_effect(event: Dictionary) -> bool:
	return event.kind == "effect" and event.target == "group"

func _append_segment(events: Array, start: int, end: int) -> void:
	var first: Dictionary = events[start]
	if first.kind == "combo_apply" and first.before == first.after:
		return
	# 本段包含最後一次中央跑分時，由結算完成表演收尾；其餘段落保留途中回饋與閱讀頓點。
	var final := _last_central >= start and _last_central < end
	match first.kind:
		"selection":
			_append_selection(first)
		"high":
			_append_high(first, final)
		"reveal":
			_append_reveal(first)
			return
		"effect", "repeat":
			_append_effect(events.slice(start, end), final)
		"group_award":
			var after_rows: bool = start > 0 and (_is_group_effect(events[start - 1]) or events[start - 1].kind == "repeat")
			_append_awards(events.slice(start, end), final, after_rows)
		"combo_apply":
			_append_count(_score.get_node("number"), first.after, Config.COUNT_DURATION, final,
				_score.get_node("combo_counter").multiplier_hit.bind(Config.COUNT_DURATION))
	if not final:
		_timeline.tween_interval(Config.STEP_HOLD)

func _append_selection(event: Dictionary) -> void:
	var source: Control = _cats.get_card(event.source)
	var duration := CatActivation.COUNT_DURATION
	_append_activation(source, event)
	for index in event.excluded:
		_timeline.tween_callback(_combo.get_row(index).begin_count.bind(0.0, duration))
	_timeline.tween_interval(duration)
	for index in event.excluded:
		var row: Control = _combo.get_row(index)
		_timeline.parallel().tween_method(row.count_progress, 0.0, 1.0, duration)
		_timeline.parallel().tween_property(row, "modulate", ComboConfig.EXCLUDED_COLOR, duration)
	var chosen: Control = _combo.get_row(event.group)
	_timeline.parallel().tween_property(chosen, "scale", Vector2.ONE * Config.ROW_POP_SCALE, Config.ROW_POP_UP).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_timeline.tween_property(chosen, "scale", Vector2.ONE, Config.ROW_POP_DOWN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for index in event.excluded:
		_timeline.tween_callback(_combo.get_row(index).finish_count)

# 得分的 combo 條依序聚焦並推開鄰列，場上對應的牌同時沿路徑浮成扇形；最後一組開始收回時銜接下一段，收回與後續演出同時進行。
func _append_reveal(event: Dictionary) -> void:
	var groups: Array = []
	var counts: Array = []
	for index in event.groups:
		var cards: Array = []
		for cell in _result.groups[index].cells:
			cards.append(_board.card_at(cell))
		groups.append(cards)
		counts.append(cards.size())
	_timeline.tween_interval(ShowcaseMotion.stage_end(counts))
	_timeline.parallel().tween_callback(_showcase.play.bind(groups))
	for order in event.groups.size():
		_timeline.parallel().tween_callback(_showcase_row.bind(event.groups[order])).set_delay(order * ShowcaseConfig.ROW_INTERVAL)
	_timeline.tween_callback(_end_showcase)

func _showcase_row(index: int) -> void:
	_combo.showcase_row(index, _speed)

func _end_showcase() -> void:
	_combo.end_showcase(_speed)

# 來源貓牌發動一次，標籤到位後本段所有目標同時跑數字。
func _append_effect(events: Array, final: bool) -> void:
	var first: Dictionary = events[0]
	_append_activation(_cats.get_card(first.source), first)
	var duration := CatActivation.COUNT_DURATION
	match first.target:
		"group":
			_append_rows(events, duration)
		"multiplier":
			_append_count(_score.get_node("combo_counter"), first.after, duration, final)
		"subtotal", "total":
			_append_count(_score.get_node("number"), first.after, duration, final)

func _append_rows(events: Array, duration: float) -> void:
	for event in events:
		_timeline.tween_callback(_combo.get_row(event.group).begin_count.bind(event.after, duration))
	for index in events.size():
		var row: Control = _combo.get_row(events[index].group)
		(_timeline.parallel() if index > 0 else _timeline).tween_method(row.count_progress, 0.0, 1.0, duration)
	for event in events:
		_timeline.tween_callback(_combo.get_row(event.group).finish_count)

# 貓牌發動與數字標籤同時開始，標籤到位時目標開始跑數字；卡片依自身時鐘完成停留與收回。
func _append_activation(source: Control, event: Dictionary) -> void:
	_timeline.tween_callback(source.begin_feedback.bind(CatText.badge(event), BadgePalette.fills(event)))
	_timeline.tween_interval(ActivationTiming.arrival())

# 各張新出高牌依閱讀順序跳出 +N，彈完時中央接續加上該張點數；+N 在中央到位回饋開始時一起縮掉。
func _append_high(event: Dictionary, final: bool) -> void:
	var schedule := AwardSchedule.build(event.cards.size(), HighConfig.POP_INTERVAL, HighPop.lead())
	var entries: Array = []
	var targets: Array = []
	var total := 0.0
	for index in event.cards.size():
		var card: Dictionary = event.cards[index]
		total += card.points
		targets.append(total)
		entries.append({"card": _board.card_at(card.cell), "points": card.points, "launch": schedule[index].launch})
	_timeline.tween_callback(_pops.begin.bind(entries))
	_append_relay(schedule, targets, [])
	_timeline.parallel().tween_method(_pops.advance, 0.0, AwardSchedule.duration(schedule), AwardSchedule.duration(schedule))
	_timeline.tween_callback(_score.get_node("number").finish_count)
	_pops_shown = true
	if not final:
		_append_central_feedback(false)

# 各條依時間表放大並發射粒子，抵達時中央接續累加並推進 Combo；整段結束後回饋一次。
func _append_awards(events: Array, final: bool, after_rows: bool) -> void:
	var number: Control = _score.get_node("number")
	var counter: Control = _score.get_node("combo_counter")
	var schedule := AwardSchedule.build(events.size(), Config.AWARD_INTERVAL, Config.AWARD_FLIGHT_DURATION)
	if after_rows:
		_timeline.tween_interval(Config.AWARD_PHASE_HOLD)
	_append_relay(schedule, events.map(func(event): return event.after), events.map(func(event): return event.combo_count))
	for index in events.size():
		_append_launch(_combo.get_row(events[index].group), events[index].group, schedule[index].launch)
	_timeline.tween_callback(number.finish_count)
	_timeline.tween_callback(counter.finish_count)
	if not final:
		_append_central_feedback(false)

func _append_launch(row: Control, key: int, launch: float) -> void:
	_timeline.parallel().tween_callback(_fly_row.bind(row, key)).set_delay(launch)
	_timeline.parallel().tween_method(_particles.progress.bind(key), 0.0, 1.0, Config.AWARD_FLIGHT_DURATION).set_delay(launch)
	_timeline.parallel().tween_property(row, "scale", Vector2.ONE * Config.AWARD_ROW_POP_SCALE, Config.ROW_POP_UP).set_delay(launch).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_timeline.parallel().tween_property(row, "scale", Vector2.ONE, Config.ROW_POP_DOWN).from(Vector2.ONE * Config.AWARD_ROW_POP_SCALE).set_delay(launch + Config.ROW_POP_UP).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _append_relay(schedule: Array, targets: Array, combos: Array) -> void:
	_timeline.tween_callback(func(): _relay_landed = -1)
	_timeline.tween_method(_relay_progress.bind(schedule, targets, combos), 0.0, AwardSchedule.duration(schedule), AwardSchedule.duration(schedule))

# 依入帳時間軸驅動中央：每項抵達時前一段以卡點停在精確值，再接續跑向 targets 的新累計值；
# combos 有值時右側 Combo 組數同步推進。
func _relay_progress(time: float, schedule: Array, targets: Array, combos: Array) -> void:
	var number: Control = _score.get_node("number")
	var counter: Control = _score.get_node("combo_counter")
	var landed := AwardSchedule.landed(schedule, time)
	while _relay_landed < landed:
		if _relay_landed >= 0:
			number.count_progress(1.0)
			if not combos.is_empty():
				counter.group_progress(1.0)
		_relay_landed += 1
		var entry: Dictionary = schedule[_relay_landed]
		number.begin_count(targets[_relay_landed], entry.seconds)
		if not combos.is_empty():
			counter.begin_group(combos[_relay_landed], AwardSchedule.combo_seconds(entry))
	if _relay_landed < 0:
		return
	var current: Dictionary = schedule[_relay_landed]
	number.count_progress(AwardSchedule.progress(current, time, current.seconds))
	if not combos.is_empty():
		counter.group_progress(AwardSchedule.progress(current, time, AwardSchedule.combo_seconds(current)))

# feedback 與跑分同時播放，接收自本段開始經過的時間。
func _append_count(counter: Control, target: float, duration: float, final: bool, feedback := Callable()) -> void:
	_timeline.tween_callback(counter.begin_count.bind(target, duration))
	_timeline.tween_method(counter.count_progress, 0.0, 1.0, duration)
	if feedback.is_valid():
		_timeline.parallel().tween_method(feedback, 0.0, duration, duration)
	_timeline.tween_callback(counter.finish_count)
	if counter == _score.get_node("number") and not final:
		_append_central_feedback(false)

func _append_central_feedback(final: bool) -> void:
	var number: Control = _score.get_node("number")
	_timeline.tween_method(number.feedback_progress.bind(final), 0.0, 1.0, number.feedback_duration(final))
	if _pops_shown:
		_timeline.parallel().tween_method(_pops.shrink, 0.0, 1.0, HighConfig.SHRINK_DURATION)
		_pops_shown = false
	if final:
		_timeline.tween_interval(number.final_hold())

# 粒子抵達左上後累積分數跑分；高分表演時進度條同時依等級震動發光，光芒在結算結束後淡出。
func _append_level_count() -> void:
	var tier: int = _score.get_node("number").tier()
	var duration := Config.LEVEL_COUNT_DURATION
	if tier != Feel.Tier.NORMAL:
		_timeline.tween_callback(_level.begin_flare.bind(tier, duration))
	_timeline.tween_callback(_level.begin_score_count.bind(_level_target))
	_timeline.tween_method(_level.score_count_progress, 0.0, 1.0, duration)
	if tier != Feel.Tier.NORMAL:
		_timeline.parallel().tween_method(_level.flare_progress, 0.0, duration, duration)

func _fly_row(row: Control, key: int) -> void:
	_particles.begin(key, row.score_origin(), _score.get_node("number").particle_origin())

func _fly_total() -> void:
	_particles.begin(TOTAL_WAVE, _score.get_node("number").particle_origin(), _level.score_destination())

func _set_fast(fast: bool) -> void:
	_speed = Config.FAST_SPEED if fast else 1.0
	_apply_speed()

func _apply_speed() -> void:
	_score.get_node("number").set_playback_speed(_speed)
	get_tree().call_group(OdometerConfig.GROUP_NAME, "set_playback_speed", _speed)
	_cats.set_playback_speed(_speed)
	_showcase.set_playback_speed(_speed)
	if _running:
		_timeline.set_speed_scale(_speed)

func finish() -> void:
	if not _running:
		return
	_running = false
	_timeline.kill()
	_particles.clear()
	_pops.clear()
	_showcase.reset()
	_combo.reset_feedback()
	_cats.reset_feedback()
	_score.get_node("number").reset_feedback()
	_score.get_node("combo_counter").reset()
	_score.hide()
	_level.finish_score_count(_level_target)
	_level.fade_flare()
	completed.emit()
