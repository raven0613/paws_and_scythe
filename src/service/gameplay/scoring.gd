extends RefCounted

const Config = preload("res://src/configs/gameplay/game_rules.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
const Patterns = preload("res://src/service/gameplay/poker_patterns.gd")

static func evaluate(board: Dictionary, new_cards: Array, extended_min: int = Config.EXTENDED_MIN) -> Dictionary:
	var groups: Array = []
	for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
		for start in board.keys():
			if board.has(start - direction):
				continue
			var line: Array = []
			var cell: Vector2i = start
			while board.has(cell):
				line.append(cell)
				cell += direction
			groups.append_array(_select_line(board, line, direction, extended_min))
	groups.sort_custom(_display_before)
	var base := 0.0
	var used := {}
	for group in groups:
		base += group.score
		for cell in group.cells:
			used[board[cell]] = true
	var high := 0
	for card in board.values():
		if new_cards.has(card) and not used.has(card):
			high += Cards.points(card)
	var multiplier := combo_multiplier(groups.size())
	return {
		"groups": groups, "base": base, "combo": groups.size(), "multiplier": multiplier,
		"high": high, "total": (base + high) * multiplier,
	}

static func combo_multiplier(count: int) -> float:
	return 1 + maxi(0, count - 1) * Config.COMBO_STEP

# 依階級、長度、位置依序占用區段，剩餘區段繼續採用可成立的牌型。
static func _select_line(board: Dictionary, cells: Array, direction: Vector2i, extended_min: int) -> Array:
	var candidates: Array = []
	for start in cells.size():
		var cards: Array = [board[cells[start]]]
		for end in range(start + 1, cells.size()):
			cards.append(board[cells[end]])
			for pattern in Patterns.candidates(cards, extended_min):
				pattern.cells = cells.slice(start, end + 1)
				pattern.direction = direction
				candidates.append(pattern)
	candidates.sort_custom(_priority_before)
	var groups: Array = []
	var used := {}
	for group in candidates:
		if group.cells.any(func(cell): return used.has(cell)):
			continue
		groups.append(group)
		for cell in group.cells:
			used[cell] = true
	return groups

# Combo 清單依原始分數由高到低排列；同分時橫向在前，再依牌型第一格由上到下、由左到右。
static func _display_before(a: Dictionary, b: Dictionary) -> bool:
	if a.score != b.score:
		return a.score > b.score
	if a.direction != b.direction:
		return a.direction == Vector2i.RIGHT
	return _cell_before(a.cells[0], b.cells[0])

static func _priority_before(a: Dictionary, b: Dictionary) -> bool:
	var a_rank := Config.HAND_ORDER.find(a.kind)
	var b_rank := Config.HAND_ORDER.find(b.kind)
	if a_rank != b_rank:
		return a_rank < b_rank
	if a.cells.size() != b.cells.size():
		return a.cells.size() > b.cells.size()
	return _cell_before(a.cells[0], b.cells[0])

static func _cell_before(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or (a.y == b.y and a.x < b.x)
