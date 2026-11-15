extends SceneTree

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
const Scoring = preload("res://src/service/gameplay/scoring.gd")
const Resolver = preload("res://src/service/cat_cards/cat_resolver.gd")
const Modifiers = preload("res://src/service/cat_cards/rule_modifiers.gd")
var failures := 0

func _init() -> void:
	_test_runs()
	_test_selection()
	_test_extended()
	_test_specialists()
	_test_geometry()
	_test_resources()
	print("Second cat batch: %d failures" % failures)
	quit(1 if failures else 0)

func _test_runs() -> void:
	var fixtures := [
		[[8, 8], 1], [[8, 8, 8], 2], [[8, 8, 8, 8], 3],
		[[8, 8, 9, 9], 2], [[8, 8, 8, 9, 9], 3], [[9, 9, 8, 8, 8], 3],
		[[2, 3, 4, 5, 6], 0], [[8, 9, 8, 9, 8], 0],
	]
	for fixture in fixtures:
		var board := _line(fixture[0])
		var raw := Scoring.evaluate(board, [])
		var result := _resolve(board, ["consecutive"])
		_check(result.total == raw.total + fixture[1] * _value("consecutive"), "Runs count adjacent equal ranks within the adopted group")
		var events: Array = result.events.filter(func(e): return e.source == "consecutive")
		_check(events.size() == (1 if fixture[1] > 0 else 0), "One accumulated addition per group")
	var board := _line([8, 8, 8])
	var raw := Scoring.evaluate(board, [])
	_check(_resolve(board, ["consecutive", "copy"]).total == (raw.base + 2 * _value("consecutive")) * (1 + _value("copy")), "Replay rebuilds the accumulated run bonus")
	board = _line([8, 8])
	board[Vector2i(0, 1)] = Cards.id(8, 2)
	raw = Scoring.evaluate(board, [])
	_check(_resolve(board, ["consecutive"]).total == (raw.base + raw.combo * _value("consecutive")) * raw.multiplier, "Crossing runs count independently in each direction")

func _test_selection() -> void:
	var board := _line([8, 8])
	board.merge(_line([9, 9], 2))
	board[Vector2i(5, 5)] = Cards.id(2, 0)
	var raw := Scoring.evaluate(board, [])
	var result := _resolve(board, ["champion", "copy", "solo", "strays", "single_length"])
	var expected: float = raw.groups[0].score * _value("champion") * (1 + _value("strays")) * (1 + _value("copy"))
	_check(result.total == expected, "Champion permits copy but valid-group solo conditions remain false; strays exclude all recognized cards")
	_check(result.combo == 1 and result.groups[1].total_score == 0 and not result.groups[1].scoring, "Suppressed groups award neither points nor combo")
	_check(result.groups.size() == raw.groups.size(), "Recognition and stable list indices survive selection")
	_check(result.events[0].kind == "selection" and result.events[0].group == 0, "Selection is visible before scoring")
	board = _line([8, 8])
	board.merge(_line([8, 8], 2, 2))
	result = _resolve(board, ["champion"])
	_check(result.groups[0].scoring and not result.groups[1].scoring, "Original highest ties select the first group")
	board = _line([8, 8])
	result = _resolve(board, ["single_length"])
	_check(result.total == Scoring.evaluate(board, []).total * board.size(), "Single valid hand multiplies by its length")

func _test_extended() -> void:
	var minimum: int = Catalog.CARDS.sixfold.rules.extended_min
	var board := _line([2, 3, 4, 5, 6], 0, 0, true)
	_check(_resolve(board, ["sixfold"]).groups.is_empty(), "Five-card straight flush fails modified recognition")
	board = _line([2, 3, 4, 5, 6, 7])
	var raw := Scoring.evaluate(board, [])
	var result := _resolve(board, ["sixfold", "copy"])
	_check(result.groups[0].original_score == raw.groups[0].score, "Long bonus remains anchored to the original minimum")
	_check(result.total == raw.base * (1 + _value("copy")) * (raw.multiplier + _value("sixfold")), "Each qualifying group gives combo once across replays")
	_check(result.groups[0].cells.size() == minimum, "Six-card group qualifies")
	for ranks in [[2, 3, 4, 5, 6, 7], [2, 4, 6, 8, 10, 12]]:
		board = _line(ranks, 0, 0, true)
		raw = Scoring.evaluate(board, [])
		result = _resolve(board, ["sixfold"])
		_check(result.total == raw.base * (raw.multiplier + _value("sixfold")), "Six-card flush and straight flush receive the combo bonus")
		board.erase(Vector2i(minimum - 1, 0))
		_check(_resolve(board, ["sixfold"]).groups.is_empty(), "Five-card suited hands fail the modified threshold")
	board = _line([2, 2, 3, 4, 5, 6])
	result = _resolve(board, ["sixfold"])
	_check(result.groups.size() == 1 and result.groups[0].kind == "pair", "Recognition threshold applies before priority selection")

func _test_specialists() -> void:
	var fixtures := {
		"straights": [2, 3, 4, 5, 6], "flushes": [2, 4, 6, 8, 10],
		"houses": [8, 8, 8, 9, 9], "quads": [8, 8, 8, 8],
	}
	for id in fixtures:
		var board := _line(fixtures[id], 0, 0, id == "flushes")
		var second_ranks: Array = fixtures[id].map(func(rank_value): return rank_value + 2)
		board.merge(_line(second_ranks, 2, 1, id == "flushes"))
		var raw := Scoring.evaluate(board, [])
		var result := _resolve(board, [id])
		_check(result.total == raw.total * (1 + raw.combo * _value(id)), "Specialist accumulates every group including the first: " + id)
	var straight_flush := _line([2, 3, 4, 5, 6], 0, 0, true)
	_check(_resolve(straight_flush, ["straights", "flushes"]).total == Scoring.evaluate(straight_flush, []).total, "Formal straight-flush name triggers neither specialist")

func _test_geometry() -> void:
	var board := _line([8, 8])
	board[Vector2i(0, 2)] = Cards.id(2, 0)
	board[Vector2i(-1, 1)] = Cards.id(3, 0)
	board[Vector2i(1, 1)] = Cards.id(4, 0)
	var raw := Scoring.evaluate(board, [])
	_check(_resolve(board, ["hollow"]).total == raw.total * _value("hollow"), "Four orthogonal neighbors enclose an empty cell")
	board.erase(Vector2i(-1, 1))
	_check(_resolve(board, ["hollow"]).total == Scoring.evaluate(board, []).total, "Three neighbors leave the cell open")
	board[Vector2i(-1, 1)] = Cards.id(3, 0)
	board[Vector2i(0, 1)] = Cards.id(5, 0)
	_check(_resolve(board, ["hollow"]).total == Scoring.evaluate(board, []).total, "Occupied center is not a hole")
	board = _line([8, 8])
	board.merge(_line([9, 9], 2))
	_check(_resolve(board, ["islands"]).total == Scoring.evaluate(board, []).total, "Two islands are below the strict threshold")
	board.merge(_line([10, 10], 4))
	raw = Scoring.evaluate(board, [])
	_check(_resolve(board, ["islands"]).total == raw.total * _value("islands"), "Three scoring islands activate")
	_check(_resolve(board, ["islands", "champion"]).total == _resolve(board, ["champion"]).total, "Every island needs an eligible scoring group")
	board[Vector2i(0, 6)] = Cards.id(2, 0)
	_check(_resolve(board, ["islands"]).total == Scoring.evaluate(board, []).total, "Singleton island prevents activation")

func _test_resources() -> void:
	var board := _line([8, 8])
	var raw := Scoring.evaluate(board, [])
	var state := {"discards_used": 2, "discards_left": Rules.DISCARDS - 2, "operations": 3}
	var result := _resolve(board, ["discarding", "frugal", "industry", "compact"], state)
	var subtotal: float = (raw.base + state.discards_used * _value("discarding")) * _value("compact") + state.operations * _value("industry")
	_check(result.total == subtotal * (raw.multiplier + state.discards_left * _value("frugal")), "Resource effects apply to the intended stages")
	_check(Modifiers.board_limit(["compact"]) == Rules.BOARD_LIMIT + Catalog.CARDS.compact.rules.capacity_delta, "Capacity modifier comes from cat configuration")
	_check(Modifiers.board_limit([]) == Rules.BOARD_LIMIT, "Ordinary capacity remains the default")

func _resolve(board: Dictionary, ids: Array, state: Dictionary = {}) -> Dictionary:
	return Resolver.resolve(Scoring.evaluate(board, [], Modifiers.extended_min(ids)), board, ids, state)

func _line(ranks: Array, y := 0, suit_offset := 0, same_suit := false) -> Dictionary:
	var board := {}
	for x in ranks.size():
		board[Vector2i(x, y)] = Cards.id(ranks[x], suit_offset if same_suit else (x + suit_offset) % Rules.SUITS.size())
	return board

func _value(id: String) -> float:
	return Catalog.CARDS[id].value

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
