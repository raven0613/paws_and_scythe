@tool
extends Node

const Config = preload("res://src/configs/board/board_config.gd")
const Layout = preload("res://src/service/board/board_layout.gd")
const CameraInput = preload("res://src/scripts/board/board_camera_input.gd")
var auto_follow := true
var motion_paused := false:
	set(value):
		motion_paused = value
		if value:
			stop_motion()
var input_enabled := true:
	set(value):
		input_enabled = value
		if _input_router and not value:
			_input_router.cancel()
var _board: Control
var _content: Node2D
var _tween: Tween
var _input_router: Node
var _button_zoom := false
var _target_zoom := Config.DEFAULT_ZOOM

func setup(board: Control, content: Node2D) -> void:
	_board = board
	_content = content
	_board.resized.connect(_on_resized)
	if not Engine.is_editor_hint():
		_input_router = CameraInput.new()
		add_child(_input_router)
		_input_router.setup(_board, self)
	fit_view()

func set_auto_follow(enabled: bool) -> void:
	auto_follow = enabled
	if enabled:
		fit_view()

func _on_resized() -> void:
	if auto_follow:
		fit_view.call_deferred()

func fit_view() -> void:
	if motion_paused:
		return
	var occupied: Array[Vector2i] = _board.get_occupied_cells()
	var bounds := Layout.get_fit_bounds(occupied)
	var safe: Rect2 = _board.get_fit_rect()
	var zoom := Layout.get_fit_zoom(bounds, safe.size)
	var target := safe.get_center() - bounds.get_center() * zoom
	stop_motion()
	if Engine.is_editor_hint():
		_content.position = target
		_content.scale = Vector2.ONE * zoom
	else:
		_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(_content, "position", target, Config.FIT_DURATION)
		_tween.tween_property(_content, "scale", Vector2.ONE * zoom, Config.FIT_DURATION)

func zoom_at(anchor: Vector2, factor: float) -> void:
	stop_motion()
	_set_zoom(_limit_zoom(_content.scale.x * factor), anchor)

func zoom_center(direction: int) -> void:
	var from := _content.scale.x
	var pending := _target_zoom if _button_zoom else from
	var factor := Config.ZOOM_STEP if direction > 0 else 1.0 / Config.ZOOM_STEP
	stop_motion()
	_target_zoom = _limit_zoom(pending * factor)
	_button_zoom = true
	var anchor: Vector2 = _board.get_fit_rect().get_center()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_zoom.bind(anchor), from, _target_zoom, Config.BUTTON_ZOOM_DURATION)
	_tween.tween_callback(func(): _button_zoom = false)

func pinch(from: Vector2, to: Vector2, factor: float) -> void:
	zoom_at(from, factor)
	_content.position += to - from

func pan(delta: Vector2) -> void:
	stop_motion()
	_content.position += delta

func _limit_zoom(zoom: float) -> float:
	return clampf(zoom, minf(Config.MIN_ZOOM, _content.scale.x), Config.MAX_ZOOM)

func _set_zoom(zoom: float, anchor: Vector2) -> void:
	_content.position = Layout.zoom_position(_content.position, _content.scale.x, zoom, anchor)
	_content.scale = Vector2.ONE * zoom

func stop_motion() -> void:
	if _tween:
		_tween.kill()
	_button_zoom = false

func _exit_tree() -> void:
	stop_motion()
