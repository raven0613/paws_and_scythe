@tool
extends Control

const Config = preload("res://src/configs/score/score_feedback_config.gd")
const Scoring = preload("res://src/service/gameplay/scoring.gd")

func _ready() -> void:
	z_index = Config.NUMBER_LAYER
	for label in [$heading/count, $heading/word, $multiplier]:
		label.add_theme_color_override("font_color", Config.COMBO_COLOR)
		label.resized.connect(_update_pivots)
	$heading/count.add_theme_font_size_override("font_size", Config.COMBO_FONT_SIZE)
	$heading/word.add_theme_font_size_override("font_size", Config.COMBO_FONT_SIZE)
	$multiplier.add_theme_font_size_override("font_size", Config.MULTIPLIER_FONT_SIZE)
	$multiplier.prefix = Config.MULTIPLIER_FORMAT % ""
	$heading/word.text = Config.COMBO_TEXT
	$heading.add_theme_constant_override("separation", Config.COMBO_TEXT_GAP)
	if Engine.is_editor_hint():
		begin_group(Config.COMBO_VISIBLE_FROM, Config.COMBO_POP_UP + Config.COMBO_POP_DOWN)
		group_progress(1.0)
	else:
		reset()

func reset() -> void:
	hide()
	$multiplier.set_value(Scoring.combo_multiplier(0))
	$heading/count.set_value(0)
	finish_count()

# 組數與基本倍率在 seconds 內滾動並放大縮回，放大峰值位置依 COMBO_POP_UP 與 COMBO_POP_DOWN 的比例。
func begin_group(count: int, seconds: float) -> void:
	begin_count(Scoring.combo_multiplier(count), seconds)
	$heading/count.begin_count(count, seconds)
	visible = count >= Config.COMBO_VISIBLE_FROM
	group_progress(0.0)

func group_progress(progress: float) -> void:
	count_progress(progress)
	$heading/count.count_progress(progress)
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

func begin_count(amount: float, seconds: float) -> void:
	$multiplier.begin_count(amount, seconds)
	$multiplier.scale = Vector2.ONE
	show()

func count_progress(progress: float) -> void:
	$multiplier.count_progress(progress)
	multiplier_feedback(progress)

func finish_count() -> void:
	$multiplier.finish_count()
	$heading/count.finish_count()
	for label in [$heading/count, $heading/word, $multiplier]:
		label.scale = Vector2.ONE
