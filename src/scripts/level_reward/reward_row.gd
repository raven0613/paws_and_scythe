extends Control

const Config = preload("res://src/configs/level_reward/reward_view_config.gd")
const Palette = preload("res://src/configs/ui/ui_palette.gd")
const PopBurst = preload("res://src/scripts/motion/pop_burst.gd")

var amount := 0
var _visual := Control.new()
var _name := Label.new()
var _detail := Label.new()
var _amount := Label.new()

# 外層列固定占用版面，滑入與淡入作用於內層 visual，容器重新排版時動畫維持原狀。
func _init() -> void:
	custom_minimum_size = Vector2(Config.ROW_WIDTH, Config.ROW_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual.size = custom_minimum_size
	_visual.modulate.a = 0.0
	add_child(_visual)
	for label in [_name, _detail, _amount]:
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_visual.add_child(label)
	_style(_name, Config.ROW_SIZE, Palette.TEXT)
	_style(_detail, Config.DETAIL_SIZE, Palette.DETAIL)
	_style(_amount, Config.ROW_SIZE, Palette.MONEY)
	_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func configure(name_text: String, detail_text: String, value: int) -> void:
	amount = value
	_name.text = name_text
	_detail.text = detail_text
	_amount.text = Config.AMOUNT_FORMAT % value
	_name.size = Vector2(_name.get_minimum_size().x, Config.ROW_HEIGHT)
	_detail.position.x = _name.size.x + Config.DETAIL_GAP
	_detail.size = Vector2(_detail.get_minimum_size().x, Config.ROW_HEIGHT)
	_amount.position.x = Config.ROW_WIDTH - Config.AMOUNT_WIDTH
	_amount.size = Vector2(Config.AMOUNT_WIDTH, Config.ROW_HEIGHT)

func slide_in() -> void:
	_visual.position.x = -Config.ROW_SLIDE
	var slide := create_tween().set_parallel()
	slide.tween_property(_visual, "position:x", 0.0, Config.ROW_SLIDE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	slide.tween_property(_visual, "modulate:a", 1.0, Config.ROW_SLIDE_DURATION / 2)

# 有金額時金額放大回彈並抖動；零元的列淡成次要資訊。
func pop_amount() -> void:
	if amount > 0:
		PopBurst.play(self, _amount, Config.AMOUNT_POP_SCALE, Config.POP)
	else:
		create_tween().tween_property(_visual, "modulate:a", Config.ZERO_ALPHA, Config.ROW_SLIDE_DURATION)

func amount_center() -> Vector2:
	return _amount.get_global_rect().get_center()

func _style(label: Label, size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
