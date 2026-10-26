@tool
extends Control

signal zoom_requested(direction: int)
signal reset_requested
signal auto_changed(enabled: bool)

const Config = preload("res://src/configs/gameplay_controls/controls_config.gd")
@export var icon_color := Config.ICON_COLOR:
	set(value):
		icon_color = value
		_refresh()

func _ready() -> void:
	$auto.toggled.connect(_on_auto_toggled)
	$reset.pressed.connect(func(): reset_requested.emit())
	$zoom_in.pressed.connect(func(): zoom_requested.emit(1))
	$zoom_out.pressed.connect(func(): zoom_requested.emit(-1))
	for button in get_children():
		button.mouse_entered.connect(_refresh)
		button.mouse_exited.connect(_refresh)
	_refresh()

func _on_auto_toggled(enabled: bool) -> void:
	_refresh()
	auto_changed.emit(enabled)

func _refresh() -> void:
	if not is_node_ready():
		return
	for button in get_children():
		var color := icon_color
		if button.is_hovered():
			color *= Config.HOVER_BRIGHTNESS
		color.a = Config.DISABLED_ALPHA if button == $auto and not button.button_pressed else 1.0
		button.self_modulate = color


func set_controls_enabled(enabled: bool) -> void:
	for button in get_children():
		button.disabled = not enabled
	_refresh()
