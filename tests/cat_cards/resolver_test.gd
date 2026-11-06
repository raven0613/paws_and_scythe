extends SceneTree

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
const Scoring = preload("res://src/service/gameplay/scoring.gd")
const Resolver = preload("res://src/service/cat_cards/cat_resolver.gd")
var failures := 0

func _init() -> void:
	var board := _line([8, 8], [0, 1])
	var raw := Scoring.evaluate(board, [])
	var original: float = raw.base
	var state := {"hand_count": 2, "settlements": 0, "swaps": 0, "digs": 0}
	var result := Resolver.resolve(raw, board, [], state)
	_check(result.total == raw.total, "Zero cats preserve ordinary scoring")
	var first := Resolver.resolve(raw, board, ["matching", "alternating"], state)
	var second := Resolver.resolve(raw, board, ["alternating", "matching"], state)
	_check(first.total == (original + _value("matching")) * _value("alternating"), "Ordered add then multiply")
	_check(second.total == original * _value("alternating") + _value("matching"), "Reordering changes arithmetic")
	result = Resolver.resolve(raw, board, ["copy", "matching", "combo", "solo", "growth"], state)
	var group_score := original + _value("matching")
	var subtotal := group_score * (1 + _value("copy")) + _value("growth")
	_check(result.total == subtotal * (raw.multiplier + _value("combo")) * _value("solo"), "Copy replays group effects and global effects fire once")
	_check(result.combo == raw.combo, "Replay preserves combo count")
	_check(result.events.filter(func(e): return e.source == "matching").size() == 1, "Copy presents the group cat once")
	_check(result.events.filter(func(e): return e.source == "growth").size() == 1, "Growth is once per settlement")
	_check(raw.base == original and not raw.has("events"), "Preview leaves source evaluation untouched")
	_check(state.settlements == 0, "Preview never commits growth")
	_check(result == Resolver.resolve(raw, board, ["copy", "matching", "combo", "solo", "growth"], state), "Preview is deterministic")
	_check(result.events[-1].after == result.total, "Event flow ends at the exact score")
	result = Resolver.resolve(raw, board, ["pairs", "reserve", "peace"], state)
	_check(result.total == original * (1 + _value("pairs")) * (1 + state.hand_count * _value("reserve")) + _value("peace"), "Each cat combines its own scale before applying")
	state.digs = 1
	_check(Resolver.resolve(raw, board, ["peace"], state).total == raw.total, "Dig disables untouched bonus")
	state.digs = 0
	state.swaps = 1
	_check(Resolver.resolve(raw, board, ["peace"], state).total == raw.total, "Swap disables untouched bonus")
	state.swaps = 0
	state.settlements = Rules.SETTLEMENTS - 1
	_check(Resolver.resolve(raw, board, ["growth"], state).total == original + Rules.SETTLEMENTS * _value("growth"), "Growth uses confirmed settlement count")
	_test_patterns()
	print("Cat resolver: %d failures" % failures)
	quit(1 if failures else 0)

func _test_patterns() -> void:
	var board := _line([8, 8], [0, 1])
	board[Vector2i(0, 1)] = Cards.id(8, 2)
	var raw := Scoring.evaluate(board, [])
	var result := Resolver.resolve(raw, board, ["crossing", "pairs", "small", "variety"], {})
	var expected: float = raw.base * _value("crossing") * (1 + raw.combo * _value("pairs"))
	expected *= (raw.multiplier + _value("variety")) * _value("small")
	_check(result.total == expected, "Crosses score per group, repeated kinds count once for variety")
	_check(Resolver.resolve(raw, board, ["copy", "solo"], {}).total == raw.total, "Single-group cats require exactly one group")
	board = _line([1, 2, 3, 4, 5, 6], [0, 0, 0, 0, 0, 0])
	raw = Scoring.evaluate(board, [])
	result = Resolver.resolve(raw, board, ["suited", "long"], {})
	_check(result.total == raw.total * _value("suited") * (1 + _value("long")), "Long suited hand scales once per cat")
	_check(Resolver.resolve(raw, board, ["small", "alternating", "pairs", "matching", "unique"], {}).total == raw.total, "Ineligible effects preserve score")
	var empty := Scoring.evaluate({}, [])
	_check(Resolver.resolve(empty, {}, ["solo", "small", "unique", "copy", "reserve"], {}).events.filter(func(e): return not e.source.is_empty()).is_empty(), "Empty board has no vacuous conditional activations")
	# Three spatially separated kinds: pair, three, straight.
	board = _line([8, 8], [0, 1])
	for x in 3:
		board[Vector2i(x, 2)] = Cards.id(9, x)
	for x in Rules.EXTENDED_MIN:
		board[Vector2i(x, 4)] = Cards.id(x + 2, x % Rules.SUITS.size())
	raw = Scoring.evaluate(board, [])
	result = Resolver.resolve(raw, board, ["unique", "variety"], {})
	_check(result.total == raw.base * (raw.multiplier + raw.combo * _value("variety")) * _value("unique"), "All distinct kinds activate diversity")
	result = Resolver.resolve(raw, board, ["matching", "reserve"], {"hand_count": 2})
	_check(result.events.filter(func(e): return e.source == "reserve")[0].group == 2, "Highest target uses original scores even after earlier cat boosts")
	_check(Catalog.valid_selection([]) and Catalog.valid_selection(["copy"]), "Zero and single selections are valid")
	_check(not Catalog.valid_selection(["copy", "copy"]) and not Catalog.valid_selection(["missing"]), "Duplicate and unknown cats rejected")
	_check(not Catalog.valid_selection(Catalog.CARDS.keys()), "Selection obeys configured capacity")

func _value(id: String) -> float:
	return Catalog.CARDS[id].value

func _line(ranks: Array, suits: Array) -> Dictionary:
	var board := {}
	for i in ranks.size():
		board[Vector2i(i, 0)] = Cards.id(ranks[i], suits[i])
	return board

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
