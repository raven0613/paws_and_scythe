@tool
extends Control

const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Config = preload("res://src/configs/gameplay_controls/controls_config.gd")
const Motion = preload("res://src/configs/money/money_motion_config.gd")
const Shake = preload("res://src/service/motion/shake_motion.gd")
@export var deck_color := Config.ICON_COLOR:
	set(value):
		deck_color = value
		_refresh_palette()
@export var money_color := Config.MONEY_COLOR:
	set(value):
		money_color = value
		_refresh_palette()

var money := 0
var _money_tween: Tween
var _icon_tween: Tween
var _board_full := false
var _board_pulse: Tween
var _board_alert: Tween

func _ready() -> void:
	_refresh_palette()
	if Engine.is_editor_hint():
		set_deck_count(Rules.DECK_SIZE)
		set_money(Rules.STARTING_MONEY)
		set_board_count(0, Rules.BOARD_LIMIT)

func _refresh_palette() -> void:
	if not is_node_ready():
		return
	$deck_icon.material.set_shader_parameter("tint", deck_color)
	$deck_icon.material.set_shader_parameter("reference_tint", Config.ICON_COLOR)
	$money_icon.material.set_shader_parameter("tint", money_color)
	$money_icon.material.set_shader_parameter("reference_tint", Config.MONEY_COLOR)
	$deck_count.add_theme_color_override("font_color", deck_color)
	$board_count.add_theme_color_override("font_color", deck_color)
	$money_count.add_theme_color_override("font_color", money_color)
	for label in [$board_count, $deck_count, $money_count]:
		label.add_theme_font_size_override("font_size", Config.FONT_SIZE)

func set_deck_count(value: int) -> void:
	$deck_count.text = str(value)

# 達到容量上限時彈跳一次並開始呼吸閃爍，低於上限時回到原色。
func set_board_count(count: int, limit: int) -> void:
	$board_count.text = Config.BOARD_COUNT_FORMAT % [count, limit]
	var full := count >= limit
	if full == _board_full:
		return
	_board_full = full
	if _board_pulse:
		_board_pulse.kill()
	if not full:
		_tint_board(deck_color)
		return
	alert_board_full()
	_board_pulse = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_board_pulse.tween_method(_tint_board, Config.BOARD_FULL_COLOR, Config.BOARD_FULL_DIM_COLOR, Config.BOARD_FULL_PERIOD / 2)
	_board_pulse.tween_method(_tint_board, Config.BOARD_FULL_DIM_COLOR, Config.BOARD_FULL_COLOR, Config.BOARD_FULL_PERIOD / 2)

# 場上張數以右緣為軸放大回彈並旋轉抖動。
func alert_board_full() -> void:
	if _board_alert:
		_board_alert.kill()
	var label: Label = $board_count
	label.pivot_offset = Vector2(label.size.x, label.size.y / 2)
	label.scale = Vector2.ONE * Config.BOARD_ALERT_SCALE
	_board_alert = create_tween().set_parallel()
	_board_alert.tween_property(label, "scale", Vector2.ONE, Config.BOARD_ALERT_DURATION).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_board_alert.tween_method(_shake_board.bind(label), 0.0, 1.0, Config.BOARD_ALERT_DURATION)

func _tint_board(color: Color) -> void:
	$board_count.add_theme_color_override("font_color", color)

func _shake_board(progress: float, label: Label) -> void:
	label.rotation = Shake.pose(progress, Vector2.ZERO, Config.BOARD_ALERT_TILT, Config.BOARD_ALERT_CYCLES, 0.0, Config.BOARD_ALERT_DECAY).rotation

func set_money(value: int) -> void:
	if _money_tween:
		_money_tween.kill()
	money = value
	$money_count.text = str(value)
	$money_count.scale = Vector2.ONE
	$money_count.add_theme_color_override("font_color", money_color)

# 數字跳到新數值並從左側放大回彈；增加時亮起、減少時短暫轉紅，金錢圖示同時彈跳抖動。
func animate_money(value: int) -> void:
	if _money_tween:
		_money_tween.kill()
	var from := money
	money = value
	var label: Label = $money_count
	var flash := Motion.GAIN_FLASH if value >= from else Motion.SPEND_FLASH
	label.pivot_offset = Vector2(0, label.size.y / 2)
	label.scale = Vector2.ONE * Motion.POP_SCALE
	_money_tween = create_tween().set_parallel()
	_money_tween.tween_method(func(amount: float): label.text = str(roundi(amount)), float(from), float(value), Motion.COUNT_DURATION)
	_money_tween.tween_property(label, "scale", Vector2.ONE, Motion.POP_DURATION).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_money_tween.tween_method(func(color: Color): label.add_theme_color_override("font_color", color), flash, money_color, Motion.FLASH_DURATION)
	_pop_icon()

func money_target() -> Vector2:
	return $money_icon.get_global_rect().get_center()

func deal_origin() -> Vector2:
	return $deck_icon.get_global_rect().get_center()

func _pop_icon() -> void:
	if _icon_tween:
		_icon_tween.kill()
	var icon: Control = $money_icon
	icon.pivot_offset = icon.size / 2
	icon.scale = Vector2.ONE * Motion.ICON_POP_SCALE
	_icon_tween = create_tween().set_parallel()
	_icon_tween.tween_property(icon, "scale", Vector2.ONE, Motion.POP_DURATION).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_icon_tween.tween_method(_shake_icon.bind(icon), 0.0, 1.0, Motion.ICON_SHAKE_DURATION)

func _shake_icon(progress: float, icon: Control) -> void:
	icon.rotation = Shake.pose(progress, Vector2.ZERO, Motion.ICON_TILT, Motion.ICON_SHAKE_CYCLES, 0.0, Motion.ICON_SHAKE_DECAY).rotation
