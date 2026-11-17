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
			$progress_label.set_value(value)
			_update_display()
		else:
			var interrupted: bool = _count.active
			begin_score_count(value)
			_tween = create_tween()
			if interrupted:
				_tween.tween_interval(Feedback.STEP_HOLD)
			_tween.tween_method(score_count_progress, 0.0, 1.0, Feedback.LEVEL_COUNT_DURATION)
			_tween.tween_callback(finish_score_count.bind(value))
@export var target_score: int = Config.PREVIEW_TARGET_SCORE:
	set(value):
		target_score = maxi(value, Config.MIN_TARGET_SCORE)
		_update_display()

@onready var _count = $progress_label.motion
var _tween: Tween

func _ready() -> void:
	$progress_label.z_index = Feedback.LABEL_LAYER
	$progress_label.set_value(current_score)
	_update_display()

func reset_score(value: float) -> void:
	finish_score_count(value)

func begin_score_count(target: float) -> void:
	if _tween:
		_tween.kill()
	$progress_label.begin_count(target, Feedback.LEVEL_COUNT_DURATION)
	_update_display()

func score_count_progress(progress: float) -> void:
	$progress_label.count_progress(progress)
	$progress_bar.value = _count.current

func finish_score_count(value: float) -> void:
	if _tween:
		_tween.kill()
	if _count.target == value:
		$progress_label.finish_count()
	else:
		$progress_label.set_value(value)
	_actual_score = value
	_update_display()

func score_destination() -> Vector2:
	return $progress_bar.get_global_transform() * ($progress_bar.size / 2)

func _update_display() -> void:
	if not is_node_ready():
		return
	$level_label.text = Config.LEVEL_TEXT_FORMAT % level
	$progress_label.suffix = Config.PROGRESS_TEXT_FORMAT % ["", Numbers.number(target_score)]
	_fit_progress_text()
	$progress_bar.max_value = target_score
	$progress_bar.value = _count.current

func _fit_progress_text() -> void:
	var label: Control = $progress_label
	var available: float = $progress_bar.position.x + $progress_bar.size.x - label.position.x
	var maximum := maxf(target_score, maxf(absf(_actual_score), absf(_count.target)))
	var font_size := Config.PROGRESS_FONT_SIZE
	label.add_theme_font_size_override("font_size", font_size)
	while font_size > Config.MIN_PROGRESS_FONT_SIZE and label.measure_value(maximum) > available:
		font_size -= 1
		label.add_theme_font_size_override("font_size", font_size)
	label.size.x = available
