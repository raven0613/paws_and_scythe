@tool
extends Control

const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Config = preload("res://src/configs/gameplay_controls/controls_config.gd")
@export var deck_color := Config.ICON_COLOR:
	set(value):
		deck_color = value
		_refresh_palette()
@export var money_color := Config.MONEY_COLOR:
	set(value):
		money_color = value
		_refresh_palette()

func _ready() -> void:
	_refresh_palette()
	if Engine.is_editor_hint():
		update_values(Rules.DECK_SIZE, Rules.STARTING_MONEY)
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

func update_values(deck_count: int, money: int) -> void:
	set_deck_count(deck_count)
	$money_count.text = str(money)

func set_deck_count(value: int) -> void:
	$deck_count.text = str(value)

func set_board_count(count: int, limit: int) -> void:
	$board_count.text = Config.BOARD_COUNT_FORMAT % [count, limit]

func deal_origin() -> Vector2:
	return $deck_icon.get_global_rect().get_center()
