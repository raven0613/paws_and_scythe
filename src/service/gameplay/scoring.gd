extends RefCounted

const Config = preload("res://src/configs/gameplay/game_rules.gd")
const Patterns = preload("res://src/service/gameplay/poker_patterns.gd")

static func evaluate(board: Dictionary, new_cards: Array, cost: int = 0) -> Dictionary:
	var groups: Array = []
	var cells: Array = board.keys()
	cells.sort_custom(func(a: Vector2i, b: Vector2i): return a.y < b.y or (a.y == b.y and a.x < b.x))
	for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
		for start in cells:
			if board.has(start - direction):
				continue
			var line: Array = []
			var cell: Vector2i = start
			while board.has(cell):
				line.append(cell)
				cell += direction
			groups.append_array(_best_line(board, line, direction))
	var base := 0.0
	var used := {}
	for group in groups:
		base += group.score
		for cell in group.cells:
			used[board[cell]] = true
	var high := 0
	for card in board.values():
		if new_cards.has(card) and not used.has(card):
			high += Config.SCORES.high
	var multiplier: float = 1 + maxi(0, groups.size() - 1) * Config.COMBO_STEP
	return {
		"groups": groups, "base": base, "combo": groups.size(), "multiplier": multiplier,
		"high": high, "cost": cost, "gross": base * multiplier,
		"net": base * multiplier + high - cost,
	}

# 每個方向內為不重疊區間最佳化；同分依組數、參與張數、固定候選順序決定。
static func _best_line(board: Dictionary, cells: Array, direction: Vector2i) -> Array:
	var best: Array = []
	best.resize(cells.size() + 1)
	best[cells.size()] = {"score": 0.0, "count": 0, "used": 0, "groups": []}
	for start in range(cells.size() - 1, -1, -1):
		var winner: Dictionary = best[start + 1]
		var cards: Array = [board[cells[start]]]
		for end in range(start + 1, cells.size()):
			cards.append(board[cells[end]])
			for pattern in Patterns.candidates(cards):
				var tail: Dictionary = best[end + 1]
				var group: Dictionary = pattern.duplicate()
				group.cells = cells.slice(start, end + 1)
				group.direction = direction
				var candidate := {
					"score": pattern.score + tail.score,
					"count": 1 + tail.count, "used": cards.size() + tail.used,
					"groups": [group] + tail.groups,
				}
				if _better(candidate, winner):
					winner = candidate
		best[start] = winner
	return best[0].groups

static func _better(a: Dictionary, b: Dictionary) -> bool:
	for key in ["score", "count", "used"]:
		if a[key] != b[key]:
			return a[key] > b[key]
	return false
