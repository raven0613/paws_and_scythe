@tool
extends Control

const Numbers = preload("res://src/configs/gameplay/gameplay_ui_config.gd")
const Config = preload("res://src/configs/level_board/level_board_config.gd")
const Feedback = preload("res://src/configs/score/score_feedback_config.gd")

var _actual_score := float(Config.PREVIEW_CURRENT_SCORE)

@export var level: int = Config.PREVIEW_LEVEL:
	set(value):
		level = maxi(value, Config.MIN_LEVEL)
		_update_display()
@export var current_score: float = Config.PREVIEW_CURRENT_SCORE:
	get:
		return _actual_score
	set(value):
		if _actual_score == value:
			return
		_actual_score = value
		if not is_node_ready():
			return
		if Engine.is_editor_hint():
			_displayed_score = value
			_update_display()
		else:
			begin_score_count(value)
			_tween = create_tween()
			_tween.tween_method(score_count_progress, 0.0, 1.0, Feedback.LEVEL_COUNT_DURATION)
			_tween.tween_callback(finish_score_count.bind(value))
@export var target_score: int = Config.PREVIEW_TARGET_SCORE:
	set(value):
		target_score = maxi(value, Config.MIN_TARGET_SCORE)
		_update_display()

var _displayed_score := 0.0
var _count_from := 0.0
var _count_target := 0.0
var _tween: Tween

func _ready() -> void:
	$progress_label.z_index = Feedback.NUMBER_LAYER
	_displayed_score = current_score
	_update_display()

func reset_score(value: float) -> void:
	finish_score_count(value)

func begin_score_count(target: float) -> void:
	if _tween:
		_tween.kill()
	_count_from = _displayed_score
	_count_target = target

func score_count_progress(progress: float) -> void:
	var tail := minf(Feedback.COUNT_TAIL, absf(_count_target - _count_from))
	var direction := signf(_count_target - _count_from)
	if progress < Feedback.COUNT_MAIN_RATIO:
		var k := progress / Feedback.COUNT_MAIN_RATIO
		_displayed_score = lerpf(_count_from, _count_target - direction * tail, 1.0 - pow(1.0 - k, 2))
	else:
		var k := (progress - Feedback.COUNT_MAIN_RATIO) / (1.0 - Feedback.COUNT_MAIN_RATIO)
		_displayed_score = _count_target - direction * tail * (1.0 - k)
	_update_display()

func finish_score_count(value: float) -> void:
	if _tween:
		_tween.kill()
	_displayed_score = value
	_actual_score = value
	_update_display()

func score_destination() -> Vector2:
	return $progress_bar.get_global_transform() * ($progress_bar.size / 2)

func _update_display() -> void:
	if not is_node_ready():
		return
	$level_label.text = Config.LEVEL_TEXT_FORMAT % level
	$progress_label.text = Config.PROGRESS_TEXT_FORMAT % [Numbers.number(_displayed_score), Numbers.number(target_score)]
	_fit_progress_text()
	$progress_bar.max_value = target_score
	$progress_bar.value = _displayed_score

func _fit_progress_text() -> void:
	var label: Label = $progress_label
	var font := label.get_theme_font("font")
	var available: float = $progress_bar.position.x + $progress_bar.size.x - label.position.x
	# Reserve the final count's width so ordinary count-up frames keep one size.
	var maximum := maxf(target_score, maxf(absf(_actual_score), absf(_count_target)))
	var reserved := Config.PROGRESS_TEXT_FORMAT % [Numbers.number(maximum), Numbers.number(target_score)]
	var font_size := Config.PROGRESS_FONT_SIZE
	while font_size > Config.MIN_PROGRESS_FONT_SIZE:
		var width := maxf(
			font.get_string_size(reserved, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x,
			font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		)
		if width <= available:
			break
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)
	label.size.x = available
