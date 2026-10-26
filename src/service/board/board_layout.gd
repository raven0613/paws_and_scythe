@tool
extends RefCounted

const Config = preload("res://src/configs/board/board_config.gd")
const Rules = preload("res://src/service/board/board_rules.gd")
const Frame = preload("res://src/configs/gameplay/gameplay_frame_config.gd")


static func cell_position(cell: Vector2i) -> Vector2:
	return Vector2(cell) * Config.CELL_STEP


static func get_bounds(cells: Array[Vector2i]) -> Rect2:
	if cells.is_empty():
		return Rect2(cell_position(Config.INITIAL_CELL), Config.CARD_SIZE)
	var bounds := Rect2(cell_position(cells[0]), Config.CARD_SIZE)
	for cell in cells:
		bounds = bounds.merge(Rect2(cell_position(cell), Config.CARD_SIZE))
	return bounds


static func get_fit_zoom(bounds: Rect2, view_size: Vector2, maximum: float = Config.DEFAULT_ZOOM) -> float:
	var available := (view_size - Vector2.ONE * Config.VIEW_PADDING * 2).max(Vector2.ONE)
	return minf(minf(available.x / bounds.size.x, available.y / bounds.size.y), maximum)


static func get_fit_bounds(occupied: Array[Vector2i]) -> Rect2:
	var cells := occupied.duplicate()
	cells.append_array(Rules.get_placements(occupied))
	return get_bounds(cells)


static func get_clear_rect(view_size: Vector2) -> Rect2:
	var ratio := view_size / Frame.REFERENCE_SIZE
	return Rect2(Frame.CLEAR_RECT.position * ratio, Frame.CLEAR_RECT.size * ratio)


static func get_free_rect(clear: Rect2, obstacles: Array[Rect2]) -> Rect2:
	var candidates: Array[Rect2] = [clear]
	for obstacle in obstacles:
		var next: Array[Rect2] = []
		for candidate in candidates:
			if not candidate.intersects(obstacle):
				next.append(candidate)
				continue
			var cut := candidate.intersection(obstacle)
			var pieces: Array[Rect2] = [
				Rect2(candidate.position, Vector2(cut.position.x - candidate.position.x, candidate.size.y)),
				Rect2(Vector2(cut.end.x, candidate.position.y), Vector2(candidate.end.x - cut.end.x, candidate.size.y)),
				Rect2(candidate.position, Vector2(candidate.size.x, cut.position.y - candidate.position.y)),
				Rect2(Vector2(candidate.position.x, cut.end.y), Vector2(candidate.size.x, candidate.end.y - cut.end.y)),
			]
			for piece in pieces:
				if piece.has_area() and not next.has(piece):
					next.append(piece)
		candidates = next
	var largest := Rect2()
	for candidate in candidates:
		if candidate.get_area() > largest.get_area():
			largest = candidate
	return largest


static func scroll_factor(delta: float) -> float:
	return exp(-delta * Config.TRACKPAD_ZOOM_SENSITIVITY)


static func pinch_factor(previous: Vector2, current: Vector2) -> float:
	return current.length() / previous.length() if not previous.is_zero_approx() else 1.0


static func zoom_position(position: Vector2, current_zoom: float, next_zoom: float, anchor: Vector2) -> Vector2:
	var world_anchor := (anchor - position) / current_zoom
	return anchor - world_anchor * next_zoom
