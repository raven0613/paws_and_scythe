@tool
extends RefCounted

const Config = preload("res://src/configs/board/board_config.gd")


static func cell_position(cell: Vector2i) -> Vector2:
	return Vector2(cell) * Config.CELL_STEP


static func get_bounds(cells: Array[Vector2i]) -> Rect2:
	if cells.is_empty():
		return Rect2(cell_position(Config.INITIAL_CELL), Config.CARD_SIZE)
	var bounds := Rect2(cell_position(cells[0]), Config.CARD_SIZE)
	for cell in cells:
		bounds = bounds.merge(Rect2(cell_position(cell), Config.CARD_SIZE))
	return bounds


static func get_fit_zoom(bounds: Rect2, view_size: Vector2) -> float:
	var available := (view_size - Vector2.ONE * Config.VIEW_PADDING * 2).max(Vector2.ONE)
	return minf(Config.DEFAULT_ZOOM, minf(available.x / bounds.size.x, available.y / bounds.size.y))
