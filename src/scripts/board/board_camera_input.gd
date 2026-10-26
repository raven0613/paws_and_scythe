extends Node

const Config = preload("res://src/configs/board/board_config.gd")
const Layout = preload("res://src/service/board/board_layout.gd")
const Touch = preload("res://src/service/board/board_touch.gd")
var _board: Control
var _camera: Node
var _touch := Touch.new()
var _drag_button := MOUSE_BUTTON_NONE
var _last_pointer := Vector2.ZERO
var _owns_emulated_mouse := false

func setup(board: Control, camera: Node) -> void:
	_board = board
	_camera = camera
	get_viewport().get_window().focus_exited.connect(cancel)

func cancel() -> void:
	_drag_button = MOUSE_BUTTON_NONE
	_touch.clear()
	_camera.stop_motion()

func _input(event: InputEvent) -> void:
	if not _camera.input_enabled:
		return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		# Godot sends the emulated mouse press before the raw touch press.
		if event is InputEventMouseButton and event.pressed:
			_owns_emulated_mouse = _board.allows_camera_at(event.position)
		if _owns_emulated_mouse:
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_handle_touch(event)
	elif event is InputEventGesture:
		if not _touch.points.is_empty() or not _board.allows_camera_at(event.position):
			return
		if event is InputEventPanGesture:
			_camera.zoom_at(_local(event.position), Layout.scroll_factor(event.delta.y))
		elif event is InputEventMagnifyGesture:
			_camera.zoom_at(_local(event.position), event.factor)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _drag_button != MOUSE_BUTTON_NONE:
		var point := _local(event.position)
		_camera.pan(point - _last_pointer)
		_last_pointer = point
		get_viewport().set_input_as_handled()

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if not event.pressed:
		if event.button_index == _drag_button:
			_drag_button = MOUSE_BUTTON_NONE
		return
	if not _board.allows_camera_at(event.position):
		return
	if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var direction := 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
		var amount := event.factor if event.factor > 0.0 else 1.0
		_camera.zoom_at(_local(event.position), pow(Config.ZOOM_STEP, direction * amount))
		get_viewport().set_input_as_handled()
	elif event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
		if _board.has_card_at(event.position) or _board.has_active_placement_at(event.position):
			return
		_drag_button = event.button_index
		_last_pointer = _local(event.position)
		_camera.stop_motion()
		get_viewport().set_input_as_handled()

func _handle_touch(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if not _board.allows_camera_at(event.position):
			return
		_touch.press(event.index, _local(event.position))
		_camera.stop_motion()
	elif not _touch.points.has(event.index):
		return
	elif event is InputEventScreenTouch:
		if _touch.release(event.index, _local(event.position), event.canceled) and _board.allows_camera_at(event.position):
			_board.tap_at(event.position)
	else:
		var gesture := _touch.move(event.index, _local(event.position))
		if not gesture.is_empty():
			_camera.pinch(gesture.from, gesture.to, gesture.factor)
	get_viewport().set_input_as_handled()

func _local(point: Vector2) -> Vector2:
	return _board.get_global_transform_with_canvas().affine_inverse() * point
