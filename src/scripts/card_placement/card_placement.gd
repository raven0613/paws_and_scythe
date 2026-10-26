@tool
extends Button

signal placement_requested(cell: Vector2i)

const Config = preload("res://src/configs/card_placement/card_placement_config.gd")
enum State { INITIAL, AVAILABLE }

@export var state: State = State.INITIAL:
	set(value):
		state = value
		_refresh()

var cell := Vector2i.ZERO


func _ready() -> void:
	pressed.connect(func(): placement_requested.emit(cell))
	mouse_entered.connect(_refresh)
	mouse_exited.connect(_refresh)
	focus_entered.connect(_refresh)
	focus_exited.connect(_refresh)
	_refresh()


func set_input_enabled(enabled: bool) -> void:
	disabled = not enabled
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	var highlighted := not disabled and (is_hovered() or has_focus())
	$background.self_modulate = Config.HOVER_COLOR if highlighted else Config.BASE_COLOR
	$frame.self_modulate = Config.ACTIVE_COLOR if highlighted else Config.FRAME_COLOR
	$plus.self_modulate = $frame.self_modulate
	$initial_hint.visible = state == State.INITIAL
	$initial_hint.text = Config.INITIAL_HINT
	$initial_hint.add_theme_color_override("font_color", Config.FRAME_COLOR)
	$initial_hint.add_theme_font_size_override("font_size", Config.HINT_FONT_SIZE)
	tooltip_text = Config.INITIAL_TOOLTIP if state == State.INITIAL else Config.AVAILABLE_TOOLTIP
