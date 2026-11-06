extends SceneTree

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Run = preload("res://src/service/gameplay/run_state.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
const Effects = preload("res://src/service/cat_cards/effect_rules.gd")
var failures := 0

func _init() -> void:
	_test_run_history()
	_test_discards()
	_test_capacity()
	_test_current_amounts()
	print("Cat resource state: %d failures" % failures)
	quit(1 if failures else 0)

func _test_run_history() -> void:
	var game = Run.new()
	game.start(Rules.TEST_SEED)
	var confirmed := 0
	for level in Rules.LEVEL_TARGETS.size():
		# First level records history before the permanent-growth cat is equipped.
		if level == 1:
			game.cats.ids = ["industry"]
		game.score = game.target() + Rules.SWAP_COSTS[0] + Rules.DIG_COST
		game.place(game.hand[0], Vector2i.ZERO)
		game.place(game.hand[0], Vector2i.RIGHT)
		var before: Dictionary = game.preview()
		var balance: float = game.score
		_check(not game.swap(Vector2i.ZERO, Vector2i.ZERO), "Invalid exchange adds no history")
		_check(game.swap(Vector2i.ZERO, Vector2i.RIGHT), "Exchange succeeds")
		_check(game.cat_state().operations == confirmed + 1, "Exchange counts once for two swapped cards")
		game.undo()
		_check(game.preview() == before and game.score == balance, "Undo restores score, counters and exact preview")
		game.swap(Vector2i.ZERO, Vector2i.RIGHT)
		game.dig(Vector2i.RIGHT)
		_check(game.cat_state().operations == confirmed + 2, "Dig adds one pending operation")
		game.undo()
		_check(game.cat_state().operations == confirmed + 1, "Undo dig removes its pending bonus")
		game.dig(Vector2i.RIGHT)
		var snapshot: Dictionary = game.preview()
		_check(game.preview() == snapshot and game.cats.operations == confirmed, "Repeated previews leave confirmed growth unchanged")
		if level > 0:
			var effects: Array = snapshot.events.filter(func(e): return e.source == "industry")
			_check(effects.size() == 1 and effects[0].amount == (confirmed + 2) * Catalog.CARDS.industry.value, "Growth includes past levels and pending actions exactly once")
		confirmed += 2
		var result: Dictionary = game.settle(snapshot)
		_check(result == snapshot and game.cats.operations == confirmed, "Settlement commits operations once")
		_check(game.settle().is_empty() and game.cats.operations == confirmed, "Completed settlement cannot commit a second time")
		if level < Rules.LEVEL_TARGETS.size() - 1:
			_check(game.advance(), "Advance through the full run")
			_check(game.cats.operations == confirmed and game.cats.settlements == 0, "Permanent operations survive per-level reset")
	_check(game.status == Run.Status.WON, "Full 21-level history ends in victory")
	game.start(Rules.TEST_SEED, ["industry"])
	_check(game.cats.operations == 0 and not game.preview().events.any(func(e): return e.source == "industry"), "New run resets permanent growth")

func _test_discards() -> void:
	var game = Run.new()
	game.start(Rules.TEST_SEED, ["discarding", "frugal"])
	game.place(game.hand[0], Vector2i.ZERO)
	_check(game.discard(game.hand.slice(0, Rules.MAX_DISCARD)), "Discard up to the configured limit")
	game.undo()
	_check(game.cat_state().discards_used == 1, "Undoing a placement preserves confirmed discard count")
	_check(game.cat_state().discards_left == Rules.DISCARDS - 1, "Multiple cards consume one discard opportunity")
	_check(not game.discard([]) and game.cat_state().discards_used == 1, "Invalid discard leaves bonuses unchanged")
	game.place(game.hand[0], Vector2i.ZERO)
	game.score = game.target()
	game.settle()
	game.advance()
	_check(game.cat_state().discards_used == 0 and game.cat_state().discards_left == Rules.DISCARDS, "Discard growth and reserve reset each level")

func _test_capacity() -> void:
	var game = Run.new()
	for offset in [-1, 0]:
		game.start(Rules.TEST_SEED, ["compact"])
		game.level = Rules.LEVEL_TARGETS.size()
		_fill_board(game, game.board_limit() + offset)
		game.settle()
		_check(game.status == (Run.Status.PLAYING if offset < 0 else Run.Status.LOST), "Capacity is checked at the modified threshold after settlement")
	game.start(Rules.TEST_SEED, ["compact"])
	_fill_board(game, game.board_limit())
	game.score = game.target()
	game.settle()
	_check(game.status == Run.Status.LEVEL_CLEARED, "Victory takes priority over reaching modified capacity")

func _test_current_amounts() -> void:
	var game = Run.new()
	game.start(Rules.TEST_SEED, ["growth", "industry", "discarding", "frugal"])
	var expected := {
		"growth": Catalog.CARDS.growth.value,
		"industry": 0.0,
		"discarding": 0.0,
		"frugal": Rules.DISCARDS * Catalog.CARDS.frugal.value,
	}
	_check_current_amounts(game, expected)
	game.board = {Vector2i.ZERO: Cards.id(8, 0), Vector2i.RIGHT: Cards.id(8, 1)}
	game.played = game.board.values()
	game.score = game.target() + Rules.SWAP_COSTS[0] + Rules.DIG_COST
	game.swap(Vector2i.ZERO, Vector2i.RIGHT)
	expected.industry += Catalog.CARDS.industry.value
	_check_current_amounts(game, expected)
	game.dig(Vector2i.RIGHT)
	expected.industry += Catalog.CARDS.industry.value
	_check_current_amounts(game, expected)
	game.undo()
	expected.industry -= Catalog.CARDS.industry.value
	_check_current_amounts(game, expected)
	for used in Rules.DISCARDS:
		_check(game.discard([game.hand[0]]), "Discard advances current bonuses")
		expected.discarding = (used + 1) * Catalog.CARDS.discarding.value
		expected.frugal = (Rules.DISCARDS - used - 1) * Catalog.CARDS.frugal.value
		_check_current_amounts(game, expected)
	game.settle()
	expected.growth += Catalog.CARDS.growth.value
	_check_current_amounts(game, expected)
	_check(game.advance(), "Current bonuses follow level transitions")
	expected.growth = Catalog.CARDS.growth.value
	expected.discarding = 0.0
	expected.frugal = Rules.DISCARDS * Catalog.CARDS.frugal.value
	_check_current_amounts(game, expected)

func _check_current_amounts(game: RefCounted, expected: Dictionary) -> void:
	var state: Dictionary = game.cat_state()
	var snapshot: Dictionary = game.preview()
	for id in expected:
		var amount := Effects.amount(Catalog.CARDS[id], state, -1)
		_check(is_equal_approx(amount, expected[id]), "Current %s amount follows live state" % id)
		for event in snapshot.events:
			if event.source == id:
				_check(is_equal_approx(event.amount, amount), "Current %s amount matches settlement arithmetic" % id)

func _fill_board(game: RefCounted, count: int) -> void:
	game.board.clear()
	for i in count:
		game.board[Vector2i(i, 0)] = i
	game.played = [count - 1]

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
