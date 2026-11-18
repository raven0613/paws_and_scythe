extends Node2D

const Config = preload("res://src/configs/score/high_card_config.gd")
const Pop = preload("res://src/service/score/high_card_pop.gd")
const Fonts = preload("res://src/service/fonts/font_library.gd")
var _pops: Array = []
var _time := 0.0
var _shrink := 1.0

func _ready() -> void:
	z_index = Config.LAYER

# entries 依跳出順序排列，每項包含場上卡牌、點數與自本段開始的跳出時間；+N 定位在牌的上緣中央上方。
func begin(entries: Array) -> void:
	var inverse := get_global_transform_with_canvas().affine_inverse()
	_pops = []
	for entry in entries:
		var card: Control = entry.card
		var top: Vector2 = card.get_global_transform_with_canvas() * Vector2(card.size.x / 2.0, 0.0)
		_pops.append({"position": inverse * top + Vector2.UP * Config.GAP, "text": Config.TEXT_FORMAT % entry.points, "launch": entry.launch})
	_time = 0.0
	_shrink = 1.0
	queue_redraw()

func advance(time: float) -> void:
	_time = time
	queue_redraw()

func shrink(progress: float) -> void:
	if progress >= 1.0:
		clear()
		return
	_shrink = Pop.shrink(progress)
	queue_redraw()

func clear() -> void:
	_pops = []
	queue_redraw()

# 以描邊下緣中央為縮放基準，由後往前畫描邊與填色。
func _draw() -> void:
	var font := Fonts.get_font()
	for pop in _pops:
		var pose := Pop.pose(_time - pop.launch)
		var width := font.get_string_size(pop.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Config.FONT_SIZE).x
		var origin := Vector2(-width / 2.0, -Config.OUTLINE_SIZE / 2.0)
		draw_set_transform(pop.position + pose.offset, 0.0, pose.scale * _shrink)
		draw_string_outline(font, origin, pop.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Config.FONT_SIZE, Config.OUTLINE_SIZE, Config.OUTLINE_COLOR)
		draw_string(font, origin, pop.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Config.FONT_SIZE, Config.TEXT_COLOR)
	draw_set_transform(Vector2.ZERO)
