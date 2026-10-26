@tool
extends RefCounted

const Config = preload("res://src/configs/board/board_config.gd")


static func get_placements(occupied: Array[Vector2i]) -> Array[Vector2i]:
	if occupied.is_empty():
		return [Config.INITIAL_CELL]
	var filled := {}
	for cell in occupied:
		filled[cell] = true
	var empty := {}
	for cell in occupied:
		for direction in Config.NEIGHBORS:
			var neighbor := cell + direction
			if not filled.has(neighbor):
				empty[neighbor] = true
	var result: Array[Vector2i] = []
	result.assign(empty.keys())
	result.sort_custom(func(a: Vector2i, b: Vector2i): return a.y < b.y or (a.y == b.y and a.x < b.x))
	return result


static func can_place(occupied: Array[Vector2i], cell: Vector2i) -> bool:
	if occupied.is_empty():
		return cell == Config.INITIAL_CELL
	if occupied.has(cell):
		return false
	for direction in Config.NEIGHBORS:
		if occupied.has(cell + direction):
			return true
	return false


static func can_play_this_turn(cards_played: int) -> bool:
	return cards_played < Config.MAX_PLAYS_PER_TURN
