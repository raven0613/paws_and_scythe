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
var _visibility_tween: Tween
var _shown := false


func _ready() -> void:
	pressed.connect(func(): placement_requested.emit(cell))
	mouse_entered.connect(_refresh)
	mouse_exited.connect(_refresh)
	focus_entered.connect(_refresh)
	focus_exited.connect(_refresh)
	_refresh()
	if not Engine.is_editor_hint():
		HoverInfo.bind_source(self, _hover_content)
		modulate.a = 0.0
		scale = Config.HIDDEN_SCALE
		pivot_offset = size / 2


func set_input_enabled(enabled: bool, shown: bool) -> void:
	disabled = not enabled
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	_refresh()
	if Engine.is_editor_hint() or shown == _shown:
		return
	_shown = shown
	if _visibility_tween:
		_visibility_tween.kill()
	_visibility_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_visibility_tween.tween_property(self, "modulate:a", 1.0 if shown else 0.0, Config.FADE_DURATION)
	_visibility_tween.tween_property(self, "scale", Vector2.ONE if shown else Config.HIDDEN_SCALE, Config.FADE_DURATION)


func retire() -> void:
	set_input_enabled(false, false)
	if _visibility_tween and _visibility_tween.is_running():
		_visibility_tween.finished.connect(queue_free)
	else:
		queue_free()


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

func _hover_content() -> Array:
	return [Config.INITIAL_TOOLTIP if state == State.INITIAL else Config.AVAILABLE_TOOLTIP, ""]
