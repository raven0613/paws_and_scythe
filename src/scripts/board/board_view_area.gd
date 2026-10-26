@tool
extends RefCounted

const Layout = preload("res://src/service/board/board_layout.gd")
var _board: Control
var _frame: Control
var _overlays: Array[Control] = []

func setup(board: Control, frame: Control, overlays: Array[Control]) -> void:
	_board = board
	_frame = frame
	_overlays = overlays

func fit_rect() -> Rect2:
	var obstacles: Array[Rect2] = []
	var inverse := _board.get_global_transform_with_canvas().affine_inverse()
	for overlay in _overlays:
		if overlay.is_visible_in_tree():
			var transform := inverse * overlay.get_global_transform_with_canvas()
			obstacles.append(transform * Rect2(Vector2.ZERO, overlay.size))
	return Layout.get_free_rect(Layout.get_clear_rect(_board.size), obstacles)

func allows(point: Vector2) -> bool:
	if not contains_point(_board, point):
		return false
	var local := _frame.get_global_transform_with_canvas().affine_inverse() * point
	if _frame._has_point(local):
		return false
	for overlay in _overlays:
		if overlay.is_visible_in_tree() and contains_point(overlay, point):
			return false
	return true

static func contains_point(control: Control, point: Vector2) -> bool:
	var local := control.get_global_transform_with_canvas().affine_inverse() * point
	return Rect2(Vector2.ZERO, control.size).has_point(local)
