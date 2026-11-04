@tool
extends Control

const Config = preload("res://src/configs/score/score_feedback_config.gd")
const Numbers = preload("res://src/configs/gameplay/gameplay_ui_config.gd")
const Scoring = preload("res://src/service/gameplay/scoring.gd")

var _from := 1.0
var _target := 1.0

func _ready() -> void:
	z_index = Config.NUMBER_LAYER
	for label in [$heading/count, $heading/word, $multiplier]:
		label.add_theme_color_override("font_color", Config.COMBO_COLOR)
		label.resized.connect(_update_pivots)
	$heading/count.add_theme_font_size_override("font_size", Config.COMBO_FONT_SIZE)
	$heading/word.add_theme_font_size_override("font_size", Config.COMBO_FONT_SIZE)
	$multiplier.add_theme_font_size_override("font_size", Config.MULTIPLIER_FONT_SIZE)
	$heading/word.text = Config.COMBO_TEXT
	$heading.add_theme_constant_override("separation", Config.COMBO_TEXT_GAP)
	if Engine.is_editor_hint():
		begin_group(Config.COMBO_VISIBLE_FROM)
		count_progress(1.0)
	else:
		reset()

func reset() -> void:
	hide()
	_from = Scoring.combo_multiplier(0)
	_target = _from
	$heading/count.text = Numbers.number(0)
	count_progress(1.0)

func begin_group(count: int) -> void:
	_from = _target
	_target = Scoring.combo_multiplier(count)
	$heading/count.text = Numbers.number(count)
	visible = count >= Config.COMBO_VISIBLE_FROM
	count_progress(0.0)

func count_progress(progress: float) -> void:
	var amount := lerpf(_from, _target, 1.0 - pow(1.0 - progress, 2))
	$multiplier.text = Config.MULTIPLIER_FORMAT % Numbers.multiplier(amount)
	_update_pivots()
	var pop := _pop_amount(progress)
	$heading/count.scale = Vector2.ONE * lerpf(1.0, Config.COMBO_NUMBER_POP_SCALE, pop)
	$heading/word.scale = Vector2.ONE * lerpf(1.0, Config.COMBO_WORD_POP_SCALE, pop)
	$multiplier.scale = Vector2.ONE * lerpf(1.0, Config.MULTIPLIER_POP_SCALE, pop)

func multiplier_feedback(progress: float) -> void:
	$multiplier.scale = Vector2.ONE * lerpf(1.0, Config.MULTIPLIER_POP_SCALE, _pop_amount(progress))

func _pop_amount(progress: float) -> float:
	var peak := Config.COMBO_POP_UP / (Config.COMBO_POP_UP + Config.COMBO_POP_DOWN)
	var phase := progress / peak if progress < peak else (1.0 - progress) / (1.0 - peak)
	return sin(phase * PI / 2)

func _update_pivots() -> void:
	for label in [$heading/count, $heading/word, $multiplier]:
		label.pivot_offset = Vector2(label.get_minimum_size().x / 2, label.size.y / 2)

func left_pop_margin() -> float:
	var peak := maxf(Config.COMBO_NUMBER_POP_SCALE, maxf(Config.COMBO_WORD_POP_SCALE, Config.MULTIPLIER_POP_SCALE))
	return size.x * maxf(0.0, peak - 1.0) / 2
