@tool
extends Control

signal selection_requested(card: Control)

const Config = preload("res://src/configs/playing_card/playing_card_config.gd")

@export var selection_enabled: bool = false:
	set(value):
		selection_enabled = value
		mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_ALL if value else Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if value else Control.CURSOR_ARROW
		queue_redraw()

var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()


func _ready() -> void:
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _gui_input(event: InputEvent) -> void:
	if not selection_enabled:
		return
	var clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if clicked or event.is_action_pressed("ui_accept"):
		accept_event()
		selection_requested.emit(self)


func _draw() -> void:
	if not selection_enabled:
		return
	if selected or has_focus() or Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position()):
		var color := Config.SELECTION_COLOR if selected else Config.HOVER_COLOR
		draw_rect(Rect2(Vector2.ZERO, size).grow(Config.OUTLINE_WIDTH), color, false, Config.OUTLINE_WIDTH)
