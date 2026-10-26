extends Control

const Config = preload("res://src/configs/score/score_feedback_config.gd")
const Numbers = preload("res://src/configs/gameplay/gameplay_ui_config.gd")
var value := 0.0
var _from := 0.0
var _target := 0.0
var _counting := false
var _font: Font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = Config.NUMBER_LAYER
	_font = ThemeDB.fallback_font
	resized.connect(func(): pivot_offset = size / 2)
	pivot_offset = size / 2

func set_value(amount: float) -> void:
	value = amount
	_counting = false
	scale = Vector2.ONE
	queue_redraw()

func begin_count(target: float) -> void:
	_from = value
	_target = target
	_counting = _from != _target

func count_progress(progress: float) -> void:
	var distance := absf(_target - _from)
	var tail := minf(Config.COUNT_TAIL, distance)
	var direction := signf(_target - _from)
	if progress < Config.COUNT_MAIN_RATIO:
		var k := progress / Config.COUNT_MAIN_RATIO
		value = _from + direction * (distance - tail) * k
	else:
		var k := (progress - Config.COUNT_MAIN_RATIO) / (1.0 - Config.COUNT_MAIN_RATIO)
		value = _target - direction * tail * (1.0 - k)
	var pop := 0.0
	if progress >= Config.NUMBER_POP_START and progress < Config.NUMBER_POP_PEAK:
		pop = sin((progress - Config.NUMBER_POP_START) / (Config.NUMBER_POP_PEAK - Config.NUMBER_POP_START) * PI / 2)
	elif progress >= Config.NUMBER_POP_PEAK:
		pop = sin((1.0 - progress) / (1.0 - Config.NUMBER_POP_PEAK) * PI / 2)
	scale = Vector2.ONE * lerpf(1.0, Config.NUMBER_POP_SCALE, pop)
	if progress >= 1.0:
		set_value(_target)
	queue_redraw()

func particle_origin() -> Vector2:
	return get_global_rect().get_center()

func _draw() -> void:
	if _font == null:
		return
	var shown := floorf(value) if _counting else value
	_draw_number(Numbers.number(shown))

func _draw_number(text: String) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, Config.NUMBER_FONT_SIZE).x
	var baseline := (size.y - _font.get_height(Config.NUMBER_FONT_SIZE)) / 2 + _font.get_ascent(Config.NUMBER_FONT_SIZE)
	var origin := Vector2((size.x - width) / 2, baseline)
	draw_string_outline(_font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, Config.NUMBER_FONT_SIZE, Config.NUMBER_OUTLINE_SIZE, Config.NUMBER_OUTLINE)
	draw_string(_font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, Config.NUMBER_FONT_SIZE, Config.NUMBER_COLOR)
