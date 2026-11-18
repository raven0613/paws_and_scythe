extends Control

signal shop_requested

const Config = preload("res://src/configs/level_reward/reward_view_config.gd")
const Palette = preload("res://src/configs/ui/ui_palette.gd")
const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Numbers = preload("res://src/configs/gameplay/gameplay_ui_config.gd")
const BoxStyle = preload("res://src/scripts/ui/box_style.gd")
const PopBurst = preload("res://src/scripts/motion/pop_burst.gd")
const Row = preload("res://src/scripts/level_reward/reward_row.gd")

@onready var _pivot: Control = $pivot
@onready var _content: VBoxContainer = $pivot/panel/margin/content
@onready var _rows: VBoxContainer = $pivot/panel/margin/content/rows
@onready var _total: Label = $pivot/panel/margin/content/total/amount
@onready var _button: Button = $pivot/panel/margin/content/actions/shop
var _money: Control
var _coins: Control
var _timeline: Tween
var _breath: Tween
var _total_tween: Tween
var _rest := Vector2.ZERO
var _total_value := 0

func setup(money: Control, coins: Control) -> void:
	_money = money
	_coins = coins

func _ready() -> void:
	z_index = Config.LAYER
	_rest = _pivot.position
	$shade.color = Palette.SHADE
	$pivot/panel.add_theme_stylebox_override("panel", BoxStyle.flat(Palette.PANEL, Palette.PANEL_BORDER))
	$pivot/panel/margin/content/divider.color = Palette.PANEL_BORDER
	_style($pivot/panel/margin/content/title, Config.TITLE_SIZE, Palette.TITLE)
	_style($pivot/panel/margin/content/score, Config.SCORE_SIZE, Palette.DETAIL)
	_style($pivot/panel/margin/content/total/name, Config.ROW_SIZE, Palette.TEXT)
	_style(_total, Config.TOTAL_SIZE, Palette.MONEY)
	$pivot/panel/margin/content/total/name.text = Config.TOTAL_NAME
	BoxStyle.apply_button(_button, Config.BUTTON_SIZE)
	_button.text = Config.SHOP_TEXT
	_button.pressed.connect(_leave)

# 依獎勵明細逐列演出；held 為加入獎勵前的持有金錢，金幣抵達時右上金錢由此逐步加到最終金額。
func play(level: int, score: float, target: int, reward: Dictionary, held: int) -> void:
	_stop()
	show()
	var title: Label = $pivot/panel/margin/content/title
	title.text = Config.TITLE % level
	$pivot/panel/margin/content/score.text = Config.SCORE_TEXT % [Numbers.number(score), Numbers.number(target)]
	_build_rows(reward.entries)
	_total_value = 0
	_total.text = Config.AMOUNT_FORMAT % 0
	_button.disabled = true
	_button.modulate.a = 0.0
	title.scale = Vector2.ZERO
	$shade.modulate.a = 0.0
	_pivot.position = _rest + Config.DROP_OFFSET
	_pivot.rotation = Config.DROP_TILT
	_pivot.scale = Vector2.ONE
	_timeline = create_tween()
	_timeline.tween_property($shade, "modulate:a", 1.0, Config.SHADE_FADE)
	_timeline.parallel().tween_property(_pivot, "position", _rest, Config.DROP_DURATION).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_timeline.parallel().tween_property(_pivot, "rotation", 0.0, Config.DROP_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_timeline.tween_callback(_land)
	_timeline.tween_interval(Config.TITLE_DELAY)
	_timeline.tween_callback(PopBurst.play.bind(self, title, Config.TITLE_POP_SCALE, Config.POP))
	var running := held
	for index in reward.entries.size():
		_timeline.tween_interval(Config.ROW_STAGGER)
		_timeline.tween_callback(_reveal_row.bind(index, running))
		running += reward.entries[index].amount
	_timeline.tween_interval(Config.COIN_SETTLE)
	_timeline.tween_callback(PopBurst.play.bind(self, _total, Config.TOTAL_POP_SCALE, Config.POP))
	_timeline.tween_interval(Config.BUTTON_DELAY)
	_timeline.tween_callback(_reveal_button)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and _timeline and _timeline.is_running():
		_timeline.set_speed_scale(Config.SKIP_SPEED)
		accept_event()

func _build_rows(entries: Array) -> void:
	for row in _rows.get_children():
		row.queue_free()
	for entry in entries:
		var row := Row.new()
		_rows.add_child(row)
		row.configure(_row_name(entry), _row_detail(entry), entry.amount)

func _row_name(entry: Dictionary) -> String:
	return Catalog.CARDS[entry.detail].name if entry.kind == "cat" else Config.ROW_NAMES[entry.kind]

func _row_detail(entry: Dictionary) -> String:
	return Config.ROW_DETAILS[entry.kind] % entry.detail if Config.ROW_DETAILS.has(entry.kind) else ""

func _land() -> void:
	_pivot.scale = Config.LAND_SQUASH
	create_tween().tween_property(_pivot, "scale", Vector2.ONE, Config.LAND_DURATION).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

# 列滑入後金額彈出，合計同步累加；有金額時噴出金幣，每枚抵達讓右上金錢推進一段。
func _reveal_row(index: int, before: int) -> void:
	var row: Control = _rows.get_child(index)
	row.slide_in()
	var reveal := create_tween()
	reveal.tween_interval(Config.AMOUNT_DELAY)
	reveal.tween_callback(_pay_row.bind(row, before))

func _pay_row(row: Control, before: int) -> void:
	row.pop_amount()
	_count_total(_total_value + row.amount)
	if row.amount > 0:
		_coins.launch(row.amount_center(), _money.money_target(), row.amount, _coin_landed.bind(before, row.amount))

func _coin_landed(index: int, count: int, before: int, amount: int) -> void:
	_money.animate_money(before + roundi(amount * (index + 1) / float(count)))

func _count_total(value: int) -> void:
	if _total_tween:
		_total_tween.kill()
	var from := _total_value
	_total_value = value
	_total_tween = create_tween()
	_total_tween.tween_method(func(amount: float): _total.text = Config.AMOUNT_FORMAT % roundi(amount), float(from), float(value), Config.TOTAL_COUNT_DURATION)

func _reveal_button() -> void:
	_button.disabled = false
	_button.modulate.a = 1.0
	_button.scale = Vector2.ZERO
	PopBurst.play(self, _button, Config.TITLE_POP_SCALE, Config.POP)
	_breath = create_tween().set_loops()
	_breath.tween_interval(Config.POP.rise + Config.POP.settle)
	_breath.tween_property(_button, "scale", Vector2.ONE * Config.BREATH_SCALE, Config.BREATH_PERIOD / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breath.tween_property(_button, "scale", Vector2.ONE, Config.BREATH_PERIOD / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _leave() -> void:
	_stop()
	_button.disabled = true
	var exit := create_tween().set_parallel()
	exit.tween_property(_pivot, "position", _rest + Config.EXIT_OFFSET, Config.EXIT_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	exit.tween_property($shade, "modulate:a", 0.0, Config.EXIT_DURATION)
	exit.chain().tween_callback(_finish_leave)

func _finish_leave() -> void:
	hide()
	shop_requested.emit()

func _stop() -> void:
	for tween in [_timeline, _breath, _total_tween]:
		if tween:
			tween.kill()

func _style(control: Control, size: int, color: Color) -> void:
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_color", color)
