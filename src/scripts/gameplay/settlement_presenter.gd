extends Node

signal completed

const Config = preload("res://src/configs/score/score_feedback_config.gd")
const ComboConfig = preload("res://src/configs/combo/combo_config.gd")
const CatFeedback = preload("res://src/configs/cat_cards/cat_feedback_config.gd")
const CatText = preload("res://src/scripts/cat_cards/cat_score_text.gd")
const Celebration = preload("res://src/service/score/celebration_math.gd")
const OdometerConfig = preload("res://src/configs/score/odometer_config.gd")
const Particles = preload("res://src/scripts/score/score_particles.gd")
var _score: Control
var _combo: Control
var _level: Control
var _cats: Control
var _particles: Control
var _timeline: Tween
var _result: Dictionary
var _level_target := 0.0
var _running := false
var _speed := 1.0
var _last_central := -1
var _event_index := -1

func setup(score: Control, combo: Control, level: Control, cats: Control, canvas: Control) -> void:
	_score = score
	_combo = combo
	_level = level
	_cats = cats
	_particles = Particles.new()
	canvas.add_child(_particles)
	_score.get_node("controls/skip").pressed.connect(finish)
	_score.get_node("controls/fast").toggled.connect(_set_fast)

func play(result: Dictionary, current_score: float) -> void:
	_result = result
	_level_target = current_score + result.total
	_running = true
	_score.show()
	_score.get_node("number").show()
	_score.get_node("number").prepare(result.total, _level.target_score)
	_score.get_node("number").set_playback_speed(_speed)
	get_tree().call_group(OdometerConfig.GROUP_NAME, "set_playback_speed", _speed)
	_score.get_node("combo_counter").reset()
	for index in result.groups.size():
		var row: Control = _combo.get_row(index)
		row.prepare_settlement()
		row.modulate = Color.WHITE
		row.score = result.groups[index].original_score
	_timeline = create_tween().set_speed_scale(_speed)
	_last_central = Celebration.last_central_event(result.events)
	for index in result.events.size():
		_event_index = index
		_append_event(result.events[index])
	_append_central_feedback(true)
	_timeline.tween_callback(_fly_total)
	_timeline.tween_method(_particles.progress, 0.0, 1.0, Config.FINAL_FLIGHT_DURATION)
	_timeline.tween_callback(_particles.clear)
	_timeline.tween_callback(_level.begin_score_count.bind(_level_target))
	_timeline.tween_method(_level.score_count_progress, 0.0, 1.0, Config.LEVEL_COUNT_DURATION)
	_timeline.tween_callback(finish)

func _append_event(event: Dictionary) -> void:
	if event.kind == "combo_apply" and event.before == event.after:
		return
	match event.kind:
		"selection":
			_append_selection(event)
		"high":
			_append_count(_score.get_node("number"), event.after, Config.COUNT_DURATION)
		"group_start":
			_append_group_start(event)
		"effect", "repeat":
			_append_effect(event)
		"group_award":
			var row: Control = _combo.get_row(event.group)
			_timeline.tween_callback(_fly_row.bind(row))
			_timeline.tween_method(_particles.progress, 0.0, 1.0, Config.FLIGHT_DURATION)
			_timeline.tween_callback(_particles.clear)
			_append_count(_score.get_node("number"), event.after, Config.COUNT_DURATION)
		"combo_apply":
			_append_count(_score.get_node("number"), event.after, Config.COUNT_DURATION,
				_score.get_node("combo_counter").multiplier_feedback)
	# 最後一次中央跑分直接銜接結算收尾，其餘段落保留閱讀頓點。
	if _event_index != _last_central:
		_timeline.tween_interval(Config.STEP_HOLD)

func _append_selection(event: Dictionary) -> void:
	var source: Control = _cats.get_card(event.source)
	var duration := CatFeedback.EFFECT_DURATION
	_timeline.tween_callback(source.begin_feedback.bind(CatText.effect(event)))
	for index in event.excluded:
		_timeline.tween_callback(_combo.get_row(index).begin_count.bind(0.0, duration))
	_timeline.tween_method(source.feedback_progress, 0.0, 1.0, duration)
	for index in event.excluded:
		var row: Control = _combo.get_row(index)
		_timeline.parallel().tween_method(row.count_progress, 0.0, 1.0, duration)
		_timeline.parallel().tween_property(row, "modulate", ComboConfig.EXCLUDED_COLOR, duration)
	var chosen: Control = _combo.get_row(event.group)
	_timeline.parallel().tween_property(chosen, "scale", Vector2.ONE * Config.ROW_POP_SCALE, Config.ROW_POP_UP).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_timeline.tween_property(chosen, "scale", Vector2.ONE, Config.ROW_POP_DOWN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for index in event.excluded:
		_timeline.tween_callback(_combo.get_row(index).finish_count)

func _append_group_start(event: Dictionary) -> void:
	var row: Control = _combo.get_row(event.group)
	_timeline.tween_callback(row.prepare_settlement)
	_timeline.tween_callback(row.set.bind("score", event.after))
	_timeline.tween_callback(_score.get_node("combo_counter").begin_group.bind(event.combo_count))
	_timeline.tween_property(row, "scale", Vector2.ONE * Config.ROW_POP_SCALE, Config.ROW_POP_UP).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_timeline.parallel().tween_property(row, "scale", Vector2.ONE, Config.ROW_POP_DOWN).from(Vector2.ONE * Config.ROW_POP_SCALE).set_delay(Config.ROW_POP_UP).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if event.combo_count >= Config.COMBO_VISIBLE_FROM:
		_timeline.parallel().tween_method(_score.get_node("combo_counter").group_progress, 0.0, 1.0, Config.COMBO_POP_UP + Config.COMBO_POP_DOWN)
	_timeline.tween_callback(_score.get_node("combo_counter").finish_count)

func _append_effect(event: Dictionary) -> void:
	var source: Control = _cats.get_card(event.source)
	var duration := CatFeedback.EFFECT_DURATION
	_timeline.tween_callback(source.begin_feedback.bind(CatText.effect(event)))
	match event.target:
		"group":
			_append_count(_combo.get_row(event.group), event.after, duration, source.feedback_progress)
		"multiplier":
			_append_count(_score.get_node("combo_counter"), event.after, duration, source.feedback_progress)
		"subtotal", "total":
			_append_count(_score.get_node("number"), event.after, duration, source.feedback_progress)

func _append_count(counter: Control, target: float, duration: float, feedback := Callable()) -> void:
	_timeline.tween_callback(counter.begin_count.bind(target, duration))
	_timeline.tween_method(counter.count_progress, 0.0, 1.0, duration)
	if feedback.is_valid():
		_timeline.parallel().tween_method(feedback, 0.0, 1.0, duration)
	_timeline.tween_callback(counter.finish_count)
	if counter == _score.get_node("number") and _event_index != _last_central:
		_append_central_feedback(false)

func _append_central_feedback(final: bool) -> void:
	var number: Control = _score.get_node("number")
	_timeline.tween_method(number.feedback_progress.bind(final), 0.0, 1.0, number.feedback_duration(final))
	if final:
		_timeline.tween_interval(Config.STEP_HOLD)

func _fly_row(row: Control) -> void:
	_particles.begin(row.score_origin(), _score.get_node("number").particle_origin())

func _fly_total() -> void:
	_particles.begin(_score.get_node("number").particle_origin(), _level.score_destination())

func _set_fast(fast: bool) -> void:
	_speed = Config.FAST_SPEED if fast else 1.0
	_score.get_node("number").set_playback_speed(_speed)
	get_tree().call_group(OdometerConfig.GROUP_NAME, "set_playback_speed", _speed)
	if _running:
		_timeline.set_speed_scale(_speed)

func finish() -> void:
	if not _running:
		return
	_running = false
	_timeline.kill()
	_particles.clear()
	_combo.reset_feedback()
	_cats.reset_feedback()
	_score.get_node("number").reset_feedback()
	_score.get_node("combo_counter").reset()
	_score.hide()
	_level.finish_score_count(_level_target)
	completed.emit()
