extends Node2D

const Config = preload("res://src/configs/cat_cards/cat_activation_config.gd")
const Motion = preload("res://src/service/cat_cards/activation/badge_motion.gd")
const Tail = preload("res://src/service/cat_cards/activation/badge_tail.gd")
const Fonts = preload("res://src/service/fonts/font_library.gd")
var text := ""
var _clock := 0.0
var _fills: Array[GradientTexture2D] = []

func update(clock: float) -> void:
	_clock = clock
	queue_redraw()

# 依主體、第一節、第二節的色標建立斜向漸層貼圖，單一色標即為純色。
func paint(fills: Array[PackedColorArray]) -> void:
	_fills.clear()
	for stops in fills:
		var gradient := Gradient.new()
		var offsets := PackedFloat32Array()
		for index in stops.size():
			offsets.append(float(index) / maxi(stops.size() - 1, 1))
		gradient.offsets = offsets
		gradient.colors = stops
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = Config.BADGE_GRADIENT_RESOLUTION
		texture.height = Config.BADGE_GRADIENT_RESOLUTION
		texture.fill_from = Vector2.ZERO
		texture.fill_to = Vector2.ONE
		_fills.append(texture)

# 由後往前畫尾巴、主體與文字；尾巴維持各自相對主體的角度一起轉動，文字只跟隨主體相對到位角度的轉動。
func _draw() -> void:
	var body := Motion.body(_clock)
	var offsets := Tail.offsets(_clock)
	for index in range(offsets.size() - 1, -1, -1):
		var angle: float = body.rotation + Config.TAIL_ROTATIONS[index]
		_square(body.position + offsets[index] * body.scale, Config.TAIL_SIZES[index] * body.scale, angle, _fills[index + 1])
	_square(body.position, Config.BADGE_SIZE * body.scale, body.rotation, _fills[0])
	var font := Fonts.get_font()
	var font_size := Config.BADGE_FONT_SIZE
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := Vector2(-width / 2, font.get_ascent(font_size) - font.get_height(font_size) / 2)
	draw_set_transform(body.position, body.spin, Vector2.ONE * body.scale)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Config.BADGE_TEXT_OUTLINE_SIZE, Config.BADGE_TEXT_OUTLINE)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Config.BADGE_TEXT_COLOR)
	draw_set_transform(Vector2.ZERO)

func _square(center: Vector2, side: float, angle: float, fill: Texture2D) -> void:
	draw_set_transform(center, angle)
	draw_texture_rect(fill, Rect2(Vector2.ONE * -side / 2, Vector2.ONE * side), false)
