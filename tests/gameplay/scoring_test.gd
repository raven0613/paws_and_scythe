extends SceneTree

const Config = preload("res://src/configs/gameplay/game_rules.gd")
const Scoring = preload("res://src/service/gameplay/scoring.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
var failures := 0

func _init() -> void:
	var pair := _line([7, 7])
	var result := Scoring.evaluate(pair, pair.values())
	_check(result.base == Config.SCORES.pair and result.combo == 1, "Pair scores once with no high-card double count")
	_check(Scoring.evaluate(pair, []).net == result.net, "Existing pairs keep scoring")
	var lone := _line([7])
	_check(Scoring.evaluate(lone, lone.values()).net == Config.SCORES.high, "New lone card gets fallback")
	_check(Scoring.evaluate(lone, []).net == 0, "Existing lone card gets no fallback")
	_check(_score([1, 2, 3, 4, 5]).base == Config.SCORES.straight, "Ace-low straight")
	_check(_score([10, 11, 12, 13, 1]).base == Config.SCORES.straight, "Ace-high straight")
	_check(_score([11, 12, 13, 1, 2]).base == Config.SCORES.straight, "JQKA2 wraps across ace")
	_check(_score([12, 13, 1, 2, 3]).base == Config.SCORES.straight, "QKA23 wraps across ace")
	_check(_score([12, 13, 1, 2, 4]).combo == 0, "A missing cyclic rank breaks the straight")
	_test_cyclic_straights()
	_check(_score([6, 2, 4, 3, 5]).base == Config.SCORES.straight, "Poker ranks may be arranged in any order")
	_check(_score([4, 4, 8, 8]).base == Config.SCORES.two_pair, "Two pair")
	_check(_score([4, 8, 4, 8, 4]).base == Config.SCORES.full_house, "Full house")
	_check(_score([4, 4, 4, 4]).base == Config.SCORES.four, "Four of a kind")
	var extended := _score([1, 2, 3, 4, 5, 6, 6, 6])
	var expected := Config.SCORES.straight * (1 + Config.LENGTH_BONUS) + Config.SCORES.pair
	_check(extended.base == expected, "Optimal split chooses six-card straight plus pair")
	_check(_score([1, 2, 2, 3, 4, 5, 6]).base == Config.SCORES.straight, "Search finds straight past duplicate prefix")
	var flush := {}
	for i in range(Config.EXTENDED_MIN):
		flush[Vector2i(i, 0)] = Cards.id(i + 1, 0)
	_check(Scoring.evaluate(flush, []).base == Config.SCORES.straight_flush, "Straight flush outranks flush")
	flush[Vector2i(Config.EXTENDED_MIN, 0)] = Cards.id(Config.EXTENDED_MIN + 1, 0)
	_check(Scoring.evaluate(flush, []).base == Config.SCORES.straight_flush * (1 + Config.LENGTH_BONUS), "Long straight flush")
	flush.clear()
	var flush_ranks := [1, 3, 5, 7, 9, 11]
	for i in flush_ranks.size():
		flush[Vector2i(i, 0)] = Cards.id(flush_ranks[i], 0)
	_check(Scoring.evaluate(flush, []).base == Config.SCORES.flush * (1 + Config.LENGTH_BONUS), "Extended flush uses length bonus")
	flush.erase(Vector2i(flush_ranks.size() - 1, 0))
	_check(Scoring.evaluate(flush, []).base == Config.SCORES.flush, "Nonconsecutive flush")
	var cross := _line([7, 7, 7])
	cross[Vector2i(1, -1)] = Cards.id(7, 3)
	result = Scoring.evaluate(cross, cross.values())
	_check(result.combo == 2 and result.base == Config.SCORES.three + Config.SCORES.pair, "Crossing directions share cards and count both groups")
	_check(result.net == result.base * (1 + Config.COMBO_STEP), "Multiplier uses group count")
	var reversed := {}
	var cells: Array = cross.keys()
	cells.reverse()
	for cell in cells:
		reversed[cell] = cross[cell]
	_check(Scoring.evaluate(reversed, []) == Scoring.evaluate(cross, []), "Coordinate ordering makes evaluation deterministic")
	var disjoint := _line([7, 7])
	disjoint[Vector2i(4, 0)] = Cards.id(9, 0)
	disjoint[Vector2i(5, 0)] = Cards.id(9, 1)
	_check(Scoring.evaluate(disjoint, []).combo == 2, "Islands score independently")
	print("Scoring tests: %d failures" % failures)
	quit(1 if failures else 0)

func _line(ranks: Array) -> Dictionary:
	var board := {}
	for i in ranks.size():
		board[Vector2i(i, 0)] = Cards.id(ranks[i], i % Config.SUITS.size())
	return board

func _score(ranks: Array) -> Dictionary:
	return Scoring.evaluate(_line(ranks), [])

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
			var expected: float = Config.SCORES.straight_flush * (1 + (length - Config.EXTENDED_MIN) * Config.LENGTH_BONUS)
			_check(candidates.any(func(group): return group.kind == "straight_flush" and group.score == expected), "Every cyclic starting rank and supported length scores")
	var duplicate: Array = [Cards.id(12, 0), Cards.id(13, 0), Cards.id(1, 0), Cards.id(1, 1), Cards.id(2, 0)]
	_check(not Patterns.candidates(duplicate).any(func(group): return group.kind == "straight"), "Repeated ranks cannot complete a cyclic straight")
