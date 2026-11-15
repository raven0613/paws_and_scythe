extends SceneTree

const Config = preload("res://src/configs/gameplay/game_rules.gd")
const Scoring = preload("res://src/service/gameplay/scoring.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
var failures := 0

func _init() -> void:
	_test_hand_priority()
	_test_card_points()
	_test_contiguous_sets()
	_test_display_order()
	_check(Scoring.combo_multiplier(0) == Scoring.combo_multiplier(1), "Zero and one combo share the base multiplier")
	var pair := _line([7, 7])
	var result := Scoring.evaluate(pair, pair.values())
	_check(result.base == _expected("pair", [7, 7]) and result.combo == 1, "Pair scores once with no high-card double count")
	_check(Scoring.evaluate(pair, []).total == result.total, "Existing pairs keep scoring")
	var lone := _line([7])
	_check(Scoring.evaluate(lone, lone.values()).total == _rank_points([7]), "New lone card gets fallback")
	_check(Scoring.evaluate(lone, []).total == 0, "Existing lone card gets no fallback")
	_check(_score([1, 2, 3, 4, 5]).base == _expected("straight", [1, 2, 3, 4, 5]), "Ace-low straight")
	_check(_score([10, 11, 12, 13, 1]).base == _expected("straight", [10, 11, 12, 13, 1]), "Ace-high straight")
	_check(_score([11, 12, 13, 1, 2]).base == _expected("straight", [11, 12, 13, 1, 2]), "JQKA2 wraps across ace")
	_check(_score([12, 13, 1, 2, 3]).base == _expected("straight", [12, 13, 1, 2, 3]), "QKA23 wraps across ace")
	_check(_score([12, 13, 1, 2, 4]).combo == 0, "A missing cyclic rank breaks the straight")
	_test_cyclic_straights()
	_check(_score([6, 2, 4, 3, 5]).base == _expected("straight", [6, 2, 4, 3, 5]), "Poker ranks may be arranged in any order")
	_check(_score([4, 4, 8, 8]).base == _expected("two_pair", [4, 4, 8, 8]), "Two pair")
	_check(_score([4, 4, 4, 8, 8]).base == _expected("full_house", [4, 4, 4, 8, 8]), "Full house")
	_check(_score([4, 4, 4, 4]).base == _expected("four", [4, 4, 4, 4]), "Four of a kind")
	var extended := _score([1, 2, 3, 4, 5, 6, 6, 6])
	var expected := _expected("straight", [1, 2, 3, 4, 5, 6]) + _expected("pair", [6, 6])
	_check(extended.base == expected, "Longest straight leaves a separate pair")
	_check(_score([1, 2, 2, 3, 4, 5, 6]).base == _expected("straight", [2, 3, 4, 5, 6]), "Search finds straight past duplicate prefix")
	var flush := {}
	for i in range(Config.EXTENDED_MIN):
		flush[Vector2i(i, 0)] = Cards.id(i + 1, 0)
	_check(Scoring.evaluate(flush, []).base == Config.HAND_BONUSES.straight_flush + _card_points(flush.values()), "Straight flush outranks flush")
	flush[Vector2i(Config.EXTENDED_MIN, 0)] = Cards.id(Config.EXTENDED_MIN + 1, 0)
	_check(Scoring.evaluate(flush, []).base == Config.HAND_BONUSES.straight_flush * (1 + Config.LENGTH_BONUS) + _card_points(flush.values()), "Long straight flush")
	flush.clear()
	var flush_ranks := [1, 3, 5, 7, 9, 11]
	for i in flush_ranks.size():
		flush[Vector2i(i, 0)] = Cards.id(flush_ranks[i], 0)
	_check(Scoring.evaluate(flush, []).base == Config.HAND_BONUSES.flush * (1 + Config.LENGTH_BONUS) + _card_points(flush.values()), "Extended flush uses length bonus")
	flush.erase(Vector2i(flush_ranks.size() - 1, 0))
	_check(Scoring.evaluate(flush, []).base == Config.HAND_BONUSES.flush + _card_points(flush.values()), "Nonconsecutive flush")
	var cross := _line([7, 7, 7])
	cross[Vector2i(1, -1)] = Cards.id(7, 3)
	result = Scoring.evaluate(cross, cross.values())
	_check(result.combo == 2 and result.base == _expected("three", [7, 7, 7]) + _expected("pair", [7, 7]), "Crossing directions share cards and count both groups")
	_check(result.total == result.base * (1 + Config.COMBO_STEP), "Multiplier uses group count")
	_check(result.multiplier == Scoring.combo_multiplier(result.combo), "Settlement and feedback use the same multiplier")
	var reversed := {}
	var cells: Array = cross.keys()
	cells.reverse()
	for cell in cells:
		reversed[cell] = cross[cell]
	_check(Scoring.evaluate(reversed, []) == Scoring.evaluate(cross, []), "Coordinate ordering makes evaluation deterministic")
	var with_high := cross.duplicate()
	var high_card := Cards.id(2, 0)
	with_high[Vector2i(5, 5)] = high_card
	var mixed := Scoring.evaluate(with_high, [high_card])
	_check(mixed.high == _rank_points([2]) and mixed.combo == result.combo, "High cards add points without adding combos")
	_check(mixed.total == (result.base + _rank_points([2])) * result.multiplier, "High-card points receive the final combo multiplier")
	_check(Scoring.evaluate(with_high, []).total == result.total, "Existing lone cards do not receive another fallback")
	var disjoint := _line([7, 7])
	disjoint[Vector2i(4, 0)] = Cards.id(9, 0)
	disjoint[Vector2i(5, 0)] = Cards.id(9, 1)
	_check(Scoring.evaluate(disjoint, []).combo == 2, "Islands score independently")
	disjoint[Vector2i(8, 0)] = Cards.id(11, 0)
	disjoint[Vector2i(9, 0)] = Cards.id(11, 1)
	var triple := Scoring.evaluate(disjoint, [])
	_check(triple.combo == 3 and triple.multiplier == 1 + 2 * Config.COMBO_STEP, "Three combos apply two multiplier steps")
	_check(triple.multiplier == Scoring.combo_multiplier(triple.combo), "Three-combo display multiplier matches settlement")
	print("Scoring tests: %d failures" % failures)
	quit(1 if failures else 0)

func _line(ranks: Array, same_suit := false) -> Dictionary:
	var board := {}
	var next_suit := {}
	for i in ranks.size():
		var suit_index: int = next_suit.get(ranks[i], i % Config.SUITS.size())
		board[Vector2i(i, 0)] = Cards.id(ranks[i], 0 if same_suit else suit_index)
		next_suit[ranks[i]] = (suit_index + 1) % Config.SUITS.size()
	return board

func _test_hand_priority() -> void:
	var board := _line([7, 9, 11, 1, 2, 3, 4, 5, 8, 12, 13], true)
	_check_groups(Scoring.evaluate(board, []), [["straight_flush", 3, 8]], "Straight flush takes priority over a longer, higher-scoring flush")
	var result := Scoring.evaluate(board, board.values())
	_check(result.base == _expected("straight_flush", [1, 2, 3, 4, 5]) and result.high == _rank_points([7, 9, 11, 8, 12, 13]), "Rejected flush cards contribute only new-card fallback")
	# 同花色重複牌僅作為牌型判定的假設輸入；實際牌庫仍使用唯一的 52 張牌。
	board = _line([1, 1, 2, 6, 6, 9, 9, 5], true)
	_check_groups(Scoring.evaluate(board, []), [["flush", 0, 8]], "Eight-card flush takes priority over pairs")
	board = _line([1, 1, 2, 6, 6, 9, 9, 9], true)
	_check_groups(Scoring.evaluate(board, []), [["full_house", 3, 8], ["pair", 0, 2]], "Full house takes priority over flush and leaves a separate pair")
	result = Scoring.evaluate(board, board.values())
	_check(result.high == _rank_points([2]), "Only the unused new card receives fallback after selecting the full house and pair")
	board = _line([2, 2, 2, 13, 13, 13])
	_check_groups(Scoring.evaluate(board, []), [["full_house", 0, 5]], "Position wins equal-rank equal-length ties even when the later hand has more card points")
	result = Scoring.evaluate(board, board.values())
	_check(result.base == _expected("full_house", [2, 2, 2, 13, 13]) and result.high == _rank_points([13]), "Only selected cards contribute to the hand; the unused new king receives fallback")
	board = _line([2, 3, 4, 5, 6, 2])
	_check_groups(Scoring.evaluate(board, []), [["straight", 0, 5]], "Equal-rank equal-length overlaps choose the leftmost group")
	var vertical := {}
	for cell in board:
		vertical[Vector2i(0, cell.x)] = board[cell]
	result = Scoring.evaluate(vertical, [])
	_check(result.groups.size() == 1 and result.groups[0].cells[0] == Vector2i.ZERO, "Vertical ties choose the topmost group")
	_check_groups(_score([1, 2, 3, 4, 5, 6, 6, 6]), [["straight", 0, 6], ["pair", 6, 8]], "Same-rank candidates choose the longest group before processing the remainder")

# 清單依原始分數由高到低；同分時橫向在前，再依牌型第一格位置，連接在牌列上的無關牌不改變順序。
func _test_display_order() -> void:
	var board := _line([4, 4, 4, 9, 9])
	board.erase(Vector2i(2, 0))
	var result := Scoring.evaluate(board, [])
	_check(result.groups[0].score > result.groups[1].score and result.groups[0].cells[0] == Vector2i(3, 0), "Higher original score comes first regardless of position")
	var ties := {Vector2i(2, 2): Cards.id(8, 0), Vector2i(2, 3): Cards.id(8, 1),
		Vector2i(0, 2): Cards.id(8, 2), Vector2i(0, 3): Cards.id(8, 3), Vector2i(4, 5): Cards.id(8, 0), Vector2i(5, 5): Cards.id(8, 1)}
	var tied := Scoring.evaluate(ties, [])
	var starts: Array = tied.groups.map(func(group): return group.cells[0])
	_check(starts == [Vector2i(4, 5), Vector2i(0, 2), Vector2i(2, 2)], "Equal scores list horizontal groups first, then by first cell")
	var extended := ties.duplicate()
	extended[Vector2i(2, 1)] = Cards.id(3, 2)
	extended[Vector2i(2, 4)] = Cards.id(12, 2)
	var after: Array = Scoring.evaluate(extended, []).groups.map(func(group): return group.cells)
	_check(after == tied.groups.map(func(group): return group.cells), "Unrelated cards joining a line keep the list order")

func _check_groups(result: Dictionary, expected: Array, message: String) -> void:
	_check(result.groups.size() == expected.size(), message + ": group count")
	if result.groups.size() != expected.size():
		return
	for index in expected.size():
		var group: Dictionary = result.groups[index]
		var cells: Array = []
		for x in range(expected[index][1], expected[index][2]):
			cells.append(Vector2i(x, 0))
		_check(group.kind == expected[index][0] and group.cells == cells, message + ": selected cells")

func _score(ranks: Array) -> Dictionary:
	return Scoring.evaluate(_line(ranks), [])

func _test_contiguous_sets() -> void:
	for ranks in [[4, 4, 9, 9], [9, 9, 4, 4]]:
		_check_groups(_score(ranks), [["two_pair", 0, ranks.size()]], "Two adjacent pairs qualify in either rank order")
	for ranks in [[4, 4, 4, 9, 9], [9, 9, 4, 4, 4]]:
		_check_groups(_score(ranks), [["full_house", 0, ranks.size()]], "Full house has adjacent triple and pair")
	var cases := [
		[[4, 9, 9, 4], [["pair", 1, 3]]],
		[[4, 9, 4, 9], []],
		[[4, 9, 4, 9, 4], []],
		[[4, 4, 9, 9, 4], [["two_pair", 0, 4]]],
		[[4, 9, 9, 4, 4], [["two_pair", 1, 5]]],
		[[4, 9, 9, 9, 4], [["three", 1, 4]]],
	]
	for fixture in cases:
		var board := _line(fixture[0])
		var horizontal := Scoring.evaluate(board, [])
		_check_groups(horizontal, fixture[1], "Separated equal ranks fall back to contiguous groups")
		var vertical := {}
		for cell in board:
			vertical[Vector2i(0, cell.x)] = board[cell]
		var result := Scoring.evaluate(vertical, [])
		_check(result.base == horizontal.base and result.combo == horizontal.combo, "Vertical grouping follows the same contiguous rule")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _test_cyclic_straights() -> void:
	const Patterns = preload("res://src/service/gameplay/poker_patterns.gd")
	for length in range(Config.EXTENDED_MIN, Config.RANKS.size() + 1):
		for start in Config.RANKS.size():
			var cards: Array = []
			for offset in length:
				cards.append(Cards.id((start + offset) % Config.RANKS.size() + 1, 0))
			cards.reverse()
			var candidates := Patterns.candidates(cards)
			var expected: float = Config.HAND_BONUSES.straight_flush * (1 + (length - Config.EXTENDED_MIN) * Config.LENGTH_BONUS) + _card_points(cards)
			_check(candidates.any(func(group): return group.kind == "straight_flush" and group.score == expected), "Every cyclic starting rank and supported length scores")
	var duplicate: Array = [Cards.id(12, 0), Cards.id(13, 0), Cards.id(1, 0), Cards.id(1, 1), Cards.id(2, 0)]
	_check(not Patterns.candidates(duplicate).any(func(group): return group.kind == "straight"), "Repeated ranks cannot complete a cyclic straight")

func _test_card_points() -> void:
	for rank_index in Config.RANKS.size():
		for suit_index in Config.SUITS.size():
			var card := Cards.id(rank_index + 1, suit_index)
			var board := {Vector2i.ZERO: card}
			var result := Scoring.evaluate(board, [card])
			_check(result.high == Config.RANK_POINTS[rank_index], "Every rank and suit uses configured fallback points")
			_check(result.base == 0 and result.combo == 0 and result.total == result.high, "Lone cards receive points without a hand bonus or combo")
			_check(Scoring.evaluate(board, []).total == 0, "Existing unused cards receive no fallback")

func _rank_points(ranks: Array) -> int:
	var total := 0
	for rank_value in ranks:
		total += Config.RANK_POINTS[rank_value - 1]
	return total

func _card_points(cards: Array) -> int:
	var total := 0
	for card in cards:
		total += Config.RANK_POINTS[Cards.rank(card) - 1]
	return total

func _expected(kind: String, ranks: Array) -> float:
	var bonus: float = Config.HAND_BONUSES[kind]
	if kind in ["straight", "flush", "straight_flush"]:
		bonus *= 1 + (ranks.size() - Config.EXTENDED_MIN) * Config.LENGTH_BONUS
	return bonus + _rank_points(ranks)
