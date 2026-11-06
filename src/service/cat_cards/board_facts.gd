extends RefCounted

const DIRECTIONS = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

# 連通性只由實體格子決定，孤島包含單張牌。
static func build(board: Dictionary, groups: Array, scoring: Array) -> Dictionary:
	var membership := {}
	var island_count := 0
	var hole := false
	for cell in board:
		for direction in DIRECTIONS:
			var empty: Vector2i = cell + direction
			if not board.has(empty) and DIRECTIONS.all(func(d): return board.has(empty + d)):
				hole = true
		if membership.has(cell):
			continue
		var pending: Array = [cell]
		membership[cell] = island_count
		while not pending.is_empty():
			var current: Vector2i = pending.pop_back()
			for direction in DIRECTIONS:
				var next: Vector2i = current + direction
				if board.has(next) and not membership.has(next):
					membership[next] = island_count
					pending.append(next)
		island_count += 1
	var scoring_islands := {}
	for index in scoring:
		scoring_islands[membership[groups[index].cells[0]]] = true
	var recognized := {}
	for group in groups:
		for cell in group.cells:
			recognized[cell] = true
	return {"hole": hole, "islands": island_count,
		"all_islands_scoring": scoring_islands.size() == island_count,
		"strays": board.size() - recognized.size()}
