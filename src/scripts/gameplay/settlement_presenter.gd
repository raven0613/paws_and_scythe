extends Node

signal completed

const Config = preload("res://src/configs/score/score_feedback_config.gd")
const Particles = preload("res://src/scripts/score/score_particles.gd")
var _score: Control
var _combo: Control
var _level: Control
var _particles: Control
var _timeline: Tween
var _result: Dictionary
var _level_target := 0.0
var _running := false
var _speed := 1.0

func setup(score: Control, combo: Control, level: Control, canvas: Control) -> void:
	_score = score
	_combo = combo
	_level = level
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
	_score.get_node("number").set_value(0)
	_score.get_node("combo_counter").reset()
	_timeline = create_tween().set_speed_scale(_speed)
	var subtotal: float = result.high
	if subtotal > 0:
		_append_count(subtotal)
	for index in result.groups.size():
		var row: Control = _combo.get_row(index)
		_timeline.tween_callback(row.prepare_settlement)
		_timeline.tween_callback(_score.get_node("combo_counter").begin_group.bind(index + 1))
		_timeline.tween_property(row, "scale", Vector2.ONE * Config.ROW_POP_SCALE, Config.ROW_POP_UP).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_timeline.parallel().tween_property(row, "scale", Vector2.ONE, Config.ROW_POP_DOWN).from(Vector2.ONE * Config.ROW_POP_SCALE).set_delay(Config.ROW_POP_UP).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if index + 1 >= Config.COMBO_VISIBLE_FROM:
			_timeline.parallel().tween_method(_score.get_node("combo_counter").count_progress, 0.0, 1.0, Config.COMBO_POP_UP + Config.COMBO_POP_DOWN)
		_timeline.tween_callback(_fly_row.bind(row))
		_timeline.tween_method(_particles.progress, 0.0, 1.0, Config.FLIGHT_DURATION)
		_timeline.tween_callback(_particles.clear)
		subtotal += result.groups[index].score
		_append_count(subtotal)
	if result.multiplier != 1:
		_timeline.tween_interval(Config.BEFORE_MULTIPLIER_HOLD)
		_append_count(result.total)
		_timeline.parallel().tween_method(_score.get_node("combo_counter").multiplier_feedback, 0.0, 1.0, Config.COUNT_DURATION)
	_timeline.tween_interval(Config.TOTAL_HOLD)
	_timeline.tween_callback(_fly_total)
	_timeline.tween_method(_particles.progress, 0.0, 1.0, Config.FINAL_FLIGHT_DURATION)
	_timeline.tween_callback(_particles.clear)
	_timeline.tween_callback(_level.begin_score_count.bind(_level_target))
	_timeline.tween_method(_level.score_count_progress, 0.0, 1.0, Config.LEVEL_COUNT_DURATION)
	_timeline.tween_callback(finish)

func _append_count(target: float) -> void:
	_timeline.tween_callback(_score.get_node("number").begin_count.bind(target))
	_timeline.tween_method(_score.get_node("number").count_progress, 0.0, 1.0, Config.COUNT_DURATION)

func _fly_row(row: Control) -> void:
	_particles.begin(row.score_origin(), _score.get_node("number").particle_origin())

func _fly_total() -> void:
	_particles.begin(_score.get_node("number").particle_origin(), _level.score_destination())

func _set_fast(fast: bool) -> void:
	_speed = Config.FAST_SPEED if fast else 1.0
	if _running:
		_timeline.set_speed_scale(_speed)

func finish() -> void:
	if not _running:
		return
	_running = false
	_timeline.kill()
	_particles.clear()
	_combo.reset_feedback()
	_score.get_node("number").set_value(_result.total)
	_score.get_node("combo_counter").reset()
	_score.hide()
	_level.finish_score_count(_level_target)
	completed.emit()
