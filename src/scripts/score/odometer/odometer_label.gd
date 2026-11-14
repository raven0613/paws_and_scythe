@tool
extends Control

const Motion = preload("res://src/service/score/number_motion.gd")
const Math = preload("res://src/service/score/odometer_math.gd")
const Config = preload("res://src/configs/score/odometer_config.gd")
const Fonts = preload("res://src/service/fonts/font_library.gd")

@export var prefix := "":
	set(value):
		prefix = value
		_refresh()
@export var suffix := "":
	set(value):
		suffix = value
		_refresh()
@export var multiplier := false
@export var horizontal_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
@export var display_value := 0.0:
	set(value):
		display_value = value
		set_value(value)

var motion := Motion.new()
var _precision := 0
var _from_units := 0
var _target_units := 0
var _units := 0.0
var _places := 1
var _font: Font
var _digit_width := 0.0
var _minimum := Vector2.ZERO
var _outline: Node2D
var _fill: Node2D
var _tick := 0.0
var _speed := 1.0
var _progress := 0.0
var _seconds := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_font = Fonts.get_font()
	_outline = Node2D.new()
	_fill = Node2D.new()
	add_child(_outline)
	add_child(_fill)
	_outline.draw.connect(_draw_layer.bind(_outline, true))
	_fill.draw.connect(_draw_layer.bind(_fill, false))
	resized.connect(_redraw)
	add_to_group(Config.GROUP_NAME)
	set_value(display_value)

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_refresh()

func _get_minimum_size() -> Vector2:
	return _minimum

func set_fill_material(value: Material) -> void:
	_fill.material = value

func set_playback_speed(value: float) -> void:
	_speed = value

func set_value(value: float) -> void:
	motion.reset(value)
	_precision = Math.decimals(value, value, multiplier)
	_from_units = Math.units(value, _precision)
	_target_units = _from_units
	_units = _from_units
	_tick = 0.0
	_refresh()

# seconds 為該段時間軸長度，依目前播放速度換算成實際秒數以判斷各位數是否轉得太快。
func begin_count(target: float, seconds: float) -> void:
	motion.begin(target)
	_precision = Math.decimals(motion.current, target, multiplier)
	_from_units = Math.units(motion.current, _precision)
	_target_units = Math.units(target, _precision)
	_units = _from_units
	_progress = 0.0
	_seconds = seconds / _speed
	_tick = 0.0
	_refresh()

func count_progress(progress: float) -> void:
	if not motion.active:
		return
	motion.advance(progress)
	_progress = progress
	_units = Motion.value(_from_units, _target_units, progress) if progress < 1.0 else float(_target_units)
	if progress >= 1.0:
		_tick = Config.DETENT_DURATION
	_redraw()

func finish_count() -> void:
	if motion.active:
		_tick = Config.DETENT_DURATION
	motion.finish()
	_units = _target_units
	_redraw()

func _process(delta: float) -> void:
	if _tick > 0.0:
		_tick = maxf(0.0, _tick - delta * _speed)
		_redraw()

func _refresh() -> void:
	if not is_node_ready():
		return
	var font_size := get_theme_font_size("font_size")
	_digit_width = 0.0
	for digit in Config.RADIX:
		_digit_width = maxf(_digit_width, _width(str(digit)))
	_digit_width += Config.DIGIT_PADDING * 2
	_places = maxi(str(maxi(absi(_from_units), absi(_target_units))).length(), _precision + 1)
	var width := _places * _digit_width + _width(prefix + suffix)
	if _precision > 0:
		width += _width(".")
	if mini(_from_units, _target_units) < 0:
		width += _width("-")
	var border := get_theme_constant("outline_size")
	_minimum = Vector2(width + border * 2, _font.get_height(font_size) + (border + Config.VERTICAL_PADDING) * 2)
	update_minimum_size()
	_redraw()

func _redraw() -> void:
	if _fill:
		_outline.queue_redraw()
		_fill.queue_redraw()

func _width(text: String) -> float:
	return _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size("font_size")).x

# 數字字形上緣與下緣在元件內的縱向位置，與繪製時的基線一致。
func digit_bounds() -> Vector2:
	var font_size := get_theme_font_size("font_size")
	var baseline := size.y / 2 + _font.get_ascent(font_size) - _font.get_height(font_size) / 2
	var server := TextServerManager.get_primary_interface()
	var rid := _font.get_rids()[0]
	var glyph := server.font_get_glyph_index(rid, font_size, "0".unicode_at(0), 0)
	var top := baseline + server.font_get_glyph_offset(rid, Vector2i(font_size, 0), glyph).y
	return Vector2(top, top + server.font_get_glyph_size(rid, Vector2i(font_size, 0), glyph).y)

func measure_value(value: float) -> float:
	var digits := Math.format_units(Math.units(value, _precision), _precision)
	return _width(prefix + suffix) + digits.length() * _digit_width + get_theme_constant("outline_size") * 2

func _draw_layer(layer: Node2D, outline: bool) -> void:
	var font_size := get_theme_font_size("font_size")
	var height := size.y
	var baseline := _font.get_ascent(font_size) - _font.get_height(font_size) / 2
	var visible_places := Math.visible_places(_units, _precision)
	var visible_width := _minimum.x - (_places - visible_places) * _digit_width
	var x := float(get_theme_constant("outline_size"))
	if horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
		x += (size.x - visible_width) / 2
	elif horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x += size.x - visible_width
	_draw_glyph(layer, prefix, Vector2(x, height / 2 + baseline), outline)
	x += _width(prefix)
	if mini(_from_units, _target_units) < 0:
		_draw_glyph(layer, "-" if _units < 0 else "", Vector2(x, height / 2 + baseline), outline)
		x += _width("-")
	for place in range(visible_places - 1, -1, -1):
		if _precision > 0 and place == _precision - 1:
			_draw_glyph(layer, ".", Vector2(x, height / 2 + baseline), outline)
			x += _width(".")
		var spinning := motion.active and _progress < Math.handoff(_from_units, _target_units, _seconds, place)
		var wheel := Math.reel(_from_units, _target_units, _progress, _seconds, place) if spinning else Math.wheel(_units, place)
		var changed := floori(absf(_from_units) / pow(Config.RADIX, place)) != floori(absf(_target_units) / pow(Config.RADIX, place))
		var tick_scale := Math.wheel_detent(_units, place, _target_units < _from_units) if changed and motion.active and not spinning else Vector2.ONE
		if changed and _tick > 0.0:
			tick_scale = Vector2.ONE + Config.DETENT_SCALE * sin(_tick / Config.DETENT_DURATION * PI)
		layer.draw_set_transform(Vector2(x + _digit_width / 2, height / 2), 0.0, tick_scale)
		var digit := str(int(wheel.x))
		if place <= _precision or absf(_units) >= pow(Config.RADIX, place):
			_draw_glyph(layer, digit, Vector2(-_width(digit) / 2, baseline - wheel.y * height), outline)
		if wheel.y > 0.0:
			var next := str((int(wheel.x) + 1) % Config.RADIX)
			_draw_glyph(layer, next, Vector2(-_width(next) / 2, baseline + (1.0 - wheel.y) * height), outline)
		layer.draw_set_transform(Vector2.ZERO)
		x += _digit_width
	_draw_glyph(layer, suffix, Vector2(x, height / 2 + baseline), outline)

func _draw_glyph(layer: Node2D, text: String, origin: Vector2, outline: bool) -> void:
	var font_size := get_theme_font_size("font_size")
	if outline:
		var border := get_theme_constant("outline_size")
		if border > 0:
			layer.draw_string_outline(_font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, border, get_theme_color("font_outline_color"))
	else:
		layer.draw_string(_font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, get_theme_color("font_color"))
