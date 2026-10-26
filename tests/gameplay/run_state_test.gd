extends SceneTree

const Config = preload("res://src/configs/gameplay/game_rules.gd")
const Run = preload("res://src/service/gameplay/run_state.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
var failures := 0

func _init() -> void:
	var game = Run.new()
	game.start(Config.TEST_SEED)
	_check(game.hand.size() == Config.HAND_LIMIT, "Deal full opening hand")
	_check(game.deck.draw_pile.size() == Config.DECK_SIZE - Config.HAND_LIMIT, "Opening draw removes cards")
	_check(not game.can_settle(), "Require a newly played card")
	_check(game.settle().is_empty(), "Invalid settle preserves turn")
	_check_unique(game)
	var original: Array = game.hand.duplicate()
	_check(game.place(original[0], Vector2i.ZERO), "Place first card")
	_check(not game.place(original[1], Vector2i.ONE), "Reject diagonal placement")
	_check(game.place(original[1], Vector2i.RIGHT), "Place neighbor")
	_check(game.swap(Vector2i.ZERO, Vector2i.RIGHT), "Swap")
	_check(game.pending_cost() == Config.SWAP_COSTS[0], "First swap cost")
	_check(game.dig(Vector2i.ZERO), "Dig")
	_check(game.pending_cost() == Config.SWAP_COSTS[0] + Config.DIG_COST, "Accumulate fees")
	var discarded: int = game.hand[0]
	_check(game.discard([discarded]), "Discard mid-turn")
	var replacement: int = game.hand[0]
	_check(game.undo() and game.board[Vector2i.ZERO] == original[1], "Undo dig restores swapped card")
	_check(game.pending_cost() == Config.SWAP_COSTS[0], "Undo dig refunds fee")
	_check(game.undo() and game.board[Vector2i.ZERO] == original[0], "Undo swap restores content")
	_check(game.pending_cost() == 0, "Undo swap refunds fee")
	_check(game.undo() and game.undo(), "Undo placements")
	_check(game.hand[0] == original[0] and game.hand[1] == original[1] and game.hand[2] == replacement, "Restore hand order while keeping irreversible discard")
	_check(game.discards_left == Config.DISCARDS - 1 and not game.undo(), "Discard stays spent and has no undo record")
	_check_unique(game)
	game.start(Config.TEST_SEED)
	for i in Config.MAX_PLAYS:
		_check(game.place(game.hand[0], Vector2i(i, 0)), "Up to maximum plays")
	var preview: Dictionary = game.preview()
	var report: Dictionary = game.settle()
	_check(report.net == preview.net, "Preview equals settlement")
	_check(game.board.size() == Config.MAX_PLAYS, "Scoring preserves all cards")
	_check(game.hand.size() == Config.HAND_LIMIT, "Refill after settlement")
	_check(game.turns_left == Config.SETTLEMENTS - 1 and game.history.is_empty(), "Settlement consumes turn and commits history")
	_check(game.played.is_empty(), "Fallback eligibility resets")
	_check_unique(game)
	_test_limits()
	_test_levels()
	_test_capacity()
	_test_reserved_recycling()
	print("Run state tests: %d failures" % failures)
	quit(1 if failures else 0)

func _test_limits() -> void:
	var game = Run.new()
	game.hand_limit = Config.MAX_HAND_LIMIT
	game.start(Config.TEST_SEED)
	for i in Config.MAX_PLAYS:
		game.place(game.hand[0], Vector2i(i, 0))
	_check(not game.place(game.hand[0], Vector2i(Config.MAX_PLAYS, 0)), "Play quota enforced with remaining hand cards")
	_check(game.discard([game.hand[0]]), "Discard remains available at play limit")
	_check_unique(game)
	game.hand_limit = Config.HAND_LIMIT
	game.start(Config.TEST_SEED)
	game.place(game.hand[0], Vector2i.ZERO)
	game.place(game.hand[0], Vector2i.RIGHT)
	for cost in Config.SWAP_COSTS:
		_check(game.next_swap_cost() == cost, "Escalating swap cost")
		_check(game.swap(Vector2i.ZERO, Vector2i.RIGHT), "Swap within quota")
	_check(not game.swap(Vector2i.ZERO, Vector2i.RIGHT), "Swap quota enforced")
	for cell in game.board.keys():
		_check(game.dig(cell), "Dig within quota")
	_check(game.digs_left() == 0, "Dig quota spent")
	_check_unique(game)
	game.settle()
	_check(game.swaps_left() == Config.SWAP_COSTS.size() and game.digs_left() == Config.DIGS, "Paid quotas reset")
	_check(game.score < 0, "Net costs may produce negative score")
	game.start(Config.TEST_SEED)
	_check(not game.discard([]), "Empty discard rejected")
	_check(not game.discard(game.hand.slice(0, Config.MAX_DISCARD + 1)), "Oversized discard rejected")
	for i in Config.DISCARDS:
		_check(game.discard([game.hand[0]]), "Discard within quota")
	_check(not game.discard([game.hand[0]]), "Discard quota enforced")
	_check_unique(game)

func _test_levels() -> void:
	for i in range(1, Config.LEVEL_TARGETS.size()):
		_check(Config.LEVEL_TARGETS[i] > Config.LEVEL_TARGETS[i - 1], "Targets strictly increase")
	var game = Run.new()
	game.start(Config.TEST_SEED)
	game.turns_left = 1
	game.place(game.hand[0], Vector2i.ZERO)
	game.settle()
	_check(game.status == Run.Status.LOST, "Turns exhausted loses")
	game.start(Config.TEST_SEED)
	for level in range(1, Config.LEVEL_TARGETS.size() + 1):
		game.score = game.target()
		game.turns_left = 1
		game.place(game.hand[0], Vector2i.ZERO)
		game.settle()
		if level < Config.LEVEL_TARGETS.size():
			_check(game.status == Run.Status.LEVEL_CLEARED, "Pass takes priority over exhausted turns")
			_check(game.advance(), "Continue to next level")
			_check(game.score == 0 and game.board.is_empty() and game.hand.size() == Config.HAND_LIMIT, "New level resets board and deck")
			_check_unique(game)
		else:
			_check(game.status == Run.Status.WON and not game.advance(), "Final target ends the run")

func _test_capacity() -> void:
	for rescue in [false, true]:
		var game = Run.new()
		game.start(Config.TEST_SEED)
		game.level = Config.LEVEL_TARGETS.size()
		for i in Config.BOARD_LIMIT:
			game.board[Vector2i(i * 2, 0)] = game.deck.draw_pile.pop_back()
		_check(game.place(game.hand[0], Vector2i.RIGHT), "Capacity may be exceeded during operations")
		if rescue:
			for i in Config.DIGS:
				game.dig(Vector2i(i * 2, 0))
		game.settle()
		_check(game.status == (Run.Status.PLAYING if rescue else Run.Status.LOST), "Capacity is checked after final digs")
		_check_unique(game)
	var game = Run.new()
	game.start(Config.TEST_SEED)
	game.score = game.target()
	for i in Config.BOARD_LIMIT:
		game.board[Vector2i(i * 2, 0)] = game.deck.draw_pile.pop_back()
	game.place(game.hand[0], Vector2i.RIGHT)
	game.settle()
	_check(game.status == Run.Status.LEVEL_CLEARED, "Passing score takes priority over full board")

func _test_reserved_recycling() -> void:
	var game = Run.new()
	game.start(Config.TEST_SEED)
	var index := 0
	while not game.deck.draw_pile.is_empty():
		game.board[Vector2i(index, 0)] = game.deck.draw_pile.pop_back()
		index += 1
	var dug: int = game.board[Vector2i.ZERO]
	game.dig(Vector2i.ZERO)
	game.discard(game.hand.slice(0, Config.MAX_DISCARD))
	_check(not game.hand.has(dug), "Recycling excludes reversible dug cards")
	_check(game.undo() and game.board[Vector2i.ZERO] == dug, "Dig restores after discard pile recycled")
	_check_unique(game)

func _check_unique(game) -> void:
	var all: Array = game.hand + game.board.values() + game.deck.draw_pile + game.deck.discard_pile + game.reserved_cards()
	var unique := {}
	for card in all:
		unique[card] = true
	_check(all.size() == Config.DECK_SIZE and unique.size() == Config.DECK_SIZE, "All physical cards exist in exactly one location")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
