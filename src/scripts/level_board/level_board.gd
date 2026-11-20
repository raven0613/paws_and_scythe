@tool
extends Control

const Numbers = preload("res://src/configs/gameplay/gameplay_ui_config.gd")
const Config = preload("res://src/configs/level_board/level_board_config.gd")
const Feedback = preload("res://src/configs/score/score_feedback_config.gd")
const FlareConfig = preload("res://src/configs/level_board/progress_flare_config.gd")
const Flare = preload("res://src/service/level_board/progress_flare.gd")

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
@onready var _bar: ProgressBar = $progress_bar
var _tween: Tween
# 進度條入帳演出：原位、原圖層、原色與兩個執行期複製的樣式，以及當下套用的等級數值、跑分長度與發光強度。
var _bar_position := Vector2.ZERO
var _bar_rotation := 0.0
var _bar_layer := 0
var _track: StyleBoxFlat
var _fill: StyleBoxFlat
var _track_border := Color.WHITE
var _fill_color := Color.WHITE
var _flare: Dictionary = FlareConfig.HOLOGRAPHIC
var _flare_duration := Feedback.LEVEL_COUNT_DURATION
var _glow := 0.0
var _glow_tween: Tween

func _ready() -> void:
	$progress_label.z_index = Feedback.LABEL_LAYER
	$progress_label.set_value(current_score)
	_update_display()
	if not Engine.is_editor_hint():
		_prepare_flare()

func reset_score(value: float) -> void:
	finish_score_count(value)
	_stop_glow()
	_rest_bar()
	_apply_glow(0.0)
	_bar.z_index = _bar_layer

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

# 高分表演時由結算時間軸驅動：begin_flare 選用等級數值與跑分長度，並把進度條升到銀河暗角上方的飛行粒子圖層；
# flare_progress 接收跑分開始後經過的秒數。
func begin_flare(tier: int, duration: float) -> void:
	_stop_glow()
	_flare = Flare.params(tier)
	_flare_duration = duration
	_track.shadow_size = _flare.halo_size
	_bar.z_index = Feedback.PARTICLE_LAYER

func flare_progress(time: float) -> void:
	var pose := Flare.pose(time, _flare_duration, _flare)
	_bar.position = _bar_position + pose.position
	_bar.rotation = _bar_rotation + pose.rotation
	_bar.scale = Vector2.ONE * pose.scale
	_apply_glow(pose.glow)

# 結算結束時進度條回到原位，光芒從當下亮度淡出，淡出後回到原圖層。
func fade_flare() -> void:
	_stop_glow()
	_rest_bar()
	_glow_tween = create_tween()
	_glow_tween.tween_method(_apply_glow, _glow, 0.0, FlareConfig.GLOW_FADE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_glow_tween.tween_callback(_bar.set.bind("z_index", _bar_layer))

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

# 進度條以中心為軸震動與放大，位置補償軸心移動以維持場景中的畫面位置；樣式複製後才調整，場景資源維持原設定。
func _prepare_flare() -> void:
	var pivot := _bar.size / 2
	_bar.position += pivot.rotated(_bar.rotation) - pivot
	_bar.pivot_offset = pivot
	_bar_position = _bar.position
	_bar_rotation = _bar.rotation
	_bar_layer = _bar.z_index
	_track = _bar.get_theme_stylebox("background").duplicate()
	_fill = _bar.get_theme_stylebox("fill").duplicate()
	_bar.add_theme_stylebox_override("background", _track)
	_bar.add_theme_stylebox_override("fill", _fill)
	_track_border = _track.border_color
	_fill_color = _fill.bg_color

func _rest_bar() -> void:
	_bar.position = _bar_position
	_bar.rotation = _bar_rotation
	_bar.scale = Vector2.ONE

# 填色與邊框混入亮芯，外暈以樣式的陰影沿圓角外形向外淡出。
func _apply_glow(amount: float) -> void:
	_glow = amount
	var core: float = _flare.core * amount
	_fill.bg_color = _fill_color.lerp(FlareConfig.CORE_COLOR, core)
	_track.border_color = _track_border.lerp(FlareConfig.CORE_COLOR, core)
	_track.shadow_color = Color(FlareConfig.HALO_COLOR, FlareConfig.HALO_COLOR.a * _flare.halo_alpha * amount)

func _stop_glow() -> void:
	if _glow_tween:
		_glow_tween.kill()
