@tool
extends Control

signal layout_changed

const Motion = preload("res://src/service/score/number_motion.gd")
const Config = preload("res://src/configs/score/score_feedback_config.gd")
const Numbers = preload("res://src/configs/gameplay/gameplay_ui_config.gd")
const Fonts = preload("res://src/service/fonts/font_library.gd")
var _count = Motion.new()
var value: float:
	get:
		return _count.current
var _font: Font
var _digit_width := 0.0
var _sign_width := 0.0
var _reserved_width := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = Config.NUMBER_LAYER
	_font = Fonts.get_font()
	for digit in range(10):
		_digit_width = maxf(_digit_width, _text_width(str(digit)))
	_sign_width = _text_width("-")
	resized.connect(_update_geometry)
	_refresh()
	_update_geometry()

func _update_geometry() -> void:
	pivot_offset = size / 2
	queue_redraw()
	layout_changed.emit()

func _refresh() -> void:
	queue_redraw()
	var text := Numbers.number(value)
	var width := text.trim_prefix("-").length() * _digit_width
	if text.begins_with("-"):
		width += _sign_width
	if width != _reserved_width:
		_reserved_width = width
		layout_changed.emit()

func set_value(amount: float) -> void:
	_count.reset(amount)
	scale = Vector2.ONE
	_refresh()

func begin_count(target: float) -> void:
	_count.begin(target)
	scale = Vector2.ONE
	_refresh()

func count_progress(progress: float) -> void:
	_count.advance(progress)
	scale = Motion.scale_at(progress)
	_refresh()

func finish_count() -> void:
	_count.finish()
	scale = Vector2.ONE
	_refresh()

func layout_right() -> float:
	var half_width := (_reserved_width / 2 + Config.NUMBER_OUTLINE_SIZE) * maxf(1.0, Config.NUMBER_POP_SCALE)
	return position.x + size.x / 2 + half_width

func _text_width(text: String) -> float:
	return _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, Config.NUMBER_FONT_SIZE).x

func particle_origin() -> Vector2:
	return get_global_rect().get_center()

func _draw() -> void:
	if _font == null:
		return
	_draw_number(Numbers.number(value))

func _draw_number(text: String) -> void:
	var width := _text_width(text)
	var baseline := (size.y - _font.get_height(Config.NUMBER_FONT_SIZE)) / 2 + _font.get_ascent(Config.NUMBER_FONT_SIZE)
	var origin := Vector2((size.x - width) / 2, baseline)
	draw_string_outline(_font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, Config.NUMBER_FONT_SIZE, Config.NUMBER_OUTLINE_SIZE, Config.NUMBER_OUTLINE)
	draw_string(_font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, Config.NUMBER_FONT_SIZE, Config.NUMBER_COLOR)
